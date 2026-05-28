#if os(macOS)
  import DebugSnapshotsMacrosSupport
  import MacroTesting
  import SnapshotTesting
  import SwiftSyntax
  import SwiftSyntaxMacros
  import Testing

  enum DebugSnapshotWithPropagatedAttributesMacro {}

  extension DebugSnapshotWithPropagatedAttributesMacro: ExtensionMacro {
    static func expansion(
      of node: AttributeSyntax,
      attachedTo declaration: some DeclGroupSyntax,
      providingExtensionsOf type: some TypeSyntaxProtocol,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
      try DebugSnapshotMacro.expansion(
        of: node,
        attachedTo: declaration,
        providingExtensionsOf: type,
        conformingTo: protocols,
        in: context
      )
    }
  }

  extension DebugSnapshotWithPropagatedAttributesMacro: MemberAttributeMacro {
    static func expansion(
      of node: AttributeSyntax,
      attachedTo declaration: some DeclGroupSyntax,
      providingAttributesFor member: some DeclSyntaxProtocol,
      in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
      try DebugSnapshotMacro.expansion(
        of: node,
        attachedTo: declaration,
        providingAttributesFor: member,
        in: context
      )
    }
  }

  extension DebugSnapshotWithPropagatedAttributesMacro: MemberMacro {
    static func expansion(
      of node: AttributeSyntax,
      providingMembersOf declaration: some DeclGroupSyntax,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
      try DebugSnapshotMacro.expansion(
        of: node,
        providingMembersOf: declaration,
        conformingTo: protocols,
        in: context,
        attributeConformanceMapping: [
          "CasePathable": [
            "CasePaths.CasePathable",
            "CasePaths.CasePathIterable",
          ]
        ]
      ) { attributes in
        attributes.filter { element in
          guard let attribute = element.as(AttributeSyntax.self) else { return false }
          let name = attribute.attributeName.trimmedDescription
          let shortName = name.split(separator: ".").last
          return shortName == "CasePathable" || shortName == "dynamicMemberLookup"
        }
      } debugSnapshotAttribute: { _ in
        .tracked
      }
    }
  }

  @Suite(
    .macros(
      [DebugSnapshotWithPropagatedAttributesMacro.self],
      record: .failed
    )
  )
  struct DebugSnapshotMacrosSupportTests {
    @Test func propagatesConfiguredAttributes() {
      assertMacro {
        """
        @DebugSnapshotWithPropagatedAttributes
        @CasePathable
        @dynamicMemberLookup
        enum FeatureAction {
          case increment
        }
        """
      } expansion: {
        """
        @CasePathable
        @dynamicMemberLookup
        enum FeatureAction {
          @DebugSnapshotTracked
          case increment

          @CasePathable
          @dynamicMemberLookup
          public enum DebugSnapshot: CasePaths.CasePathable, CasePaths.CasePathIterable, DebugSnapshots._DebugSnapshotCopyable {
            case increment
            public static func _copySnapshot(_ value: DebugSnapshot, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
              switch value {
              case .increment:
                return .increment
              }
            }
          }

          public static func _debugSnapshot(_ value: FeatureAction, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            switch value {
            case .increment:
              return .increment
            }
          }
        }

        extension FeatureAction: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }
  }
#endif
