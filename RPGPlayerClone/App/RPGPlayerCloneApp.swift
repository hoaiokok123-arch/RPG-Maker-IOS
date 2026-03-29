import SwiftUI

@main
struct RPGPlayerCloneApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var libraryViewModel = GameLibraryViewModel()

    init() {
        GameControllerMonitor.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                GameLibraryView(viewModel: libraryViewModel)
                    .tabItem {
                        Label("Library", systemImage: "books.vertical")
                    }

                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            .onOpenURL { url in
                Task { @MainActor in
                    ExternalFileOpenCoordinator.shared.handleIncoming(urls: [url])
                }
            }
        }
    }
}
