import Foundation
import AppKit

@MainActor
class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    @Published var updateAvailable: Bool = false
    @Published var latestVersion: String = ""
    @Published var downloadURL: String = ""
    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Double = 0

    private let currentVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.7.0"
    }()
    private let repoOwner = "Real-Pixeldrop"
    private let repoName = "agent-meter"
    private let lastCheckKey = "lastUpdateCheck"

    var currentVersionDisplay: String { currentVersion }

    /// Check for updates. By default, checks at most once per day unless force=true.
    func checkForUpdates(force: Bool = false) async {
        let now = Date()
        if !force, let last = UserDefaults.standard.object(forKey: lastCheckKey) as? Date,
           now.timeIntervalSince(last) < 86400 {
            return
        }
        UserDefaults.standard.set(now, forKey: lastCheckKey)

        guard let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest") else { return }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else { return }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String else { return }

            let remoteVersion = tagName.replacingOccurrences(of: "v", with: "")

            if remoteVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                // Find zip asset
                if let assets = json["assets"] as? [[String: Any]] {
                    for asset in assets {
                        if let name = asset["name"] as? String, name.hasSuffix(".zip"),
                           let dlURL = asset["browser_download_url"] as? String {
                            self.latestVersion = remoteVersion
                            self.downloadURL = dlURL
                            self.updateAvailable = true
                            return
                        }
                    }
                }
            } else {
                self.updateAvailable = false
            }
        } catch {
            print("Update check failed: \(error)")
        }
    }

    /// Download, extract, replace and relaunch
    func performUpdate() async {
        guard !downloadURL.isEmpty, let url = URL(string: downloadURL) else { return }

        isDownloading = true
        downloadProgress = 0

        do {
            // Download to temp
            let (tempURL, response) = try await URLSession.shared.download(from: url)
            guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
                isDownloading = false
                showError("Download failed (HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0))")
                return
            }

            downloadProgress = 0.5

            // Unzip
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("AgentMeterUpdate-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            let unzipProcess = Process()
            unzipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            unzipProcess.arguments = ["-o", tempURL.path, "-d", tempDir.path]
            unzipProcess.standardOutput = Pipe()
            unzipProcess.standardError = Pipe()
            try unzipProcess.run()
            unzipProcess.waitUntilExit()

            guard unzipProcess.terminationStatus == 0 else {
                isDownloading = false
                showError("Failed to unzip update")
                return
            }

            downloadProgress = 0.75

            // Find .app in extracted contents
            let extractedContents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            guard let appBundle = extractedContents.first(where: { $0.pathExtension == "app" }) else {
                isDownloading = false
                showError("No .app found in downloaded archive")
                return
            }

            // Determine install location
            let currentAppPath = Bundle.main.bundlePath
            let installPath: String

            if currentAppPath.hasPrefix("/Applications") {
                installPath = "/Applications/" + appBundle.lastPathComponent
            } else {
                // Install to /Applications anyway
                installPath = "/Applications/" + appBundle.lastPathComponent
            }

            let installURL = URL(fileURLWithPath: installPath)

            // Remove old app
            if FileManager.default.fileExists(atPath: installPath) {
                try FileManager.default.removeItem(at: installURL)
            }

            // Move new app
            try FileManager.default.moveItem(at: appBundle, to: installURL)

            downloadProgress = 1.0

            // Cleanup
            try? FileManager.default.removeItem(at: tempDir)
            try? FileManager.default.removeItem(at: tempURL)

            // Relaunch
            relaunch(from: installPath)

        } catch {
            isDownloading = false
            showError("Update failed: \(error.localizedDescription)")
        }
    }

    private func relaunch(from path: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-n", path]
        try? task.run()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.terminate(nil)
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Update Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
