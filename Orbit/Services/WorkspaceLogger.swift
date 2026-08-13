import Foundation

struct WorkspaceLogger: Sendable {
    func log(_ category: String, _ message: String) {
        print("[\(category)] \(message)")
    }
}
