import SwiftUI
import AppKit

@main
struct AgentMeterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var costTracker: CostTracker!
    var timer: Timer?
    private var updateObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        // Initialize cost tracker
        costTracker = CostTracker()

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "gauge.with.dots.needle.33percent", accessibilityDescription: "AgentMeter")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 480)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(costTracker: costTracker)
        )

        // Auto-refresh every 5 minutes
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                await self?.costTracker.refreshAll()
                await MainActor.run {
                    self?.updateStatusBarTitle()
                }
            }
        }

        // Initial fetch
        Task {
            await costTracker.refreshAll()
            await MainActor.run {
                self.updateStatusBarTitle()
            }
        }

        // Check for updates on launch
        Task {
            await UpdateChecker.shared.checkForUpdates()
            await MainActor.run {
                self.updateStatusBarTitle()
            }
        }

        // Observe update checker changes to refresh badge
        updateObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateStatusBarTitle()
        }
    }

    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                // Refresh on open
                Task {
                    await costTracker.refreshAll()
                    await MainActor.run {
                        self.updateStatusBarTitle()
                    }
                }
            }
        }
    }

    @MainActor
    func updateStatusBarTitle() {
        let maxUsage = costTracker.activeSessions.map(\.contextUsage).max() ?? 0
        let symbolName: String
        if maxUsage > 0.90 {
            symbolName = "gauge.with.dots.needle.100percent"
        } else if maxUsage > 0.75 {
            symbolName = "gauge.with.dots.needle.67percent"
        } else if maxUsage > 0.50 {
            symbolName = "gauge.with.dots.needle.50percent"
        } else {
            symbolName = "gauge.with.dots.needle.33percent"
        }

        if let button = statusItem.button {
            // Show update badge as text suffix
            if UpdateChecker.shared.updateAvailable {
                let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "AgentMeter")
                image?.isTemplate = true
                button.image = image
                button.title = " ⬆"
            } else {
                let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "AgentMeter")
                image?.isTemplate = true
                button.image = image
                button.title = ""
            }
        }
    }
}
