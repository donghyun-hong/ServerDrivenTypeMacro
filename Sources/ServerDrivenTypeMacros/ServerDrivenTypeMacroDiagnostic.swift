//
//  ServerDrivenTypeMacroDiagnostic.swift
//
//
//  Created by 홍동현 on 7/11/24.
//

import SwiftDiagnostics
import SwiftSyntax

enum ServerDrivenTypeMacroDiagnostic: DiagnosticMessage {
    
    case invalidType
    case missingUnknownCase
    case tooManyParametersInUnknownCase
    case invalidParameterTypeInUnknownCase
    
    var message: String {
        switch self {
        case .invalidType:
            return "ServerDrivenTypeMacro can only be applied to enums."
        case .missingUnknownCase:
            return "unknown case must be defined."
        case .tooManyParametersInUnknownCase:
            return "unknown case must have a single parameter."
        case .invalidParameterTypeInUnknownCase:
            return "The parameter of unknown case must be of type String."
        }
    }
    var severity: DiagnosticSeverity { .error }
    var diagnosticID: SwiftDiagnostics.MessageID { MessageID(domain: "Swift", id: "ServerDrivenTypeMacro.\(self)") }
    
    func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
        return Diagnostic(node: Syntax(node), message: self)
    }
}
