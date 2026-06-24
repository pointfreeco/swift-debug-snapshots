import DebugSnapshotsMacrosSupport
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MacrosPlugin: CompilerPlugin {
  let providingMacros: [any Macro.Type] = [
    ConvertibleCheckPassMacro.self,
    ConvertibleCheckFailMacro.self,
    DebugSnapshotIgnoredMacro.self,
    DebugSnapshotMacro.self,
    DebugSnapshotConvertibleMacro.self,
    DebugSnapshotTrackedMacro.self,
    LogChangesMacro.self,
    LogChangesIgnoredMacro.self,
  ]
}
