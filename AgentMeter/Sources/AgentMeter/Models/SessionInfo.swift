import Foundation

struct SessionInfo: Identifiable {
    let id: String
    let agent: String
    let agentId: String
    let model: String
    let configuredModel: String
    let authMode: String
    let contextTokens: Int
    let contextLimit: Int
    let lastActivity: Date
    let messageCount: Int
    let sessionCost: Double
    let compactions: Int

    var contextUsage: Double {
        guard contextLimit > 0 else { return 0 }
        return Double(contextTokens) / Double(contextLimit)
    }

    var isNearCompaction: Bool { contextUsage > 0.75 }
    var isCritical: Bool { contextUsage > 0.90 }

    var isOAuth: Bool { authMode == "oauth" }
}
