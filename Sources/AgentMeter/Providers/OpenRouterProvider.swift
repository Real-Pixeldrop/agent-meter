import Foundation

actor OpenRouterProvider {
    private let baseURL = "https://openrouter.ai/api/v1"

    var apiKey: String? {
        KeychainHelper.load(key: "openrouter_api_key")
    }

    func fetchUsage() async throws -> ProviderUsage {
        guard let key = apiKey, !key.isEmpty else {
            return ProviderUsage(name: "OpenRouter", totalCost: 0, remainingCredit: nil, agents: [])
        }

        guard let url = URL(string: "\(baseURL)/auth/key") else {
            return ProviderUsage(name: "OpenRouter", totalCost: 0, remainingCredit: nil, agents: [])
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenRouterKeyResponse.self, from: data)

        let usage = response.data?.usage ?? 0
        let limit = response.data?.limit

        let remaining: Double? = limit.map { $0 - usage }

        return ProviderUsage(
            name: "OpenRouter",
            totalCost: usage,
            remainingCredit: remaining,
            agents: []
        )
    }
}
