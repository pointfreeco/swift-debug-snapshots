#if os(macOS)
  import DebugSnapshotsMacros
  import MacroTesting
  import SnapshotTesting
  import Testing

  @Suite(
    .macros(
      [
        "DebugSnapshot": DebugSnapshotMacro.self,
        "LogChanges": LogChangesMacro.self,
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
            #if DEBUG
            var __macro_local_4snapfMu_ = DebugSnapshots.snap(self)
            var __macro_local_6calledfMu_ = false
            func $logChanges(
              _ message: String = "",
              line: UInt = #line,
              function: StaticString = #function
            ) {
              __macro_local_6calledfMu_ = true
              let next = DebugSnapshots.snap(self)
              DebugSnapshots._logChanges(
                __macro_local_4snapfMu_, next, message, line: line, function: function
              )
              __macro_local_4snapfMu_ = next
            }
            defer {
              let next = DebugSnapshots.snap(self)
              DebugSnapshots._logChanges(
                __macro_local_4snapfMu_, next, quiet: __macro_local_6calledfMu_, line: 7
              )
            }
            #else
            @_transparent
            func $logChanges(
              _ message: String = "",
              line: UInt = #line,
              function: StaticString = #function
            ) {
            }
            #endif
            #sourceLocation(file: "Test.swift", line: 6)
            count += 1
            #sourceLocation()
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

    @Test func staticFunction() {
      assertMacro {
        """
        @DebugSnapshot
        class Model {
          @LogChanges
          static func tick() {}
        }
        """
      } diagnostics: {
        """
        @DebugSnapshot
        class Model {
          @LogChanges
          static func tick() {}
          ┬─────
          ╰─ 🛑 '@LogChanges' can only be applied to instance methods
             ✏️ Remove '@LogChanges'
        }
        """
      } fixes: {
        """
        @DebugSnapshot
        class Model {
          static func tick() {}
        }
        """
      } expansion: {
        """
        class Model {
          static func tick() {}

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

          public static func _debugSnapshot(_ value: Model, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot()
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

    @Test func missingDebugSnapshot() {
      assertMacro {
        """
        class Model {
          var count = 0
          @LogChanges
          func incrementButtonTapped() {
            count += 1
          }
        }
        """
      } diagnostics: {
        """
        class Model {
          var count = 0
          @LogChanges
          ┬──────────
          ╰─ 🛑 '@LogChanges' requires the enclosing type to apply '@DebugSnapshot'
             ✏️ Apply '@DebugSnapshot' to 'Model'
          func incrementButtonTapped() {
            count += 1
          }
        }
        """
      } fixes: {
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
            #if DEBUG
            var __macro_local_4snapfMu_ = DebugSnapshots.snap(self)
            var __macro_local_6calledfMu_ = false
            func $logChanges(
              _ message: String = "",
              line: UInt = #line,
              function: StaticString = #function
            ) {
              __macro_local_6calledfMu_ = true
              let next = DebugSnapshots.snap(self)
              DebugSnapshots._logChanges(
                __macro_local_4snapfMu_, next, message, line: line, function: function
              )
              __macro_local_4snapfMu_ = next
            }
            defer {
              let next = DebugSnapshots.snap(self)
              DebugSnapshots._logChanges(
                __macro_local_4snapfMu_, next, quiet: __macro_local_6calledfMu_, line: 7
              )
            }
            #else
            @_transparent
            func $logChanges(
              _ message: String = "",
              line: UInt = #line,
              function: StaticString = #function
            ) {
            }
            #endif
            #sourceLocation(file: "Test.swift", line: 6)
            count += 1
            #sourceLocation()
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

    @Test func implicitReturnValue() {
      assertMacro {
        """
        @DebugSnapshot
        class Model {
          @LogChanges
          func fetch() async throws -> Int {
            42
          }
        }
        """
      } expansion: {
        """
        class Model {
          func fetch() async throws -> Int {
            #if DEBUG
            var __macro_local_4snapfMu_ = DebugSnapshots.snap(self)
            var __macro_local_6calledfMu_ = false
            func $logChanges(
              _ message: String = "",
              line: UInt = #line,
              function: StaticString = #function
            ) {
              __macro_local_6calledfMu_ = true
              let next = DebugSnapshots.snap(self)
              DebugSnapshots._logChanges(
                __macro_local_4snapfMu_, next, message, line: line, function: function
              )
              __macro_local_4snapfMu_ = next
            }
            defer {
              let next = DebugSnapshots.snap(self)
              DebugSnapshots._logChanges(
                __macro_local_4snapfMu_, next, quiet: __macro_local_6calledfMu_, line: 6
              )
            }
            #else
            @_transparent
            func $logChanges(
              _ message: String = "",
              line: UInt = #line,
              function: StaticString = #function
            ) {
            }
            #endif
            #sourceLocation(file: "Test.swift", line: 5)
            return 42
            #sourceLocation()
          }

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

          public static func _debugSnapshot(_ value: Model, visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> DebugSnapshot {
            if let existing: DebugSnapshot = visitor.lookup(value) {
              return existing
            }
            let snapshot = DebugSnapshot()
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

    @Test func manualLogChangesCall() {
      assertMacro {
        """
        @DebugSnapshot
        class Model {
          var count = 0
          @LogChanges
          func incrementButtonTapped() {
            count += 1
            _$logChanges()
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
            #if DEBUG
            var __macro_local_4snapfMu_ = DebugSnapshots.snap(self)
            var __macro_local_6calledfMu_ = false
            func $logChanges(
              _ message: String = "",
              line: UInt = #line,
              function: StaticString = #function
            ) {
              __macro_local_6calledfMu_ = true
              let next = DebugSnapshots.snap(self)
              DebugSnapshots._logChanges(
                __macro_local_4snapfMu_, next, message, line: line, function: function
              )
              __macro_local_4snapfMu_ = next
            }
            defer {
              let next = DebugSnapshots.snap(self)
              DebugSnapshots._logChanges(
                __macro_local_4snapfMu_, next, quiet: __macro_local_6calledfMu_, line: 9
              )
            }
            #else
            @_transparent
            func $logChanges(
              _ message: String = "",
              line: UInt = #line,
              function: StaticString = #function
            ) {
            }
            #endif
            #sourceLocation(file: "Test.swift", line: 6)
            count += 1
            _$logChanges()
            count += 1
            #sourceLocation()
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

    @Test func logChangesOptionWithManualCall() {
      assertMacro {
        """
        @DebugSnapshot(.logChanges)
        class Model {
          var count = 0
          func incrementButtonTapped() {
            count += 1
            _$logChanges()
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
            #if DEBUG
            var __macro_local_4snapfMu_ = DebugSnapshots.snap(self)
            var __macro_local_6calledfMu_ = false
            func $logChanges(
              _ message: String = "",
              line: UInt = #line,
              function: StaticString = #function
            ) {
              __macro_local_6calledfMu_ = true
              let next = DebugSnapshots.snap(self)
              DebugSnapshots._logChanges(
                __macro_local_4snapfMu_, next, message, line: line, function: function
              )
              __macro_local_4snapfMu_ = next
            }
            defer {
              let next = DebugSnapshots.snap(self)
              DebugSnapshots._logChanges(
                __macro_local_4snapfMu_, next, quiet: __macro_local_6calledfMu_
              )
            }
            #else
            @_transparent
            func $logChanges(
              _ message: String = "",
              line: UInt = #line,
              function: StaticString = #function
            ) {
            }
            #endif
            count += 1
            _$logChanges()
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

    @Test func logChangesOption() {
      assertMacro {
        """
        @DebugSnapshot(.logChanges)
        class Model {
          var count = 0
          func incrementButtonTapped() {
            count += 1
          }
          static func tick() {}
        }
        """
      } expansion: {
        """
        class Model {
          @DebugSnapshotTracked
          var count = 0
          func incrementButtonTapped() {
            #if DEBUG
            var __macro_local_4snapfMu_ = DebugSnapshots.snap(self)
            var __macro_local_6calledfMu_ = false
            func $logChanges(
              _ message: String = "",
              line: UInt = #line,
              function: StaticString = #function
            ) {
              __macro_local_6calledfMu_ = true
              let next = DebugSnapshots.snap(self)
              DebugSnapshots._logChanges(
                __macro_local_4snapfMu_, next, message, line: line, function: function
              )
              __macro_local_4snapfMu_ = next
            }
            defer {
              let next = DebugSnapshots.snap(self)
              DebugSnapshots._logChanges(
                __macro_local_4snapfMu_, next, quiet: __macro_local_6calledfMu_
              )
            }
            #else
            @_transparent
            func $logChanges(
              _ message: String = "",
              line: UInt = #line,
              function: StaticString = #function
            ) {
            }
            #endif
            count += 1
          }
          static func tick() {}

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
