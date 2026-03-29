import Foundation
import UIKit

extension Notification.Name {
    static let didReceiveExternalGameURLs = Notification.Name("RPGPlayerClone.didReceiveExternalGameURLs")
}

@MainActor
final class ExternalFileOpenCoordinator {
    static let shared = ExternalFileOpenCoordinator()

    private var pendingURLs: [URL] = []
    private var recentDeliveries: [URL: Date] = [:]
    private let dedupeWindow: TimeInterval = 2

    private init() {}

    func handleIncoming(urls: [URL]) {
        guard !urls.isEmpty else {
            return
        }

        purgeExpiredDeliveries()

        let now = Date()
        var seen = Set(pendingURLs.map { $0.standardizedFileURL })
        let uniqueURLs = urls.filter { url in
            let standardized = url.standardizedFileURL

            if let deliveredAt = recentDeliveries[standardized],
               now.timeIntervalSince(deliveredAt) < dedupeWindow {
                return false
            }

            let inserted = seen.insert(standardized).inserted
            if inserted {
                recentDeliveries[standardized] = now
            }
            return inserted
        }

        guard !uniqueURLs.isEmpty else {
            return
        }

        pendingURLs.append(contentsOf: uniqueURLs)
        NotificationCenter.default.post(name: .didReceiveExternalGameURLs, object: uniqueURLs)
    }

    func drainPendingURLs() -> [URL] {
        let urls = pendingURLs
        pendingURLs.removeAll()
        return urls
    }

    func markAsConsumed(_ urls: [URL]) {
        let consumed = Set(urls.map { $0.standardizedFileURL })
        pendingURLs.removeAll { consumed.contains($0.standardizedFileURL) }
    }

    private func purgeExpiredDeliveries() {
        let now = Date()
        recentDeliveries = recentDeliveries.filter { now.timeIntervalSince($0.value) < dedupeWindow }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        Task { @MainActor in
            ExternalFileOpenCoordinator.shared.handleIncoming(urls: [url])
        }
        return true
    }
}
