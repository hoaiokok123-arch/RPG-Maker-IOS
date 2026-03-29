import Combine
import Foundation

@MainActor
final class GameLibraryViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var statusMessage: String?

    private let store: GameLibraryStore
    private let importer: FileImporter
    private let fileManager = FileManager.default

    private struct ImportOutcome: Sendable {
        let importedGames: [Game]
        let failures: [String]
    }

    init(store: GameLibraryStore = .shared, importer: FileImporter = .shared) {
        self.store = store
        self.importer = importer
        loadGames()
    }

    func loadGames() {
        let loadedGames = store.loadGames().filter { fileManager.itemExists(at: $0.path) }
        games = sorted(loadedGames)
        persistGames()
    }

    func deleteGame() {
        statusMessage = "Hay goi deleteGame(_:) hoac deleteGame(at:)."
    }

    func deleteGame(_ game: Game) {
        if fileManager.itemExists(at: game.path) {
            try? fileManager.removeItem(at: game.path)
        }

        games.removeAll { $0.id == game.id }
        persistGames()
    }

    func deleteGame(at offsets: IndexSet) {
        for offset in offsets.sorted(by: >) {
            deleteGame(games[offset])
        }
    }

    func importGameFromFiles() {
        statusMessage = "Hay truyen URL vao importGameFromFiles(urls:)."
    }

    func importGameFromFiles(urls: [URL]) {
        guard !urls.isEmpty else {
            return
        }

        statusMessage = "Dang import \(urls.count) muc..."

        let importer = self.importer
        let store = self.store

        Task {
            let outcome = await Task.detached(priority: .userInitiated) { () -> ImportOutcome in
                var importedGames: [Game] = []
                var failures: [String] = []

                for url in urls {
                    switch importer.importGame(from: url) {
                    case .success(let importedURL):
                        importedGames.append(store.makeGame(from: importedURL))
                    case .failure(let error):
                        failures.append("\(url.lastPathComponent): \(error.localizedDescription)")
                    }
                }

                return ImportOutcome(importedGames: importedGames, failures: failures)
            }.value

            var merged = games
            for game in outcome.importedGames {
                merged.removeAll { $0.path.standardizedFileURL == game.path.standardizedFileURL }
                merged.append(game)
            }

            games = sorted(merged)
            persistGames()

            if !outcome.importedGames.isEmpty && outcome.failures.isEmpty {
                statusMessage = "Da import \(outcome.importedGames.count) muc."
            } else if outcome.failures.isEmpty {
                statusMessage = nil
            } else {
                statusMessage = outcome.failures.joined(separator: "\n")
            }
        }
    }

    func markPlayed(_ game: Game) {
        guard let index = games.firstIndex(where: { $0.id == game.id }) else {
            return
        }

        games[index].lastPlayed = Date()
        games = sorted(games)
        persistGames()
    }

    private func persistGames() {
        do {
            try store.saveGames(games)
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func sorted(_ input: [Game]) -> [Game] {
        input.sorted { lhs, rhs in
            switch (lhs.lastPlayed, rhs.lastPlayed) {
            case let (left?, right?):
                if left != right {
                    return left > right
                }
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                break
            }

            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}
