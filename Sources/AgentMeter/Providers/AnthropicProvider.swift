import Foundation

actor AnthropicProvider {

    func fetchUsage() async throws -> [UsageRecord] {
        // Parse Clawdbot session JSONL files for real usage data
        return try await parseClawdbotSessions()
    }

    private func parseClawdbotSessions() async throws -> [UsageRecord] {
        var records: [UsageRecord] = []
        let homeDir = NSHomeDirectory()
        let agentsDir = homeDir + "/.clawdbot/agents"

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: agentsDir) else { return [] }

        // Map agent folder names to display names
        let agentNames: [String: String] = [
            "main": "Claudia",
            "mike": "Mike",
            "plaza-marketing": "Valentina",
            "clea": "Clea",
            "donald": "Donald",
            "groupas": "GroupAs",
        ]

        let today = Calendar.current.startOfDay(for: Date())
        let weekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!

        // Scan each agent directory
        guard let agentDirs = try? fileManager.contentsOfDirectory(atPath: agentsDir) else { return [] }

        for agentDir in agentDirs {
            let sessionsPath = agentsDir + "/" + agentDir + "/sessions"
            guard fileManager.fileExists(atPath: sessionsPath) else { continue }
            guard let sessionFiles = try? fileManager.contentsOfDirectory(atPath: sessionsPath) else { continue }

            let displayName = agentNames[agentDir] ?? agentDir

            for sessionFile in sessionFiles {
                guard sessionFile.hasSuffix(".jsonl") else { continue }
                let filePath = sessionsPath + "/" + sessionFile

                // Only read files modified in the last 31 days
                guard let attrs = try? fileManager.attributesOfItem(atPath: filePath),
                      let modDate = attrs[.modificationDate] as? Date,
                      modDate >= monthStart else { continue }

                guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else { continue }

                for line in content.components(separatedBy: "\n") {
                    guard line.contains("\"usage\"") && line.contains("\"cost\"") else { continue }

                    // Parse JSON
                    guard let data = line.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let message = json["message"] as? [String: Any],
                          let usage = message["usage"] as? [String: Any],
                          let costObj = usage["cost"] as? [String: Any],
                          let totalCost = costObj["total"] as? Double,
                          let timestampStr = json["timestamp"] as? String else { continue }

                    // Parse timestamp
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    guard let timestamp = formatter.date(from: timestampStr) else { continue }

                    // Only include records from this month
                    guard timestamp >= monthStart else { continue }

                    let model = message["model"] as? String ?? "unknown"
                    let inputTokens = usage["input"] as? Int ?? 0
                    let outputTokens = usage["output"] as? Int ?? 0
                    let cacheRead = usage["cacheRead"] as? Int ?? 0
                    let cacheWrite = usage["cacheWrite"] as? Int ?? 0

                    records.append(UsageRecord(
                        provider: "Anthropic",
                        agent: displayName,
                        model: model,
                        inputTokens: inputTokens + cacheRead + cacheWrite,
                        outputTokens: outputTokens,
                        cost: totalCost,
                        timestamp: timestamp
                    ))
                }
            }
        }

        return records
    }
}
