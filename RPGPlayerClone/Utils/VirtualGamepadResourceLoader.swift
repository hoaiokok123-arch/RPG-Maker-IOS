import Foundation

enum VirtualGamepadResourceLoader {
    private static let fallbackControlMap: [String: [String]] = [
        "up": ["ArrowUp"],
        "down": ["ArrowDown"],
        "left": ["ArrowLeft"],
        "right": ["ArrowRight"],
        "a": ["Enter"],
        "b": ["Escape"],
        "x": ["ShiftLeft"],
        "y": ["ControlLeft"],
        "l": ["PageUp"],
        "r": ["PageDown"],
        "start": ["Escape"],
        "select": ["ControlLeft"]
    ]

    static func controlMap() -> [String: [String]] {
        guard let url = resourceURL(named: "control-map", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return fallbackControlMap
        }

        return decoded
    }

    static func textResource(named name: String, withExtension ext: String) -> String? {
        guard let url = resourceURL(named: name, withExtension: ext) else {
            return nil
        }

        return try? String(contentsOf: url, encoding: .utf8)
    }

    private static func resourceURL(named name: String, withExtension ext: String) -> URL? {
        let bundle = Bundle.main
        let directCandidates = [
            bundle.url(forResource: name, withExtension: ext, subdirectory: "VirtualGamepad"),
            bundle.url(forResource: name, withExtension: ext, subdirectory: "Resources/VirtualGamepad"),
            bundle.url(forResource: name, withExtension: ext)
        ]

        if let directMatch = directCandidates.compactMap({ $0 }).first {
            return directMatch
        }

        guard let resourcePath = bundle.resourcePath else {
            return nil
        }

        let expectedFileName = "\(name).\(ext)"
        let enumerator = FileManager.default.enumerator(atPath: resourcePath)

        while let relativePath = enumerator?.nextObject() as? String {
            if (relativePath as NSString).lastPathComponent == expectedFileName {
                return URL(fileURLWithPath: resourcePath).appendingPathComponent(relativePath)
            }
        }

        return nil
    }
}
