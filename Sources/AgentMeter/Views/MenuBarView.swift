import SwiftUI

struct MenuBarView: View {
    @ObservedObject var costTracker: CostTracker
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AgentMeter")
                    .font(.headline)
                    .fontWeight(.bold)
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
        switch agent.name {
        case "Claudia": return "🤖"
        case "Mike": return "💪"
        case "Valentina": return "💃"
        case "Clea": return "🎨"
        default: return "🔹"
        }
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

// MARK: - Provider Row
struct ProviderRow: View {
    let provider: ProviderUsage

    var body: some View {
        HStack {
            Circle()
                .fill(provider.name == "Anthropic" ? Color.orange : Color.green)
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
