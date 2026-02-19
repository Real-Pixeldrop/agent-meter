import SwiftUI

struct SettingsView: View {
    @State private var anthropicKey: String = KeychainHelper.load(key: "anthropic_api_key") ?? ""
    @State private var openRouterKey: String = KeychainHelper.load(key: "openrouter_api_key") ?? ""
    @State private var budgetLimit: String = String(format: "%.0f", UserDefaults.standard.double(forKey: "budgetLimit"))
    @State private var saved = false

    var body: some View {
        Form {
            Section("API Keys") {
                SecureField("Anthropic API Key", text: $anthropicKey)
                    .textFieldStyle(.roundedBorder)

                SecureField("OpenRouter API Key", text: $openRouterKey)
                    .textFieldStyle(.roundedBorder)
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
                    Text("v0.1.0")
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
                    KeychainHelper.save(key: "openrouter_api_key", value: openRouterKey)
                    if let limit = Double(budgetLimit) {
                        UserDefaults.standard.set(limit, forKey: "budgetLimit")
                    }
                    saved = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 350)
        .padding()
    }
}
