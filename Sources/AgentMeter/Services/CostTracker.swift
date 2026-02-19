import Foundation
import SwiftUI

@MainActor
class CostTracker: ObservableObject {
    @Published var todayCost: Double = 0
    @Published var weekCost: Double = 0
    @Published var monthCost: Double = 0
    @Published var agentCosts: [AgentCost] = []
    @Published var providers: [ProviderUsage] = []
    @Published var dailyCosts: [DailyCost] = []
    @Published var isLoading: Bool = false
    @Published var lastRefresh: Date?
    @Published var budgetLimit: Double = 10.0
    @Published var budgetAlertShown: Bool = false

    private let anthropic = AnthropicProvider()
    private let openRouter = OpenRouterProvider()

    init() {
        // Load budget from UserDefaults
        budgetLimit = UserDefaults.standard.double(forKey: "budgetLimit")
        if budgetLimit == 0 { budgetLimit = 10.0 }
    }

    func refreshAll() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch Anthropic usage from logs
            let anthropicRecords = try await anthropic.fetchUsage()

            // Fetch OpenRouter usage
            let openRouterUsage = try await openRouter.fetchUsage()

            // Calculate today's cost
            let calendar = Calendar.current
            let now = Date()
            let todayRecords = anthropicRecords.filter { calendar.isDateInToday($0.timestamp) }

            todayCost = todayRecords.reduce(0) { $0 + $1.cost } + openRouterUsage.totalCost

            // Calculate week cost
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let weekRecords = anthropicRecords.filter { $0.timestamp >= weekStart }
            weekCost = weekRecords.reduce(0) { $0 + $1.cost } + openRouterUsage.totalCost

            // Calculate month cost
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let monthRecords = anthropicRecords.filter { $0.timestamp >= monthStart }
            monthCost = monthRecords.reduce(0) { $0 + $1.cost } + openRouterUsage.totalCost

            // Group by agent
            var agentMap: [String: (cost: Double, tokens: Int)] = [:]
            for record in todayRecords {
                let existing = agentMap[record.agent] ?? (0, 0)
                agentMap[record.agent] = (
                    existing.cost + record.cost,
                    existing.tokens + record.inputTokens + record.outputTokens
                )
            }

            let totalAgentCost = max(agentMap.values.reduce(0) { $0 + $1.cost }, 0.001)
            agentCosts = agentMap.map { name, data in
                AgentCost(
                    name: name,
                    cost: data.cost,
                    tokens: data.tokens,
                    percentage: (data.cost / totalAgentCost) * 100
                )
            }.sorted { $0.cost > $1.cost }

            // Provider summary
            let anthropicTotal = todayRecords.reduce(0) { $0 + $1.cost }
            providers = [
                ProviderUsage(
                    name: "Anthropic",
                    totalCost: anthropicTotal,
                    remainingCredit: nil,
                    agents: agentCosts
                ),
                openRouterUsage
            ]

            lastRefresh = Date()

            // Budget alert
            if todayCost >= budgetLimit && !budgetAlertShown {
                budgetAlertShown = true
                showBudgetAlert()
            }

        } catch {
            print("Error refreshing: \(error)")
        }
    }

    func setBudgetLimit(_ limit: Double) {
        budgetLimit = limit
        UserDefaults.standard.set(limit, forKey: "budgetLimit")
        budgetAlertShown = false
    }

    private func showBudgetAlert() {
        let alert = NSAlert()
        alert.messageText = "Budget Alert"
        alert.informativeText = String(format: "Today's AI spending (%.2f€) has exceeded your budget of %.2f€", todayCost, budgetLimit)
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
