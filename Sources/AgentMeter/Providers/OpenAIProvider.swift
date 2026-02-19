import Foundation

actor OpenAIProvider {

    var apiKey: String? {
        KeychainHelper.load(key: "openai_api_key")
    }

    func fetchUsage() async throws -> [UsageRecord] {
        guard let key = apiKey, !key.isEmpty else {
            return []
        }

        // OpenAI usage endpoint - get costs for current billing period
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = dateFormatter.string(from: startOfMonth)
        let endDate = dateFormatter.string(from: now)

        guard let url = URL(string: "https://api.openai.com/v1/usage?date=\(startDate)") else {
            return []
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // Fallback: try the billing endpoint
                return try await fetchBillingUsage(apiKey: key, startDate: startDate, endDate: endDate)
            }

            // Parse usage response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataArray = json["data"] as? [[String: Any]] {
                var records: [UsageRecord] = []
                for item in dataArray {
                    let tokens = item["n_context_tokens_total"] as? Int ?? 0
                    let generatedTokens = item["n_generated_tokens_total"] as? Int ?? 0
                    let model = item["snapshot_id"] as? String ?? "gpt-4"

                    let cost = calculateOpenAICost(model: model, inputTokens: tokens, outputTokens: generatedTokens)

                    records.append(UsageRecord(
                        provider: "OpenAI",
                        agent: "ChatGPT",
                        model: model,
                        inputTokens: tokens,
                        outputTokens: generatedTokens,
                        cost: cost,
                        timestamp: now
                    ))
                }
                return records
            }

            return []
        } catch {
            return []
        }
    }

    private func fetchBillingUsage(apiKey: String, startDate: String, endDate: String) async throws -> [UsageRecord] {
        guard let url = URL(string: "https://api.openai.com/dashboard/billing/usage?start_date=\(startDate)&end_date=\(endDate)") else {
            return []
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let totalUsage = json["total_usage"] as? Double {
            // total_usage is in cents
            return [UsageRecord(
                provider: "OpenAI",
                agent: "ChatGPT",
                model: "gpt-4",
                inputTokens: 0,
                outputTokens: 0,
                cost: totalUsage / 100.0,
                timestamp: Date()
            )]
        }

        return []
    }

    private func calculateOpenAICost(model: String, inputTokens: Int, outputTokens: Int) -> Double {
        // Pricing per 1M tokens
        let pricing: (input: Double, output: Double)
        if model.contains("gpt-4o") {
            pricing = (2.5 / 1_000_000, 10.0 / 1_000_000)
        } else if model.contains("gpt-4") {
            pricing = (30.0 / 1_000_000, 60.0 / 1_000_000)
        } else if model.contains("gpt-3.5") {
            pricing = (0.5 / 1_000_000, 1.5 / 1_000_000)
        } else if model.contains("o1") || model.contains("o3") {
            pricing = (15.0 / 1_000_000, 60.0 / 1_000_000)
        } else {
            pricing = (2.5 / 1_000_000, 10.0 / 1_000_000)
        }
        return (Double(inputTokens) * pricing.input) + (Double(outputTokens) * pricing.output)
    }
}
