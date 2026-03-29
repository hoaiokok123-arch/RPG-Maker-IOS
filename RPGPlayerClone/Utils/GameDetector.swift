import Foundation

enum GameDetector {
    static func detectType(from path: URL) -> GameType {
        let gameRoot = normalizedGameRoot(from: path)
        let fileManager = FileManager.default
        let lowercased = fileManager.contentsMappedByLowercasedName(in: gameRoot)

        if lowercased["game.rmmzproject"] != nil {
            return .rpgMZ
        }

        if lowercased["game.rmmvproject"] != nil {
            return .rpgMV
        }

        if let wwwURL = lowercased["www"],
           fileManager.normalizedItemURL(named: "index.html", in: wwwURL) != nil {
            return .rpgMV
        }

        if lowercased["index.html"] != nil,
           let jsFolder = lowercased["js"] {
            let jsFiles = fileManager.contentsMappedByLowercasedName(in: jsFolder)
            if jsFiles["rmmz_core.js"] != nil || jsFiles["rmmz_managers.js"] != nil {
                return .rpgMZ
            }

            if jsFiles["rpg_core.js"] != nil || jsFiles["rpg_managers.js"] != nil {
                return .rpgMV
            }
        }

        if lowercased["game.rgss3a"] != nil {
            return .rpgVXAce
        }

        if lowercased["game.rgss2a"] != nil {
            return .rpgVX
        }

        if lowercased["game.rgssad"] != nil {
            return .rpgXP
        }

        if lowercased["game.exe"] != nil {
            let dataFolder = lowercased["data"]
            if let dataFolder {
                let dataFiles = fileManager.contentsMappedByLowercasedName(in: dataFolder)
                if dataFiles["scripts.rvdata2"] != nil {
                    return .rpgVXAce
                }
                if dataFiles["scripts.rvdata"] != nil {
                    return .rpgVX
                }
                if dataFiles["scripts.rxdata"] != nil {
                    return .rpgXP
                }
            }
        }

        if lowercased["rpg_rt.exe"] != nil || lowercased["rpg_rt.ldb"] != nil {
            return detectLegacyRPGType(in: gameRoot)
        }

        return .unknown
    }

    static func bestEffortCoverImage(in path: URL) -> URL? {
        let gameRoot = normalizedGameRoot(from: path)
        let fileManager = FileManager.default
        let candidates = [
            "cover.png",
            "cover.jpg",
            "cover.jpeg",
            "icon.png",
            "icon.jpg",
            "title.png"
        ]

        let rootFiles = fileManager.contentsMappedByLowercasedName(in: gameRoot)
        for candidate in candidates {
            if let url = rootFiles[candidate] {
                return url
            }
        }

        let nestedCandidates = [
            gameRoot.appendingPathComponent("www/icon/icon.png"),
            gameRoot.appendingPathComponent("www/icon/icon.jpg"),
            gameRoot.appendingPathComponent("icon/icon.png"),
            gameRoot.appendingPathComponent("icon/icon.jpg")
        ]

        return nestedCandidates.first(where: { fileManager.itemExists(at: $0) })
    }

    static func normalizedGameRoot(from path: URL) -> URL {
        var isDirectory: ObjCBool = false
        let fileManager = FileManager.default
        let standardized = path.standardizedFileURL

        guard fileManager.fileExists(atPath: standardized.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return standardized.deletingLastPathComponent()
        }

        let items = (try? fileManager.contentsOfDirectory(
            at: standardized,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        if items.count == 1,
           let first = items.first,
           (try? first.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true,
           detectTypeFromKnownMarkers(in: first) != .unknown {
            return first
        }

        return standardized
    }

    private static func detectTypeFromKnownMarkers(in path: URL) -> GameType {
        let fileManager = FileManager.default
        let lowercased = fileManager.contentsMappedByLowercasedName(in: path)

        if lowercased["game.rmmzproject"] != nil {
            return .rpgMZ
        }

        if lowercased["game.rmmvproject"] != nil {
            return .rpgMV
        }

        if lowercased["index.html"] != nil,
           let jsFolder = lowercased["js"] {
            let jsFiles = fileManager.contentsMappedByLowercasedName(in: jsFolder)
            if jsFiles["rmmz_core.js"] != nil || jsFiles["rmmz_managers.js"] != nil {
                return .rpgMZ
            }

            if jsFiles["rpg_core.js"] != nil || jsFiles["rpg_managers.js"] != nil {
                return .rpgMV
            }
        }

        if let wwwURL = lowercased["www"],
           fileManager.normalizedItemURL(named: "index.html", in: wwwURL) != nil {
            return .rpgMV
        }

        if lowercased["rpg_rt.exe"] != nil || lowercased["rpg_rt.ldb"] != nil {
            return detectLegacyRPGType(in: path)
        }

        if lowercased["game.rgss3a"] != nil {
            return .rpgVXAce
        }

        if lowercased["game.rgss2a"] != nil {
            return .rpgVX
        }

        if lowercased["game.rgssad"] != nil {
            return .rpgXP
        }

        return .unknown
    }

    private static func detectLegacyRPGType(in directory: URL) -> GameType {
        let probeFiles = [
            directory.appendingPathComponent("RPG_RT.ldb"),
            directory.appendingPathComponent("RPG_RT.ini"),
            directory.appendingPathComponent("RPG_RT.exe")
        ]

        let probeNeedles2k3 = ["rpg2003", "rpg 2003", "rm2k3"]
        let probeNeedles2k = ["rpg2000", "rpg 2000", "rm2k"]

        for file in probeFiles where FileManager.default.itemExists(at: file) {
            guard let data = try? Data(contentsOf: file, options: [.mappedIfSafe]) else {
                continue
            }

            let sampled = data.prefix(262_144)
            let ascii = String(decoding: sampled, as: UTF8.self).lowercased()

            if probeNeedles2k3.contains(where: ascii.contains) {
                return .rpg2k3
            }

            if probeNeedles2k.contains(where: ascii.contains) {
                return .rpg2k
            }
        }

        // If detection stays ambiguous, keep it in the EasyRPG family and default to 2003.
        return .rpg2k3
    }
}
