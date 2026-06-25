import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum InferenceCheckPassMacro: PeerMacro {
  static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    []
  }
}

enum InferenceCheckFailAnyObjectMacro: PeerMacro {
  static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    let message: String
    if declaration.is(EnumCaseDeclSyntax.self) {
      message = "Associated value is a reference type that is not 'DebugSnapshotConvertible'"
    } else {
      message = "Property is a reference type that is not 'DebugSnapshotConvertible'"
    }
    context.diagnose(
      Diagnostic(
        node: Syntax(declaration),
        message: MacroExpansionWarningMessage(message),
        fixIts: [
          .replace(
            message: MacroExpansionFixItMessage(
              "Apply '@DebugSnapshotIgnored' to ignore"
            ),
            oldNode: declaration,
            newNode: declaration.apply("@DebugSnapshotIgnored")
          ),
          .replace(
            message: MacroExpansionFixItMessage(
              "Apply '@DebugSnapshotTracked' to track reference in snapshot"
            ),
            oldNode: declaration,
            newNode: declaration.apply("@DebugSnapshotTracked")
          ),
        ]
      )
    )
    return []
  }
}

enum InferenceCheckFailConvertibleMacro: PeerMacro {
  static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    for node in context.lexicalContext {
      if node.is(StructDeclSyntax.self) { return [] }
      if node.is(ClassDeclSyntax.self) || node.is(EnumDeclSyntax.self) { break }
    }
    let message: String
    if declaration.is(EnumCaseDeclSyntax.self) {
      message = "Associated value must be annotated '@DebugSnapshotConvertible' to snapshot"
    } else {
      message = "Property must be annotated '@DebugSnapshotConvertible' to snapshot"
    }
    context.diagnose(
      Diagnostic(
        node: Syntax(declaration),
        message: MacroExpansionWarningMessage(message),
        fixIts: [
          .replace(
            message: MacroExpansionFixItMessage(
              "Apply '@DebugSnapshotConvertible' to snapshot"
            ),
            oldNode: declaration,
            newNode: declaration.apply("@DebugSnapshotConvertible")
          ),
          .replace(
            message: MacroExpansionFixItMessage(
              "Apply '@DebugSnapshotIgnored' to ignore"
            ),
            oldNode: declaration,
            newNode: declaration.apply("@DebugSnapshotIgnored")
          ),
          .replace(
            message: MacroExpansionFixItMessage(
              "Apply '@DebugSnapshotTracked' to track reference in snapshot"
            ),
            oldNode: declaration,
            newNode: declaration.apply("@DebugSnapshotTracked")
          ),
        ]
      )
    )
    return []
  }
}

extension DeclSyntaxProtocol {
  fileprivate func apply(_ attribute: AttributeSyntax) -> some DeclSyntaxProtocol {
    let attribute = attribute.with(\.trailingTrivia, .space)
    func rebuilt(_ attributes: AttributeListSyntax) -> AttributeListSyntax {
      var filtered = Array(attributes).filter { element in
        guard case .attribute(let attribute) = element else { return true }
        let name = attribute.attributeName.trimmedDescription
        return name != "_InferenceCheck" && name != "DebugSnapshotTracked"
      }
      filtered.insert(.attribute(attribute), at: filtered.startIndex)
      return AttributeListSyntax(filtered)
    }
    if let variable = self.as(VariableDeclSyntax.self) {
      let leading = variable.leadingTrivia
      let variable = variable.with(\.leadingTrivia, [])
      return DeclSyntax(
        variable
          .with(\.attributes, rebuilt(variable.attributes))
          .with(\.leadingTrivia, leading)
      )
    }
    if let enumCase = self.as(EnumCaseDeclSyntax.self) {
      let leading = enumCase.leadingTrivia
      let enumCase = enumCase.with(\.leadingTrivia, [])
      return DeclSyntax(
        enumCase
          .with(\.attributes, rebuilt(enumCase.attributes))
          .with(\.leadingTrivia, leading)
      )
    }
    return DeclSyntax(self)
  }
}
