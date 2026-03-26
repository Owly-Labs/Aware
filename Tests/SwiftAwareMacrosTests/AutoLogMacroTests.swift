import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(SwiftAwareMacrosPlugin)
import SwiftAwareMacrosPlugin

let testMacros: [String: Macro.Type] = [
    "AutoLog": AutoLogMacro.self,
    "AutoLogAll": AutoLogAllMacro.self,
    "NoLog": NoLogMacro.self,
]
#endif

final class AutoLogMacroTests: XCTestCase {

    func testAutoLogNotAFunction() throws {
        #if canImport(SwiftAwareMacrosPlugin)
        // @AutoLog should error when applied to non-functions
        assertMacroExpansion(
            """
            @AutoLog
            var x = 5
            """,
            expandedSource: """
            var x = 5
            """,
            diagnostics: [
                DiagnosticSpec(message: "@AutoLog can only be applied to functions", line: 1, column: 1)
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}

final class AutoLogAllMacroTests: XCTestCase {

    func testAutoLogAllAppliesAutoLogAttribute() throws {
        #if canImport(SwiftAwareMacrosPlugin)
        // @AutoLogAll applies @AutoLog which generates a wrapper function
        assertMacroExpansion(
            """
            @AutoLogAll
            class UserService {
                func getUser() {}
            }
            """,
            expandedSource: """
            class UserService {
                func getUser() {}

                func _logged_getUser() {    let _start = CFAbsoluteTimeGetCurrent()
                    SwiftAware.shared.logger.debug("[ENTER] getUser", category: "Services")
                    getUser()
                    let _duration = CFAbsoluteTimeGetCurrent() - _start
                    SwiftAware.shared.logger.debug("[EXIT] getUser (\\(_duration)s)", category: "Services")
                }
            }
            """,
            macros: testMacros,
            indentationWidth: .spaces(4)
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAutoLogAllInfersCategoryFromTypeName() throws {
        #if canImport(SwiftAwareMacrosPlugin)
        // Category should be inferred from type suffix
        assertMacroExpansion(
            """
            @AutoLogAll
            struct AuthManager {
                func login() {}
            }
            """,
            expandedSource: """
            struct AuthManager {
                func login() {}

                func _logged_login() {    let _start = CFAbsoluteTimeGetCurrent()
                    SwiftAware.shared.logger.debug("[ENTER] login", category: "Managers")
                    login()
                    let _duration = CFAbsoluteTimeGetCurrent() - _start
                    SwiftAware.shared.logger.debug("[EXIT] login (\\(_duration)s)", category: "Managers")
                }
            }
            """,
            macros: testMacros,
            indentationWidth: .spaces(4)
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAutoLogAllWithExplicitCategory() throws {
        #if canImport(SwiftAwareMacrosPlugin)
        // Explicit category should override inference
        assertMacroExpansion(
            """
            @AutoLogAll(category: "CustomCategory")
            struct MyStruct {
                func doSomething() {}
            }
            """,
            expandedSource: """
            struct MyStruct {
                func doSomething() {}

                func _logged_doSomething() {    let _start = CFAbsoluteTimeGetCurrent()
                    SwiftAware.shared.logger.debug("[ENTER] doSomething", category: "CustomCategory")
                    doSomething()
                    let _duration = CFAbsoluteTimeGetCurrent() - _start
                    SwiftAware.shared.logger.debug("[EXIT] doSomething (\\(_duration)s)", category: "CustomCategory")
                }
            }
            """,
            macros: testMacros,
            indentationWidth: .spaces(4)
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAutoLogAllWithVerbosity() throws {
        #if canImport(SwiftAwareMacrosPlugin)
        // Verbosity should propagate to generated @AutoLog (verbose includes args)
        assertMacroExpansion(
            """
            @AutoLogAll(verbosity: .verbose)
            class DataProvider {
                func fetch() {}
            }
            """,
            expandedSource: """
            class DataProvider {
                func fetch() {}

                func _logged_fetch() {    let _start = CFAbsoluteTimeGetCurrent()
                    SwiftAware.shared.logger.debug("[ENTER] fetch()", category: "Providers")
                    fetch()
                    let _duration = CFAbsoluteTimeGetCurrent() - _start
                    SwiftAware.shared.logger.debug("[EXIT] fetch (\\(_duration)s)", category: "Providers")
                }
            }
            """,
            macros: testMacros,
            indentationWidth: .spaces(4)
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAutoLogAllSkipsNonFunctions() throws {
        #if canImport(SwiftAwareMacrosPlugin)
        // @AutoLogAll should only apply to functions, not properties
        assertMacroExpansion(
            """
            @AutoLogAll
            class MyCache {
                var value: Int = 0
                func refresh() {}
            }
            """,
            expandedSource: """
            class MyCache {
                var value: Int = 0
                func refresh() {}

                func _logged_refresh() {    let _start = CFAbsoluteTimeGetCurrent()
                    SwiftAware.shared.logger.debug("[ENTER] refresh", category: "Caches")
                    refresh()
                    let _duration = CFAbsoluteTimeGetCurrent() - _start
                    SwiftAware.shared.logger.debug("[EXIT] refresh (\\(_duration)s)", category: "Caches")
                }
            }
            """,
            macros: testMacros,
            indentationWidth: .spaces(4)
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testNoLogExcludesFunctionFromAutoLogAll() throws {
        #if canImport(SwiftAwareMacrosPlugin)
        // @NoLog should prevent @AutoLogAll from applying @AutoLog to that function
        assertMacroExpansion(
            """
            @AutoLogAll
            class MyService {
                func loggedMethod() {}

                @NoLog
                func excludedMethod() {}
            }
            """,
            expandedSource: """
            class MyService {
                func loggedMethod() {}

                func _logged_loggedMethod() {    let _start = CFAbsoluteTimeGetCurrent()
                    SwiftAware.shared.logger.debug("[ENTER] loggedMethod", category: "Services")
                    loggedMethod()
                    let _duration = CFAbsoluteTimeGetCurrent() - _start
                    SwiftAware.shared.logger.debug("[EXIT] loggedMethod (\\(_duration)s)", category: "Services")
                }
                func excludedMethod() {}
            }
            """,
            macros: testMacros,
            indentationWidth: .spaces(4)
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
