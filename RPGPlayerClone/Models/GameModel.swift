import Foundation

struct Game: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var path: URL
    var coverImage: URL?
    var gameType: GameType
    var lastPlayed: Date?

    init(
        id: UUID = UUID(),
        name: String,
        path: URL,
        coverImage: URL? = nil,
        gameType: GameType = .unknown,
        lastPlayed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.coverImage = coverImage
        self.gameType = gameType
        self.lastPlayed = lastPlayed
    }

    var isPlayable: Bool {
        gameType != .unknown
    }

    var sandboxFriendlyPath: URL {
        path.standardizedFileURL
    }
}
