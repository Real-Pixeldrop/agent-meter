import Foundation

/// Centralized manager for resolving the Clawdbot installation path.
/// Priority: 1) User-configured custom path  2) Process detection  3) Common paths
class ClawdbotPathManager {
    static let shared = ClawdbotPathManager()

    private let customPathKey = "clawdbotCustomPath"

    /// The resolved clawdbot base directory (e.g. ~/.clawdbot)
    var basePath: String? {
        // Priority 1: User-defined custom path
        if let custom = customPath, !custom.isEmpty {
            let expanded = (custom as NSString).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expanded + "/agents") {
                return expanded
            }
        }

        // Priority 2: Detect from running process
        if let detected = detectFromProcess() {
            return detected
        }

        // Priority 3: Check common paths
        return checkCommonPaths()
    }

    /// The agents directory path
    var agentsPath: String? {
        guard let base = basePath else { return nil }
        let path = base + "/agents"
        return FileManager.default.fileExists(atPath: path) ? path : nil
    }

    /// Whether Clawdbot is detected at all
    var isDetected: Bool {
        return basePath != nil
    }

    /// The user-configured custom path (raw, as stored)
    var customPath: String? {
        get { UserDefaults.standard.string(forKey: customPathKey) }
        set { UserDefaults.standard.set(newValue, forKey: customPathKey) }
    }

    /// Detection source description
    var detectionSource: String {
        if let custom = customPath, !custom.isEmpty {
            let expanded = (custom as NSString).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expanded + "/agents") {
                return "Custom path"
            }
        }
        if detectFromProcess() != nil {
            return "Process detection"
        }
        if checkCommonPaths() != nil {
            return "Default path"
        }
        return "Not found"
    }

    // MARK: - Detection Methods

    /// Try to detect Clawdbot path from running process
    private func detectFromProcess() -> String? {
        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "ps aux | grep -v grep | grep clawdbot | head -5"]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8), !output.isEmpty else { return nil }

        // Look for --config or config path patterns in the process command line
        let lines = output.components(separatedBy: "\n")
        for line in lines {
            // Pattern 1: explicit --config /path/to/.clawdbot
            if let range = line.range(of: "--config\\s+(\\S+)", options: .regularExpression) {
                let match = String(line[range])
                let path = match.replacingOccurrences(of: "--config", with: "").trimmingCharacters(in: .whitespaces)
                let expanded = (path as NSString).expandingTildeInPath
                if FileManager.default.fileExists(atPath: expanded + "/agents") {
                    return expanded
                }
            }

            // Pattern 2: look for .clawdbot in the command path
            if let range = line.range(of: "/[^\\s]*\\.clawdbot", options: .regularExpression) {
                var path = String(line[range])
                // Strip trailing subpath after .clawdbot
                if let clawdbotRange = path.range(of: ".clawdbot") {
                    path = String(path[path.startIndex...clawdbotRange.upperBound].dropLast(1)) + ".clawdbot"
                }
                if FileManager.default.fileExists(atPath: path + "/agents") {
                    return path
                }
            }

            // Pattern 3: the process binary itself might be in a known location
            // Extract the home directory of the user running clawdbot
            let components = line.split(separator: " ", maxSplits: 10)
            if components.count > 1 {
                let username = String(components[0])
                let userHome = "/Users/\(username)"
                let candidatePath = userHome + "/.clawdbot"
                if FileManager.default.fileExists(atPath: candidatePath + "/agents") {
                    return candidatePath
                }
            }
        }

        return nil
    }

    /// Check common installation paths
    private func checkCommonPaths() -> String? {
        let homeDir = NSHomeDirectory()
        let commonPaths = [
            homeDir + "/.clawdbot",
            homeDir + "/.config/clawdbot",
            "/usr/local/etc/clawdbot",
            "/opt/clawdbot",
        ]

        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path + "/agents") {
                return path
            }
        }

        return nil
    }
}
