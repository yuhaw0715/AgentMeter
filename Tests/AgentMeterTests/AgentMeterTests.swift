import Testing
import Foundation
@testable import AgentMeterCore

@Suite("AgentMeter Basic Suite")
struct AgentMeterTests {
    @Test("Version is defined")
    func testVersion() {
        #expect(AgentMeterCore.version == "0.1.1")
        #expect(AgentMeterCore.appName == "AgentMeter")
    }
}
