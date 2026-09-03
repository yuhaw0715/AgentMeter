import SwiftUI
import AppKit
import AgentMeterCore

/// Custom NSApplicationDelegate to manage window lifecycle, focus, Dock icon, and Reopen events.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        setApplicationIcon()
        hideInitialDesktopWindows()
    }

    /// Keep the Menu Bar Extra alive when the last desktop window is closed.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // A Menu Bar Extra should remain available without showing AgentMeter as
        // an active Dock application while its desktop window is closed.
        _ = sender.setActivationPolicy(.accessory)
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Reopen is a background-entry event. Keep the accessory policy here
        // explicit so a prior window lifecycle cannot make the Dock icon flash
        // back into view while the Menu Bar Extra is being restored.
        _ = sender.setActivationPolicy(.accessory)
        NSApplication.shared.activate(ignoringOtherApps: true)
        for window in sender.windows where isStandardContentWindow(window) {
            window.deminiaturize(nil)
            window.setIsVisible(true)
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            return true
        }
        return true
    }

    private func hideInitialDesktopWindows() {
        for window in NSApplication.shared.windows where isStandardContentWindow(window) {
            window.orderOut(nil)
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            for window in NSApplication.shared.windows where self.isStandardContentWindow(window) {
                window.orderOut(nil)
            }
        }
    }

    func isStandardContentWindow(_ window: NSWindow) -> Bool {
        let name = String(describing: type(of: window))
        return !name.contains("StatusBar") && !name.contains("MenuBar") && !name.contains("Popover") && window.canBecomeMain
    }

    private func setApplicationIcon() {
        let iconUrl = Bundle.main.url(forResource: "AppIcon", withExtension: "icns")
            ?? Bundle.module.url(forResource: "AppIcon", withExtension: "png")

        if let iconUrl,
           let iconImage = NSImage(contentsOf: iconUrl) {
            NSApplication.shared.applicationIconImage = iconImage
        }
    }
}

@main
struct AgentMeterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var viewModel = UsageMonitorViewModel()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        // Main Desktop Window (Single Instance Window)
        Window("AgentMeter", id: "mainWindow") {
            MainDesktopContainerView(viewModel: viewModel)
                .task {
                    await viewModel.refreshDesktop()
                }
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 760, height: 520)

        // Menu Bar Extra (Option 1 shared AM Monogram visual language)
        MenuBarExtra {
            MenuBarPopoverView(viewModel: viewModel) {
                openMainWindow()
            }
        } label: {
            Text("AM")
                .font(.system(size: 13, weight: .black, design: .rounded))
        }
        .menuBarExtraStyle(.window)
    }

    private func openMainWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)

        let existingWindow = NSApplication.shared.windows.first { window in
            let name = String(describing: type(of: window))
            return !name.contains("StatusBar") && !name.contains("MenuBar") && !name.contains("Popover") && window.canBecomeMain
        }

        if let window = existingWindow {
            window.deminiaturize(nil)
            window.setIsVisible(true)
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        } else {
            openWindow(id: "mainWindow")
        }
    }
}
