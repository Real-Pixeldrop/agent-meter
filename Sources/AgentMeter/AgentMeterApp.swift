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

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        // Initialize cost tracker
        costTracker = CostTracker()

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "📊 --€"
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
            }
        }

        // Initial fetch
        Task {
            await costTracker.refreshAll()
            await MainActor.run {
                self.updateStatusBarTitle()
            }
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
        let todayCost = costTracker.todayCost
        if todayCost > 0 {
            statusItem.button?.title = String(format: "📊 %.2f€", todayCost)
        } else {
            statusItem.button?.title = "📊 0€"
        }
    }
}
