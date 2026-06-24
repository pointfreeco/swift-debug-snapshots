import SwiftDiagnostics
import SwiftSyntax
public import SwiftSyntaxMacros

enum ConvertibleCheckPassMacro: PeerMacro {
  static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    []
  }
}

enum ConvertibleCheckFailMacro: PeerMacro {
  static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    let message: String
    if declaration.is(EnumCaseDeclSyntax.self) {
      message = "Associated value must be annotated '@DebugSnapshotConvertible'"
    } else {
      message = "Property must be annotated '@DebugSnapshotConvertible'"
    }
    context.diagnose(
      Diagnostic(
        node: Syntax(declaration),
        message: MacroExpansionWarningMessage(message),
        fixIt: .replace(
          message: MacroExpansionFixItMessage("Apply '@DebugSnapshotConvertible'"),
          oldNode: declaration,
          newNode: declaration.debugSnapshotConvertible
        )
      )
    )
    return []
  }
}

extension DeclSyntaxProtocol {
  fileprivate var debugSnapshotConvertible: some DeclSyntaxProtocol {
    let convertible = AttributeSyntax(
      attributeName: IdentifierTypeSyntax(name: .identifier("DebugSnapshotConvertible")),
      trailingTrivia: .space
    )
    func rebuilt(_ attributes: AttributeListSyntax) -> AttributeListSyntax {
      var filtered = Array(attributes).filter { element in
        guard case .attribute(let attribute) = element else { return true }
        let name = attribute.attributeName.trimmedDescription
        return name != "_ConvertibleCheck" && name != "DebugSnapshotTracked"
      }
      filtered.insert(.attribute(convertible), at: filtered.startIndex)
      return AttributeListSyntax(filtered)
    }
    if let variable = self.as(VariableDeclSyntax.self) {
      let leading = variable.leadingTrivia
      return DeclSyntax(
        variable
          .with(\.attributes, rebuilt(variable.attributes))
          .with(\.leadingTrivia, leading)
      )
    }
    if let enumCase = self.as(EnumCaseDeclSyntax.self) {
      let leading = enumCase.leadingTrivia
      return DeclSyntax(
        enumCase
          .with(\.attributes, rebuilt(enumCase.attributes))
          .with(\.leadingTrivia, leading)
      )
    }
    return DeclSyntax(self)
  }
}
