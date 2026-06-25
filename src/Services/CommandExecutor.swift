import Foundation

public protocol ContainerCommandRunning {
    func run(
        executablePath: URL,
        arguments: [String],
        workingDirectory: URL?
    ) async throws -> CLICommandOutput
}

public final class ContainerCommandRunner: ContainerCommandRunning, @unchecked Sendable {
    private let lock = NSLock()

    public init() {}

    public func run(
        executablePath: URL,
        arguments: [String],
        workingDirectory: URL? = nil
    ) async throws -> CLICommandOutput {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = executablePath
            process.arguments = arguments
            process.currentDirectoryURL = workingDirectory

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            let startedAt = Date()
            var stdoutData = Data()
            var stderrData = Data()
            var chunks: [CLICommandOutput.StreamChunk] = []
            var finished = false
            let commandArguments = arguments

            let finish: (Int32) -> Void = { status in
                self.lock.lock()
                if finished {
                    self.lock.unlock()
                    return
                }
                finished = true
                self.lock.unlock()

                let elapsed = Date().timeIntervalSince(startedAt)
                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""
                let output = CLICommandOutput(
                    exitCode: Int(status),
                    stdout: stdout,
                    stderr: stderr,
                    executedAt: startedAt,
                    elapsed: elapsed,
                    arguments: commandArguments,
                    chunks: chunks
                )
                continuation.resume(returning: output)
            }

            func fail(_ error: Error) {
                self.lock.lock()
                if finished {
                    self.lock.unlock()
                    return
                }
                finished = true
                self.lock.unlock()
                continuation.resume(throwing: ContainerCLIError.commandFailed(error.localizedDescription))
            }

            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    handle.readabilityHandler = nil
                    return
                }

                self.lock.lock()
                stdoutData.append(data)
                if let line = String(data: data, encoding: .utf8), !line.isEmpty {
                    chunks.append(.init(stream: .standardOutput, text: line))
                }
                self.lock.unlock()
            }

            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    handle.readabilityHandler = nil
                    return
                }

                self.lock.lock()
                stderrData.append(data)
                if let line = String(data: data, encoding: .utf8), !line.isEmpty {
                    chunks.append(.init(stream: .standardError, text: line))
                }
                self.lock.unlock()
            }

            process.terminationHandler = { process in
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil

                let stdoutRemainder = (try? stdoutPipe.fileHandleForReading.readToEnd()) ?? Data()
                let stderrRemainder = (try? stderrPipe.fileHandleForReading.readToEnd()) ?? Data()
                self.lock.lock()
                stdoutData.append(stdoutRemainder)
                stderrData.append(stderrRemainder)
                let outputChunks = chunks
                self.lock.unlock()
                var updatedChunks = outputChunks
                if let remaining = String(data: stdoutRemainder, encoding: .utf8), !remaining.isEmpty {
                    updatedChunks.append(.init(stream: .standardOutput, text: remaining))
                }
                if let remaining = String(data: stderrRemainder, encoding: .utf8), !remaining.isEmpty {
                    updatedChunks.append(.init(stream: .standardError, text: remaining))
                }
                self.lock.lock()
                chunks = updatedChunks
                self.lock.unlock()

                if process.terminationReason == .exit {
                    finish(process.terminationStatus)
                    return
                }
                if process.terminationStatus == 0 {
                    finish(process.terminationStatus)
                } else {
                    finish(process.terminationStatus)
                }
            }

            do {
                try process.run()
            } catch {
                fail(error)
            }
        }
    }
}
