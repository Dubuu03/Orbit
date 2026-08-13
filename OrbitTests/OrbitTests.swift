import Foundation
import Testing
@testable import Orbit

struct OrbitTests {
    @Test func workWorkspaceContainsExpectedMVPActions() async throws {
        let configuration = AppConfiguration.default
        let workspace = WorkspaceStore.workWorkspace(configuration: configuration)

        #expect(workspace.name == "Work")
        #expect(workspace.actions.count == 7)
        #expect(workspace.actions.contains { $0.title == "Open VM startup page in Edge Work profile" })
        #expect(workspace.actions.contains { $0.title == "Launch Microsoft Teams" })
        #expect(workspace.actions.contains { $0.title == "Launch Microsoft Outlook" })
        #expect(workspace.actions.contains { $0.title == "Launch Windows App" })
    }

    @Test func defaultConfigurationCentralizesApplications() async throws {
        let configuration = AppConfiguration.default

        #expect(configuration.application(for: ApplicationCatalog.edgeID)?.displayName == "Microsoft Edge")
        #expect(configuration.application(for: ApplicationCatalog.teamsID)?.bundleIdentifiers.isEmpty == false)
        #expect(configuration.application(for: ApplicationCatalog.outlookID)?.fallbackPaths.isEmpty == false)
        #expect(configuration.application(for: ApplicationCatalog.windowsAppID)?.displayName == "Windows App")
    }
}
