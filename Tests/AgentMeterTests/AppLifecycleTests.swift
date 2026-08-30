import AppKit
import Testing
@testable import AgentMeter

@Suite("App Lifecycle Tests")
@MainActor
struct AppLifecycleTests {
    @Test("Closing the last window hides the Dock presence but keeps the Menu Bar Extra running")
    func applicationStaysAliveAndLeavesTheDockAfterLastWindowCloses() {
        let application = NSApplication.shared
        _ = application.setActivationPolicy(.regular)

        let delegate = AppDelegate()
        let shouldTerminate = delegate.applicationShouldTerminateAfterLastWindowClosed(application)

        #expect(shouldTerminate == false)
        #expect(application.activationPolicy() == .accessory)

        // Leave the shared test application in its normal policy for other tests.
        _ = application.setActivationPolicy(.regular)
    }
}
