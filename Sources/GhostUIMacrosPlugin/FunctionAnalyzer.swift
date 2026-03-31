import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - FunctionParameter

/// Represents a single parameter in a function declaration
public struct FunctionParameter {
    /// The internal name used in the function body (e.g., "user" in "for user: User")
    public let name: String

    /// The external label used at call site (e.g., "for" in "for user: User")
    /// nil when the label is "_" (underscore) indicating no external label
    public let label: String?

    /// The type of the parameter as a string (e.g., "User", "Int", "[String]")
    public let type: String

    /// Whether this parameter has a generic type
    /// True if the type contains "<", "some ", "any ", or is a closure type
    public let isGeneric: Bool

    public init(name: String, label: String?, type: String, isGeneric: Bool) {
        self.name = name
        self.label = label
        self.type = type
        self.isGeneric = isGeneric
    }
}

// MARK: - FunctionInfo

/// Contains all extracted information about a function declaration
public struct FunctionInfo {
    /// The name of the function
    public let name: String

    /// All parameters of the function
    public let parameters: [FunctionParameter]

    /// Whether the function is marked async
    public let isAsync: Bool

    /// Whether the function is marked throws or rethrows
    public let isThrowing: Bool

    /// The return type as a string, nil if the function returns Void
    public let returnType: String?

    public init(
        name: String,
        parameters: [FunctionParameter],
        isAsync: Bool,
        isThrowing: Bool,
        returnType: String?
    ) {
        self.name = name
        self.parameters = parameters
        self.isAsync = isAsync
        self.isThrowing = isThrowing
        self.returnType = returnType
    }
}

// MARK: - FunctionAnalyzer

/// Analyzes Swift function declarations to extract structured information
public enum FunctionAnalyzer {

    /// Analyzes a FunctionDeclSyntax and extracts all relevant information
    /// - Parameter declaration: The function declaration syntax node
    /// - Returns: A FunctionInfo struct containing the analyzed information
    public static func analyze(_ declaration: FunctionDeclSyntax) -> FunctionInfo {
        let name = extractFunctionName(from: declaration)
        let parameters = extractParameters(from: declaration)
        let isAsync = checkIsAsync(declaration)
        let isThrowing = checkIsThrowing(declaration)
        let returnType = extractReturnType(from: declaration)

        return FunctionInfo(
            name: name,
            parameters: parameters,
            isAsync: isAsync,
            isThrowing: isThrowing,
            returnType: returnType
        )
    }

    // MARK: - Private Extraction Methods

    /// Extracts the function name from the declaration
    private static func extractFunctionName(from declaration: FunctionDeclSyntax) -> String {
        return declaration.name.text
    }

    /// Extracts all parameters from the function signature
    private static func extractParameters(from declaration: FunctionDeclSyntax) -> [FunctionParameter] {
        let parameterClause = declaration.signature.parameterClause

        return parameterClause.parameters.map { param in
            let name = param.secondName?.text ?? param.firstName.text
            let label = extractLabel(from: param)
            let typeString = param.type.trimmedDescription
            let isGeneric = isGenericType(typeString)

            return FunctionParameter(
                name: name,
                label: label,
                type: typeString,
                isGeneric: isGeneric
            )
        }
    }

    /// Extracts the external label from a parameter
    /// Returns nil if the label is "_" (underscore)
    private static func extractLabel(from param: FunctionParameterSyntax) -> String? {
        let firstNameText = param.firstName.text

        // If firstName is "_", there's no external label
        if firstNameText == "_" {
            return nil
        }

        // If there's a secondName, firstName is the label
        // If there's no secondName, firstName serves as both label and name
        return firstNameText
    }

    /// Checks if the function has the async keyword
    private static func checkIsAsync(_ declaration: FunctionDeclSyntax) -> Bool {
        // Check the effect specifiers for async keyword
        if let effectSpecifiers = declaration.signature.effectSpecifiers {
            return effectSpecifiers.asyncSpecifier != nil
        }
        return false
    }

    /// Checks if the function has throws or rethrows keyword
    private static func checkIsThrowing(_ declaration: FunctionDeclSyntax) -> Bool {
        // Check the effect specifiers for throws/rethrows keyword
        // In swift-syntax 600+, throwsSpecifier is now throwsClause
        if let effectSpecifiers = declaration.signature.effectSpecifiers {
            return effectSpecifiers.throwsClause != nil
        }
        return false
    }

    /// Extracts the return type from the function signature
    /// Returns nil if the function returns Void or has no explicit return type
    private static func extractReturnType(from declaration: FunctionDeclSyntax) -> String? {
        guard let returnClause = declaration.signature.returnClause else {
            return nil
        }

        let typeString = returnClause.type.trimmedDescription

        // Treat Void, (), and empty as no return type
        if typeString == "Void" || typeString == "()" || typeString.isEmpty {
            return nil
        }

        return typeString
    }

    // MARK: - Type Analysis Helpers

    /// Determines if a type string represents a generic type
    /// Checks for: angle brackets (<>), "some" keyword, "any" keyword, or closure syntax (->)
    private static func isGenericType(_ typeString: String) -> Bool {
        // Check for generic angle brackets (e.g., Array<Int>, Optional<String>)
        if typeString.contains("<") {
            return true
        }

        // Check for "some" keyword (e.g., some View, some Collection)
        if typeString.hasPrefix("some ") || typeString.contains(" some ") {
            return true
        }

        // Check for "any" keyword (e.g., any Error, any Collection)
        if typeString.hasPrefix("any ") || typeString.contains(" any ") {
            return true
        }

        // Check for closure types (e.g., (Int) -> String, () -> Void)
        if typeString.contains("->") {
            return true
        }

        return false
    }
}
