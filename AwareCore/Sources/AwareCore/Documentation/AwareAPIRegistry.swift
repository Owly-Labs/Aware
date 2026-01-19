//
//  AwareAPIRegistry.swift
//  AwareCore
//
//  Central registry for Aware framework API documentation.
//  Stores metadata about all public API surfaces (modifiers, types, methods).
//

import Foundation
import os.log

// MARK: - Aware API Registry

/// Central registry for framework API documentation
///
/// **Pattern**: Singleton with static registration (mirrors `Aware.shared` + `viewRegistry`)
/// **Usage**: AwarePlatform modules register their APIs via static `register()` methods
@MainActor
public final class AwareAPIRegistry: ObservableObject {
    public static let shared = AwareAPIRegistry()

    private let logger = Logger(subsystem: "com.aware.framework", category: "APIRegistry")

    // MARK: - Storage

    /// Registered modifiers by name
    @Published private(set) public var modifiers: [String: ModifierMetadata] = [:]

    /// Registered types by name
    @Published private(set) public var types: [String: TypeMetadata] = [:]

    /// Registered methods by id (className.methodName)
    @Published private(set) public var methods: [String: MethodMetadata] = [:]

    /// Framework version
    public let frameworkVersion: String = "3.0.0-beta"

    /// Registration timestamp
    public private(set) var lastRegistrationDate: Date = Date()

    private init() {
        logger.info("AwareAPIRegistry initialized")
    }

    // MARK: - Registration

    /// Register a modifier
    public func registerModifier(_ metadata: ModifierMetadata) {
        modifiers[metadata.name] = metadata
        lastRegistrationDate = Date()
        logger.debug("Registered modifier: \(metadata.name)")
    }

    /// Register multiple modifiers at once
    public func registerModifiers(_ metadataList: [ModifierMetadata]) {
        for metadata in metadataList {
            modifiers[metadata.name] = metadata
        }
        lastRegistrationDate = Date()
        logger.info("Registered \(metadataList.count) modifiers")
    }

    /// Register a type
    public func registerType(_ metadata: TypeMetadata) {
        types[metadata.name] = metadata
        lastRegistrationDate = Date()
        logger.debug("Registered type: \(metadata.name)")
    }

    /// Register multiple types at once
    public func registerTypes(_ metadataList: [TypeMetadata]) {
        for metadata in metadataList {
            types[metadata.name] = metadata
        }
        lastRegistrationDate = Date()
        logger.info("Registered \(metadataList.count) types")
    }

    /// Register a method
    public func registerMethod(_ metadata: MethodMetadata) {
        methods[metadata.id] = metadata
        lastRegistrationDate = Date()
        logger.debug("Registered method: \(metadata.id)")
    }

    /// Register multiple methods at once
    public func registerMethods(_ metadataList: [MethodMetadata]) {
        for metadata in metadataList {
            methods[metadata.id] = metadata
        }
        lastRegistrationDate = Date()
        logger.info("Registered \(metadataList.count) methods")
    }

    // MARK: - Queries

    /// Get modifier by name
    public func getModifier(_ name: String) -> ModifierMetadata? {
        modifiers[name]
    }

    /// Get modifiers by category
    public func getModifiers(category: ModifierCategory? = nil, platform: AwarePlatform? = nil) -> [ModifierMetadata] {
        var results = Array(modifiers.values)

        if let cat = category {
            results = results.filter { $0.category == cat }
        }

        if let plat = platform {
            results = results.filter { $0.platform == plat || $0.platform == .all }
        }

        return results.sorted { $0.name < $1.name }
    }

    /// Get type by name
    public func getType(_ name: String) -> TypeMetadata? {
        types[name]
    }

    /// Get types by category
    public func getTypes(category: TypeCategory? = nil, kind: TypeKind? = nil) -> [TypeMetadata] {
        var results = Array(types.values)

        if let cat = category {
            results = results.filter { $0.category == cat }
        }

        if let typeKind = kind {
            results = results.filter { $0.kind == typeKind }
        }

        return results.sorted { $0.name < $1.name }
    }

    /// Get method by id
    public func getMethod(_ id: String) -> MethodMetadata? {
        methods[id]
    }

    /// Get methods by class name or category
    public func getMethods(className: String? = nil, category: MethodCategory? = nil) -> [MethodMetadata] {
        var results = Array(methods.values)

        if let cls = className {
            results = results.filter { $0.className == cls }
        }

        if let cat = category {
            results = results.filter { $0.category == cat }
        }

        return results.sorted { $0.id < $1.id }
    }

    // MARK: - Search

    /// Search all API surfaces by query string
    public func search(_ query: String) -> APISearchResult {
        let lowercasedQuery = query.lowercased()

        let matchingModifiers = modifiers.values.filter { modifier in
            modifier.name.lowercased().contains(lowercasedQuery) ||
            modifier.description.lowercased().contains(lowercasedQuery)
        }

        let matchingTypes = types.values.filter { type in
            type.name.lowercased().contains(lowercasedQuery) ||
            type.description.lowercased().contains(lowercasedQuery)
        }

        let matchingMethods = methods.values.filter { method in
            method.name.lowercased().contains(lowercasedQuery) ||
            method.description.lowercased().contains(lowercasedQuery) ||
            method.className.lowercased().contains(lowercasedQuery)
        }

        return APISearchResult(
            query: query,
            modifiers: Array(matchingModifiers).sorted { $0.name < $1.name },
            types: Array(matchingTypes).sorted { $0.name < $1.name },
            methods: Array(matchingMethods).sorted { $0.id < $1.id }
        )
    }

    // MARK: - Statistics

    /// Get registry statistics
    public func getStatistics() -> RegistryStatistics {
        RegistryStatistics(
            modifierCount: modifiers.count,
            typeCount: types.count,
            methodCount: methods.count,
            frameworkVersion: frameworkVersion,
            lastUpdated: lastRegistrationDate
        )
    }

    /// Reset registry (for testing)
    public func reset() {
        modifiers.removeAll()
        types.removeAll()
        methods.removeAll()
        lastRegistrationDate = Date()
        logger.warning("Registry reset")
    }
}

// MARK: - Search Result

/// Search result containing matching API surfaces
public struct APISearchResult: Codable, Sendable {
    public let query: String
    public let modifiers: [ModifierMetadata]
    public let types: [TypeMetadata]
    public let methods: [MethodMetadata]

    public var totalResults: Int {
        modifiers.count + types.count + methods.count
    }

    public var isEmpty: Bool {
        totalResults == 0
    }
}

// MARK: - Registry Statistics

/// Statistics about the API registry
public struct RegistryStatistics: Codable, Sendable {
    public let modifierCount: Int
    public let typeCount: Int
    public let methodCount: Int
    public let frameworkVersion: String
    public let lastUpdated: Date

    public var totalAPIs: Int {
        modifierCount + typeCount + methodCount
    }
}
