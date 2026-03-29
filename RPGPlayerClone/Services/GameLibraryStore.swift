import Foundation

final class GameLibraryStore: @unchecked Sendable {
    static let shared = GameLibraryStore()

    private let fileManager = FileManager.default

    private init() {}

    private var libraryFileURL: URL {
        FileManager.documentsDirectory
            .appendingPathComponent("LibraryMetadata", isDirectory: true)
            .appendingPathComponent("games.json")
    }

    func loadGames() -> [Game] {
        guard let data = try? Data(contentsOf: libraryFileURL) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Game].self, from: data)
        } catch {
            return []
        }
    }

    func saveGames(_ games: [Game]) throws {
        let parent = libraryFileURL.deletingLastPathComponent()
        try fileManager.createDirectoryIfNeeded(at: parent)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(games)
        try data.write(to: libraryFileURL, options: [.atomic])
    }

    func makeGame(from directory: URL) -> Game {
        let gameRoot = GameDetector.normalizedGameRoot(from: directory)
        return Game(
            name: prettifiedName(from: gameRoot.lastPathComponent),
            path: gameRoot,
            coverImage: GameDetector.bestEffortCoverImage(in: gameRoot),
            gameType: GameType.detect(from: gameRoot),
            lastPlayed: nil
        )
    }

    private func prettifiedName(from raw: String) -> String {
        raw
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
