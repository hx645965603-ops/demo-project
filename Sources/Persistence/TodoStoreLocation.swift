import Foundation

enum TodoStoreLocation {
    static let bundleID = "com.hx645965603.TodayTodo"
    static let fileName = "todos.json"

    /// `~/Library/Application Support/<Bundle ID>/todos.json`.
    /// Inside the App Sandbox this is the container's Application Support directory.
    static func defaultFileURL(fileManager: FileManager = .default) -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
                .appendingPathComponent("Library/Application Support", isDirectory: true)
        return base
            .appendingPathComponent(bundleID, isDirectory: true)
            .appendingPathComponent(fileName)
    }
}

struct TodoFileRepository {
    let fileURL: URL

    func load() throws -> TodoStoreFile {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return TodoStoreFile(schemaVersion: TodoSchema.current, items: [])
        }
        return try AtomicJSONStore.load(TodoStoreFile.self, from: fileURL)
    }

    func save(_ file: TodoStoreFile) throws {
        var copy = file
        if copy.schemaVersion <= 0 {
            copy.schemaVersion = TodoSchema.current
        }
        try AtomicJSONStore.save(copy, to: fileURL)
    }
}
