/// Defines a debug snapshot for a given type.
///
/// When applied to a type, a conformance for ``DebugSnapshotConvertible`` is generated. This
/// includes a nested ``DebugSnapshotConvertible/DebugSnapshot``, which is a simple type devoid of
/// logic and behavior. `DebugSnapshot` represents the data of a model instance captured at a
/// specific moment, _i.e._ when it is passed to the ``snap(_:)`` function (or to functions that
/// invoke ``snap(_:)`` internally, like
/// ``expect(_:_:operation:changes:fileID:filePath:line:column:)``).
///
/// Structs and enums get a nested `DebugSnapshot` struct or enum, while classes get a nested
/// `DebugSnapshot` class, preserving the type's ability to hold circular references.
///
/// See <doc:Customization> to learn how the macro tracks and ignores certain properties, and how
/// to customize which properties are tracked and ignored.
@attached(
  extension,
  conformances: DebugSnapshotConvertible
)
@attached(
  member,
  names: named(DebugSnapshotValue),
  named(DebugSnapshot),
  named(_debugSnapshot)
)
@attached(memberAttribute)
public macro DebugSnapshot() =
  #externalMacro(module: "DebugSnapshotsMacros", type: "DebugSnapshotMacro")

/// Tells `@DebugSnapshot` to track a property.
///
/// ``DebugSnapshot()`` automatically applies this macro to most of a type's stored properties, as
/// long as the property matches the enclosing type's access control, is not underscored, is not a
/// closure, and is not explicitly ignored using ``DebugSnapshotIgnored()``.
///
/// To explicitly snapshot a property that would otherwise be ignored, apply
/// `@DebugSnapshotTracked`:
///
/// ```swift
/// @DebugSnapshotTracked var isLoading: Bool {
///   task != nil
/// }
/// private var task: Task<Void, Never>?
/// ```
@attached(peer)
public macro DebugSnapshotTracked() =
  #externalMacro(module: "DebugSnapshotsMacros", type: "DebugSnapshotTrackedMacro")

/// Tells `@DebugSnapshot` to ignore a property.
///
/// ``DebugSnapshot()`` automatically applies this macro to properties with less access control than
/// the enclosing type, as well as underscored properties, computed properties, and closures.
///
/// To explicitly ignore ``DebugSnapshotTracked()`` properties, apply `@DebugSnapshotIgnored`:
///
/// ```swift
/// @DebugSnapshotIgnored let id: UUID
/// ```
@attached(peer)
public macro DebugSnapshotIgnored() =
  #externalMacro(module: "DebugSnapshotsMacros", type: "DebugSnapshotIgnoredMacro")

/// Tells `@DebugSnapshot` to snapshot a property.
///
/// If a property itself is a ``DebugSnapshotConvertible`` type (including optional convertibles and
/// arrays of convertibles), apply `@DebugSnapshotConvertible` to snapshot it in the corresponding
/// property of the debug snapshot.
///
/// ```swift
/// @DebugSnapshot
/// @MainActor
/// @Observable
/// final class ParentModel {
///   @DebugSnapshotConvertible
///   var child: ChildModel?
///
///   // DebugSnapshot {
///   //   var child: ChildModel.DebugSnapshot?
///   // }
/// }
/// ```
@attached(peer)
public macro DebugSnapshotConvertible() =
  #externalMacro(module: "DebugSnapshotsMacros", type: "DebugSnapshotConvertibleMacro")
