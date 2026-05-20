#if os(macOS)
  import DebugSnapshotsMacros
  import MacroTesting
  import SnapshotTesting
  import Testing

  @Suite(
    .macros(
      [
        LogChangesMacro.self,
        DebugSnapshotMacro.self
      ],
      record: .failed
    )
  )
  struct LogChangesMacroTests {
    @Test func basics() {
      assertMacro {
        """
        @DebugSnapshot
        class Model {
          var count = 0
          @LogChanges
          func incrementButtonTapped() {
            count += 1
          }
        }
        """
      } expansion: {
        """
        class Model {
          @DebugSnapshotTracked
          var count = 0
          func incrementButtonTapped() {
            let x = 1
            defer { print(x) }
            count += 1
          }

          public struct DebugSnapshotValue {
            public var count = 0
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(count: Int = 0) {
              self._snapshot = DebugSnapshotValue(count: count)
            }
            public subscript <T>(dynamicMember keyPath: WritableKeyPath<DebugSnapshotValue, T>) -> T {
              get {
                _snapshot[keyPath: keyPath]
              }
              set {
                _snapshot[keyPath: keyPath] = newValue
              }
            }
          }

          public static func _debugSnapshot(_ value: Model, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot(count: value.count)
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            return snapshot
          }
        }

        extension Model: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }
  }
#endif
