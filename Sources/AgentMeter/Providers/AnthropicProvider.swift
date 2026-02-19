import Foundation

actor AnthropicProvider {
    private let baseURL = "https://api.anthropic.com/v1"

    var apiKey: String? {
        KeychainHelper.load(key: "anthropic_api_key")
    }

    func fetchUsage() async throws -> [UsageRecord] {
        guard let key = apiKey, !key.isEmpty else {
            return []
        }

        // Anthropic admin API for usage
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
        guard let url = URL(string: "\(baseURL)/messages/count_tokens") else {
            return []
        }

        // For now, parse Clawdbot logs to get usage data
        // Anthropic doesn't have a public usage API yet
        // We'll read from local gateway logs
        return try await parseClawdbotLogs()
    }

    private func parseClawdbotLogs() async throws -> [UsageRecord] {
        var records: [UsageRecord] = []

        let logPath = NSHomeDirectory() + "/.clawdbot/logs/gateway.log"
        guard FileManager.default.fileExists(atPath: logPath) else { return [] }

        guard let content = try? String(contentsOfFile: logPath, encoding: .utf8) else { return [] }

        let lines = content.components(separatedBy: "\n")
        let today = formatDate(Date())

        for line in lines.suffix(5000) {
            // Parse lines with token usage info
            guard line.contains(today),
                  line.contains("tokens") || line.contains("usage") else { continue }

            // Extract agent name from log line
            let agent = extractAgent(from: line)
            let model = extractModel(from: line)
            let (input, output) = extractTokens(from: line)

            if input > 0 || output > 0 {
                let cost = ModelPricing.costFor(model: model, inputTokens: input, outputTokens: output)
                records.append(UsageRecord(
                    provider: "Anthropic",
                    agent: agent,
                    model: model,
                    inputTokens: input,
                    outputTokens: output,
                    cost: cost
                ))
            }
        }

        return records
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func extractAgent(from line: String) -> String {
        if line.contains("agents/main") { return "Claudia" }
        if line.contains("agents/mike") { return "Mike" }
        if line.contains("agents/plaza") { return "Valentina" }
        if line.contains("agents/clea") { return "Clea" }
        return "Unknown"
    }

    private func extractModel(from line: String) -> String {
        let models = ["claude-opus-4-6", "claude-sonnet-4-20250514", "claude-3-5-haiku", "claude-3-5-sonnet"]
        for model in models {
            if line.contains(model) { return model }
        }
        return "claude-sonnet-4-20250514"
    }

    private func extractTokens(from line: String) -> (Int, Int) {
        // Try to match patterns like "input_tokens":1234 or inputTokens: 1234
        let inputPattern = try! NSRegularExpression(pattern: #"(?:input_tokens|inputTokens)[\"\s:]+(\d+)"#)
        let outputPattern = try! NSRegularExpression(pattern: #"(?:output_tokens|outputTokens)[\"\s:]+(\d+)"#)

        let nsString = line as NSString
        
        let inputMatch = inputPattern.firstMatch(in: line, options: [], range: NSRange(location: 0, length: nsString.length))
        let outputMatch = outputPattern.firstMatch(in: line, options: [], range: NSRange(location: 0, length: nsString.length))
        
        let input = inputMatch?.range(at: 1).location != NSNotFound ? Int(nsString.substring(with: inputMatch!.range(at: 1))) ?? 0 : 0
        let output = outputMatch?.range(at: 1).location != NSNotFound ? Int(nsString.substring(with: outputMatch!.range(at: 1))) ?? 0 : 0

        return (input, output)
    }
}
