import Foundation
import AppKit

class UpdateChecker {
    static let shared = UpdateChecker()
    private let currentVersion = "0.4.0"
    private let repoOwner = "Real-Pixeldrop"
    private let repoName = "agent-meter"
    private let lastCheckKey = "lastUpdateCheck"
    
    func checkForUpdates(force: Bool = false) {
        let now = Date()
        if !force, let last = UserDefaults.standard.object(forKey: lastCheckKey) as? Date,
           now.timeIntervalSince(last) < 86400 { return }
        UserDefaults.standard.set(now, forKey: lastCheckKey)
        
        guard let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String else { return }
            let latestVersion = tagName.replacingOccurrences(of: "v", with: "")
            if latestVersion.compare(self.currentVersion, options: .numeric) == .orderedDescending {
                if let assets = json["assets"] as? [[String: Any]],
                   let asset = assets.first,
                   let downloadURL = asset["browser_download_url"] as? String {
                    DispatchQueue.main.async {
                        self.showUpdateAlert(version: latestVersion, downloadURL: downloadURL)
                    }
                }
            }
        }.resume()
    }
    
    private func showUpdateAlert(version: String, downloadURL: String) {
        let alert = NSAlert()
        alert.messageText = "Mise à jour disponible"
        alert.informativeText = "La version \(version) est disponible. Voulez-vous la télécharger ?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Télécharger")
        alert.addButton(withTitle: "Plus tard")
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: downloadURL) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
