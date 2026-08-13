import AppKit
import ApplicationServices
import Foundation

@MainActor
final class WindowManager {
    private let appLauncher: AppLauncher
    private let displayManager: DisplayManager
    private let logger: WorkspaceLogger

    init(
        appLauncher: AppLauncher,
        displayManager: DisplayManager,
        logger: WorkspaceLogger = WorkspaceLogger()
    ) {
        self.appLauncher = appLauncher
        self.displayManager = displayManager
        self.logger = logger
    }

    var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options)
    }

    func moveFirstWindowToPreferredExternalDisplay(
        application: ApplicationDefinition,
        preferredDisplayName: String?,
        timeout: TimeInterval,
        retryInterval: TimeInterval
    ) async -> Result<String, WorkspaceError> {
        guard hasAccessibilityPermission || requestAccessibilityPermission() else {
            logger.log("WindowManager", "Accessibility permission unavailable")
            return .failure(.accessibilityPermissionUnavailable)
        }

        guard let display = displayManager.preferredExternalDisplay(named: preferredDisplayName) else {
            logger.log("WindowManager", "No external display available for \(application.displayName)")
            return .failure(.displayUnavailable(preferredDisplayName))
        }

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let runningApplication = appLauncher.runningApplication(for: application),
               let window = firstWindow(for: runningApplication) {
                let result = move(window: window, to: display.visibleFrame)
                if result {
                    logger.log("WindowManager", "Moved \(application.displayName) window to \(display.name)")
                    return .success("Moved \(application.displayName) to \(display.name).")
                }
                return .failure(.windowNotFound(application.displayName))
            }

            try? await Task.sleep(for: .seconds(retryInterval))
        }

        return .failure(.timeout("Waiting for \(application.displayName) window"))
    }

    private func firstWindow(for application: NSRunningApplication) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(application.processIdentifier)
        var rawWindows: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &rawWindows)
        guard result == .success,
              let windows = rawWindows as? [AXUIElement] else {
            return nil
        }
        return windows.first
    }

    private func move(window: AXUIElement, to frame: CGRect) -> Bool {
        var origin = CGPoint(x: frame.minX, y: frame.minY)
        var size = CGSize(width: frame.width, height: frame.height)

        guard let originValue = AXValueCreate(.cgPoint, &origin),
              let sizeValue = AXValueCreate(.cgSize, &size) else {
            return false
        }

        let positionResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, originValue)
        let sizeResult = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        return positionResult == .success && sizeResult == .success
    }
}
