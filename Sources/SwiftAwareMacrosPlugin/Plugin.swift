import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftAwareMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AutoLogMacro.self,
        AutoLogAllMacro.self,
        NoLogMacro.self,
    ]
}
