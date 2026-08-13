import Foundation

struct AppConfiguration: Sendable {
    var work: WorkConfiguration
    var applications: [String: ApplicationDefinition]

    static let `default` = AppConfiguration(
        work: .default,
        applications: ApplicationCatalog.defaultApplications
    )

    func application(for id: String) -> ApplicationDefinition? {
        applications[id]
    }
}

struct WorkConfiguration: Sendable {
    var edgeProfileDirectory: String
    var vmURL: URL?
    var preferredExternalDisplayName: String?
    var windowsAppWindowTimeout: TimeInterval
    var processTimeout: TimeInterval
    var retryInterval: TimeInterval

    static let `default` = WorkConfiguration(
        // Open edge://version in the intended Edge profile and copy the Profile Path's final directory,
        // such as "Profile 1", "Profile 2", or "Default".
        edgeProfileDirectory: "Profile 2",
        // Replace this placeholder with the VM/startup page used by your work environment.
        vmURL: URL(string: "https://example.com/work-vm-startup"),
        // Set this to a display name from System Settings > Displays, or leave nil to use any external display.
        preferredExternalDisplayName: nil,
        windowsAppWindowTimeout: 30,
        processTimeout: 30,
        retryInterval: 1
    )
}

enum ApplicationCatalog {
    static let edgeID = "edge"
    static let teamsID = "teams"
    static let outlookID = "outlook"
    static let windowsAppID = "windowsApp"

    static let defaultApplications: [String: ApplicationDefinition] = [
        edgeID: ApplicationDefinition(
            id: edgeID,
            displayName: "Microsoft Edge",
            bundleIdentifiers: ["com.microsoft.edgemac"],
            fallbackPaths: ["/Applications/Microsoft Edge.app"]
        ),
        teamsID: ApplicationDefinition(
            id: teamsID,
            displayName: "Microsoft Teams",
            bundleIdentifiers: [
                "com.microsoft.teams2",
                "com.microsoft.teams"
            ],
            fallbackPaths: [
                "/Applications/Microsoft Teams.app",
                "/Applications/Microsoft Teams classic.app"
            ]
        ),
        outlookID: ApplicationDefinition(
            id: outlookID,
            displayName: "Microsoft Outlook",
            bundleIdentifiers: ["com.microsoft.Outlook"],
            fallbackPaths: ["/Applications/Microsoft Outlook.app"]
        ),
        windowsAppID: ApplicationDefinition(
            id: windowsAppID,
            displayName: "Windows App",
            bundleIdentifiers: [
                "com.microsoft.rdc.macos",
                "com.microsoft.rdc.macosuniversal"
            ],
            fallbackPaths: [
                "/Applications/Windows App.app",
                "/Applications/Microsoft Remote Desktop.app"
            ]
        )
    ]
}
