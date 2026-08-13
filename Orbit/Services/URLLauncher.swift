import AppKit
import Foundation

@MainActor
final class URLLauncher {
    private let workspace: NSWorkspace
    private let logger: WorkspaceLogger

    init(workspace: NSWorkspace = .shared, logger: WorkspaceLogger = WorkspaceLogger()) {
        self.workspace = workspace
        self.logger = logger
    }

    func open(_ url: URL) -> Result<String, WorkspaceError> {
        logger.log("URLLauncher", "Opening URL: \(url.absoluteString)")
        if workspace.open(url) {
            return .success("Opened \(url.absoluteString).")
        }
        return .failure(.launchFailed("Unable to open \(url.absoluteString)."))
    }
}
