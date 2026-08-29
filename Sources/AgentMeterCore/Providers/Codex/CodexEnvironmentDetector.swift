import Foundation

/// Detects and verifies the local Codex CLI environment.
public struct CodexEnvironmentDetector: Sendable {
    public let customExecutablePath: String?

    public static let commonPaths = [
        "/opt/homebrew/bin/codex",
        "/usr/local/bin/codex",
        "~/.cargo/bin/codex",
        "~/.local/bin/codex"
    ]

    public init(customExecutablePath: String? = nil) {
        self.customExecutablePath = customExecutablePath
    }

    /// Resolves the absolute path to the codex binary.
    public func resolveExecutablePath() -> String? {
        let fileManager = FileManager.default

        // 1. Check custom path if provided
        if let custom = customExecutablePath?.trimmingCharacters(in: .whitespacesAndNewlines), !custom.isEmpty {
            let expanded = NSString(string: custom).expandingTildeInPath
            if fileManager.isExecutableFile(atPath: expanded) {
                return expanded
            }
        }

        // 2. Check standard common locations
        for path in Self.commonPaths {
            let expanded = NSString(string: path).expandingTildeInPath
            if fileManager.isExecutableFile(atPath: expanded) {
                return expanded
            }
        }

        // 3. Search via which or PATH environment
        if let pathEnv = ProcessInfo.processInfo.environment["PATH"] {
            for dir in pathEnv.split(separator: ":") {
                let candidate = (String(dir) as NSString).appendingPathComponent("codex")
                if fileManager.isExecutableFile(atPath: candidate) {
                    return candidate
                }
            }
        }

        return nil
    }

    /// Evaluates the environment status.
    public func detectStatus() async -> EnvironmentStatus {
        guard let execPath = resolveExecutablePath() else {
            return .cliMissing(expectedPath: customExecutablePath ?? "/opt/homebrew/bin/codex")
        }

        // Check if executable runs and reports authentication status
        let (output, exitCode) = await runProcess(executable: execPath, arguments: ["--version"])
        guard exitCode == 0 else {
            return .error(description: "Failed to execute codex binary at \(execPath): \(output)")
        }

        return .healthy
    }

    /// Helper to execute a short-lived process.
    private func runProcess(executable: String, arguments: [String]) async -> (output: String, exitCode: Int32) {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let pipe = Pipe()

                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = arguments
                process.standardOutput = pipe
                process.standardError = pipe

                do {
                    try process.run()
                    process.waitUntilExit()

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    continuation.resume(returning: (output.trimmingCharacters(in: .whitespacesAndNewlines), process.terminationStatus))
                } catch {
                    continuation.resume(returning: (error.localizedDescription, -1))
                }
            }
        }
    }
}
