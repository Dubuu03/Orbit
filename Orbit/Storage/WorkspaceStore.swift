import Foundation

struct WorkspaceStore: Sendable {
    var workspaces: [Workspace]

    static func defaultStore(configuration: AppConfiguration = .default) -> WorkspaceStore {
        WorkspaceStore(workspaces: [Self.workWorkspace(configuration: configuration)])
    }

    static func workWorkspace(configuration: AppConfiguration) -> Workspace {
        let work = configuration.work
        var actions: [WorkspaceAction] = [
            WorkspaceAction(
                title: "Check external display",
                type: .checkDisplay(preferredDisplayName: work.preferredExternalDisplayName),
                isCritical: false
            )
        ]

        if let vmURL = work.vmURL {
            actions.append(
                WorkspaceAction(
                    title: "Open VM startup page in Edge Work profile",
                    type: .launchBrowser(
                        BrowserLaunchRequest(
                            browserID: ApplicationCatalog.edgeID,
                            profileDirectory: work.edgeProfileDirectory,
                            url: vmURL
                        )
                    ),
                    isCritical: true
                )
            )
        } else {
            actions.append(
                WorkspaceAction(
                    title: "Open VM startup page in Edge Work profile",
                    type: .launchBrowser(
                        BrowserLaunchRequest(
                            browserID: ApplicationCatalog.edgeID,
                            profileDirectory: work.edgeProfileDirectory
                        )
                    ),
                    isCritical: true
                )
            )
        }

        actions.append(contentsOf: [
            WorkspaceAction(
                title: "Launch Microsoft Teams",
                type: .launchApplication(applicationID: ApplicationCatalog.teamsID),
                isCritical: false
            ),
            WorkspaceAction(
                title: "Launch Microsoft Outlook",
                type: .launchApplication(applicationID: ApplicationCatalog.outlookID),
                isCritical: false
            ),
            WorkspaceAction(
                title: "Launch Windows App",
                type: .launchApplication(applicationID: ApplicationCatalog.windowsAppID),
                isCritical: false
            ),
            WorkspaceAction(
                title: "Wait for Windows App",
                type: .waitForApplication(
                    applicationID: ApplicationCatalog.windowsAppID,
                    timeout: work.processTimeout,
                    retryInterval: work.retryInterval
                ),
                isCritical: false
            ),
            WorkspaceAction(
                title: "Move Windows App to external display",
                type: .moveWindow(
                    WindowMoveRequest(
                        applicationID: ApplicationCatalog.windowsAppID,
                        preferredDisplayName: work.preferredExternalDisplayName,
                        timeout: work.windowsAppWindowTimeout,
                        retryInterval: work.retryInterval
                    )
                ),
                isCritical: false
            )
        ])

        return Workspace(name: "Work", actions: actions)
    }
}
