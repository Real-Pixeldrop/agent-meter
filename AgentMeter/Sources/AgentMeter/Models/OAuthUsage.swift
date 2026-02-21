import Foundation

struct OAuthUsage {
    let sessionUtilization: Double   // 0-100
    let sessionResetsAt: Date?
    let weeklyUtilization: Double    // 0-100
    let weeklyResetsAt: Date?
    let sonnetUtilization: Double?
    let sonnetResetsAt: Date?
    let extraUsageEnabled: Bool
    let extraUsageLimit: Int
    let extraUsageUsed: Double
    let extraUsageUtilization: Double

    var sessionRemaining: Double { max(0, 100 - sessionUtilization) }
    var weeklyRemaining: Double { max(0, 100 - weeklyUtilization) }

    var sessionTimeLeft: String {
        guard let resetsAt = sessionResetsAt else { return "?" }
        return Self.timeUntil(resetsAt)
    }

    var weeklyTimeLeft: String {
        guard let resetsAt = weeklyResetsAt else { return "?" }
        return Self.timeUntil(resetsAt)
    }

    var isSessionCritical: Bool { sessionUtilization > 80 }
    var isSessionWarning: Bool { sessionUtilization > 50 }
    var isWeeklyCritical: Bool { weeklyUtilization > 80 }
    var isWeeklyWarning: Bool { weeklyUtilization > 50 }

    static func timeUntil(_ date: Date) -> String {
        let secs = Int(date.timeIntervalSinceNow)
        if secs <= 0 { return "now" }
        let days = secs / 86400
        let hours = (secs % 86400) / 3600
        let mins = (secs % 3600) / 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(mins)m" }
        return "\(mins)m"
    }
}
