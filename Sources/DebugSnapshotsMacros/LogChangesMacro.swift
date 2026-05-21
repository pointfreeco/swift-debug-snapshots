import DebugSnapshotsMacrosSupport
import SwiftDiagnostics
public import SwiftSyntax
import SwiftSyntaxBuilder
public import SwiftSyntaxMacros

public struct LogChangesMacro: BodyMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
    in context: some MacroExpansionContext
  ) throws -> [CodeBlockItemSyntax] {
    if let funcDecl = declaration.as(FunctionDeclSyntax.self),
      let staticModifier = funcDecl.modifiers.first(where: {
        $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
      })
    {
      let newAttributes = funcDecl.attributes.filter { element in
        guard case .attribute(let attr) = element else { return true }
        return attr.attributeName.trimmedDescription
          != node.attributeName.trimmedDescription
      }
      context.diagnose(
        Diagnostic(
          node: Syntax(staticModifier),
          message: MacroExpansionErrorMessage(
            "'@_LogChanges' can only be applied to instance methods"
          ),
          fixIt: FixIt(
            message: MacroExpansionFixItMessage("Remove '@_LogChanges'"),
            changes: [
              .replace(
                oldNode: Syntax(funcDecl.attributes),
                newNode: Syntax(newAttributes)
              )
            ]
          )
        )
      )
      return []
    }

    if let enclosingType = enclosingTypeDecl(in: context),
      !enclosingType.hasDebugSnapshotAttribute
    {
      let newAttribute = AttributeListSyntax.Element.attribute(
        AttributeSyntax(
          attributeName: IdentifierTypeSyntax(name: .identifier("DebugSnapshot"))
        )
        .with(\.trailingTrivia, .newline + enclosingType.leadingIndentation)
      )
      let newAttributes = AttributeListSyntax(
        [newAttribute] + Array(enclosingType.attributes)
      )
      context.diagnose(
        Diagnostic(
          node: Syntax(node),
          message: MacroExpansionErrorMessage(
            "'@_LogChanges' requires the enclosing type to apply '@DebugSnapshot'"
          ),
          fixIt: FixIt(
            message: MacroExpansionFixItMessage(
              "Apply '@DebugSnapshot' to '\(enclosingType.name.text)'"
            ),
            changes: [
              .replace(
                oldNode: Syntax(enclosingType.attributes),
                newNode: Syntax(newAttributes)
              )
            ]
          )
        )
      )
      return []
    }

    guard let body = declaration.body else { return [] }
    let identifier = context.makeUniqueName("snap")
    let returnsValue =
      declaration.as(FunctionDeclSyntax.self)?.signature.returnClause != nil
    let processed =
      returnsValue
      ? body.statements.withImplicitReturns
      : body.statements
    let relocated: [CodeBlockItemSyntax] = zip(body.statements, processed)
      .flatMap { original, item -> [CodeBlockItemSyntax] in
        guard
          let location = context.location(
            of: original,
            at: .afterLeadingTrivia,
            filePathMode: .filePath
          ),
          let lineLiteral = location.line.as(IntegerLiteralExprSyntax.self),
          let line = Int(lineLiteral.literal.text)
        else {
          return [item]
        }
        return Array(
          CodeBlockItemListSyntax {
            "#sourceLocation(file: \(location.file), line: \(raw: line))"
            item.trimmed(matching: \.isNewline)
            "#sourceLocation()"
          }
        )
      }
    return [
      #"""
      #if DEBUG
      let \#(identifier) = \#(raw: moduleName).snap(self)
      defer {
      \#(raw: moduleName)._logChanges(\#(identifier), \#(raw: moduleName).snap(self))
      }
      #endif
      """#
    ] + relocated
  }
}

private func enclosingTypeDecl(
  in context: some MacroExpansionContext
) -> (any DeclGroupSyntax & NamedDeclSyntax)? {
  for syntax in context.lexicalContext {
    if let syntax = syntax.as(ClassDeclSyntax.self) { return syntax }
    if let syntax = syntax.as(StructDeclSyntax.self) { return syntax }
    if let syntax = syntax.as(EnumDeclSyntax.self) { return syntax }
  }
  return nil
}

extension DeclGroupSyntax {
  fileprivate var hasDebugSnapshotAttribute: Bool {
    let target: AttributeSyntax = "@DebugSnapshot"
    return attributes.contains { element in
      guard case .attribute(let attr) = element else { return false }
      return attr.isEquivalent(to: target)
    }
  }

  fileprivate var leadingIndentation: Trivia {
    var indent: [TriviaPiece] = []
    for piece in leadingTrivia.reversed() {
      switch piece {
      case .newlines, .carriageReturns, .carriageReturnLineFeeds:
        return Trivia(pieces: indent)
      case .spaces, .tabs:
        indent.insert(piece, at: 0)
      default:
        continue
      }
    }
    return Trivia(pieces: indent)
  }
}

extension CodeBlockItemListSyntax {
  fileprivate var withImplicitReturns: CodeBlockItemListSyntax {
    guard count == 1, let item = first else { return self }
    switch item.item {
    case .expr(let expr):
      let returnStmt = ReturnStmtSyntax(
        returnKeyword: .keyword(.return, trailingTrivia: .space),
        expression: expr.trimmed
      )
      return CodeBlockItemListSyntax([
        item.with(\.item, .stmt(StmtSyntax(returnStmt)))
      ])
    case .decl(let decl):
      guard let ifConfig = decl.as(IfConfigDeclSyntax.self) else { return self }
      let newClauses = IfConfigClauseListSyntax(
        ifConfig.clauses.map { clause in
          guard case .statements(let stmts)? = clause.elements else { return clause }
          return clause.with(\.elements, .statements(stmts.withImplicitReturns))
        }
      )
      return CodeBlockItemListSyntax([
        item.with(\.item, .decl(DeclSyntax(ifConfig.with(\.clauses, newClauses))))
      ])
    case .stmt:
      return self
    }
  }
}
