import Foundation

actor RemoteProvider {
    private var serverURL: String {
        UserDefaults.standard.string(forKey: "remoteServerURL") ?? ""
    }

    var isConfigured: Bool {
        !serverURL.isEmpty
    }

    func fetchUsage() async throws -> (records: [UsageRecord], hasClawdbot: Bool) {
        let url = serverURL.isEmpty ? "" : serverURL
        guard !url.isEmpty, let endpoint = URL(string: url + "/api/usage") else {
            return ([], false)
        }

        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return ([], false)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let recordsArray = json["records"] as? [[String: Any]],
              let hasClawdbot = json["hasClawdbot"] as? Bool else {
            return ([], false)
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var records: [UsageRecord] = []
        for item in recordsArray {
            let provider = item["provider"] as? String ?? "Unknown"
            let agent = item["agent"] as? String ?? "Unknown"
            let model = item["model"] as? String ?? "unknown"
            let inputTokens = item["inputTokens"] as? Int ?? 0
            let outputTokens = item["outputTokens"] as? Int ?? 0
            let cost = item["cost"] as? Double ?? 0
            let timestampStr = item["timestamp"] as? String ?? ""
            let timestamp = formatter.date(from: timestampStr) ?? Date()

            records.append(UsageRecord(
                provider: provider,
                agent: agent,
                model: model,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                cost: cost,
                timestamp: timestamp
            ))
        }

        return (records, hasClawdbot)
    }

    func fetchSessions() async throws -> [SessionInfo] {
        let url = serverURL
        guard !url.isEmpty, let endpoint = URL(string: url + "/api/sessions") else { return [] }

        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return [] }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sessionsArray = json["sessions"] as? [[String: Any]] else { return [] }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return sessionsArray.compactMap { item in
            guard let id = item["id"] as? String,
                  let agent = item["agent"] as? String,
                  let model = item["model"] as? String,
                  let contextTokens = item["contextTokens"] as? Int,
                  let contextLimit = item["contextLimit"] as? Int else { return nil }

            let lastTs = item["lastActivity"] as? String ?? ""
            let lastActivity = formatter.date(from: lastTs) ?? Date()
            let messageCount = item["messageCount"] as? Int ?? 0
            let sessionCost = item["sessionCost"] as? Double ?? 0
            let agentId = item["agentId"] as? String ?? ""
            let configuredModel = item["configuredModel"] as? String ?? model
            let authMode = item["authMode"] as? String ?? "unknown"
            let compactions = item["compactions"] as? Int ?? 0

            return SessionInfo(
                id: id,
                agent: agent,
                agentId: agentId,
                model: model,
                configuredModel: configuredModel,
                authMode: authMode,
                contextTokens: contextTokens,
                contextLimit: contextLimit,
                lastActivity: lastActivity,
                messageCount: messageCount,
                sessionCost: sessionCost,
                compactions: compactions
            )
        }
    }

    func fetchOAuthUsage() async throws -> OAuthUsage? {
        let url = serverURL
        guard !url.isEmpty, let endpoint = URL(string: url + "/api/oauth") else { return nil }

        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        // Check for error
        if json["error"] != nil { return nil }

        let session = json["session"] as? [String: Any] ?? [:]
        let weekly = json["weekly"] as? [String: Any] ?? [:]
        let sonnet = json["sonnet"] as? [String: Any]
        let extra = json["extra_usage"] as? [String: Any]

        return OAuthUsage(
            sessionUtilization: session["utilization"] as? Double ?? 0,
            sessionResetsAt: Self.parseDate(session["resets_at"] as? String),
            weeklyUtilization: weekly["utilization"] as? Double ?? 0,
            weeklyResetsAt: Self.parseDate(weekly["resets_at"] as? String),
            sonnetUtilization: sonnet?["utilization"] as? Double,
            sonnetResetsAt: Self.parseDate(sonnet?["resets_at"] as? String),
            extraUsageEnabled: extra?["enabled"] as? Bool ?? false,
            extraUsageLimit: extra?["monthly_limit"] as? Int ?? 0,
            extraUsageUsed: extra?["used_credits"] as? Double ?? 0,
            extraUsageUtilization: extra?["utilization"] as? Double ?? 0
        )
    }

    private static func parseDate(_ str: String?) -> Date? {
        guard let str = str, !str.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: str) { return d }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        // Handle timezone offset format
        let cleaned = str.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression)
        return formatter.date(from: cleaned)
    }

    func checkHealth() async -> Bool {
        let url = serverURL
        guard !url.isEmpty, let endpoint = URL(string: url + "/api/health") else { return false }

        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 5

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}
