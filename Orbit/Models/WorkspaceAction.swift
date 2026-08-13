import Foundation

struct WorkspaceAction: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var title: String
    var type: ActionType
    var isCritical: Bool

    init(
        id: UUID = UUID(),
        title: String,
        type: ActionType,
        isCritical: Bool = true
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.isCritical = isCritical
    }
}

enum ActionType: Hashable, Codable, Sendable {
    case checkDisplay(preferredDisplayName: String?)
    case launchApplication(applicationID: String)
    case launchBrowser(BrowserLaunchRequest)
    case openURL(URL)
    case wait(seconds: TimeInterval)
    case waitForApplication(applicationID: String, timeout: TimeInterval, retryInterval: TimeInterval)
    case moveWindow(WindowMoveRequest)
    case resizeWindow
    case checkApplication(applicationID: String)
    case runCommand(CommandRequest)
}

struct BrowserLaunchRequest: Hashable, Codable, Sendable {
    var browserID: String
    var profileDirectory: String?
    var url: URL?
    var additionalArguments: [String]

    init(
        browserID: String,
        profileDirectory: String? = nil,
        url: URL? = nil,
        additionalArguments: [String] = []
    ) {
        self.browserID = browserID
        self.profileDirectory = profileDirectory
        self.url = url
        self.additionalArguments = additionalArguments
    }
}

struct WindowMoveRequest: Hashable, Codable, Sendable {
    var applicationID: String
    var preferredDisplayName: String?
    var timeout: TimeInterval
    var retryInterval: TimeInterval

    init(
        applicationID: String,
        preferredDisplayName: String? = nil,
        timeout: TimeInterval,
        retryInterval: TimeInterval
    ) {
        self.applicationID = applicationID
        self.preferredDisplayName = preferredDisplayName
        self.timeout = timeout
        self.retryInterval = retryInterval
    }
}

struct CommandRequest: Hashable, Codable, Sendable {
    var executablePath: String
    var arguments: [String]

    init(executablePath: String, arguments: [String] = []) {
        self.executablePath = executablePath
        self.arguments = arguments
    }
}
