import Testing
import Foundation
@testable import AgentMeterCore

@Suite("Antigravity Detector & Version Tests")
struct AntigravityDetectorTests {
    @Test("SemVer parsing from CLI output")
    func testVersionParsing() {
        #expect(AntigravityEnvironmentDetector.parseVersion(from: "1.1.19") == "1.1.19")
        #expect(AntigravityEnvironmentDetector.parseVersion(from: "agy version 1.1.11") == "1.1.11")
        #expect(AntigravityEnvironmentDetector.parseVersion(from: "agy 1.2.0 (arm64-apple-darwin)") == "1.2.0")
        #expect(AntigravityEnvironmentDetector.parseVersion(from: "1.1.11-beta.1") == "1.1.11-beta.1")
        #expect(AntigravityEnvironmentDetector.parseVersion(from: "invalid version string") == nil)
    }

    @Test("SemVer comparison against minimum required 1.1.11")
    func testVersionCompatibility() {
        // Supported versions (>= 1.1.11)
        #expect(AntigravityEnvironmentDetector.isVersionSupported("1.1.11", minimumRequired: "1.1.11") == true)
        #expect(AntigravityEnvironmentDetector.isVersionSupported("1.1.19", minimumRequired: "1.1.11") == true)
        #expect(AntigravityEnvironmentDetector.isVersionSupported("1.2.0", minimumRequired: "1.1.11") == true)
        #expect(AntigravityEnvironmentDetector.isVersionSupported("2.0.0", minimumRequired: "1.1.11") == true)
        #expect(AntigravityEnvironmentDetector.isVersionSupported("1.1.12", minimumRequired: "1.1.11") == true)

        // Unsupported versions (< 1.1.11)
        #expect(AntigravityEnvironmentDetector.isVersionSupported("1.1.10", minimumRequired: "1.1.11") == false)
        #expect(AntigravityEnvironmentDetector.isVersionSupported("1.1.0", minimumRequired: "1.1.11") == false)
        #expect(AntigravityEnvironmentDetector.isVersionSupported("1.0.99", minimumRequired: "1.1.11") == false)
        #expect(AntigravityEnvironmentDetector.isVersionSupported("0.9.5", minimumRequired: "1.1.11") == false)
    }

    @Test("Custom executable path resolution")
    func testCustomPathResolution() {
        let detectorNonExistent = AntigravityEnvironmentDetector(customExecutablePath: "/non/existent/path/to/agy")
        let resolvedNonExistent = detectorNonExistent.resolveExecutablePath()
        #expect(resolvedNonExistent != "/non/existent/path/to/agy")

        let detectorValid = AntigravityEnvironmentDetector(customExecutablePath: "/bin/sh")
        let resolvedValid = detectorValid.resolveExecutablePath()
        #expect(resolvedValid == "/bin/sh")
    }
}
