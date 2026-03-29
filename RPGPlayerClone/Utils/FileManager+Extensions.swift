import Foundation

extension FileManager {
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    static var cachesDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    func createDirectoryIfNeeded(at url: URL) throws {
        guard !fileExists(atPath: url.path) else {
            return
        }

        try createDirectory(at: url, withIntermediateDirectories: true)
    }

    func itemExists(at url: URL) -> Bool {
        fileExists(atPath: url.path)
    }

    func uniqueDirectoryURL(in parent: URL, preferredName: String) -> URL {
        let cleanedName = preferredName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")

        let baseName = cleanedName.isEmpty ? "ImportedGame" : cleanedName
        var candidate = parent.appendingPathComponent(baseName, isDirectory: true)
        var suffix = 2

        while itemExists(at: candidate) {
            candidate = parent.appendingPathComponent("\(baseName)-\(suffix)", isDirectory: true)
            suffix += 1
        }

        return candidate
    }

    func copyItemSafely(from source: URL, to destination: URL, replaceExisting: Bool = false) throws {
        if itemExists(at: destination) {
            guard replaceExisting else {
                throw CocoaError(.fileWriteFileExists)
            }

            try removeItem(at: destination)
        }

        try copyItem(at: source, to: destination)
    }

    func contentsMappedByLowercasedName(in directory: URL) -> [String: URL] {
        guard let items = try? contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return [:]
        }

        return Dictionary(uniqueKeysWithValues: items.map { ($0.lastPathComponent.lowercased(), $0) })
    }

    func normalizedItemURL(named name: String, in directory: URL) -> URL? {
        contentsMappedByLowercasedName(in: directory)[name.lowercased()]
    }
}

