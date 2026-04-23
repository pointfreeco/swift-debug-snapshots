#if os(macOS)
  import DebugSnapshotsMacros
  import MacroTesting
  import Testing

  @Suite(
    .macros(
      [DebugSnapshotMacro.self],
      record: .failed
    )
  )
  struct DebugSnapshotsMacroTests {
    @Test func basics() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel {
          private var count: Int
          var title: String
          var onChange: (Int) -> Void
          @DebugSnapshotIgnored var ignored: UUID

          init(count: Int, title: String, onChange: @escaping (Int) -> Void, ignored: UUID) {
            self.count = count
            self.title = title
            self.onChange = onChange
            self.ignored = ignored
          }
        }
        """
      } expansion: {
        """
        final class FeatureModel {
          @DebugSnapshotIgnored
          private var count: Int
          @DebugSnapshotTracked
          var title: String
          @DebugSnapshotIgnored
          var onChange: (Int) -> Void
          @DebugSnapshotIgnored var ignored: UUID

          init(count: Int, title: String, onChange: @escaping (Int) -> Void, ignored: UUID) {
            self.count = count
            self.title = title
            self.onChange = onChange
            self.ignored = ignored
          }

          public struct DebugSnapshotValue {
            public var title: String
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(title: String) {
              self._snapshot = DebugSnapshotValue(title: title)
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot(title: value.title)
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func trackedComputedProperty() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel {
          @DebugSnapshotTracked
          var doubledCount: Int {
            count * 2
          }
          var count: Int

          init(count: Int) {
            self.count = count
          }
        }
        """
      } expansion: {
        """
        final class FeatureModel {
          @DebugSnapshotTracked
          var doubledCount: Int {
            count * 2
          }
          @DebugSnapshotTracked
          var count: Int

          init(count: Int) {
            self.count = count
          }

          public struct DebugSnapshotValue {
            public var doubledCount: Int
            public var count: Int
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(doubledCount: Int, count: Int) {
              self._snapshot = DebugSnapshotValue(doubledCount: doubledCount, count: count)
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot(doubledCount: value.doubledCount, count: value.count)
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func trackedPrivateProperty() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel {
          @DebugSnapshotTracked private var count: Int
          private var title: String

          init(count: Int, title: String) {
            self.count = count
            self.title = title
          }
        }
        """
      } expansion: {
        """
        final class FeatureModel {
          @DebugSnapshotTracked private var count: Int
          @DebugSnapshotIgnored
          private var title: String

          init(count: Int, title: String) {
            self.count = count
            self.title = title
          }

          public struct DebugSnapshotValue {
            public var count: Int
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(count: Int) {
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot(count: value.count)
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func underscoredPropertyIgnoredByDefault() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel {
          var count: Int
          var _cache: Int

          init(count: Int, _cache: Int) {
            self.count = count
            self._cache = _cache
          }
        }
        """
      } expansion: {
        """
        final class FeatureModel {
          @DebugSnapshotTracked
          var count: Int
          @DebugSnapshotIgnored
          var _cache: Int

          init(count: Int, _cache: Int) {
            self.count = count
            self._cache = _cache
          }

          public struct DebugSnapshotValue {
            public var count: Int
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(count: Int) {
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot(count: value.count)
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func mainActor() {
      assertMacro {
        """
        @MainActor
        @DebugSnapshot
        final class FeatureModel {
          var count: Int

          init(count: Int) {
            self.count = count
          }
        }
        """
      } expansion: {
        """
        @MainActor
        final class FeatureModel {
          @DebugSnapshotTracked
          var count: Int

          init(count: Int) {
            self.count = count
          }

          public struct DebugSnapshotValue {
            public var count: Int
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(count: Int) {
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot(count: value.count)
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            return snapshot
          }
        }

        extension FeatureModel: @MainActor DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func alreadyConforms() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel: DebugSnapshotConvertible {
          var count: Int

          init(count: Int) {
            self.count = count
          }
        }
        """
      } expansion: {
        """
        final class FeatureModel: DebugSnapshotConvertible {
          @DebugSnapshotTracked
          var count: Int

          init(count: Int) {
            self.count = count
          }

          public struct DebugSnapshotValue {
            public var count: Int
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(count: Int) {
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot(count: value.count)
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            return snapshot
          }
        }
        """
      }
    }

    @Test func alreadyConformsMainActor() {
      assertMacro {
        """
        @DebugSnapshot
        @MainActor
        final class FeatureModel: @MainActor DebugSnapshotConvertible {
          var count: Int

          init(count: Int) {
            self.count = count
          }
        }
        """
      } expansion: {
        """
        @MainActor
        final class FeatureModel: @MainActor DebugSnapshotConvertible {
          @DebugSnapshotTracked
          var count: Int

          init(count: Int) {
            self.count = count
          }

          public struct DebugSnapshotValue {
            public var count: Int
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(count: Int) {
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot(count: value.count)
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            return snapshot
          }
        }
        """
      }
    }

    @Test func emptyClass() {
      assertMacro {
        """
        @DebugSnapshot
        final class EmptyModel {
          init() {}
        }
        """
      } expansion: {
        """
        final class EmptyModel {
          init() {}

          public struct DebugSnapshotValue {

          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init() {
              self._snapshot = DebugSnapshotValue()
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

          public static func _debugSnapshot(_ value: EmptyModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot()
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            return snapshot
          }
        }

        extension EmptyModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func privateTypeUsesFileprivateMembers() {
      assertMacro {
        """
        @DebugSnapshot
        private final class FeatureModel {
          var count: Int

          init(count: Int) {
            self.count = count
          }
        }
        """
      } expansion: {
        """
        private final class FeatureModel {
          @DebugSnapshotTracked
          var count: Int

          init(count: Int) {
            self.count = count
          }

          public struct DebugSnapshotValue {
            public var count: Int
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(count: Int) {
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot(count: value.count)
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func privateContainerUsesFileprivateMembers() {
      assertMacro {
        """
        private struct Parent {
          @DebugSnapshot
          final class FeatureModel {
            var count: Int

            init(count: Int) {
              self.count = count
            }
          }
        }
        """
      } expansion: {
        """
        private struct Parent {
          final class FeatureModel {
            @DebugSnapshotTracked
            var count: Int

            init(count: Int) {
              self.count = count
            }

            public struct DebugSnapshotValue {
              public var count: Int
            }

            @dynamicMemberLookup
            public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
              public var _snapshot: DebugSnapshotValue
              public var _originIdentifier: ObjectIdentifier?
              public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
              public init(count: Int) {
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

            public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
              if let existing: DebugSnapshot = visitor.lookup(value) {
                return existing
              }
              let snapshot = DebugSnapshot(count: value.count)
              snapshot._originIdentifier = ObjectIdentifier(value)
              visitor.register(value, snapshot: snapshot)
              return snapshot
            }
          }
        }

        extension Parent.FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func defaultLiteral() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel {
          var count = 0
        }
        """
      } expansion: {
        """
        final class FeatureModel {
          @DebugSnapshotTracked
          var count = 0

          public struct DebugSnapshotValue {
            public var count = 0
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(count: _ = 0) {
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot(count: value.count)
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func DebugSnapshotsProperty() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel {
          @DebugSnapshotConvertible var child: Child
          var count: Int

          init(child: Child, count: Int) {
            self.child = child
            self.count = count
          }
        }
        """
      } expansion: {
        """
        final class FeatureModel {
          @DebugSnapshotConvertible var child: Child
          @DebugSnapshotTracked
          var count: Int

          init(child: Child, count: Int) {
            self.child = child
            self.count = count
          }

          public struct DebugSnapshotValue {
            public var child: Child.DebugSnapshot
            public var count: Int
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(child: Child.DebugSnapshot, count: Int) {
              self._snapshot = DebugSnapshotValue(child: child, count: count)
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot(count: value.count)
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            snapshot.child = DebugSnapshots._debugSnapshot(value.child, visitor: &visitor)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func DebugSnapshotsOptionalConvertibleProperty() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel {
          @DebugSnapshotConvertible var child: Child?
        }
        """
      } expansion: {
        """
        final class FeatureModel {
          @DebugSnapshotConvertible var child: Child?

          public struct DebugSnapshotValue {
            public var child: Child.DebugSnapshot?
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(child: Child.DebugSnapshot? = nil) {
              self._snapshot = DebugSnapshotValue(child: child)
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot()
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            snapshot.child = DebugSnapshots._debugSnapshot(value.child, visitor: &visitor)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func DebugSnapshotsConvertiblePrivateProperty() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel {
          @DebugSnapshotConvertible private var child: Child
          private var count: Int

          init(child: Child, count: Int) {
            self.child = child
            self.count = count
          }
        }
        """
      } expansion: {
        """
        final class FeatureModel {
          @DebugSnapshotConvertible private var child: Child
          @DebugSnapshotIgnored
          private var count: Int

          init(child: Child, count: Int) {
            self.child = child
            self.count = count
          }

          public struct DebugSnapshotValue {
            public var child: Child.DebugSnapshot
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(child: Child.DebugSnapshot) {
              self._snapshot = DebugSnapshotValue(child: child)
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot()
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            snapshot.child = DebugSnapshots._debugSnapshot(value.child, visitor: &visitor)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func DebugSnapshotsValueInheritsSendableNotHashable() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel: Hashable, Sendable {
          var count: Int

          init(count: Int) {
            self.count = count
          }
        }
        """
      } expansion: {
        """
        final class FeatureModel: Hashable, Sendable {
          @DebugSnapshotTracked
          var count: Int

          init(count: Int) {
            self.count = count
          }

          public struct DebugSnapshotValue: Sendable {
            public var count: Int
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(count: Int) {
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot(count: value.count)
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func DebugSnapshotsValueInheritsSendableOnly() {
      assertMacro {
        """
        @DebugSnapshot
        struct FeatureModel: Sendable {
          var count: Int
        }
        """
      } expansion: {
        """
        struct FeatureModel: Sendable {
          @DebugSnapshotTracked
          var count: Int

          public struct DebugSnapshot: Sendable {
            public var count: Int
          }

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            DebugSnapshot(count: value.count)
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func DebugSnapshotsValueInheritsUncheckedSendable() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel: @unchecked Sendable {
          var count: Int
        }
        """
      } expansion: {
        """
        final class FeatureModel: @unchecked Sendable {
          @DebugSnapshotTracked
          var count: Int

          public struct DebugSnapshotValue: @unchecked Sendable {
            public var count: Int
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(count: Int) {
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot(count: value.count)
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func DebugSnapshotsValueInheritsIdentifiableWhenIDIncluded() {
      assertMacro {
        """
        @DebugSnapshot
        struct FeatureModel: Identifiable {
          var id: UUID
          var count: Int
        }
        """
      } expansion: {
        """
        struct FeatureModel: Identifiable {
          @DebugSnapshotTracked
          var id: UUID
          @DebugSnapshotTracked
          var count: Int

          public struct DebugSnapshot: Identifiable {
            public var id: UUID
            public var count: Int
          }

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            DebugSnapshot(id: value.id, count: value.count)
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func DebugSnapshotsValueDoesNotInheritIdentifiableWhenIDExcluded() {
      assertMacro {
        """
        @DebugSnapshot
        struct FeatureModel: Identifiable {
          @DebugSnapshotIgnored var id: UUID
          var count: Int
        }
        """
      } expansion: {
        """
        struct FeatureModel: Identifiable {
          @DebugSnapshotIgnored var id: UUID
          @DebugSnapshotTracked
          var count: Int

          public struct DebugSnapshot {
            public var count: Int
          }

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            DebugSnapshot(count: value.count)
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func DebugSnapshotsPropertyInferredTypeFromInitializer() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel {
          @DebugSnapshotConvertible var child = Child()
        }
        """
      } expansion: {
        """
        final class FeatureModel {
          @DebugSnapshotConvertible var child = Child()

          public struct DebugSnapshotValue {
            public var child = DebugSnapshots.snap(Child())
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(child: _ = DebugSnapshots.snap(Child())) {
              self._snapshot = DebugSnapshotValue(child: child)
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot()
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            snapshot.child = DebugSnapshots._debugSnapshot(value.child, visitor: &visitor)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func DebugSnapshotsPropertyInitializerWithExplicitType() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel {
          @DebugSnapshotConvertible var child: Child = Child()
        }
        """
      } expansion: {
        """
        final class FeatureModel {
          @DebugSnapshotConvertible var child: Child = Child()

          public struct DebugSnapshotValue {
            public var child: Child.DebugSnapshot = DebugSnapshots.snap(Child())
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(child: Child.DebugSnapshot = DebugSnapshots.snap(Child())) {
              self._snapshot = DebugSnapshotValue(child: child)
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot()
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            snapshot.child = DebugSnapshots._debugSnapshot(value.child, visitor: &visitor)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func DebugSnapshotsPropertyInitializerRewritesSelf() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel {
          @DebugSnapshotConvertible var child: Child = Self.makeChild()

          static func makeChild() -> Child {
            Child()
          }
        }
        """
      } expansion: {
        """
        final class FeatureModel {
          @DebugSnapshotConvertible var child: Child = Self.makeChild()

          static func makeChild() -> Child {
            Child()
          }

          public struct DebugSnapshotValue {
            public var child: Child.DebugSnapshot = DebugSnapshots.snap(FeatureModel.makeChild())
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(child: Child.DebugSnapshot = DebugSnapshots.snap(FeatureModel.makeChild())) {
              self._snapshot = DebugSnapshotValue(child: child)
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot()
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            snapshot.child = DebugSnapshots._debugSnapshot(value.child, visitor: &visitor)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func DebugSnapshotsPropertyInitializerStaticShorthand() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel {
          @DebugSnapshotConvertible var child: Child = .make()
        }
        """
      } expansion: {
        """
        final class FeatureModel {
          @DebugSnapshotConvertible var child: Child = .make()

          public struct DebugSnapshotValue {
            public var child: Child.DebugSnapshot = DebugSnapshots.snap(Child.make())
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(child: Child.DebugSnapshot = DebugSnapshots.snap(Child.make())) {
              self._snapshot = DebugSnapshotValue(child: child)
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot()
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            snapshot.child = DebugSnapshots._debugSnapshot(value.child, visitor: &visitor)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func DebugSnapshotsPropertyInitializerStaticShorthandOptional() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel {
          @DebugSnapshotConvertible var child: Child? = .make()
        }
        """
      } expansion: {
        """
        final class FeatureModel {
          @DebugSnapshotConvertible var child: Child? = .make()

          public struct DebugSnapshotValue {
            public var child: Child.DebugSnapshot? = DebugSnapshots.snap(Child.make())
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(child: Child.DebugSnapshot? = nil) {
              self._snapshot = DebugSnapshotValue(child: child)
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot()
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            snapshot.child = DebugSnapshots._debugSnapshot(value.child, visitor: &visitor)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func DebugSnapshotsPropertyInitializerStaticShorthandDoubleOptional() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel {
          @DebugSnapshotConvertible var child: Child?? = .make()
        }
        """
      } expansion: {
        """
        final class FeatureModel {
          @DebugSnapshotConvertible var child: Child?? = .make()

          public struct DebugSnapshotValue {
            public var child: Child.DebugSnapshot?? = DebugSnapshots.snap(Child.make())
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(child: Child.DebugSnapshot?? = nil) {
              self._snapshot = DebugSnapshotValue(child: child)
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot()
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            snapshot.child = DebugSnapshots._debugSnapshot(value.child, visitor: &visitor)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func DebugSnapshotsPropertyInitializerRewritesNestedSelfTypeReferences() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel {
          @DebugSnapshotConvertible var child: Child = Factory<Self>.make()
        }
        """
      } expansion: {
        """
        final class FeatureModel {
          @DebugSnapshotConvertible var child: Child = Factory<Self>.make()

          public struct DebugSnapshotValue {
            public var child: Child.DebugSnapshot = DebugSnapshots.snap(Factory<FeatureModel>.make())
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(child: Child.DebugSnapshot = DebugSnapshots.snap(Factory<FeatureModel>.make())) {
              self._snapshot = DebugSnapshotValue(child: child)
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot()
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            snapshot.child = DebugSnapshots._debugSnapshot(value.child, visitor: &visitor)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func DebugSnapshotsPropertyInitializerNestedImplicitMemberUnchanged() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel {
          @DebugSnapshotConvertible var child: ChildContainer = ChildContainer(child: .make())
        }
        """
      } expansion: {
        """
        final class FeatureModel {
          @DebugSnapshotConvertible var child: ChildContainer = ChildContainer(child: .make())

          public struct DebugSnapshotValue {
            public var child: ChildContainer.DebugSnapshot = DebugSnapshots.snap(ChildContainer(child: .make()))
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(child: ChildContainer.DebugSnapshot = DebugSnapshots.snap(ChildContainer(child: .make()))) {
              self._snapshot = DebugSnapshotValue(child: child)
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot()
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            snapshot.child = DebugSnapshots._debugSnapshot(value.child, visitor: &visitor)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func DebugSnapshotsPropertyInitializerClosureInvocationRewritesSelf() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel {
          @DebugSnapshotConvertible var child = { Self.makeChild() }()

          static func makeChild() -> Child {
            Child()
          }
        }
        """
      } expansion: {
        """
        final class FeatureModel {
          @DebugSnapshotConvertible var child = { Self.makeChild() }()

          static func makeChild() -> Child {
            Child()
          }

          public struct DebugSnapshotValue {
            public var child = DebugSnapshots.snap({
                FeatureModel.makeChild()
              }())
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(child: _ = DebugSnapshots.snap({
                  FeatureModel.makeChild()
                }())) {
              self._snapshot = DebugSnapshotValue(child: child)
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot()
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            snapshot.child = DebugSnapshots._debugSnapshot(value.child, visitor: &visitor)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func enumBasics() {
      assertMacro {
        """
        @DebugSnapshot
        enum FeatureAction {
          case increment
          @DebugSnapshotConvertible
          case decrement(Bar)
          case update(Int, String)
        }
        """
      } expansion: {
        """
        enum FeatureAction {
          @DebugSnapshotTracked
          case increment
          @DebugSnapshotConvertible
          case decrement(Bar)
          @DebugSnapshotTracked
          case update(Int, String)

          public enum DebugSnapshot {
            case increment
            case decrement(Bar.DebugSnapshot)
            case update(Int, String)
          }

          public static func _debugSnapshot(_ value: FeatureAction, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            switch value {
            case .increment:
              return .increment
            case .decrement(let v1):
              return .decrement(DebugSnapshots._debugSnapshot(v1, visitor: &visitor))
            case .update(let v1, let v2):
              return .update(v1, v2)
            }
          }
        }

        extension FeatureAction: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func enumWithOptionalPayloadMapsAssociatedValue() {
      assertMacro {
        """
        @DebugSnapshot
        enum FeatureAction {
          @DebugSnapshotConvertible
          case decrement(Bar?)
          case increment
        }
        """
      } expansion: {
        """
        enum FeatureAction {
          @DebugSnapshotConvertible
          case decrement(Bar?)
          @DebugSnapshotTracked
          case increment

          public enum DebugSnapshot {
            case decrement(Bar.DebugSnapshot?)
            case increment
          }

          public static func _debugSnapshot(_ value: FeatureAction, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            switch value {
            case .decrement(let v1):
              return .decrement(DebugSnapshots._debugSnapshot(v1, visitor: &visitor))
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

    @Test func indirectEnumPropagatesToDebugSnapshotType() {
      assertMacro {
        """
        @DebugSnapshot
        indirect enum FeatureAction {
          @DebugSnapshotConvertible
          case next(FeatureAction)
          case done
        }
        """
      } expansion: {
        """
        indirect enum FeatureAction {
          @DebugSnapshotConvertible
          case next(FeatureAction)
          @DebugSnapshotTracked
          case done

          public indirect enum DebugSnapshot {
            case next(FeatureAction.DebugSnapshot)
            case done
          }

          public static func _debugSnapshot(_ value: FeatureAction, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            switch value {
            case .next(let v1):
              return .next(DebugSnapshots._debugSnapshot(v1, visitor: &visitor))
            case .done:
              return .done
            }
          }
        }

        extension FeatureAction: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func indirectCasePropagatesToDebugSnapshotCase() {
      assertMacro {
        """
        @DebugSnapshot
        enum FeatureAction {
          @DebugSnapshotConvertible
          indirect case next(FeatureAction)
          case done
        }
        """
      } expansion: {
        """
        enum FeatureAction {
          @DebugSnapshotConvertible
          indirect case next(FeatureAction)
          @DebugSnapshotTracked
          case done

          public enum DebugSnapshot {
            indirect case next(FeatureAction.DebugSnapshot)
            case done
          }

          public static func _debugSnapshot(_ value: FeatureAction, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            switch value {
            case .next(let v1):
              return .next(DebugSnapshots._debugSnapshot(v1, visitor: &visitor))
            case .done:
              return .done
            }
          }
        }

        extension FeatureAction: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }

    @Test func enumIgnoredCaseDropsPayloadFromSnapshot() {
      assertMacro {
        """
        @DebugSnapshot
        enum FeatureAction {
          @DebugSnapshotIgnored
          case decrement(Int, String)
          case increment
        }
        """
      } expansion: {
        """
        enum FeatureAction {
          @DebugSnapshotIgnored
          case decrement(Int, String)
          @DebugSnapshotTracked
          case increment

          public enum DebugSnapshot {
            case decrement
            case increment
          }

          public static func _debugSnapshot(_ value: FeatureAction, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            switch value {
            case .decrement:
              return .decrement
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

    @Test func missingTypeAnnotation() {
      assertMacro {
        """
        @DebugSnapshot
        final class FeatureModel {
          @FetchAll(Reminder.all) var reminders
        }
        """
      } diagnostics: {
        """
        @DebugSnapshot
        final class FeatureModel {
          @FetchAll(Reminder.all) var reminders
                                      ┬────────
                                      ╰─ 🛑 '@DebugSnapshot' requires explicit type annotations for stored properties.
                                         ✏️ Insert ': <#Type#>'
        }
        """
      } fixes: {
        """
        @DebugSnapshot
        final class FeatureModel {
          @FetchAll(Reminder.all) var reminders: <#Type#>
        }
        """
      } expansion: {
        """
        final class FeatureModel {
          @FetchAll(Reminder.all)
          @DebugSnapshotTracked var reminders: <#Type#>

          public struct DebugSnapshotValue {
            public var reminders: <#Type#>
          }

          @dynamicMemberLookup
          public final class DebugSnapshot: DebugSnapshots._DebugSnapshotObject {
            public var _snapshot: DebugSnapshotValue
            public var _originIdentifier: ObjectIdentifier?
            public var _diffSnapshot: (any DebugSnapshots._DebugSnapshotObject)?
            public init(reminders: <#Type#>) {
              self._snapshot = DebugSnapshotValue(reminders: reminders)
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

          public static func _debugSnapshot(_ value: FeatureModel, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot(reminders: value.reminders)
            snapshot._originIdentifier = ObjectIdentifier(value)
            visitor.register(value, snapshot: snapshot)
            return snapshot
          }
        }

        extension FeatureModel: DebugSnapshots.DebugSnapshotConvertible {
        }
        """
      }
    }
  }
#endif
