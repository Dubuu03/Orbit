import Foundation
import Observation

@MainActor
@Observable
final class WorkspaceRunner {
    private let configuration: AppConfiguration
    private let appLauncher: AppLauncher
    private let browserLauncher: BrowserLauncher
    private let urlLauncher: URLLauncher
    private let displayManager: DisplayManager
    private let windowManager: WindowManager
    private let processMonitor: ProcessMonitor
    private let commandRunner: CommandRunner
    private let logger: WorkspaceLogger

    private(set) var runState: WorkspaceRunState = .idle
    private(set) var actionStates: [ActionExecutionState] = []
    private(set) var logMessages: [String] = []

    init(configuration: AppConfiguration = .default) {
        let logger = WorkspaceLogger()
        let appLauncher = AppLauncher(logger: logger)
        let displayManager = DisplayManager(logger: logger)

        self.configuration = configuration
        self.appLauncher = appLauncher
        self.browserLauncher = BrowserLauncher(appLauncher: appLauncher, configuration: configuration, logger: logger)
        self.urlLauncher = URLLauncher(logger: logger)
        self.displayManager = displayManager
        self.windowManager = WindowManager(appLauncher: appLauncher, displayManager: displayManager, logger: logger)
        self.processMonitor = ProcessMonitor(appLauncher: appLauncher, logger: logger)
        self.commandRunner = CommandRunner(logger: logger)
        self.logger = logger
    }

    func run(_ workspace: Workspace) async {
        guard runState != .running else {
            return
        }

        logger.log("WorkspaceRunner", "Starting workspace: \(workspace.name)")
        runState = .running
        actionStates = workspace.actions.map { ActionExecutionState(action: $0) }
        logMessages = ["Starting workspace: \(workspace.name)"]

        for action in workspace.actions {
            update(action, status: .running, message: nil)
            appendLog(action.title)

            let result = await execute(action)
            switch result {
            case .success(let message):
                update(action, status: .success, message: message)
                appendLog(message)
            case .failure(let error):
                let message = error.localizedDescription
                update(action, status: action.isCritical ? .failed : .skipped, message: message)
                appendLog(message)

                if action.isCritical {
                    markPendingActionsSkipped(after: action)
                    runState = .failed(message)
                    logger.log("WorkspaceRunner", "Workspace failed: \(message)")
                    return
                }
            }
        }

        runState = .completed
        logger.log("WorkspaceRunner", "Workspace completed")
        appendLog("Workspace completed.")
    }

    private func execute(_ action: WorkspaceAction) async -> Result<String, WorkspaceError> {
        switch action.type {
        case .checkDisplay(let preferredDisplayName):
            return displayManager.checkExternalDisplay(named: preferredDisplayName)
                .map { "External display available: \($0.name)." }
        case .launchApplication(let applicationID):
            guard let application = configuration.application(for: applicationID) else {
                return .failure(.applicationNotConfigured(applicationID))
            }
            let result = await appLauncher.launch(application)
            switch result {
            case .launched, .alreadyRunning:
                return .success(result.message)
            case .notInstalled(let name):
                return .failure(.applicationNotInstalled(name))
            case .failed(let reason):
                return .failure(.launchFailed(reason))
            }
        case .launchBrowser(let request):
            return await browserLauncher.launch(request)
        case .openURL(let url):
            return urlLauncher.open(url)
        case .wait(let seconds):
            try? await Task.sleep(for: .seconds(seconds))
            return .success("Waited \(seconds) seconds.")
        case .waitForApplication(let applicationID, let timeout, let retryInterval):
            guard let application = configuration.application(for: applicationID) else {
                return .failure(.applicationNotConfigured(applicationID))
            }
            return await processMonitor.waitForApplication(
                application,
                timeout: timeout,
                retryInterval: retryInterval
            ).map { _ in "\(application.displayName) is running." }
        case .moveWindow(let request):
            guard let application = configuration.application(for: request.applicationID) else {
                return .failure(.applicationNotConfigured(request.applicationID))
            }
            return await windowManager.moveFirstWindowToPreferredExternalDisplay(
                application: application,
                preferredDisplayName: request.preferredDisplayName,
                timeout: request.timeout,
                retryInterval: request.retryInterval
            )
        case .resizeWindow:
            return .failure(.unsupportedAction("resizeWindow"))
        case .checkApplication(let applicationID):
            guard let application = configuration.application(for: applicationID) else {
                return .failure(.applicationNotConfigured(applicationID))
            }
            return appLauncher.isRunning(application)
                ? .success("\(application.displayName) is running.")
                : .failure(.timeout("\(application.displayName) is not running"))
        case .runCommand(let request):
            return await commandRunner.run(request).map { result in
                "Command completed with status \(result.terminationStatus)."
            }
        }
    }

    private func update(_ action: WorkspaceAction, status: ActionExecutionStatus, message: String?) {
        guard let index = actionStates.firstIndex(where: { $0.actionID == action.id }) else {
            return
        }
        actionStates[index].status = status
        actionStates[index].message = message
    }

    private func markPendingActionsSkipped(after failedAction: WorkspaceAction) {
        guard let failedIndex = actionStates.firstIndex(where: { $0.actionID == failedAction.id }) else {
            return
        }

        for index in actionStates.indices where index > failedIndex && actionStates[index].status == .pending {
            actionStates[index].status = .skipped
            actionStates[index].message = "Skipped because a critical action failed."
        }
    }

    private func appendLog(_ message: String) {
        logMessages.append(message)
    }
}
