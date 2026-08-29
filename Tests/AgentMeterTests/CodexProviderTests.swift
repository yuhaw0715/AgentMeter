import Testing
import Foundation
@testable import AgentMeterCore

// Mock transport for testing JSON-RPC interactions
struct MockCodexTransport: CodexJSONRPCTransport, @unchecked Sendable {
    let mockResult: [String: Any]?
    let errorToThrow: Error?

    init(mockResult: [String: Any]? = nil, errorToThrow: Error? = nil) {
        self.mockResult = mockResult
        self.errorToThrow = errorToThrow
    }

    func sendRequest(method: String, params: [String: Any]?, timeout: TimeInterval) async throws -> RPCResponse {
        if let error = errorToThrow {
            throw error
        }
        guard let result = mockResult else {
            throw CodexError.noResponse
        }
        return RPCResponse(result)
    }
}

@Suite("Codex Provider & JSON-RPC Tests")
struct CodexProviderTests {
    @Test("Dynamic parsing of official Codex rateLimits primary/secondary structure")
    func testOfficialCodexRateLimitsParsing() throws {
        let payload: [String: Any] = [
            "rateLimits": [
                "limitId": "codex",
                "planType": "plus",
                "primary": [
                    "usedPercent": 2,
                    "windowDurationMins": 300,
                    "resetsAt": 1787987287
                ],
                "secondary": [
                    "usedPercent": 0,
                    "windowDurationMins": 10080,
                    "resetsAt": 1788574087
                ]
            ]
        ]

        let provider = CodexRateLimitProvider()
        let snapshot = try provider.parseRateLimits(from: payload)

        #expect(snapshot.provider == .codex)
        #expect(snapshot.accountPlan == "Plus")
        #expect(snapshot.items.count == 2)

        let sessionItem = try #require(snapshot.item(withId: "codex_primary"))
        #expect(sessionItem.usedPercentageInt == 2)
        #expect(sessionItem.remainingPercentageInt == 98)
        #expect(sessionItem.hasResetTime == true)
        #expect(sessionItem.name == "5-Hour Session Limit")

        let weeklyItem = try #require(snapshot.item(withId: "codex_secondary"))
        #expect(weeklyItem.usedPercentageInt == 0)
        #expect(weeklyItem.remainingPercentageInt == 100)
        #expect(weeklyItem.hasResetTime == true)
        #expect(weeklyItem.name == "Weekly Limit")
    }

    @Test("Dynamic parsing of standard rate limits array")
    func testArrayRateLimitsParsing() throws {
        let payload: [String: Any] = [
            "email": "developer@openai.com",
            "plan": "Pro",
            "rateLimits": [
                [
                    "id": "5h_limit",
                    "title": "5-Hour Session Limit",
                    "usedPercent": 35.4,
                    "resetsAt": "2026-08-29T18:00:00Z"
                ],
                [
                    "id": "weekly_limit",
                    "title": "Weekly Limit",
                    "usedPercent": 92.0,
                    "resetTimestamp": 1787990400
                ],
                [
                    "id": "new_experimental_quota",
                    "title": "Fast Code Quota",
                    "used": 80,
                    "limit": 100
                ]
            ]
        ]

        let provider = CodexRateLimitProvider()
        let snapshot = try provider.parseRateLimits(from: payload)

        #expect(snapshot.provider == .codex)
        #expect(snapshot.accountEmail == "developer@openai.com")
        #expect(snapshot.accountPlan == "Pro")
        #expect(snapshot.items.count == 3)

        let sessionItem = try #require(snapshot.item(withId: "5h_limit"))
        #expect(sessionItem.usedPercentageInt == 35)
        #expect(sessionItem.remainingPercentageInt == 65)
        #expect(sessionItem.hasResetTime == true)

        let weeklyItem = try #require(snapshot.item(withId: "weekly_limit"))
        #expect(weeklyItem.usedPercentageInt == 92)
        #expect(weeklyItem.remainingPercentageInt == 8)
        #expect(weeklyItem.hasResetTime == true)

        let fastQuota = try #require(snapshot.item(withId: "new_experimental_quota"))
        #expect(fastQuota.usedPercentageInt == 80)
        #expect(fastQuota.hasResetTime == false)
    }

    @Test("Provider execution using mock transport")
    func testProviderWithMockTransport() async throws {
        let mockPayload: [String: Any] = [
            "limits": [
                ["name": "Standard Limit", "usedPercent": 50]
            ]
        ]
        let transport = MockCodexTransport(mockResult: mockPayload)
        let provider = CodexRateLimitProvider(transport: transport)

        let snapshot = try await provider.fetchRateLimits()
        #expect(snapshot.items.count == 1)
        #expect(snapshot.items.first?.usedPercentageInt == 50)
    }

    @Test("Provider handles transport timeout error")
    func testProviderTimeout() async {
        let transport = MockCodexTransport(errorToThrow: CodexError.timeout)
        let provider = CodexRateLimitProvider(transport: transport)

        do {
            _ = try await provider.fetchRateLimits()
            #expect(Bool(false), "Should have thrown timeout error")
        } catch let error as CodexError {
            if case .timeout = error {
                #expect(Bool(true))
            } else {
                #expect(Bool(false), "Expected .timeout but got \(error)")
            }
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("Environment detector custom path handling")
    func testCustomPathResolution() {
        let detector = CodexEnvironmentDetector(customExecutablePath: "/non/existent/path/to/codex")
        let resolved = detector.resolveExecutablePath()
        #expect(resolved != "/non/existent/path/to/codex")
    }
}
