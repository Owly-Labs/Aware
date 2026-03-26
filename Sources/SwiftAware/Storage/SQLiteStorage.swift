// SQLiteStorage.swift
// SwiftAware Storage Module
//
// SQLite-based storage implementation for local persistence.

import Foundation

#if canImport(SQLite3)
import SQLite3
#endif

// MARK: - SQLite Storage

/// SQLite-based storage implementation.
/// Uses the system SQLite library for local persistence.
public actor SQLiteStorage: AwareStorage {

    // MARK: - Properties

    /// Database file path
    public let path: String

    /// SQLite database handle
    private var db: OpaquePointer?

    /// JSON encoder
    private let encoder = JSONEncoder()

    /// JSON decoder
    private let decoder = JSONDecoder()

    /// Table name for key-value storage
    private let tableName = "aware_kv"

    /// Whether the database is open
    private var isOpen = false

    // MARK: - Initialization

    /// Create storage - call open() before use
    public init(path: String) {
        self.path = path
    }

    /// Open the database and create tables
    public func open() async throws {
        guard !isOpen else { return }

        // Ensure directory exists
        let url = URL(fileURLWithPath: path)
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // Open database
        let result = sqlite3_open(path, &db)
        guard result == SQLITE_OK else {
            throw StorageError.connectionFailed("SQLite open failed: \(result)")
        }

        try createTableIfNeeded()
        isOpen = true
    }

    /// Close the database
    public func close() {
        if db != nil {
            sqlite3_close(db)
            db = nil
            isOpen = false
        }
    }

    /// Factory method that opens immediately
    public static func open(path: String) async throws -> SQLiteStorage {
        let storage = SQLiteStorage(path: path)
        try await storage.open()
        return storage
    }

    // MARK: - Database Operations

    private func createTableIfNeeded() throws {
        let sql = """
            CREATE TABLE IF NOT EXISTS \(tableName) (
                key TEXT PRIMARY KEY,
                value BLOB NOT NULL,
                created_at INTEGER DEFAULT (strftime('%s', 'now')),
                updated_at INTEGER DEFAULT (strftime('%s', 'now'))
            );
            CREATE INDEX IF NOT EXISTS idx_key ON \(tableName)(key);
            """

        var errMsg: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, sql, nil, nil, &errMsg)

        if result != SQLITE_OK {
            let error = errMsg.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errMsg)
            throw StorageError.transactionFailed("Create table failed: \(error)")
        }
    }

    private func ensureOpen() throws {
        guard isOpen else {
            throw StorageError.connectionFailed("Database not open. Call open() first.")
        }
    }

    // MARK: - AwareStorage Protocol

    public func get<T: Codable & Sendable>(key: String) async throws -> T? {
        try ensureOpen()

        let sql = "SELECT value FROM \(tableName) WHERE key = ?;"

        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw StorageError.transactionFailed("Prepare failed")
        }

        sqlite3_bind_text(stmt, 1, key, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        guard sqlite3_step(stmt) == SQLITE_ROW else {
            return nil
        }

        guard let blob = sqlite3_column_blob(stmt, 0) else {
            return nil
        }

        let length = sqlite3_column_bytes(stmt, 0)
        let data = Data(bytes: blob, count: Int(length))

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw StorageError.decodingFailed("\(error)")
        }
    }

    public func set<T: Codable & Sendable>(key: String, value: T) async throws {
        try ensureOpen()

        let sql = """
            INSERT INTO \(tableName) (key, value, updated_at)
            VALUES (?, ?, strftime('%s', 'now'))
            ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = strftime('%s', 'now');
            """

        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw StorageError.transactionFailed("Prepare failed")
        }

        let data: Data
        do {
            data = try encoder.encode(value)
        } catch {
            throw StorageError.encodingFailed("\(error)")
        }

        sqlite3_bind_text(stmt, 1, key, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        _ = data.withUnsafeBytes { bytes in
            sqlite3_bind_blob(stmt, 2, bytes.baseAddress, Int32(data.count), unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        }

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw StorageError.transactionFailed("Insert failed")
        }
    }

    public func delete(key: String) async throws {
        try ensureOpen()

        let sql = "DELETE FROM \(tableName) WHERE key = ?;"

        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw StorageError.transactionFailed("Prepare failed")
        }

        sqlite3_bind_text(stmt, 1, key, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw StorageError.transactionFailed("Delete failed")
        }
    }

    public func exists(key: String) async throws -> Bool {
        try ensureOpen()

        let sql = "SELECT 1 FROM \(tableName) WHERE key = ? LIMIT 1;"

        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw StorageError.transactionFailed("Prepare failed")
        }

        sqlite3_bind_text(stmt, 1, key, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        return sqlite3_step(stmt) == SQLITE_ROW
    }

    public func list(prefix: String?) async throws -> [String] {
        try ensureOpen()

        let sql: String
        if prefix != nil {
            sql = "SELECT key FROM \(tableName) WHERE key LIKE ? ORDER BY key;"
        } else {
            sql = "SELECT key FROM \(tableName) ORDER BY key;"
        }

        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw StorageError.transactionFailed("Prepare failed")
        }

        if let prefix = prefix {
            let pattern = "\(prefix)%"
            sqlite3_bind_text(stmt, 1, pattern, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        }

        var keys: [String] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let keyPtr = sqlite3_column_text(stmt, 0) {
                keys.append(String(cString: keyPtr))
            }
        }

        return keys
    }

    public func allKeys() async throws -> [String] {
        try await list(prefix: nil)
    }

    // MARK: - Additional Methods

    /// Get database file size in bytes
    public nonisolated func fileSize() throws -> Int64 {
        let attrs = try FileManager.default.attributesOfItem(atPath: path)
        return attrs[.size] as? Int64 ?? 0
    }

    /// Vacuum the database to reclaim space
    public func vacuum() throws {
        try ensureOpen()

        var errMsg: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, "VACUUM;", nil, nil, &errMsg)

        if result != SQLITE_OK {
            let error = errMsg.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errMsg)
            throw StorageError.transactionFailed("Vacuum failed: \(error)")
        }
    }

    /// Get count of stored items
    public func count() async throws -> Int {
        try ensureOpen()

        let sql = "SELECT COUNT(*) FROM \(tableName);"

        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw StorageError.transactionFailed("Prepare failed")
        }

        guard sqlite3_step(stmt) == SQLITE_ROW else {
            return 0
        }

        return Int(sqlite3_column_int64(stmt, 0))
    }

    /// Clear all data
    public func clear() async throws {
        try ensureOpen()

        var errMsg: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, "DELETE FROM \(tableName);", nil, nil, &errMsg)

        if result != SQLITE_OK {
            let error = errMsg.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errMsg)
            throw StorageError.transactionFailed("Clear failed: \(error)")
        }
    }
}
