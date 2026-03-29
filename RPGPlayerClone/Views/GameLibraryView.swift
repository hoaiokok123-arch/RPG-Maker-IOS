import SwiftUI
import UIKit
import UniformTypeIdentifiers
import Combine

struct GameLibraryView: View {
    @ObservedObject var viewModel: GameLibraryViewModel

    @State private var showingImporter = false
    @State private var activeGame: Game?
    @State private var activeController: UIViewController?
    @State private var deleteCandidate: Game?

    private let columns = [
        GridItem(.adaptive(minimum: 190), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.games.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.games) { game in
                                GameCardView(
                                    game: game,
                                    playAction: { launch(game) },
                                    deleteAction: { deleteCandidate = game }
                                )
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("RPGPlayer Clone")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Import") {
                        showingImporter = true
                    }

                    NavigationLink("Settings") {
                        SettingsView()
                    }
                }
            }
            .refreshable {
                viewModel.loadGames()
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: supportedImportTypes,
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    viewModel.importGameFromFiles(urls: urls)
                case .failure(let error):
                    viewModel.statusMessage = error.localizedDescription
                }
            }
            .alert(
                "Thong bao",
                isPresented: Binding(
                    get: { viewModel.statusMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            viewModel.statusMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    viewModel.statusMessage = nil
                }
            } message: {
                Text(viewModel.statusMessage ?? "")
            }
            .confirmationDialog(
                "Xoa game khoi thu vien?",
                isPresented: Binding(
                    get: { deleteCandidate != nil },
                    set: { isPresented in
                        if !isPresented {
                            deleteCandidate = nil
                        }
                    }
                ),
                titleVisibility: .visible
            ) {
                Button("Xoa", role: .destructive) {
                    if let deleteCandidate {
                        viewModel.deleteGame(deleteCandidate)
                    }
                    self.deleteCandidate = nil
                }

                Button("Huy", role: .cancel) {
                    deleteCandidate = nil
                }
            } message: {
                Text(deleteCandidate?.name ?? "")
            }
        }
        .fullScreenCover(item: $activeGame, onDismiss: {
            activeController = nil
            GameEngineManager.shared.shutdownCurrentEngine()
        }) { game in
            GameRuntimeScreen(
                game: game,
                controller: activeController
            ) {
                activeGame = nil
            }
        }
        .onAppear {
            let pendingURLs = ExternalFileOpenCoordinator.shared.drainPendingURLs()
            if !pendingURLs.isEmpty {
                viewModel.importGameFromFiles(urls: pendingURLs)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didReceiveExternalGameURLs)) { notification in
            guard let urls = notification.object as? [URL], !urls.isEmpty else {
                return
            }

            viewModel.importGameFromFiles(urls: urls)
            ExternalFileOpenCoordinator.shared.markAsConsumed(urls)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "shippingbox")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Chua co game nao")
                .font(.title3.weight(.semibold))
            Text("Import thu muc game, file ZIP hoac file RAR vao Documents/Games.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
            Button("Import game") {
                showingImporter = true
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }

    private var supportedImportTypes: [UTType] {
        var types: [UTType] = [.folder, .zip]
        if let rarType = UTType(filenameExtension: "rar") {
            types.append(rarType)
        }
        return types
    }

    private func launch(_ game: Game) {
        guard let controller = GameEngineManager.shared.launch(game: game) else {
            viewModel.statusMessage = "Khong tim thay engine phu hop cho \(game.name)."
            return
        }

        activeController = controller
        activeGame = game
        viewModel.markPlayed(game)
    }
}

private struct GameCardView: View {
    let game: Game
    let playAction: () -> Void
    let deleteAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CoverThumbnailView(url: game.coverImage)
                .frame(height: 140)
                .frame(maxWidth: .infinity)

            Text(game.name)
                .font(.headline)
                .lineLimit(2)

            Text(game.gameType.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(lastPlayedText)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button("Play", action: playAction)
                    .buttonStyle(.borderedProminent)

                Button("Delete", role: .destructive, action: deleteAction)
                    .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var lastPlayedText: String {
        guard let date = game.lastPlayed else {
            return "Last played: Never"
        }

        return "Last played: \(date.formatted(date: .abbreviated, time: .shortened))"
    }
}

private struct CoverThumbnailView: View {
    let url: URL?

    var body: some View {
        Group {
            if let url,
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [.black.opacity(0.8), .gray.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 34))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct GameRuntimeScreen: View {
    let game: Game
    let controller: UIViewController?
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let controller {
                GameRuntimeContainer(viewController: controller)
                    .ignoresSafeArea()
            } else {
                Color.black
                    .overlay {
                        Text("Khong the khoi tao engine cho \(game.name).")
                            .foregroundStyle(.white)
                            .padding()
                    }
                    .ignoresSafeArea()
            }

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.white)
                    .shadow(radius: 6)
            }
            .padding(.top, 20)
            .padding(.trailing, 20)
        }
        .onDisappear {
            GameEngineManager.shared.shutdownCurrentEngine()
        }
    }
}

private struct GameRuntimeContainer: UIViewControllerRepresentable {
    let viewController: UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
