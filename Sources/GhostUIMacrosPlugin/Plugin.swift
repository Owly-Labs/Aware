import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct GhostUIMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AutoLogMacro.self,
        AutoLogAllMacro.self,
        NoLogMacro.self,
    ]
}
