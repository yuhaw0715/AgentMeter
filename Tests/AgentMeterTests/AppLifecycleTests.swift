import AppKit
import Testing
@testable import AgentMeter

@Suite("App Lifecycle Tests")
@MainActor
struct AppLifecycleTests {
    @Test("Launching the app configures accessory activation policy")
    func applicationLaunchesInAccessoryMode() {
        let application = NSApplication.shared
        let delegate = AppDelegate()

        delegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        #expect(application.activationPolicy() == .accessory)
    }

    @Test("Closing the last window maintains accessory mode and keeps Menu Bar running")
    func applicationStaysAliveAndMaintainsAccessoryModeAfterLastWindowCloses() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        let shouldTerminate = delegate.applicationShouldTerminateAfterLastWindowClosed(application)

        #expect(shouldTerminate == false)
        #expect(application.activationPolicy() == .accessory)
    }

    @Test("Reopen event handles application reactivation")
    func applicationHandlesReopenEvent() {
        let application = NSApplication.shared
        let delegate = AppDelegate()

        let handled = delegate.applicationShouldHandleReopen(application, hasVisibleWindows: false)
        #expect(handled == true)
        #expect(application.activationPolicy() == .accessory)
    }
}
