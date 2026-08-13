import Foundation

struct Workspace: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var name: String
    var actions: [WorkspaceAction]

    init(id: UUID = UUID(), name: String, actions: [WorkspaceAction]) {
        self.id = id
        self.name = name
        self.actions = actions
    }
}
