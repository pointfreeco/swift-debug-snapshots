import DebugSnapshotsMacrosSupport
public import SwiftSyntax
public import SwiftSyntaxMacros

public enum DebugSnapshotMacro {}

extension DebugSnapshotMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    try DebugSnapshotsMacrosSupport.DebugSnapshotMacro.expansion(
      of: node,
      attachedTo: declaration,
      providingExtensionsOf: type,
      conformingTo: protocols,
      in: context
    )
  }
}

extension DebugSnapshotMacro: MemberAttributeMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingAttributesFor member: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AttributeSyntax] {
    try DebugSnapshotsMacrosSupport.DebugSnapshotMacro.expansion(
      of: node,
      attachedTo: declaration,
      providingAttributesFor: member,
      in: context
    )
  }
}

extension DebugSnapshotMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    try DebugSnapshotsMacrosSupport.DebugSnapshotMacro.expansion(
      of: node,
      providingMembersOf: declaration,
      conformingTo: protocols,
      in: context
    )
  }
}
