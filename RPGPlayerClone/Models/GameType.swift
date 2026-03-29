import Foundation

enum GameType: String, Codable, CaseIterable, Hashable, Sendable {
    case rpg2k
    case rpg2k3
    case rpgXP
    case rpgVX
    case rpgVXAce
    case rpgMV
    case rpgMZ
    case unknown

    var displayName: String {
        switch self {
        case .rpg2k:
            return "RPG Maker 2000"
        case .rpg2k3:
            return "RPG Maker 2003"
        case .rpgXP:
            return "RPG Maker XP"
        case .rpgVX:
            return "RPG Maker VX"
        case .rpgVXAce:
            return "RPG Maker VX Ace"
        case .rpgMV:
            return "RPG Maker MV"
        case .rpgMZ:
            return "RPG Maker MZ"
        case .unknown:
            return "Unknown"
        }
    }

    var preferredEngineName: String {
        switch self {
        case .rpg2k, .rpg2k3:
            return "EasyRPG Player"
        case .rpgXP, .rpgVX, .rpgVXAce:
            return "mkxp-z"
        case .rpgMV, .rpgMZ:
            return "WKWebView"
        case .unknown:
            return "Unknown"
        }
    }

    static func detect(from path: URL) -> GameType {
        GameDetector.detectType(from: path)
    }
}
