import AppKit
import Foundation

enum ProcessState: String, Sendable {
    case running
    case notRunning
    case starting
    case terminated
}

@MainActor
final class ProcessMonitor {
    private let appLauncher: AppLauncher
    private let logger: WorkspaceLogger

    init(appLauncher: AppLauncher, logger: WorkspaceLogger = WorkspaceLogger()) {
        self.appLauncher = appLauncher
        self.logger = logger
    }

    func state(for application: ApplicationDefinition) -> ProcessState {
        appLauncher.isRunning(application) ? .running : .notRunning
    }

    func waitForApplication(
        _ application: ApplicationDefinition,
        timeout: TimeInterval,
        retryInterval: TimeInterval
    ) async -> Result<NSRunningApplication, WorkspaceError> {
        logger.log("ProcessMonitor", "Waiting for \(application.displayName)")
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if let runningApplication = appLauncher.runningApplication(for: application) {
                logger.log("ProcessMonitor", "\(application.displayName) is running")
                return .success(runningApplication)
            }

            try? await Task.sleep(for: .seconds(retryInterval))
        }

        return .failure(.timeout("Waiting for \(application.displayName)"))
    }
}
