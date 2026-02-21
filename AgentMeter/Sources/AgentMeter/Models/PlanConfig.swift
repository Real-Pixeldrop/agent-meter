import Foundation

enum AIPlan: String, CaseIterable, Codable {
    case none = "No Plan (Pay-per-use)"
    case anthropicMax = "Anthropic Max ($200/mo)"
    case anthropicPro = "Anthropic Pro ($20/mo)"
    case chatgptPlus = "ChatGPT Plus ($20/mo)"
    case chatgptPro = "ChatGPT Pro ($200/mo)"
    case custom = "Custom"

    var monthlyCost: Double {
        switch self {
        case .none: return 0
        case .anthropicMax: return 200
        case .anthropicPro: return 20
        case .chatgptPlus: return 20
        case .chatgptPro: return 200
        case .custom: return UserDefaults.standard.double(forKey: "customPlanCost")
        }
    }

    var displayName: String { rawValue }
}

struct PlanSavings {
    let planCost: Double
    let theoreticalCost: Double

    var savings: Double { max(theoreticalCost - planCost, 0) }
    var multiplier: Double { planCost > 0 ? theoreticalCost / planCost : 0 }
    var isWorthIt: Bool { theoreticalCost > planCost }
}
