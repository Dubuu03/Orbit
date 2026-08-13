import Foundation

enum WorkspaceError: LocalizedError, Sendable {
    case applicationNotConfigured(String)
    case applicationNotInstalled(String)
    case launchFailed(String)
    case browserNotConfigured(String)
    case invalidURL(String)
    case displayUnavailable(String?)
    case accessibilityPermissionUnavailable
    case windowNotFound(String)
    case commandUnavailable
    case commandFailed(String)
    case timeout(String)
    case unsupportedAction(String)

    var errorDescription: String? {
        switch self {
        case .applicationNotConfigured(let id):
            return "Application is not configured: \(id)."
        case .applicationNotInstalled(let name):
            return "Application is not installed: \(name)."
        case .launchFailed(let reason):
            return "Launch failed: \(reason)."
        case .browserNotConfigured(let id):
            return "Browser is not configured: \(id)."
        case .invalidURL(let value):
            return "Invalid URL: \(value)."
        case .displayUnavailable(let name):
            return "External display unavailable\(name.map { ": \($0)" } ?? "")."
        case .accessibilityPermissionUnavailable:
            return "Accessibility permission is unavailable."
        case .windowNotFound(let appName):
            return "Window not found for \(appName)."
        case .commandUnavailable:
            return "Command execution is not enabled for this action."
        case .commandFailed(let reason):
            return "Command failed: \(reason)."
        case .timeout(let operation):
            return "Timed out: \(operation)."
        case .unsupportedAction(let action):
            return "Unsupported action: \(action)."
        }
    }
}
