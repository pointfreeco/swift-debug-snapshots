public import SwiftSyntax
public import SwiftSyntaxMacros

public enum LogChangesIgnoredMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [DeclSyntax] {
    []
  }
}
