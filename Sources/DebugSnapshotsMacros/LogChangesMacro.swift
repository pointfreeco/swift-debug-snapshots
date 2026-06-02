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
    let funcDecl = declaration.as(FunctionDeclSyntax.self)

    if let funcDecl,
      let staticModifier = funcDecl.modifiers.first(where: {
        $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
      })
    {
      context.diagnose(
        Diagnostic(
          node: Syntax(staticModifier),
          message: MacroExpansionErrorMessage(
            "'@LogChanges' can only be applied to instance methods"
          ),
          fixIt: .replace(
            message: MacroExpansionFixItMessage("Remove '@LogChanges'"),
            oldNode: funcDecl.attributes,
            newNode: funcDecl.attributes.filter { element in
              guard case .attribute(let attr) = element else { return true }
              return !attr.isEquivalent(to: node)
            }
          )
        )
      )
      return []
    }

    if let funcDecl,
      funcDecl.isNonisolated,
      let enclosingType = enclosingTypeDecl(in: context),
      hasMainActorAnnotation(enclosingType)
    {
      context.diagnose(
        Diagnostic(
          node: Syntax(node),
          message: MacroExpansionErrorMessage(
            "'@LogChanges' cannot be applied to 'nonisolated' methods of '@MainActor' types"
          ),
          fixIt: .replace(
            message: MacroExpansionFixItMessage("Remove '@LogChanges'"),
            oldNode: funcDecl.attributes,
            newNode: funcDecl.attributes.filter { element in
              guard case .attribute(let attr) = element else { return true }
              return !attr.isEquivalent(to: node)
            }
          )
        )
      )
      return []
    }

    if let enclosingType = enclosingTypeDecl(in: context),
      !enclosingType.attributes.contains(attribute: "@DebugSnapshot")
    {
      let newAttribute = AttributeListSyntax.Element.attribute(
        AttributeSyntax(
          attributeName: IdentifierTypeSyntax(name: .identifier("DebugSnapshot"))
        )
        .with(\.trailingTrivia, .newline + enclosingType.leadingIndentation)
      )
      context.diagnose(
        Diagnostic(
          node: Syntax(node),
          message: MacroExpansionErrorMessage(
            "'@LogChanges' requires the enclosing type to apply '@DebugSnapshot'"
          ),
          fixIt: .replace(
            message: MacroExpansionFixItMessage(
              "Apply '@DebugSnapshot' to '\(enclosingType.name.text)'"
            ),
            oldNode: enclosingType.attributes,
            newNode: AttributeListSyntax(
              [newAttribute] + Array(enclosingType.attributes)
            )
          )
        )
      )
      return []
    }

    guard let body = declaration.body else { return [] }
    let identifier = context.makeUniqueName("snap")
    let calledFlag = context.makeUniqueName("called")
    let processed =
      funcDecl?.signature.returnClause == nil
      ? body.statements
      : body.statements.withExplicitReturns
    let declarationLine =
      funcDecl.flatMap { context.fileIDLine(of: $0.name) }
      ?? context.fileIDLine(of: declaration)
    let closeBraceLine = context.fileIDLine(of: body.rightBrace)
    let deferLocationArgs: String
    switch (declarationLine, closeBraceLine) {
    case (let decl?, let close?):
      deferLocationArgs = ", line: \(calledFlag) ? \(close) : \(decl)"
    case (let decl?, nil):
      deferLocationArgs = ", line: \(decl)"
    case (nil, let close?):
      deferLocationArgs = ", line: \(close)"
    case (nil, nil):
      deferLocationArgs = ""
    }
    var result: [CodeBlockItemSyntax] = [
      #"""
      #if DEBUG
      var \#(identifier) = \#(raw: moduleName).snap(self)
      var \#(calledFlag) = false
      func $logChanges(
      _ message: String = "",
      line: UInt = #line,
      function: StaticString = #function
      ) {
      \#(calledFlag) = true
      let next = \#(raw: moduleName).snap(self)
      \#(raw: moduleName)._logChanges(
      \#(identifier), next, message, line: line, function: function
      )
      \#(identifier) = next
      }
      defer {
      let next = \#(raw: moduleName).snap(self)
      \#(raw: moduleName)._logChanges(
      \#(identifier), next, quiet: \#(calledFlag)\#(raw: deferLocationArgs)
      )
      }
      #else
      @_transparent
      func $logChanges(
      _ message: String = "",
      line: UInt = #line,
      function: StaticString = #function
      ) {}
      #endif
      """#
    ]
    if let firstStatement = body.statements.first,
      let location = context.location(
        of: firstStatement, at: .afterLeadingTrivia, filePathMode: .filePath
      )
    {
      result.append(
        "#sourceLocation(file: \(location.file), line: \(raw: location.line.trimmedDescription))"
      )
      result.append(contentsOf: processed)
      result.append("#sourceLocation()")
    } else {
      result.append(contentsOf: processed)
    }
    return result
  }
}

private func hasMainActorAnnotation(_ declaration: some DeclGroupSyntax) -> Bool {
  declaration.attributes.contains { element in
    guard case .attribute(let attribute) = element else { return false }
    let name = attribute.attributeName.trimmedDescription
    return name.split(separator: ".").last == "MainActor"
  }
}

extension MacroExpansionContext {
  fileprivate func fileIDLine(of node: some SyntaxProtocol) -> String? {
    location(of: node, at: .afterLeadingTrivia, filePathMode: .fileID)?
      .line.trimmedDescription
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
  fileprivate var withExplicitReturns: CodeBlockItemListSyntax {
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
          return clause.with(\.elements, .statements(stmts.withExplicitReturns))
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
