import Foundation

struct UsageRecord: Identifiable, Codable {
    let id: UUID
    let provider: String
    let agent: String
    let model: String
    let inputTokens: Int
    let outputTokens: Int
    let cost: Double
    let timestamp: Date

    init(provider: String, agent: String, model: String, inputTokens: Int, outputTokens: Int, cost: Double, timestamp: Date = Date()) {
        self.id = UUID()
        self.provider = provider
        self.agent = agent
        self.model = model
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cost = cost
        self.timestamp = timestamp
    }
}

struct AgentCost: Identifiable {
    let id = UUID()
    let name: String
    let cost: Double
    let tokens: Int
    let percentage: Double
}

struct ProviderUsage: Identifiable {
    let id = UUID()
    let name: String
    let totalCost: Double
    let remainingCredit: Double?
    let agents: [AgentCost]
}

struct DailyCost: Identifiable {
    let id = UUID()
    let date: Date
    let cost: Double
}

// MARK: - Anthropic API Response
struct AnthropicUsageResponse: Codable {
    let data: [AnthropicUsageItem]?

    struct AnthropicUsageItem: Codable {
        let inputTokens: Int?
        let outputTokens: Int?
        let model: String?
        let date: String?

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
            case model
            case date
        }
    }
}

// MARK: - OpenRouter API Response
struct OpenRouterKeyResponse: Codable {
    let data: OpenRouterKeyData?

    struct OpenRouterKeyData: Codable {
        let label: String?
        let usage: Double?
        let limit: Double?
        let isFreeTier: Bool?
        let rateLimitInterval: String?
        let rateLimitRequests: Int?

        enum CodingKeys: String, CodingKey {
            case label
            case usage
            case limit
            case isFreeTier = "is_free_tier"
            case rateLimitInterval = "rate_limit_interval"
            case rateLimitRequests = "rate_limit_requests"
        }
    }
}

// MARK: - Pricing
struct ModelPricing {
    static let anthropic: [String: (input: Double, output: Double)] = [
        "claude-sonnet-4-20250514": (3.0 / 1_000_000, 15.0 / 1_000_000),
        "claude-opus-4-6": (15.0 / 1_000_000, 75.0 / 1_000_000),
        "claude-3-5-haiku-20241022": (0.80 / 1_000_000, 4.0 / 1_000_000),
        "claude-3-5-sonnet-20241022": (3.0 / 1_000_000, 15.0 / 1_000_000),
    ]

    static func costFor(model: String, inputTokens: Int, outputTokens: Int) -> Double {
        let pricing = anthropic[model] ?? (3.0 / 1_000_000, 15.0 / 1_000_000)
        return (Double(inputTokens) * pricing.input) + (Double(outputTokens) * pricing.output)
    }
}
