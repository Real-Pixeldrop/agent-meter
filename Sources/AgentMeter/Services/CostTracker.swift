import Foundation
import SwiftUI

@MainActor
class CostTracker: ObservableObject {
    @Published var todayCost: Double = 0
    @Published var weekCost: Double = 0
    @Published var monthCost: Double = 0
    @Published var agentCosts: [AgentCost] = []
    @Published var providers: [ProviderUsage] = []
    @Published var isLoading: Bool = false
    @Published var lastRefresh: Date?
    @Published var budgetLimit: Double = 10.0
    @Published var budgetAlertShown: Bool = false
    @Published var hasClawdbot: Bool = false
    @Published var selectedPlan: AIPlan = .none
    @Published var planSavings: PlanSavings?
    @Published var isRemote: Bool = false

    private let anthropic = AnthropicProvider()
    private let openRouter = OpenRouterProvider()
    private let openAI = OpenAIProvider()
    private let remote = RemoteProvider()

    init() {
        budgetLimit = UserDefaults.standard.double(forKey: "budgetLimit")
        if budgetLimit == 0 { budgetLimit = 10.0 }

        if let planRaw = UserDefaults.standard.string(forKey: "selectedPlan"),
           let plan = AIPlan(rawValue: planRaw) {
            selectedPlan = plan
        }

        // Detect local Clawdbot
        let clawdbotPath = NSHomeDirectory() + "/.clawdbot/agents"
        hasClawdbot = FileManager.default.fileExists(atPath: clawdbotPath)
    }

    func refreshAll() async {
        isLoading = true
        defer { isLoading = false }

        do {
            var allRecords: [UsageRecord] = []

            // Try remote server first if configured
            let remoteConfigured = await remote.isConfigured
            if remoteConfigured {
                let remoteHealth = await remote.checkHealth()
                if remoteHealth {
                    let (remoteRecords, remoteHasClawdbot) = try await remote.fetchUsage()
                    allRecords.append(contentsOf: remoteRecords)
                    hasClawdbot = remoteHasClawdbot
                    isRemote = true
                }
            }

            // If no remote data, use local sources
            if allRecords.isEmpty {
                isRemote = false

                // Fetch Anthropic/Clawdbot usage (local)
                let anthropicRecords = try await anthropic.fetchUsage()
                allRecords.append(contentsOf: anthropicRecords)

                // Detect local Clawdbot
                let clawdbotPath = NSHomeDirectory() + "/.clawdbot/agents"
                hasClawdbot = FileManager.default.fileExists(atPath: clawdbotPath)
            }

            // Fetch OpenAI usage (always from API)
            let openAIRecords = try await openAI.fetchUsage()
            allRecords.append(contentsOf: openAIRecords)

            // Fetch OpenRouter usage (always from API)
            let openRouterUsage = try await openRouter.fetchUsage()

            // Calculate costs by timeframe
            let calendar = Calendar.current
            let now = Date()

            let todayRecords = allRecords.filter { calendar.isDateInToday($0.timestamp) }
            todayCost = todayRecords.reduce(0) { $0 + $1.cost } + openRouterUsage.totalCost

            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let weekRecords = allRecords.filter { $0.timestamp >= weekStart }
            weekCost = weekRecords.reduce(0) { $0 + $1.cost } + openRouterUsage.totalCost

            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let monthRecords = allRecords.filter { $0.timestamp >= monthStart }
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

            // Provider summaries
            let anthropicTotal = todayRecords.filter { $0.provider == "Anthropic" }.reduce(0) { $0 + $1.cost }
            let openAITotal = todayRecords.filter { $0.provider == "OpenAI" }.reduce(0) { $0 + $1.cost }

            providers = [
                ProviderUsage(name: "Anthropic", totalCost: anthropicTotal, remainingCredit: nil, agents: agentCosts),
                ProviderUsage(name: "OpenAI", totalCost: openAITotal, remainingCredit: nil, agents: []),
                openRouterUsage
            ].filter { $0.totalCost > 0 || $0.name == "Anthropic" }

            // Calculate plan savings
            if selectedPlan != .none {
                planSavings = PlanSavings(planCost: selectedPlan.monthlyCost, theoreticalCost: monthCost)
            } else {
                planSavings = nil
            }

            lastRefresh = Date()

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

    func setPlan(_ plan: AIPlan) {
        selectedPlan = plan
        UserDefaults.standard.set(plan.rawValue, forKey: "selectedPlan")
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
