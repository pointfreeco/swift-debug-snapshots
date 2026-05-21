import DebugSnapshotsMacrosSupport
public import SwiftSyntax
import SwiftSyntaxBuilder
public import SwiftSyntaxMacros

public struct LogChangesMacro: BodyMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
    in context: some MacroExpansionContext
  ) throws -> [CodeBlockItemSyntax] {
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
            of: original, at: .afterLeadingTrivia, filePathMode: .filePath
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
