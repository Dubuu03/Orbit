import Foundation

enum ActionExecutionStatus: String, Codable, Sendable {
    case pending
    case running
    case success
    case failed
    case skipped
}

struct ActionExecutionState: Identifiable, Hashable, Sendable {
    let id: UUID
    let actionID: UUID
    var title: String
    var status: ActionExecutionStatus
    var message: String?
    var isCritical: Bool

    init(action: WorkspaceAction, status: ActionExecutionStatus = .pending, message: String? = nil) {
        self.id = action.id
        self.actionID = action.id
        self.title = action.title
        self.status = status
        self.message = message
        self.isCritical = action.isCritical
    }
}

enum WorkspaceRunState: Equatable, Sendable {
    case idle
    case running
    case completed
    case failed(String)
}
