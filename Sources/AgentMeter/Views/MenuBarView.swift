import SwiftUI

struct MenuBarView: View {
    @ObservedObject var costTracker: CostTracker

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AgentMeter")
                    .font(.headline)
                    .fontWeight(.bold)

                if costTracker.hasClawdbot {
                    Text(costTracker.isRemote ? "Remote" : "OpenClaw")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(costTracker.isRemote ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                        .foregroundColor(costTracker.isRemote ? .blue : .green)
                        .cornerRadius(4)
                }

                Spacer()
                if costTracker.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                } else if let lastRefresh = costTracker.lastRefresh {
                    Text(lastRefresh, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Cost Overview
            VStack(spacing: 12) {
                CostCard(label: "Today", cost: costTracker.todayCost, accent: .blue)
                HStack(spacing: 12) {
                    CostCard(label: "This Week", cost: costTracker.weekCost, accent: .cyan, compact: true)
                    CostCard(label: "This Month", cost: costTracker.monthCost, accent: .purple, compact: true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Plan Savings
            if let savings = costTracker.planSavings {
                Divider()
                VStack(spacing: 6) {
                    HStack {
                        Text("YOUR PLAN")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(costTracker.selectedPlan.displayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("You pay")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "$%.0f/mo", savings.planCost))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        VStack(alignment: .center, spacing: 2) {
                            Text("Value used")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.0f€", savings.theoreticalCost))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Savings")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.0fx", savings.multiplier))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Divider()

            // Per-Agent Breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text("AGENTS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                if costTracker.agentCosts.isEmpty {
                    Text("No usage data yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    ForEach(costTracker.agentCosts) { agent in
                        AgentRow(agent: agent)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Active Sessions / Context Gauge
            if !costTracker.activeSessions.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("SESSIONS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ForEach(costTracker.activeSessions) { session in
                        SessionRow(session: session)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            Divider()

            // Providers
            VStack(alignment: .leading, spacing: 8) {
                Text("PROVIDERS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                ForEach(costTracker.providers) { provider in
                    ProviderRow(provider: provider)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Footer
            HStack {
                Button(action: {
                    Task { await costTracker.refreshAll() }
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    SettingsWindowController.shared.showSettings()
                }) {
                    Label("Settings", systemImage: "gear")
                        .font(.caption)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    Label("Quit", systemImage: "power")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 320)
    }
}

// MARK: - Cost Card
struct CostCard: View {
    let label: String
    let cost: Double
    let accent: Color
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(compact ? .caption2 : .caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.2f€", cost))
                .font(compact ? .title3 : .title2)
                .fontWeight(.bold)
                .foregroundColor(accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? 8 : 12)
        .background(accent.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Agent Row
struct AgentRow: View {
    let agent: AgentCost

    var agentEmoji: String {
        let emojis = ["🤖", "🧠", "🎨", "💡", "⚡", "🔮", "🎯", "🚀"]
        let index = abs(agent.name.hashValue) % emojis.count
        return emojis[index]
    }

    var body: some View {
        HStack {
            Text(agentEmoji)
            Text(agent.name)
                .font(.caption)
                .fontWeight(.medium)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.3f€", agent.cost))
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("\(formatTokens(agent.tokens)) tokens")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000 { return String(format: "%.1fK", Double(count) / 1_000) }
        return "\(count)"
    }
}

// MARK: - Session Row
struct SessionRow: View {
    let session: SessionInfo

    var gaugeColor: Color {
        if session.isCritical { return .red }
        if session.isNearCompaction { return .orange }
        return .green
    }

    var statusLabel: String {
        if session.isCritical { return "COMPACTION SOON" }
        if session.isNearCompaction { return "Getting full" }
        return ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.agent)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text(shortModel(session.model))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(String(format: "%.0f%%", session.contextUsage * 100))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(gaugeColor)
            }

            // Context gauge bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(gaugeColor)
                        .frame(width: geo.size.width * min(session.contextUsage, 1.0), height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Text(formatTokens(session.contextTokens) + " / " + formatTokens(session.contextLimit))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                if !statusLabel.isEmpty {
                    Text(statusLabel)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(gaugeColor)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func shortModel(_ model: String) -> String {
        if model.contains("opus") { return "Opus" }
        if model.contains("sonnet") { return "Sonnet" }
        if model.contains("haiku") { return "Haiku" }
        if model.contains("gpt-4o") { return "GPT-4o" }
        if model.contains("gpt-4") { return "GPT-4" }
        if model.contains("o1") { return "o1" }
        if model.contains("o3") { return "o3" }
        return String(model.prefix(12))
    }

    private func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.0fK", Double(count) / 1_000) }
        if count >= 1_000 { return String(format: "%.1fK", Double(count) / 1_000) }
        return "\(count)"
    }
}

// MARK: - Provider Row
struct ProviderRow: View {
    let provider: ProviderUsage

    var providerColor: Color {
        switch provider.name {
        case "Anthropic": return .orange
        case "OpenAI": return .cyan
        case "OpenRouter": return .green
        default: return .gray
        }
    }

    var body: some View {
        HStack {
            Circle()
                .fill(providerColor)
                .frame(width: 8, height: 8)
            Text(provider.name)
                .font(.caption)
            Spacer()
            Text(String(format: "%.2f€", provider.totalCost))
                .font(.caption)
                .fontWeight(.medium)
            if let remaining = provider.remainingCredit {
                Text(String(format: "(%.2f€ left)", remaining))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
