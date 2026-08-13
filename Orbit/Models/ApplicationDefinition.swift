import Foundation

struct ApplicationDefinition: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let displayName: String
    let bundleIdentifiers: [String]
    let fallbackPaths: [String]

    init(
        id: String,
        displayName: String,
        bundleIdentifiers: [String],
        fallbackPaths: [String] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.bundleIdentifiers = bundleIdentifiers
        self.fallbackPaths = fallbackPaths
    }
}
