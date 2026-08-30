import Testing
import Foundation
@testable import AgentMeterCore

final class MockAntigravityCommandRunner: AntigravityCommandRunner, @unchecked Sendable {
    var outputToReturn: String
    var exitCodeToReturn: Int32
    var shouldThrowTimeout: Bool

    init(outputToReturn: String = "", exitCodeToReturn: Int32 = 0, shouldThrowTimeout: Bool = false) {
        self.outputToReturn = outputToReturn
        self.exitCodeToReturn = exitCodeToReturn
        self.shouldThrowTimeout = shouldThrowTimeout
    }

    func runCommand(executable: String, arguments: [String], timeout: TimeInterval) async throws -> (output: String, exitCode: Int32) {
        if shouldThrowTimeout {
            throw AntigravityError.timeout
        }
        return (outputToReturn, exitCodeToReturn)
    }
}

@Suite("Antigravity Provider & JSON Parsing Tests")
struct AntigravityProviderTests {
    let sampleValidJSON = """
    {
      "conversation_id": "",
      "status": "SUCCESS",
      "duration_seconds": 0,
      "num_turns": 0,
      "command": {
        "name": "usage",
        "data": {
          "description": "Rate limits description",
          "groups": [
            {
              "name": "Gemini Models",
              "description": "Models within this group: Gemini Flash, Gemini Pro",
              "buckets": [
                {
                  "id": "gemini-weekly",
                  "name": "Weekly Limit Remaining",
                  "description": "You have used some of your weekly limit, it will fully refresh in 20 hours.",
                  "window": "weekly",
                  "remaining_fraction": 0.546,
                  "reset_time": "2026-08-31T01:47:35Z"
                },
                {
                  "id": "gemini-5h",
                  "name": "Five Hour Limit Remaining",
                  "description": "You have used some of your 5-hour limit, it will fully refresh in 4 hours.",
                  "window": "5h",
                  "remaining_fraction": 0.988,
                  "reset_time": "2026-08-30T10:39:47Z"
                }
              ]
            },
            {
              "name": "Claude and GPT models",
              "description": "Models within this group: Claude Opus, Claude Sonnet, GPT-OSS",
              "buckets": [
                {
                  "id": "3p-weekly",
                  "name": "Weekly Limit Remaining",
                  "window": "weekly",
                  "remaining_fraction": 1.0,
                  "reset_time": "2026-09-06T05:41:22Z"
                },
                {
                  "id": "3p-5h",
                  "name": "Five Hour Limit Remaining",
                  "window": "5h",
                  "remaining_fraction": 1.0,
                  "reset_time": "2026-08-30T10:41:22Z"
                }
              ]
            }
          ]
        }
      }
    }
    """

    @Test("Parses standard Gemini models and excludes Claude and GPT models")
    func testStandardGeminiParsing() throws {
        let provider = AntigravityRateLimitProvider()
        let snapshot = try provider.parseRateLimits(from: sampleValidJSON)

        #expect(snapshot.provider == .antigravity)
        #expect(snapshot.accountEmail == nil)
        #expect(snapshot.accountPlan == nil)
        #expect(snapshot.items.count == 2)

        // 5-Hour item should be sorted first
        let item5h = snapshot.items[0]
        #expect(item5h.id == "gemini-5h")
        #expect(item5h.name == "Five Hour Limit Remaining")
        #expect(item5h.usedPercentageInt == 1) // (1.0 - 0.988) * 100 = 1.2% -> 1%
        #expect(item5h.remainingPercentageInt == 99)
        #expect(item5h.hasResetTime == true)

        // Weekly item should be sorted second
        let itemWeekly = snapshot.items[1]
        #expect(itemWeekly.id == "gemini-weekly")
        #expect(itemWeekly.name == "Weekly Limit Remaining")
        #expect(itemWeekly.usedPercentageInt == 45) // (1.0 - 0.546) * 100 = 45.4% -> 45%
        #expect(itemWeekly.remainingPercentageInt == 55)
        #expect(itemWeekly.hasResetTime == true)
    }

    @Test("Filters out disabled buckets and handles missing reset_time")
    func testDisabledBucketsAndMissingReset() throws {
        let json = """
        {
          "command": {
            "data": {
              "groups": [
                {
                  "name": "Gemini Models",
                  "buckets": [
                    {
                      "id": "gemini-active",
                      "name": "Gemini Active Limit",
                      "remaining_fraction": 0.8,
                      "disabled": false
                    },
                    {
                      "id": "gemini-disabled",
                      "name": "Gemini Disabled Limit",
                      "remaining_fraction": 0.0,
                      "disabled": true
                    }
                  ]
                }
              ]
            }
          }
        }
        """

        let provider = AntigravityRateLimitProvider()
        let snapshot = try provider.parseRateLimits(from: json)

        #expect(snapshot.items.count == 1)
        #expect(snapshot.items[0].id == "gemini-active")
        #expect(snapshot.items[0].hasResetTime == false)
        #expect(snapshot.items[0].resetAt == nil)
        #expect(snapshot.items[0].usedPercentageInt == 20)
    }

    @Test("Provider handles timeout error")
    func testTimeoutHandling() async {
        let mockDetector = AntigravityEnvironmentDetector(customExecutablePath: "/bin/echo")
        let mockRunner = MockAntigravityCommandRunner(shouldThrowTimeout: true)
        let provider = AntigravityRateLimitProvider(
            environmentDetector: mockDetector,
            commandRunner: mockRunner
        )

        await #expect(throws: AntigravityError.timeout) {
            try await provider.fetchRateLimits()
        }
    }

    @Test("Provider handles unauthenticated CLI output")
    func testUnauthenticatedOutput() async {
        let mockDetector = AntigravityEnvironmentDetector(customExecutablePath: "/bin/echo")
        let mockRunner = MockAntigravityCommandRunner(outputToReturn: "Error: Not authenticated. Please login with your Google account.", exitCodeToReturn: 1)
        let provider = AntigravityRateLimitProvider(
            environmentDetector: mockDetector,
            commandRunner: mockRunner
        )

        await #expect(throws: AntigravityError.self) {
            try await provider.fetchRateLimits()
        }
    }

    @Test("Provider detects unsupported GEMINI_API_KEY mode")
    func testAPIKeyModeOutput() async {
        let mockDetector = AntigravityEnvironmentDetector(customExecutablePath: "/bin/echo")
        let mockRunner = MockAntigravityCommandRunner(outputToReturn: "Error: Running in GEMINI_API_KEY provider mode", exitCodeToReturn: 1)
        let provider = AntigravityRateLimitProvider(
            environmentDetector: mockDetector,
            commandRunner: mockRunner
        )

        await #expect(throws: AntigravityError.unsupportedAPIKeyMode) {
            try await provider.fetchRateLimits()
        }
    }
}
