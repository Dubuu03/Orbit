import AppKit
import Foundation

enum AppLaunchResult: Equatable, Sendable {
    case launched(String)
    case alreadyRunning(String)
    case notInstalled(String)
    case failed(String)

    var message: String {
        switch self {
        case .launched(let name):
            return "Launched \(name)."
        case .alreadyRunning(let name):
            return "\(name) already running."
        case .notInstalled(let name):
            return "\(name) is not installed."
        case .failed(let reason):
            return reason
        }
    }
}

@MainActor
final class AppLauncher {
    private let workspace: NSWorkspace
    private let fileManager: FileManager
    private let logger: WorkspaceLogger

    init(
        workspace: NSWorkspace = .shared,
        fileManager: FileManager = .default,
        logger: WorkspaceLogger = WorkspaceLogger()
    ) {
        self.workspace = workspace
        self.fileManager = fileManager
        self.logger = logger
    }

    func launch(_ application: ApplicationDefinition) async -> AppLaunchResult {
        if isRunning(application) {
            logger.log("AppLauncher", "\(application.displayName) already running")
            return .alreadyRunning(application.displayName)
        }

        guard let applicationURL = applicationURL(for: application) else {
            logger.log("AppLauncher", "\(application.displayName) not installed")
            return .notInstalled(application.displayName)
        }

        do {
            _ = try await openApplication(at: applicationURL, arguments: [])
            logger.log("AppLauncher", "Launching \(application.displayName)")
            return .launched(application.displayName)
        } catch {
            logger.log("AppLauncher", "Failed launching \(application.displayName): \(error.localizedDescription)")
            return .failed(error.localizedDescription)
        }
    }

    func isRunning(_ application: ApplicationDefinition) -> Bool {
        workspace.runningApplications.contains { runningApplication in
            guard let bundleIdentifier = runningApplication.bundleIdentifier else {
                return false
            }
            return application.bundleIdentifiers.contains(bundleIdentifier)
        }
    }

    func runningApplication(for application: ApplicationDefinition) -> NSRunningApplication? {
        workspace.runningApplications.first { runningApplication in
            guard let bundleIdentifier = runningApplication.bundleIdentifier else {
                return false
            }
            return application.bundleIdentifiers.contains(bundleIdentifier)
        }
    }

    func applicationURL(for application: ApplicationDefinition) -> URL? {
        for bundleIdentifier in application.bundleIdentifiers {
            if let url = workspace.urlForApplication(withBundleIdentifier: bundleIdentifier) {
                return url
            }
        }

        for path in application.fallbackPaths where fileManager.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        return nil
    }

    func openApplication(at url: URL, arguments: [String]) async throws -> NSRunningApplication {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.arguments = arguments
        configuration.activates = true
        configuration.createsNewApplicationInstance = false

        return try await withCheckedThrowingContinuation { continuation in
            workspace.openApplication(at: url, configuration: configuration) { application, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let application {
                    continuation.resume(returning: application)
                } else {
                    continuation.resume(throwing: WorkspaceError.launchFailed("macOS did not return a running application."))
                }
            }
        }
    }
}
