import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ServerDrivenTypeMacro: MemberMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw "enum 에만 적용 가능"
        }
        let cases = enumDecl.memberBlock.members.compactMap {
            $0.decl.as(EnumCaseDeclSyntax.self)
        }
        let names = cases
            .flatMap(\.elements)
            .map(\.name.text)
        let unknownCaseLiteral = try parseUnknownCase(in: cases)
        let convertedNames = names.compactMap { name -> (String, String)? in
            guard name != "unknown",
                  let convertedName = name.snakeCased()?.uppercased() else {
                return nil
            }
            return (name, convertedName)
        }
        
        let initializer = try InitializerDeclSyntax("init?(rawValue: String?)") {
            try GuardStmtSyntax("guard let rawValue = rawValue else") {
                "return nil"
            }
            try SwitchExprSyntax("switch rawValue") {
                for (originalName, convertedName) in convertedNames {
                    SwitchCaseSyntax(stringLiteral:
                        """
                        case "\(convertedName)":
                            self = .\(originalName)
                        """
                    )
                }
                SwitchCaseSyntax(stringLiteral: unknownCaseLiteral)
            }
        }
        
        return [DeclSyntax(initializer)]
    }
    
    private static func parseUnknownCase(in cases: [EnumCaseDeclSyntax]) throws -> String {
        let unknownCase = cases.flatMap(\.elements).first { $0.name.text == "unknown" }
        guard let unknownCase else {
            throw "unknown case 가 없음"
        }
        if let unknownCaseParameterCount = unknownCase.parameterClause?.parameters.count, unknownCaseParameterCount > 1 {
            throw "unknown case 의 파라미터가 2개 이상임"
        }
        if let unknownCaseParameter = unknownCase.parameterClause?.parameters.first,
           unknownCaseParameter.type.as(IdentifierTypeSyntax.self)?.name.text != "String" {
            throw "unknown case 파라미터 타입이 String 이 아님"
        }
        let unknownCaseLiteral = if let argumentLabel = unknownCase.parameterClause?.parameters.first?.firstName?.text {
            """
            default:
                self = .unknown(\(argumentLabel): rawValue)
            """
        } else {
            """
            default:
                self = .unknown
            """
        }
        return unknownCaseLiteral
    }
}

@main
struct ServerDrivenTypePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ServerDrivenTypeMacro.self
    ]
}

import Foundation

extension String: LocalizedError {
    public var errorDescription: String? { self }
}

extension String {
  func snakeCased() -> String? {
    let pattern = "([a-z0-9])([A-Z])"

    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    let range = NSRange(location: 0, length: count)
    return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2").lowercased()
  }
}
