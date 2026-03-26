import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - MacroError

/// Errors that can occur during macro expansion
public enum MacroError: Error, CustomStringConvertible {
    case notAFunction
    case noBody
    case unsupportedSyntax(String)

    public var description: String {
        switch self {
        case .notAFunction:
            return "@AutoLog can only be applied to functions"
        case .noBody:
            return "@AutoLog requires a function with a body"
        case .unsupportedSyntax(let detail):
            return "Unsupported syntax: \(detail)"
        }
    }
}

// MARK: - AutoLogMacro

/// A peer macro that generates a logged wrapper function alongside the original
/// Usage: Apply @AutoLog to a function, then call _logged_functionName() instead
public struct AutoLogMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Ensure we have a function declaration
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw MacroError.notAFunction
        }

        // Ensure the function has a body
        guard funcDecl.body != nil else {
            throw MacroError.noBody
        }

        // Parse macro arguments
        let (verbosity, category) = parseArguments(from: node)

        // Extract function info using FunctionAnalyzer
        let functionInfo = FunctionAnalyzer.analyze(funcDecl)

        // Generate the logged wrapper function
        let wrapperFunc = generateLoggedWrapper(
            original: funcDecl,
            functionInfo: functionInfo,
            verbosity: verbosity,
            category: category
        )

        return [DeclSyntax(wrapperFunc)]
    }

    /// Parses verbosity and category arguments from the attribute syntax
    private static func parseArguments(from node: AttributeSyntax) -> (verbosity: String, category: String?) {
        var verbosity = "standard"
        var category: String? = nil

        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return (verbosity, category)
        }

        for argument in arguments {
            let label = argument.label?.text

            if label == "verbosity" || label == nil && verbosity == "standard" {
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    verbosity = memberAccess.declName.baseName.text
                } else if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
                          let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                    verbosity = segment.content.text
                }
            } else if label == "category" {
                if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
                   let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                    category = segment.content.text
                }
            }
        }

        return (verbosity, category)
    }

    /// Generates a logged wrapper function that calls the original
    private static func generateLoggedWrapper(
        original: FunctionDeclSyntax,
        functionInfo: FunctionInfo,
        verbosity: String,
        category: String?
    ) -> FunctionDeclSyntax {
        let originalName = functionInfo.name
        let wrapperName = "_logged_\(originalName)"

        // Build parameter forwarding
        let parameterForwarding = functionInfo.parameters.map { param -> String in
            if let label = param.label, label != param.name {
                return "\(label): \(param.name)"
            } else {
                return param.name
            }
        }.joined(separator: ", ")

        // Build call expression
        let asyncKeyword = functionInfo.isAsync ? "await " : ""
        let tryKeyword = functionInfo.isThrowing ? "try " : ""
        let callExpr = "\(tryKeyword)\(asyncKeyword)\(originalName)(\(parameterForwarding))"

        // Build entry log
        let entryLog: String
        let categoryArg = category.map { ", category: \"\($0)\"" } ?? ""

        switch verbosity {
        case "minimal":
            entryLog = ""
        case "verbose":
            let paramStr = functionInfo.parameters.map { "\\(\($0.name))" }.joined(separator: ", ")
            entryLog = "SwiftAware.shared.logger.debug(\"[ENTER] \(originalName)(\(paramStr))\"\(categoryArg))"
        default: // standard
            entryLog = "SwiftAware.shared.logger.debug(\"[ENTER] \(originalName)\"\(categoryArg))"
        }

        // Build exit log
        let exitLog: String
        switch verbosity {
        case "minimal":
            exitLog = ""
        default:
            if functionInfo.returnType != nil {
                exitLog = "SwiftAware.shared.logger.debug(\"[EXIT] \(originalName) -> \\(type(of: _result)) (\\(_duration)s)\"\(categoryArg))"
            } else {
                exitLog = "SwiftAware.shared.logger.debug(\"[EXIT] \(originalName) (\\(_duration)s)\"\(categoryArg))"
            }
        }

        // Build error log
        let errorLog = "SwiftAware.shared.logger.error(\"[ERROR] \(originalName): \\(_error) (\\(_duration)s)\"\(categoryArg))"

        // Build function body
        let bodyCode: String
        if functionInfo.isThrowing {
            if let _ = functionInfo.returnType {
                bodyCode = """
                    let _start = CFAbsoluteTimeGetCurrent()
                    \(entryLog.isEmpty ? "" : entryLog + "\n    ")do {
                        let _result = \(callExpr)
                        let _duration = CFAbsoluteTimeGetCurrent() - _start
                        \(exitLog)
                        return _result
                    } catch {
                        let _error = error
                        let _duration = CFAbsoluteTimeGetCurrent() - _start
                        \(errorLog)
                        throw _error
                    }
                """
            } else {
                bodyCode = """
                    let _start = CFAbsoluteTimeGetCurrent()
                    \(entryLog.isEmpty ? "" : entryLog + "\n    ")do {
                        \(callExpr)
                        let _duration = CFAbsoluteTimeGetCurrent() - _start
                        \(exitLog)
                    } catch {
                        let _error = error
                        let _duration = CFAbsoluteTimeGetCurrent() - _start
                        \(errorLog)
                        throw _error
                    }
                """
            }
        } else {
            if let _ = functionInfo.returnType {
                bodyCode = """
                    let _start = CFAbsoluteTimeGetCurrent()
                    \(entryLog.isEmpty ? "" : entryLog + "\n    ")let _result = \(callExpr)
                    let _duration = CFAbsoluteTimeGetCurrent() - _start
                    \(exitLog)
                    return _result
                """
            } else {
                bodyCode = """
                    let _start = CFAbsoluteTimeGetCurrent()
                    \(entryLog.isEmpty ? "" : entryLog + "\n    ")\(callExpr)
                    let _duration = CFAbsoluteTimeGetCurrent() - _start
                    \(exitLog)
                """
            }
        }

        // Create the wrapper function with same signature but different name
        var wrapper = original
        wrapper = wrapper.with(\.name, TokenSyntax.identifier(wrapperName))
        wrapper = wrapper.with(\.attributes, AttributeListSyntax([]))
        wrapper = wrapper.with(\.body, CodeBlockSyntax(
            leftBrace: .leftBraceToken(),
            statements: CodeBlockItemListSyntax([
                CodeBlockItemSyntax(item: .expr(ExprSyntax(stringLiteral: bodyCode)))
            ]),
            rightBrace: .rightBraceToken()
        ))

        return wrapper
    }
}

// MARK: - NoLogMacro

/// A peer macro that acts as a marker to exclude a function from @AutoLogAll.
/// This macro generates nothing; it simply marks the function to be skipped.
public struct NoLogMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // NoLog is a marker-only macro; it produces no additional declarations
        return []
    }
}

// MARK: - AutoLogAllMacro

/// A member attribute macro that applies @AutoLog to all function members in a type
public struct AutoLogAllMacro: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        // Only apply to function declarations
        guard let funcDecl = member.as(FunctionDeclSyntax.self) else {
            return []
        }

        // Check if the function has @NoLog attribute - if so, skip it
        for attribute in funcDecl.attributes {
            if let attr = attribute.as(AttributeSyntax.self),
               let identifier = attr.attributeName.as(IdentifierTypeSyntax.self),
               identifier.name.text == "NoLog" {
                return []
            }
        }

        // Parse arguments from @AutoLogAll
        let (verbosity, explicitCategory) = parseArguments(from: node)

        // Auto-infer category from type name if not explicitly provided
        let category = explicitCategory ?? inferCategory(from: declaration)

        // Build the @AutoLog attribute
        let attribute = buildAutoLogAttribute(verbosity: verbosity, category: category)

        return [attribute]
    }

    /// Parses verbosity and category arguments from the attribute syntax
    private static func parseArguments(from node: AttributeSyntax) -> (verbosity: String, category: String?) {
        var verbosity = "standard"
        var category: String? = nil

        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return (verbosity, category)
        }

        for argument in arguments {
            let label = argument.label?.text

            if label == "verbosity" {
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    verbosity = memberAccess.declName.baseName.text
                }
            } else if label == "category" {
                if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
                   let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                    category = segment.content.text
                }
            }
        }

        return (verbosity, category)
    }

    /// Infers a category from the type name
    private static func inferCategory(from declaration: some DeclGroupSyntax) -> String? {
        let typeName: String?

        if let structDecl = declaration.as(StructDeclSyntax.self) {
            typeName = structDecl.name.text
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            typeName = classDecl.name.text
        } else if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            typeName = enumDecl.name.text
        } else if let actorDecl = declaration.as(ActorDeclSyntax.self) {
            typeName = actorDecl.name.text
        } else {
            typeName = nil
        }

        guard let name = typeName else {
            return nil
        }

        let suffixMappings: [(suffix: String, category: String)] = [
            ("Service", "Services"),
            ("Manager", "Managers"),
            ("Controller", "Controllers"),
            ("Handler", "Handlers"),
            ("Provider", "Providers"),
            ("Repository", "Repositories"),
            ("Store", "Stores"),
            ("Cache", "Caches"),
            ("Client", "Clients"),
            ("ViewModel", "ViewModels"),
            ("View", "Views"),
        ]

        for (suffix, category) in suffixMappings {
            if name.hasSuffix(suffix) {
                return category
            }
        }

        return name
    }

    /// Builds an @AutoLog attribute syntax with the given parameters
    private static func buildAutoLogAttribute(verbosity: String, category: String?) -> AttributeSyntax {
        var arguments: [LabeledExprSyntax] = []

        // Add verbosity argument
        let verbosityExpr = MemberAccessExprSyntax(
            period: .periodToken(),
            declName: DeclReferenceExprSyntax(baseName: .identifier(verbosity))
        )
        arguments.append(LabeledExprSyntax(
            label: .identifier("verbosity"),
            colon: .colonToken(trailingTrivia: .space),
            expression: verbosityExpr
        ))

        // Add category argument if present
        if let category = category {
            let categoryExpr = StringLiteralExprSyntax(content: category)
            arguments.append(LabeledExprSyntax(
                leadingTrivia: .space,
                label: .identifier("category"),
                colon: .colonToken(trailingTrivia: .space),
                expression: categoryExpr
            ))
        }

        let argumentList = LabeledExprListSyntax(arguments.enumerated().map { index, arg in
            if index < arguments.count - 1 {
                return arg.with(\.trailingComma, .commaToken())
            }
            return arg
        })

        return AttributeSyntax(
            atSign: .atSignToken(),
            attributeName: IdentifierTypeSyntax(name: .identifier("AutoLog")),
            leftParen: .leftParenToken(),
            arguments: .argumentList(argumentList),
            rightParen: .rightParenToken()
        )
    }
}
