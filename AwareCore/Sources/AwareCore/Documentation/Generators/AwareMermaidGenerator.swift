//
//  AwareMermaidGenerator.swift
//  AwareCore
//
//  Generates Mermaid diagrams for architecture visualization.
//

import Foundation

// MARK: - Aware Mermaid Generator

/// Generates Mermaid diagrams for Breathe IDE visualization
@MainActor
public struct AwareMermaidGenerator {
    private let registry: AwareAPIRegistry

    public init(registry: AwareAPIRegistry) {
        self.registry = registry
    }

    public func generate(diagramType: MermaidDiagramType) -> String {
        switch diagramType {
        case .architecture:
            return generateArchitectureDiagram()
        case .actionFlow:
            return generateActionFlowDiagram()
        case .hierarchy:
            return generateHierarchyDiagram()
        case .stateMachine:
            return generateStateMachineDiagram()
        case .dataFlow:
            return generateDataFlowDiagram()
        }
    }

    private func generateArchitectureDiagram() -> String {
        """
        graph TB
            A[Aware.shared] --> B[AwareService]
            A --> C[AwareSnapshotRenderer]
            A --> D[AwareFocusManager]
            A --> E[AwareDocumentationService]
            B --> F[viewRegistry]
            B --> G[stateRegistry]
            B --> H[actionCallbacks]
            C --> I[Compact Format]
            C --> J[JSON Format]
            E --> K[AwareAPIRegistry]
            E --> L[CompactGenerator]
        """
    }

    private func generateActionFlowDiagram() -> String {
        """
        flowchart LR
            A[Button Tap] --> B{Has Callback?}
            B -->|Yes| C[Execute Action]
            B -->|No| D[Notify]
            C --> E[Update State]
            E --> F[Trigger Snapshot]
            F --> G[LLM Observes]
        """
    }

    private func generateHierarchyDiagram() -> String {
        """
        graph TD
            A[Container] --> B[Text Field]
            A --> C[Button]
            A --> D[Toggle]
        """
    }

    private func generateStateMachineDiagram() -> String {
        """
        stateDiagram-v2
            [*] --> Idle
            Idle --> Loading: Action
            Loading --> Success: Complete
            Loading --> Error: Fail
            Success --> Idle
            Error --> Idle: Retry
        """
    }

    private func generateDataFlowDiagram() -> String {
        """
        graph LR
            A[Data Source] --> B[Transform]
            B --> C[Validate]
            C --> D[Cache]
            D --> E[View]
        """
    }
}
