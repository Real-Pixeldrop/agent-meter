import Foundation

struct SessionInfo: Identifiable {
    let id: String
    let agent: String
    let model: String
    let contextTokens: Int
    let contextLimit: Int
    let lastActivity: Date
    let messageCount: Int
    let sessionCost: Double

    var contextUsage: Double {
        guard contextLimit > 0 else { return 0 }
        return Double(contextTokens) / Double(contextLimit)
    }

    var isNearCompaction: Bool { contextUsage > 0.75 }
    var isCritical: Bool { contextUsage > 0.90 }

    static func contextLimitForModel(_ model: String) -> Int {
        // Opus 4.6 supports 1M tokens in beta
        if model.contains("opus-4-6") || model.contains("opus-4.6") || model.contains("opus_4_6") { return 1_000_000 }
        if model.contains("opus") { return 200_000 }
        if model.contains("sonnet") { return 200_000 }
        if model.contains("haiku") { return 200_000 }
        if model.contains("gpt-4o") { return 128_000 }
        if model.contains("gpt-4") { return 128_000 }
        if model.contains("o1") || model.contains("o3") { return 200_000 }
        if model.contains("gemini") { return 1_000_000 }
        return 200_000
    }
}
