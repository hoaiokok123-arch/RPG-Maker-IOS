import Foundation

enum FileImporterError: LocalizedError {
    case unsupportedFormat(String)
    case archiveToolUnavailable(String)
    case extractionFailed(String)
    case invalidImportedDirectory

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let ext):
            return "Dinh dang `\(ext)` chua duoc ho tro."
        case .archiveToolUnavailable(let name):
            return "Thieu thu vien giai nen cho \(name). Hay chay `pod install`."
        case .extractionFailed(let message):
            return "Giai nen that bai: \(message)"
        case .invalidImportedDirectory:
            return "Khong tim thay thu muc game hop le sau khi import."
        }
    }
}

final class FileImporter: @unchecked Sendable {
    static let shared = FileImporter()

    private let fileManager = FileManager.default

    private init() {}

    func importGame(from url: URL) -> Result<URL, Error> {
        let secured = url.startAccessingSecurityScopedResource()
        defer {
            if secured {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let gamesDirectory = FileManager.documentsDirectory.appendingPathComponent("Games", isDirectory: true)
            try fileManager.createDirectoryIfNeeded(at: gamesDirectory)

            let preferredName = url.deletingPathExtension().lastPathComponent
            let destinationRoot = fileManager.uniqueDirectoryURL(in: gamesDirectory, preferredName: preferredName)

            if url.hasDirectoryPath {
                try fileManager.copyItemSafely(from: url, to: destinationRoot)
            } else {
                try fileManager.createDirectoryIfNeeded(at: destinationRoot)
                try importArchiveOrFile(from: url, to: destinationRoot)
            }

            let normalized = GameDetector.normalizedGameRoot(from: destinationRoot)
            guard fileManager.itemExists(at: normalized) else {
                throw FileImporterError.invalidImportedDirectory
            }

            return .success(normalized)
        } catch {
            return .failure(error)
        }
    }

    private func importArchiveOrFile(from url: URL, to destinationRoot: URL) throws {
        let fileExtension = url.pathExtension.lowercased()

        switch fileExtension {
        case "zip":
            try unzipArchive(from: url, to: destinationRoot)
        case "rar":
            try unrarArchive(from: url, to: destinationRoot)
        case "":
            throw FileImporterError.unsupportedFormat("khong co phan mo rong")
        default:
            throw FileImporterError.unsupportedFormat(fileExtension)
        }
    }

    private func unzipArchive(from archiveURL: URL, to destinationRoot: URL) throws {
        var unzipError: NSError?
        let success = ArchiveExtractor.extractZip(
            atPath: archiveURL.path,
            toDestination: destinationRoot.path,
            error: &unzipError
        )

        guard success else {
            throw FileImporterError.extractionFailed(unzipError?.localizedDescription ?? "ZIP unknown error")
        }
    }

    private func unrarArchive(from archiveURL: URL, to destinationRoot: URL) throws {
        var rarError: NSError?
        let success = ArchiveExtractor.extractRAR(
            atPath: archiveURL.path,
            toDestination: destinationRoot.path,
            error: &rarError
        )

        guard success else {
            if let rarError {
                throw FileImporterError.extractionFailed(rarError.localizedDescription)
            }

            throw FileImporterError.archiveToolUnavailable("UnrarKit")
        }
    }
}
