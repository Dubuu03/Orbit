import AppKit
import Foundation

@MainActor
final class BrowserLauncher {
    private let appLauncher: AppLauncher
    private let configuration: AppConfiguration
    private let logger: WorkspaceLogger

    init(
        appLauncher: AppLauncher,
        configuration: AppConfiguration,
        logger: WorkspaceLogger = WorkspaceLogger()
    ) {
        self.appLauncher = appLauncher
        self.configuration = configuration
        self.logger = logger
    }

    func launch(_ request: BrowserLaunchRequest) async -> Result<String, WorkspaceError> {
        guard let browser = configuration.application(for: request.browserID) else {
            return .failure(.browserNotConfigured(request.browserID))
        }

        guard let applicationURL = appLauncher.applicationURL(for: browser) else {
            return .failure(.applicationNotInstalled(browser.displayName))
        }

        var arguments = request.additionalArguments
        if let profileDirectory = request.profileDirectory, !profileDirectory.isEmpty {
            arguments.append("--profile-directory=\(profileDirectory)")
        }

        if let url = request.url {
            arguments.append(url.absoluteString)
        }

        logger.log("BrowserLauncher", "Launching \(browser.displayName) profile: \(request.profileDirectory ?? "default")")

        do {
            _ = try await appLauncher.openApplication(at: applicationURL, arguments: arguments)
            return .success("Opened \(browser.displayName) with configured profile.")
        } catch {
            return .failure(.launchFailed(error.localizedDescription))
        }
    }
}
