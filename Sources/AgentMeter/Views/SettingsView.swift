import SwiftUI

struct SettingsView: View {
    @State private var anthropicKey: String = KeychainHelper.load(key: "anthropic_api_key") ?? ""
    @State private var openRouterKey: String = KeychainHelper.load(key: "openrouter_api_key") ?? ""
    @State private var openAIKey: String = KeychainHelper.load(key: "openai_api_key") ?? ""
    @State private var budgetLimit: String = String(format: "%.0f", UserDefaults.standard.double(forKey: "budgetLimit"))
    @State private var selectedPlan: AIPlan = {
        if let raw = UserDefaults.standard.string(forKey: "selectedPlan"),
           let plan = AIPlan(rawValue: raw) { return plan }
        return .none
    }()
    @State private var customPlanCost: String = String(format: "%.0f", UserDefaults.standard.double(forKey: "customPlanCost"))
    @State private var remoteURL: String = UserDefaults.standard.string(forKey: "remoteServerURL") ?? ""
    @State private var saved = false

    private var hasClawdbot: Bool {
        FileManager.default.fileExists(atPath: NSHomeDirectory() + "/.clawdbot/agents")
    }

    var body: some View {
        Form {
            // Detection status
            Section("Status") {
                HStack {
                    if hasClawdbot {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("OpenClaw detected")
                            .fontWeight(.medium)
                        Text("Auto-tracking enabled")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.orange)
                        Text("OpenClaw not found")
                        Text("Use API keys below")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section("Your Plan") {
                Picker("Subscription", selection: $selectedPlan) {
                    ForEach(AIPlan.allCases, id: \.self) { plan in
                        Text(plan.displayName).tag(plan)
                    }
                }

                if selectedPlan == .custom {
                    HStack {
                        Text("Monthly cost ($)")
                        TextField("200", text: $customPlanCost)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                }
            }

            Section("Remote Server") {
                TextField("Server URL (e.g. http://your-server:7890)", text: $remoteURL)
                    .textFieldStyle(.roundedBorder)
                Text("Connect to an AgentMeter server on another machine to view remote agent data.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("API Keys") {
                SecureField("Anthropic API Key", text: $anthropicKey)
                    .textFieldStyle(.roundedBorder)

                SecureField("OpenAI API Key", text: $openAIKey)
                    .textFieldStyle(.roundedBorder)

                SecureField("OpenRouter API Key", text: $openRouterKey)
                    .textFieldStyle(.roundedBorder)

                if hasClawdbot {
                    Text("API keys are optional with OpenClaw. Agent usage is tracked automatically from local logs.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("Budget") {
                HStack {
                    Text("Daily budget alert (€)")
                    TextField("10", text: $budgetLimit)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
            }

            Section("About") {
                HStack {
                    Text("AgentMeter")
                        .fontWeight(.bold)
                    Text("v0.3.0")
                        .foregroundColor(.secondary)
                }
                Text("Track AI agent costs in real-time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Link("GitHub", destination: URL(string: "https://github.com/Real-Pixeldrop/agent-meter")!)
                    .font(.caption)
            }

            HStack {
                Spacer()
                if saved {
                    Text("Saved!")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                Button("Save") {
                    KeychainHelper.save(key: "anthropic_api_key", value: anthropicKey)
                    KeychainHelper.save(key: "openai_api_key", value: openAIKey)
                    KeychainHelper.save(key: "openrouter_api_key", value: openRouterKey)
                    if let limit = Double(budgetLimit) {
                        UserDefaults.standard.set(limit, forKey: "budgetLimit")
                    }
                    UserDefaults.standard.set(selectedPlan.rawValue, forKey: "selectedPlan")
                    if let cost = Double(customPlanCost) {
                        UserDefaults.standard.set(cost, forKey: "customPlanCost")
                    }
                    UserDefaults.standard.set(remoteURL, forKey: "remoteServerURL")
                    saved = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 520)
        .padding()
    }
}
