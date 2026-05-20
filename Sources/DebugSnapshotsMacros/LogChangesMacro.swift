public import SwiftSyntax
import SwiftSyntaxBuilder
public import SwiftSyntaxMacros

// TODO: handle return statement
public struct LogChangesMacro: BodyMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
    in context: some MacroExpansionContext
  ) throws -> [CodeBlockItemSyntax] {
    let identifier = context.makeUniqueName("snap")
    return [
      #"""
      #if DEBUG
      let \#(identifier) = snap(self)
      defer { 
        _logChanges(\#(identifier), snap(self))
      }
      #endif
      """#,
    ]
    +
    declaration.body!.statements
  }
}
