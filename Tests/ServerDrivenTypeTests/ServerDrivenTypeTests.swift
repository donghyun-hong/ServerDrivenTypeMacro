import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(ServerDrivenTypeMacros)
import ServerDrivenTypeMacros

let testMacros: [String: Macro.Type] = [
    "ServerDrivenType": ServerDrivenTypeMacro.self
]
#endif

final class ServerDrivenTypeTests: XCTestCase {
    
    func testServerDrivenTypeMacro1() throws {
        assertMacroExpansion(
            """
            @ServerDrivenType
            enum EntityViewTypeV2: Decodable, Hashable {
                case unknown(string: String)
                case oneColumnProductCardWithLongTitle
                case carouselSmallProductCard
            }
            """,
            expandedSource:
            """
            enum EntityViewTypeV2: Decodable, Hashable {
                case unknown(string: String)
                case oneColumnProductCardWithLongTitle
                case carouselSmallProductCard
            
                init?(rawValue: String?) {
                    guard let rawValue = rawValue else {
                        return nil
                    }
                    switch rawValue {
                    case "ONE_COLUMN_PRODUCT_CARD_WITH_LONG_TITLE":
                        self = .oneColumnProductCardWithLongTitle
                    case "CAROUSEL_SMALL_PRODUCT_CARD":
                        self = .carouselSmallProductCard
                    default:
                        self = .unknown(string: rawValue)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testServerDrivenTypeMacro2() throws {
        assertMacroExpansion(
            """
            @ServerDrivenType
            enum EntityViewTypeV2: Decodable, Hashable {
                case oneColumnProductCardWithLongTitle
                case carouselSmallProductCard
                case unknown
            }
            """,
            expandedSource:
            """
            enum EntityViewTypeV2: Decodable, Hashable {
                case oneColumnProductCardWithLongTitle
                case carouselSmallProductCard
                case unknown
            
                init?(rawValue: String?) {
                    guard let rawValue = rawValue else {
                        return nil
                    }
                    switch rawValue {
                    case "ONE_COLUMN_PRODUCT_CARD_WITH_LONG_TITLE":
                        self = .oneColumnProductCardWithLongTitle
                    case "CAROUSEL_SMALL_PRODUCT_CARD":
                        self = .carouselSmallProductCard
                    default:
                        self = .unknown
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testDynamicMacroError1() throws {
        assertMacroExpansion(
            """
            @ServerDrivenType
            struct ABCD {
            }
            """,
            expandedSource:
            """
            struct ABCD {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "ServerDrivenTypeMacro can only be applied to enums.", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
    
    func testDynamicMacroError2() throws {
        assertMacroExpansion(
            """
            @ServerDrivenType
            enum ABCD {
                case oneColumnProductCardWithLongTitle
            }
            """,
            expandedSource:
            """
            enum ABCD {
                case oneColumnProductCardWithLongTitle
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "unknown case must be defined.", line: 3, column: 5)
            ],
            macros: testMacros
        )
    }

    func testDynamicMacroError3() throws {
        assertMacroExpansion(
            """
            @ServerDrivenType
            enum ABCD {
                case oneColumnProductCardWithLongTitle
                case unknown(foo: String, bar: String)
            }
            """,
            expandedSource:
            """
            enum ABCD {
                case oneColumnProductCardWithLongTitle
                case unknown(foo: String, bar: String)
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "unknown case must have a single parameter.", line: 4, column: 10)
            ],
            macros: testMacros
        )
    }

    func testDynamicMacroError4() throws {
        assertMacroExpansion(
            """
            @ServerDrivenType
            enum ABCD {
                case oneColumnProductCardWithLongTitle
                case unknown(int: Int)
            }
            """,
            expandedSource:
            """
            enum ABCD {
                case oneColumnProductCardWithLongTitle
                case unknown(int: Int)
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "The parameter of unknownCase must be of type String.", line: 4, column: 18)
            ],
            macros: testMacros
        )
    }

}
