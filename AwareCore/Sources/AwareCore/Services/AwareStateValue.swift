//
//  AwareStateValue.swift
//  AwareCore
//
//  Type-safe state value enum to eliminate type confusion.
//  Replaces string-only state values with typed alternatives.
//

import Foundation
import SwiftUI

// MARK: - Type-Safe State Value

/// Type-safe state value that can hold different types
///
/// **Token Cost:** ~5-10 tokens per value (compact representation)
/// **LLM Guidance:** Use for type-safe state tracking, eliminates string parsing
///
/// **Problem Solved:**
/// - Before: `registerState("toggle", key: "isOn", value: "true")` - string confusion
/// - After: `registerState("toggle", key: "isOn", value: .bool(true))` - type-safe
///
/// **Storage:**
/// - Internally converts to/from String for backward compatibility
/// - Serializes to compact format for snapshots
/// - Preserves type information in metadata
public enum AwareStateValue: Codable, Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case data(Data)
    case array([AwareStateValue])
    case dictionary([String: AwareStateValue])
    case null

    // MARK: - Convenience Initializers

    /// Create from any Codable value
    public init<T: Codable>(encoding value: T) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)

        if let string = value as? String {
            self = .string(string)
        } else if let int = value as? Int {
            self = .int(int)
        } else if let double = value as? Double {
            self = .double(double)
        } else if let bool = value as? Bool {
            self = .bool(bool)
        } else {
            self = .data(data)
        }
    }

    /// Create from SwiftUI Binding
    public init<T>(_ binding: Binding<T>) where T: Codable {
        do {
            try self.init(encoding: binding.wrappedValue)
        } catch {
            self = .null
        }
    }

    // MARK: - String Conversion (Backward Compatibility)

    /// Convert to String for storage/transmission
    ///
    /// **Token Cost:** ~5 tokens average
    /// **LLM Guidance:** Use for serialization, compact representation
    public var stringValue: String {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return "\(value)"
        case .double(let value):
            return String(format: "%.2f", value)
        case .bool(let value):
            return value ? "true" : "false"
        case .data(let value):
            return value.base64EncodedString()
        case .array(let values):
            return "[" + values.map { $0.stringValue }.joined(separator: ", ") + "]"
        case .dictionary(let dict):
            let pairs = dict.map { "\($0.key): \($0.value.stringValue)" }.joined(separator: ", ")
            return "{" + pairs + "}"
        case .null:
            return "null"
        }
    }

    /// Create from String (best-effort type inference)
    ///
    /// **Token Cost:** ~10 tokens per parse
    /// **LLM Guidance:** Automatically infers type from string format
    public init(parsing string: String) {
        // Try bool
        if string == "true" || string == "false" {
            self = .bool(string == "true")
            return
        }

        // Try null
        if string == "null" || string.isEmpty {
            self = .null
            return
        }

        // Try int
        if let intValue = Int(string) {
            self = .int(intValue)
            return
        }

        // Try double
        if let doubleValue = Double(string) {
            self = .double(doubleValue)
            return
        }

        // Try array
        if string.hasPrefix("[") && string.hasSuffix("]") {
            let content = string.dropFirst().dropLast()
            let items = content.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
            self = .array(items.map { AwareStateValue(parsing: $0) })
            return
        }

        // Default to string
        self = .string(string)
    }

    // MARK: - Type-Safe Accessors

    /// Extract as String (nil if wrong type)
    public var asString: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    /// Extract as Int (nil if wrong type)
    public var asInt: Int? {
        if case .int(let value) = self { return value }
        return nil
    }

    /// Extract as Double (nil if wrong type)
    public var asDouble: Double? {
        if case .double(let value) = self { return value }
        return nil
    }

    /// Extract as Bool (nil if wrong type)
    public var asBool: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    /// Extract as Data (nil if wrong type)
    public var asData: Data? {
        if case .data(let value) = self { return value }
        return nil
    }

    /// Extract as Array (nil if wrong type)
    public var asArray: [AwareStateValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    /// Extract as Dictionary (nil if wrong type)
    public var asDictionary: [String: AwareStateValue]? {
        if case .dictionary(let value) = self { return value }
        return nil
    }

    /// Check if value is null
    public var isNull: Bool {
        if case .null = self { return true }
        return false
    }

    // MARK: - Type Information

    /// Get the type name for debugging/logging
    ///
    /// **Token Cost:** ~3 tokens
    /// **LLM Guidance:** Use for type verification, debugging
    public var typeName: String {
        switch self {
        case .string: return "String"
        case .int: return "Int"
        case .double: return "Double"
        case .bool: return "Bool"
        case .data: return "Data"
        case .array: return "Array"
        case .dictionary: return "Dictionary"
        case .null: return "Null"
        }
    }

    /// Check if value matches expected type
    ///
    /// **Token Cost:** ~5 tokens
    /// **LLM Guidance:** Use for assertions, validation
    public func isType(_ type: AwareStateType) -> Bool {
        switch (self, type) {
        case (.string, .string): return true
        case (.int, .int): return true
        case (.double, .double): return true
        case (.bool, .bool): return true
        case (.data, .data): return true
        case (.array, .array): return true
        case (.dictionary, .dictionary): return true
        case (.null, .null): return true
        default: return false
        }
    }

    // MARK: - Compact Representation

    /// Get compact representation for LLM snapshots
    ///
    /// **Token Cost:** ~3-8 tokens (vs 10-15 for full stringValue)
    /// **LLM Guidance:** Use in snapshots to reduce token usage
    public var compactValue: String {
        switch self {
        case .string(let value):
            return value.count > 50 ? "\(value.prefix(50))..." : value
        case .int(let value):
            return "\(value)"
        case .double(let value):
            return String(format: "%.1f", value)
        case .bool(let value):
            return value ? "T" : "F"
        case .data(let value):
            return "<\(value.count)b>"
        case .array(let values):
            return "[\(values.count)]"
        case .dictionary(let dict):
            return "{\(dict.count)}"
        case .null:
            return "∅"
        }
    }

    // MARK: - Codable Implementation

    enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .string(let value):
            try container.encode("string", forKey: .type)
            try container.encode(value, forKey: .value)
        case .int(let value):
            try container.encode("int", forKey: .type)
            try container.encode(value, forKey: .value)
        case .double(let value):
            try container.encode("double", forKey: .type)
            try container.encode(value, forKey: .value)
        case .bool(let value):
            try container.encode("bool", forKey: .type)
            try container.encode(value, forKey: .value)
        case .data(let value):
            try container.encode("data", forKey: .type)
            try container.encode(value, forKey: .value)
        case .array(let values):
            try container.encode("array", forKey: .type)
            try container.encode(values, forKey: .value)
        case .dictionary(let dict):
            try container.encode("dictionary", forKey: .type)
            try container.encode(dict, forKey: .value)
        case .null:
            try container.encode("null", forKey: .type)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "string":
            let value = try container.decode(String.self, forKey: .value)
            self = .string(value)
        case "int":
            let value = try container.decode(Int.self, forKey: .value)
            self = .int(value)
        case "double":
            let value = try container.decode(Double.self, forKey: .value)
            self = .double(value)
        case "bool":
            let value = try container.decode(Bool.self, forKey: .value)
            self = .bool(value)
        case "data":
            let value = try container.decode(Data.self, forKey: .value)
            self = .data(value)
        case "array":
            let values = try container.decode([AwareStateValue].self, forKey: .value)
            self = .array(values)
        case "dictionary":
            let dict = try container.decode([String: AwareStateValue].self, forKey: .value)
            self = .dictionary(dict)
        case "null":
            self = .null
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown type: \(type)"
            )
        }
    }
}

// MARK: - Type Enum

/// Enum for type checking without value extraction
public enum AwareStateType: String, Codable, Sendable {
    case string
    case int
    case double
    case bool
    case data
    case array
    case dictionary
    case null
}

// MARK: - Extensions

extension AwareStateValue: CustomStringConvertible {
    public var description: String {
        return stringValue
    }
}

extension AwareStateValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension AwareStateValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension AwareStateValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension AwareStateValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension AwareStateValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: AwareStateValue...) {
        self = .array(elements)
    }
}

extension AwareStateValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, AwareStateValue)...) {
        self = .dictionary(Dictionary(uniqueKeysWithValues: elements))
    }
}

// MARK: - Type-Safe State Management

extension Aware {

    // MARK: - Type-Safe State Registration

    /// Register state with type-safe value
    ///
    /// **Token Cost:** ~20 tokens per call
    /// **LLM Guidance:** Use for type-safe state tracking, prevents string confusion
    ///
    /// - Parameters:
    ///   - viewId: View identifier
    ///   - key: State key
    ///   - value: Type-safe state value
    @MainActor
    public func registerStateTyped(_ viewId: String, key: String, value: AwareStateValue) {
        // Convert to string for backward compatibility with existing storage
        registerState(viewId, key: key, value: value.stringValue)
    }

    /// Register state with automatic type inference
    ///
    /// **Token Cost:** ~20 tokens per call
    /// **LLM Guidance:** Use when you have typed values (Bool, Int, etc.)
    ///
    /// - Parameters:
    ///   - viewId: View identifier
    ///   - key: State key
    ///   - value: Codable value (will be wrapped in AwareStateValue)
    @MainActor
    public func registerStateTyped<T: Codable>(_ viewId: String, key: String, value: T) {
        do {
            let stateValue = try AwareStateValue(encoding: value)
            registerStateTyped(viewId, key: key, value: stateValue)
        } catch {
            AwareError.stateRegistrationFailed(
                reason: "Failed to encode value: \(error.localizedDescription)",
                viewId: viewId,
                key: key
            ).log()
        }
    }

    /// Register multiple states at once
    ///
    /// **Token Cost:** ~15 tokens per state
    /// **LLM Guidance:** Efficient for bulk state updates
    ///
    /// - Parameters:
    ///   - viewId: View identifier
    ///   - states: Dictionary of key-value pairs
    @MainActor
    public func registerStatesTyped(_ viewId: String, states: [String: AwareStateValue]) {
        for (key, value) in states {
            registerStateTyped(viewId, key: key, value: value)
        }
    }

    // MARK: - Type-Safe State Retrieval

    /// Get state value with type safety
    ///
    /// **Token Cost:** ~15 tokens per call
    /// **LLM Guidance:** Returns typed value, eliminates string parsing
    ///
    /// - Parameters:
    ///   - viewId: View identifier
    ///   - key: State key
    /// - Returns: Type-safe state value (or nil if not found)
    @MainActor
    public func getStateTyped(_ viewId: String, key: String) -> AwareStateValue? {
        guard let stringValue = getStateValue(viewId, key: key) else {
            return nil
        }
        return AwareStateValue(parsing: stringValue)
    }

    /// Get all states for a view as typed dictionary
    ///
    /// **Token Cost:** ~20 tokens base + ~10 per state
    /// **LLM Guidance:** Use to inspect all states at once
    ///
    /// - Parameter viewId: View identifier
    /// - Returns: Dictionary of typed state values
    @MainActor
    public func getAllStatesTyped(_ viewId: String) -> [String: AwareStateValue] {
        let allStates = getAllStates()
        guard let viewStates = allStates[viewId] else {
            return [:]
        }

        return viewStates.mapValues { AwareStateValue(parsing: $0) }
    }

    // MARK: - Type-Safe Assertions

    /// Assert state value with type checking
    ///
    /// **Token Cost:** ~30 tokens per call
    /// **LLM Guidance:** Use for type-safe state verification
    ///
    /// - Parameters:
    ///   - viewId: View identifier
    ///   - key: State key
    ///   - expectedValue: Expected typed value
    /// - Returns: Assertion result with type information
    @MainActor
    public func assertStateTyped(
        viewId: String,
        key: String,
        equals expectedValue: AwareStateValue
    ) async -> AwareAssertionResult {
        guard let actual = getStateTyped(viewId, key: key) else {
            return AwareAssertionResult(
                passed: false,
                viewId: viewId,
                key: key,
                expected: expectedValue.stringValue,
                actual: nil,
                message: "State '\(key)' not found"
            )
        }

        let passed = actual == expectedValue

        return AwareAssertionResult(
            passed: passed,
            viewId: viewId,
            key: key,
            expected: expectedValue.stringValue,
            actual: actual.stringValue,
            message: passed
                ? "State '\(key)' equals '\(expectedValue.compactValue)' (\(expectedValue.typeName))"
                : "State '\(key)' is '\(actual.compactValue)' (\(actual.typeName)), expected '\(expectedValue.compactValue)' (\(expectedValue.typeName))"
        )
    }

    /// Assert state has specific type
    ///
    /// **Token Cost:** ~25 tokens per call
    /// **LLM Guidance:** Use to verify state type without checking value
    ///
    /// - Parameters:
    ///   - viewId: View identifier
    ///   - key: State key
    ///   - expectedType: Expected type
    /// - Returns: Assertion result
    @MainActor
    public func assertStateType(
        viewId: String,
        key: String,
        is expectedType: AwareStateType
    ) async -> AwareAssertionResult {
        guard let actual = getStateTyped(viewId, key: key) else {
            return AwareAssertionResult(
                passed: false,
                viewId: viewId,
                key: key,
                expected: expectedType.rawValue,
                actual: nil,
                message: "State '\(key)' not found"
            )
        }

        let passed = actual.isType(expectedType)

        return AwareAssertionResult(
            passed: passed,
            viewId: viewId,
            key: key,
            expected: expectedType.rawValue,
            actual: actual.typeName,
            message: passed
                ? "State '\(key)' is type \(expectedType.rawValue)"
                : "State '\(key)' is type \(actual.typeName), expected \(expectedType.rawValue)"
        )
    }

    // MARK: - Convenience Accessors

    /// Get state as Bool (nil if wrong type or not found)
    @MainActor
    public func getStateBool(_ viewId: String, key: String) -> Bool? {
        return getStateTyped(viewId, key: key)?.asBool
    }

    /// Get state as Int (nil if wrong type or not found)
    @MainActor
    public func getStateInt(_ viewId: String, key: String) -> Int? {
        return getStateTyped(viewId, key: key)?.asInt
    }

    /// Get state as Double (nil if wrong type or not found)
    @MainActor
    public func getStateDouble(_ viewId: String, key: String) -> Double? {
        return getStateTyped(viewId, key: key)?.asDouble
    }

    /// Get state as String (nil if wrong type or not found)
    @MainActor
    public func getStateString(_ viewId: String, key: String) -> String? {
        return getStateTyped(viewId, key: key)?.asString
    }
}
