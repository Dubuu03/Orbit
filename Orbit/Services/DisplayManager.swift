import AppKit
import Foundation

struct DisplayInfo: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let frame: CGRect
    let visibleFrame: CGRect
    let isMain: Bool
    let isExternal: Bool
}

@MainActor
final class DisplayManager {
    private let logger: WorkspaceLogger

    init(logger: WorkspaceLogger = WorkspaceLogger()) {
        self.logger = logger
    }

    var displays: [DisplayInfo] {
        let mainScreen = NSScreen.main
        return NSScreen.screens.enumerated().map { index, screen in
            let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            let name = screen.localizedName
            let isMain = screen == mainScreen
            return DisplayInfo(
                id: screenNumber?.stringValue ?? "screen-\(index)",
                name: name,
                frame: screen.frame,
                visibleFrame: screen.visibleFrame,
                isMain: isMain,
                isExternal: !isMain
            )
        }
    }

    var mainDisplay: DisplayInfo? {
        displays.first(where: { $0.isMain })
    }

    var externalDisplays: [DisplayInfo] {
        displays.filter(\.isExternal)
    }

    func preferredExternalDisplay(named preferredName: String?) -> DisplayInfo? {
        let externalDisplays = externalDisplays
        guard let preferredName, !preferredName.isEmpty else {
            return externalDisplays.first
        }
        return externalDisplays.first { $0.name.localizedCaseInsensitiveContains(preferredName) }
    }

    func checkExternalDisplay(named preferredName: String?) -> Result<DisplayInfo, WorkspaceError> {
        if let display = preferredExternalDisplay(named: preferredName) {
            logger.log("DisplayManager", "External display detected: \(display.name)")
            return .success(display)
        }

        logger.log("DisplayManager", "External display unavailable")
        return .failure(.displayUnavailable(preferredName))
    }
}
