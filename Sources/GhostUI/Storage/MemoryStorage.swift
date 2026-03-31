// MemoryStorage.swift
// GhostUI Storage Module
//
// In-memory storage implementation for testing and ephemeral data.

import Foundation

// MARK: - Memory Storage

/// In-memory storage implementation.
/// Useful for testing and temporary data that doesn't need persistence.
public actor MemoryStorage: AwareStorage {

    // MARK: - Properties

    /// Internal storage
    private var data: [String: Data] = [:]

    /// JSON encoder
    private let encoder = JSONEncoder()

    /// JSON decoder
    private let decoder = JSONDecoder()

    // MARK: - Initialization

    public init() {}

    /// Initialize with existing data (for testing)
    public init(initialData: [String: any Codable & Sendable]) async {
        for (key, value) in initialData {
            if let encoded = try? encoder.encode(AnyEncodable(value)) {
                data[key] = encoded
            }
        }
    }

    // MARK: - AwareStorage Protocol

    public func get<T: Codable & Sendable>(key: String) async throws -> T? {
        guard let stored = data[key] else {
            return nil
        }

        do {
            return try decoder.decode(T.self, from: stored)
        } catch {
            throw StorageError.decodingFailed("\(error)")
        }
    }

    public func set<T: Codable & Sendable>(key: String, value: T) async throws {
        do {
            let encoded = try encoder.encode(value)
            data[key] = encoded
        } catch {
            throw StorageError.encodingFailed("\(error)")
        }
    }

    public func delete(key: String) async throws {
        data.removeValue(forKey: key)
    }

    public func exists(key: String) async throws -> Bool {
        data[key] != nil
    }

    public func list(prefix: String?) async throws -> [String] {
        guard let prefix = prefix else {
            return Array(data.keys).sorted()
        }
        return data.keys.filter { $0.hasPrefix(prefix) }.sorted()
    }

    public func allKeys() async throws -> [String] {
        Array(data.keys).sorted()
    }

    // MARK: - Additional Methods

    /// Clear all data
    public func clear() async {
        data.removeAll()
    }

    /// Get count of stored items
    public func count() async -> Int {
        data.count
    }

    /// Get raw data for debugging
    public func debugDump() async -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in data {
            result[key] = String(data: value, encoding: .utf8) ?? "<binary>"
        }
        return result
    }
}

// MARK: - Type Erasure Helper

/// Helper for encoding any Codable value
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

// MARK: - Singleton Convenience

extension MemoryStorage {
    /// Shared singleton instance (for simple use cases)
    public static let shared = MemoryStorage()
}
