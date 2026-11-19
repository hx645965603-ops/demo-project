import Foundation

/// Writes Codable JSON by saving a temp file in the same directory, then replacing the destination.
/// A crash before the replace leaves the previous file intact.
enum AtomicJSONStore {
    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    static func load<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        return try makeDecoder().decode(T.self, from: data)
    }

    static func save<T: Encodable>(_ value: T, to url: URL, fileManager: FileManager = .default) throws {
        let directory = url.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        removeStaleTempFiles(in: directory, for: url, fileManager: fileManager)

        let data = try makeEncoder().encode(value)
        let tempURL = directory.appendingPathComponent(".\(url.lastPathComponent)-\(UUID().uuidString).tmp")
        try data.write(to: tempURL)
        do {
            if fileManager.fileExists(atPath: url.path) {
                _ = try fileManager.replaceItemAt(url, withItemAt: tempURL)
            } else {
                try fileManager.moveItem(at: tempURL, to: url)
            }
        } catch {
            try? fileManager.removeItem(at: tempURL)
            throw error
        }
    }

    private static func removeStaleTempFiles(in directory: URL, for url: URL, fileManager: FileManager) {
        let prefix = ".\(url.lastPathComponent)-"
        guard let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return
        }
        for file in files where file.lastPathComponent.hasPrefix(prefix) && file.pathExtension == "tmp" {
            try? fileManager.removeItem(at: file)
        }
    }
}
