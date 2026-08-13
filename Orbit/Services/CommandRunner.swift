import Foundation

struct CommandResult: Sendable {
    var terminationStatus: Int32
}

final class CommandRunner: Sendable {
    private let logger: WorkspaceLogger

    init(logger: WorkspaceLogger = WorkspaceLogger()) {
        self.logger = logger
    }

    func run(_ request: CommandRequest) async -> Result<CommandResult, WorkspaceError> {
        // Intentionally structured: no shell parsing or arbitrary user scripting in the MVP.
        let executableURL = URL(fileURLWithPath: request.executablePath)
        guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
            return .failure(.commandUnavailable)
        }

        let process = Process()
        process.executableURL = executableURL
        process.arguments = request.arguments

        return await withCheckedContinuation { continuation in
            process.terminationHandler = { completedProcess in
                let status = completedProcess.terminationStatus
                if status == 0 {
                    continuation.resume(returning: .success(CommandResult(terminationStatus: status)))
                } else {
                    continuation.resume(returning: .failure(.commandFailed("Exit status \(status).")))
                }
            }

            do {
                logger.log("CommandRunner", "Running command: \(request.executablePath)")
                try process.run()
            } catch {
                continuation.resume(returning: .failure(.commandFailed(error.localizedDescription)))
            }
        }
    }
}
