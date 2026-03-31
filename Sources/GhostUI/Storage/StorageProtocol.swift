// StorageProtocol.swift
// GhostUI Storage Module
//
// Abstract storage protocol for local and cloud implementations.

import Foundation

// MARK: - Storage Protocol

/// Protocol for storage implementations.
/// Enables abstracting between SQLite (local), PostgreSQL (cloud), Redis (cache), etc.
public protocol AwareStorage: Sendable {
    /// Get a value by key
    func get<T: Codable & Sendable>(key: String) async throws -> T?

    /// Set a value for key
    func set<T: Codable & Sendable>(key: String, value: T) async throws

    /// Delete a key
    func delete(key: String) async throws

    /// Check if key exists
    func exists(key: String) async throws -> Bool

    /// List keys with optional prefix filter
    func list(prefix: String?) async throws -> [String]

    /// Get all keys
    func allKeys() async throws -> [String]
}

// MARK: - Storage Error

/// Errors that can occur during storage operations
public enum StorageError: Error, Sendable {
    case notFound(String)
    case encodingFailed(String)
    case decodingFailed(String)
    case connectionFailed(String)
    case transactionFailed(String)
    case invalidKey(String)

    public var localizedDescription: String {
        switch self {
        case .notFound(let key): return "Key not found: \(key)"
        case .encodingFailed(let msg): return "Encoding failed: \(msg)"
        case .decodingFailed(let msg): return "Decoding failed: \(msg)"
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        case .transactionFailed(let msg): return "Transaction failed: \(msg)"
        case .invalidKey(let key): return "Invalid key: \(key)"
        }
    }
}

// MARK: - Namespaced Storage

/// Storage wrapper that prefixes all keys with a namespace
public actor NamespacedStorage: AwareStorage {
    private let storage: any AwareStorage
    private let namespace: String

    public init(storage: any AwareStorage, namespace: String) {
        self.storage = storage
        self.namespace = namespace
    }

    private func prefixedKey(_ key: String) -> String {
        "\(namespace):\(key)"
    }

    private func stripPrefix(_ key: String) -> String {
        if key.hasPrefix("\(namespace):") {
            return String(key.dropFirst(namespace.count + 1))
        }
        return key
    }

    public func get<T: Codable & Sendable>(key: String) async throws -> T? {
        try await storage.get(key: prefixedKey(key))
    }

    public func set<T: Codable & Sendable>(key: String, value: T) async throws {
        try await storage.set(key: prefixedKey(key), value: value)
    }

    public func delete(key: String) async throws {
        try await storage.delete(key: prefixedKey(key))
    }

    public func exists(key: String) async throws -> Bool {
        try await storage.exists(key: prefixedKey(key))
    }

    public func list(prefix: String?) async throws -> [String] {
        let searchPrefix = prefix.map { prefixedKey($0) } ?? "\(namespace):"
        let keys = try await storage.list(prefix: searchPrefix)
        return keys.map { stripPrefix($0) }
    }

    public func allKeys() async throws -> [String] {
        try await list(prefix: nil)
    }
}

// MARK: - Storage Types

/// Supported storage backends
public enum StorageType: String, Sendable, CaseIterable {
    /// In-memory (for testing)
    case memory

    /// SQLite (for local persistence)
    case sqlite

    /// File-based JSON (simple local storage)
    case file

    /// PostgreSQL (for cloud deployments)
    case postgres

    /// Redis (for caching)
    case redis
}

// MARK: - Storage Configuration

/// Configuration for storage backends
public struct StorageConfig: Sendable {
    public let type: StorageType
    public let path: String?
    public let connectionString: String?

    public init(type: StorageType, path: String? = nil, connectionString: String? = nil) {
        self.type = type
        self.path = path
        self.connectionString = connectionString
    }

    /// Default in-memory storage
    public static let memory = StorageConfig(type: .memory)

    /// SQLite with default path
    public static func sqlite(path: String) -> StorageConfig {
        StorageConfig(type: .sqlite, path: path)
    }

    /// File-based storage at path
    public static func file(path: String) -> StorageConfig {
        StorageConfig(type: .file, path: path)
    }
}

// MARK: - Storage Extensions

extension AwareStorage {
    /// Get with default value
    public func get<T: Codable & Sendable>(key: String, default defaultValue: T) async throws -> T {
        try await get(key: key) ?? defaultValue
    }

    /// Get multiple keys at once
    public func getMultiple<T: Codable & Sendable>(keys: [String]) async throws -> [String: T] {
        var results: [String: T] = [:]
        for key in keys {
            if let value: T = try await get(key: key) {
                results[key] = value
            }
        }
        return results
    }

    /// Set multiple key-value pairs at once
    public func setMultiple<T: Codable & Sendable>(_ pairs: [String: T]) async throws {
        for (key, value) in pairs {
            try await set(key: key, value: value)
        }
    }

    /// Delete multiple keys
    public func deleteMultiple(_ keys: [String]) async throws {
        for key in keys {
            try await delete(key: key)
        }
    }

    /// Delete all keys with prefix
    public func deletePrefix(_ prefix: String) async throws {
        let keys = try await list(prefix: prefix)
        try await deleteMultiple(keys)
    }
}
