import Foundation

/// A sendable wrapper for JSON-RPC dictionary results.
public struct RPCResponse: @unchecked Sendable {
    public let dictionary: [String: Any]

    public init(_ dictionary: [String: Any]) {
        self.dictionary = dictionary
    }

    public subscript(key: String) -> Any? {
        return dictionary[key]
    }
}

/// Defines a transport mechanism for Codex JSON-RPC communication.
public protocol CodexJSONRPCTransport: Sendable {
    func sendRequest(method: String, params: [String: Any]?, timeout: TimeInterval) async throws -> RPCResponse
}

/// Standard process-based transport interacting with `codex app-server` via JSON-RPC 2.0.
public final class CodexProcessManager: CodexJSONRPCTransport, @unchecked Sendable {
    private let executablePath: String
    private var requestId: Int = 1
    private let lock = NSLock()

    public init(executablePath: String) {
        self.executablePath = executablePath
    }

    public func sendRequest(method: String, params: [String: Any]? = nil, timeout: TimeInterval = 10.0) async throws -> RPCResponse {
        let (initId, targetId) = lock.withLock {
            let id1 = requestId
            let id2 = requestId + 1
            requestId += 2
            return (id1, id2)
        }

        // 1. Prepare initialize handshake
        let initPayload: [String: Any] = [
            "jsonrpc": "2.0",
            "id": initId,
            "method": "initialize",
            "params": [
                "clientInfo": [
                    "name": "AgentMeter",
                    "title": "AgentMeter",
                    "version": AgentMeterCore.version
                ],
                "capabilities": NSNull()
            ]
        ]

        // 2. Prepare target method request
        var targetPayload: [String: Any] = [
            "jsonrpc": "2.0",
            "id": targetId,
            "method": method
        ]
        if let params = params {
            targetPayload["params"] = params
        }

        guard let initData = try? JSONSerialization.data(withJSONObject: initPayload, options: []),
              let initStr = String(data: initData, encoding: .utf8),
              let targetData = try? JSONSerialization.data(withJSONObject: targetPayload, options: []),
              let targetStr = String(data: targetData, encoding: .utf8) else {
            throw CodexError.invalidRequestPayload
        }

        let fullStreamInput = "\(initStr)\n\(targetStr)\n"

        return try await withThrowingTaskGroup(of: RPCResponse.self) { group in
            group.addTask {
                return try await self.executeSubprocessRPC(requestString: fullStreamInput, expectedId: targetId)
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw CodexError.timeout
            }

            guard let firstResult = try await group.next() else {
                throw CodexError.noResponse
            }
            group.cancelAll()
            return firstResult
        }
    }

    private func executeSubprocessRPC(requestString: String, expectedId: Int) async throws -> RPCResponse {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let stdinPipe = Pipe()
                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()

                process.executableURL = URL(fileURLWithPath: self.executablePath)
                process.arguments = ["app-server"]
                process.standardInput = stdinPipe
                process.standardOutput = stdoutPipe
                process.standardError = stderrPipe
                process.environment = ProcessInfo.processInfo.environment

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: CodexError.appServerLaunchFailed(error.localizedDescription))
                    return
                }

                guard let writeData = requestString.data(using: .utf8) else {
                    process.terminate()
                    continuation.resume(throwing: CodexError.invalidRequestPayload)
                    return
                }

                // Write request to stdin without closing stdin immediately
                stdinPipe.fileHandleForWriting.write(writeData)

                // Read line by line from stdout synchronously on background thread
                let fileHandle = stdoutPipe.fileHandleForReading
                var lineBuffer = ""
                var foundResult: [String: Any]? = nil
                var rpcErrorMessage: String? = nil

                while process.isRunning || foundResult != nil || rpcErrorMessage != nil {
                    let chunk = fileHandle.availableData
                    if chunk.isEmpty {
                        break
                    }
                    guard let chunkStr = String(data: chunk, encoding: .utf8) else {
                        continue
                    }
                    lineBuffer.append(chunkStr)

                    var matched = false
                    while let newlineRange = lineBuffer.range(of: "\n") {
                        let line = String(lineBuffer[..<newlineRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                        lineBuffer.removeSubrange(..<newlineRange.upperBound)

                        guard !line.isEmpty,
                              let lineData = line.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
                            continue
                        }

                        if let id = json["id"] as? Int, id == expectedId {
                            if let errorObj = json["error"] as? [String: Any] {
                                rpcErrorMessage = errorObj["message"] as? String ?? "Unknown error"
                            } else if let result = json["result"] as? [String: Any] {
                                foundResult = result
                            }
                            matched = true
                            break
                        }
                    }

                    if matched {
                        break
                    }
                }

                // Terminate process cleanly once we have the response
                if process.isRunning {
                    process.terminate()
                }

                if let err = rpcErrorMessage {
                    continuation.resume(throwing: CodexError.rpcError(err))
                } else if let result = foundResult {
                    continuation.resume(returning: RPCResponse(result))
                } else {
                    continuation.resume(throwing: CodexError.noResponse)
                }
            }
        }
    }
}
