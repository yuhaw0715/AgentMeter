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

final class RecordingCodexTransport: CodexJSONRPCTransport, @unchecked Sendable {
    let result: [String: Any]
    private let lock = NSLock()
    private var recordedMethods: [String] = []

    init(result: [String: Any]) {
        self.result = result
    }

    var methods: [String] {
        lock.withLock { recordedMethods }
    }

    func sendRequest(method: String, params: [String: Any]?, timeout: TimeInterval) async throws -> RPCResponse {
        lock.withLock {
            recordedMethods.append(method)
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

    @Test("Parses reset credits, preserves metadata, and sorts by earliest expiration")
    func testResetCreditParsingAndSorting() throws {
        let payload: [String: Any] = [
            "rateLimits": [
                "primary": ["usedPercent": 10, "windowDurationMins": 300]
            ],
            "rateLimitResetCredits": [
                "availableCount": 4,
                "credits": [
                    [
                        "id": "undated",
                        "resetType": "weekly",
                        "status": "available",
                        "title": "Do not render this",
                        "description": "Also retained only in the model"
                    ],
                    [
                        "id": "late",
                        "grantedAt": "2026-09-01T00:00:00Z",
                        "expiresAt": "2026-09-18T20:00:00Z"
                    ],
                    [
                        "id": "early",
                        "expiresAt": "2026-09-12T08:30:00Z"
                    ]
                ]
            ]
        ]

        let snapshot = try CodexRateLimitProvider().parseRateLimits(from: payload)
        let summary = try #require(snapshot.resetCredits)
        #expect(summary.availableCount == 4)
        #expect(summary.credits?.map(\.id) == ["early", "late", "undated"])
        #expect(summary.missingDetailCount == 1)
        #expect(summary.credits?.first?.title == nil)
        #expect(summary.credits?.last?.title == "Do not render this")
        #expect(summary.credits?.last?.expiresAt == nil)
    }

    @Test("Distinguishes null details, empty details, missing field, and malformed rows")
    func testResetCreditAvailabilityStates() throws {
        let provider = CodexRateLimitProvider()

        let nullDetails = try provider.parseRateLimits(from: [
            "rateLimitResetCredits": ["availableCount": 3, "credits": NSNull()]
        ])
        #expect(nullDetails.resetCredits?.availableCount == 3)
        #expect(nullDetails.resetCredits?.credits == nil)
        #expect(nullDetails.resetCredits?.missingDetailCount == nil)
        #expect(nullDetails.items.isEmpty)

        let emptyDetails = try provider.parseRateLimits(from: [
            "rateLimitResetCredits": ["availableCount": 0, "credits": []]
        ])
        #expect(emptyDetails.resetCredits?.isKnownZero == true)
        #expect(emptyDetails.resetCredits?.credits?.isEmpty == true)
        #expect(emptyDetails.items.isEmpty)

        let missingField = try provider.parseRateLimits(from: ["rateLimits": [:]])
        #expect(missingField.resetCredits == nil)
        #expect(missingField.provider == .codex)

        let malformedRow = try provider.parseRateLimits(from: [
            "rateLimitResetCredits": [
                "availableCount": 2,
                "credits": [NSNull(), ["id": "valid", "expiresAt": 1_800_000_000]]
            ]
        ])
        #expect(malformedRow.resetCredits?.credits?.map(\.id) == ["valid"])
        #expect(malformedRow.resetCredits?.missingDetailCount == 1)
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

    @Test("Fetching reset credits remains read-only")
    func testResetCreditFetchDoesNotConsume() async throws {
        let transport = RecordingCodexTransport(result: [
            "rateLimits": [:],
            "rateLimitResetCredits": ["availableCount": 1, "credits": []]
        ])
        let snapshot = try await CodexRateLimitProvider(transport: transport).fetchRateLimits()
        #expect(snapshot.resetCredits?.availableCount == 1)
        #expect(transport.methods == ["account/rateLimits/read"])
        #expect(!transport.methods.contains("account/rateLimitResetCredit/consume"))
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
