import SwiftSyntax
import SwiftSyntaxMacros

public enum DebugSnapshotTrackedMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [DeclSyntax] {
    []
  }
}
