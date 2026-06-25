import Foundation

public protocol ContainerCommandRunning {
    func run(
        executablePath: URL,
        arguments: [String],
        workingDirectory: URL?
    ) async throws -> CLICommandOutput
}

public final class ContainerCommandRunner: ContainerCommandRunning, @unchecked Sendable {
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
            let accumulator = CommandOutputAccumulator(startedAt: startedAt, arguments: arguments)

            let finish: (Int32) -> Void = { status in
                guard accumulator.markFinished() else { return }
                let output = accumulator.output(exitCode: Int(status))
                continuation.resume(returning: output)
            }

            func fail(_ error: Error) {
                guard accumulator.markFinished() else { return }
                continuation.resume(throwing: ContainerCLIError.commandFailed(error.localizedDescription))
            }

            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    handle.readabilityHandler = nil
                    return
                }

                accumulator.append(data, stream: .standardOutput)
            }

            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    handle.readabilityHandler = nil
                    return
                }

                accumulator.append(data, stream: .standardError)
            }

            process.terminationHandler = { process in
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil

                let stdoutRemainder = (try? stdoutPipe.fileHandleForReading.readToEnd()) ?? Data()
                let stderrRemainder = (try? stderrPipe.fileHandleForReading.readToEnd()) ?? Data()
                accumulator.append(stdoutRemainder, stream: .standardOutput)
                accumulator.append(stderrRemainder, stream: .standardError)

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

private final class CommandOutputAccumulator: @unchecked Sendable {
    private let lock = NSLock()
    private let startedAt: Date
    private let arguments: [String]
    private var stdoutData = Data()
    private var stderrData = Data()
    private var chunks: [CLICommandOutput.StreamChunk] = []
    private var finished = false

    init(startedAt: Date, arguments: [String]) {
        self.startedAt = startedAt
        self.arguments = arguments
    }

    func append(_ data: Data, stream: CLICommandOutput.StreamChunk.StreamType) {
        guard !data.isEmpty else { return }

        lock.lock()
        switch stream {
        case .standardOutput:
            stdoutData.append(data)
        case .standardError:
            stderrData.append(data)
        }
        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            chunks.append(.init(stream: stream, text: text))
        }
        lock.unlock()
    }

    func markFinished() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if finished {
            return false
        }
        finished = true
        return true
    }

    func output(exitCode: Int) -> CLICommandOutput {
        lock.lock()
        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""
        let outputChunks = chunks
        lock.unlock()

        return CLICommandOutput(
            exitCode: exitCode,
            stdout: stdout,
            stderr: stderr,
            executedAt: startedAt,
            elapsed: Date().timeIntervalSince(startedAt),
            arguments: arguments,
            chunks: outputChunks
        )
    }
}
