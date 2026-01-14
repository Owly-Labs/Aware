//
//  AwareDocumentationService.swift
//  AwareCore
//
//  Main service for querying and exporting Aware framework API documentation.
//

import Foundation
import os.log

// MARK: - Aware Documentation Service

/// Main service for framework API documentation queries and exports
///
/// **Pattern**: Singleton service (like `Aware.shared`)
/// **Usage**: Query API surfaces and export in multiple formats
@MainActor
public final class AwareDocumentationService: ObservableObject {
    public static let shared = AwareDocumentationService()

    private let logger = Logger(subsystem: "com.aware.framework", category: "Documentation")
    private let registry = AwareAPIRegistry.shared

    private init() {
        logger.info("AwareDocumentationService initialized")

        // Auto-register framework APIs on first access
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            CoreModifiersRegistry.register()
            CoreTypesRegistry.register()
            CoreMethodsRegistry.register()
            self.logger.info("Registered \(self.registry.getStatistics().totalAPIs) framework APIs")
        }
    }

    // MARK: - Query Interface

    /// Query modifiers with optional filters
    public func queryModifiers(platform: Platform? = nil, category: ModifierCategory? = nil) -> [ModifierMetadata] {
        registry.getModifiers(category: category, platform: platform)
    }

    /// Query types with optional filters
    public func queryTypes(category: TypeCategory? = nil, kind: TypeKind? = nil) -> [TypeMetadata] {
        registry.getTypes(category: category, kind: kind)
    }

    /// Query methods with optional filters
    public func queryMethods(className: String? = nil, category: MethodCategory? = nil) -> [MethodMetadata] {
        registry.getMethods(className: className, category: category)
    }

    /// Search all API surfaces by query string
    public func search(_ query: String) -> APISearchResult {
        registry.search(query)
    }

    /// Get registry statistics
    public func getStatistics() -> RegistryStatistics {
        registry.getStatistics()
    }

    // MARK: - Export Formats

    /// Export compact format (LLM-optimized, ~1200 tokens)
    /// Priority 1 - Most important for LLM consumption
    public func exportCompact(maxTokens: Int = 1500) -> String {
        let generator = AwareCompactGenerator(registry: registry)
        return generator.generate(maxTokens: maxTokens)
    }

    /// Export JSON Schema (programmatic consumption, ~1500 tokens)
    /// Priority 2 - For programmatic queries and validation
    public func exportJSONSchema(scope: DocumentationScope = .all) -> String {
        let generator = AwareJSONSchemaGenerator(registry: registry)
        return generator.generate(scope: scope)
    }

    /// Export Mermaid diagram (~500 tokens)
    /// Priority 3 - For Breathe IDE visualization
    public func exportMermaid(diagramType: MermaidDiagramType = .architecture) -> String {
        let generator = AwareMermaidGenerator(registry: registry)
        return generator.generate(diagramType: diagramType)
    }

    /// Export Markdown documentation (~3000 tokens)
    /// Priority 4 - For human-readable docs
    public func exportMarkdown(format: MarkdownFormat = .apiReference) -> String {
        let generator = AwareMarkdownGenerator(registry: registry)
        return generator.generate(format: format)
    }

    /// Export OpenAPI 3.0 specification (~2500 tokens)
    /// Priority 5 - For external tool integration
    public func exportOpenAPI(version: String = "3.0.0") -> String {
        let generator = AwareOpenAPIGenerator(registry: registry)
        return generator.generate(version: version)
    }

    // MARK: - Protocol-Based Development Exports (v3.0+)

    /// Export lightweight protocol stubs (50-100 LOC)
    /// For LLM code generation without framework import
    public func exportProtocolStubs(platform: Platform = .all, language: Language = .swift) -> ProtocolStubsResult {
        let generator = AwareProtocolGenerator(registry: registry)
        return generator.generateStubs(platform: platform, language: language)
    }

    /// Export validation rules (JSON)
    /// For Aware-compliance checking via MCP tools
    public func exportValidationRules() -> ValidationRulesResult {
        let generator = AwareProtocolGenerator(registry: registry)
        return generator.generateValidationRules()
    }

    /// Export pattern catalog (JSON)
    /// For LLM guidance on modifier usage
    public func exportPatternCatalog() -> PatternCatalogResult {
        let generator = AwareProtocolGenerator(registry: registry)
        return generator.generatePatternCatalog()
    }

    /// Export complete protocol specification
    /// Includes stubs, validation rules, and pattern catalog
    public func exportProtocolSpecification() -> ProtocolSpecificationResult {
        let generator = AwareProtocolGenerator(registry: registry)
        return generator.generate()
    }

    // MARK: - Convenience Exports

    /// Export to file
    public func exportToFile(format: ExportFormat, path: String) throws {
        let content: String
        switch format {
        case .compact:
            content = exportCompact()
        case .jsonSchema:
            content = exportJSONSchema()
        case .mermaid(let diagramType):
            content = exportMermaid(diagramType: diagramType)
        case .markdown(let mdFormat):
            content = exportMarkdown(format: mdFormat)
        case .openapi:
            content = exportOpenAPI()
        }

        try content.write(toFile: path, atomically: true, encoding: .utf8)
        logger.info("Exported \(format) to \(path)")
    }

    /// Export all formats to directory
    public func exportAll(toDirectory dir: String) throws {
        let formats: [(ExportFormat, String)] = [
            (.compact, "aware-api-compact.txt"),
            (.jsonSchema, "aware-api-schema.json"),
            (.mermaid(.architecture), "aware-architecture.mmd"),
            (.markdown(.apiReference), "aware-api-reference.md"),
            (.openapi, "aware-openapi.yaml")
        ]

        for (format, filename) in formats {
            let path = "\(dir)/\(filename)"
            try exportToFile(format: format, path: path)
        }

        logger.info("Exported all formats to \(dir)")
    }
}

// MARK: - Export Format

/// Export format options
public enum ExportFormat: CustomStringConvertible {
    case compact
    case jsonSchema
    case mermaid(MermaidDiagramType)
    case markdown(MarkdownFormat)
    case openapi

    public var fileExtension: String {
        switch self {
        case .compact: return "txt"
        case .jsonSchema: return "json"
        case .mermaid: return "mmd"
        case .markdown: return "md"
        case .openapi: return "yaml"
        }
    }

    public var description: String {
        switch self {
        case .compact: return "compact"
        case .jsonSchema: return "jsonSchema"
        case .mermaid(let type): return "mermaid(\(type.rawValue))"
        case .markdown(let format): return "markdown(\(format.rawValue))"
        case .openapi: return "openapi"
        }
    }
}
