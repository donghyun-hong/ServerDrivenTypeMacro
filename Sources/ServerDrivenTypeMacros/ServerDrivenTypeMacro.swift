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
            context.diagnose(ServerDrivenTypeMacroDiagnostic.invalidType.diagnose(at: declaration))
            return []
        }
        let cases = enumDecl.memberBlock.members.compactMap {
            $0.decl.as(EnumCaseDeclSyntax.self)
        }
        let names = cases
            .flatMap(\.elements)
            .map(\.name.text)
        guard let unknownCaseLiteral = parseUnknownCase(in: cases, context: context) else {
            return []
        }
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
    
    private static func parseUnknownCase(in cases: [EnumCaseDeclSyntax], context: some SwiftSyntaxMacros.MacroExpansionContext) -> String? {
        guard cases.count > 0 else {
            return nil
        }
        let unknownCase = cases.flatMap(\.elements).first { $0.name.text == "unknown" }
        guard let unknownCase else {
            context.diagnose(ServerDrivenTypeMacroDiagnostic.missingUnknownCase.diagnose(at: cases.first!))
            return nil
        }
        if let unknownCaseParameterCount = unknownCase.parameterClause?.parameters.count, unknownCaseParameterCount > 1 {
            context.diagnose(ServerDrivenTypeMacroDiagnostic.tooManyParametersInUnknownCase.diagnose(at: unknownCase))
            return nil
        }
        if let unknownCaseParameter = unknownCase.parameterClause?.parameters.first,
           unknownCaseParameter.type.as(IdentifierTypeSyntax.self)?.name.text != "String" {
            context.diagnose(ServerDrivenTypeMacroDiagnostic.invalidParameterTypeInUnknownCase.diagnose(at: unknownCaseParameter))
            return nil
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
