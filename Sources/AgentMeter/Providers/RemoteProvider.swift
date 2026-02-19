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
