/// Defines a debug snapshot for a given type.
///
/// When applied to a type, a conformance for ``DebugSnapshotConvertible`` is generated, along with
/// associated snapshot types. Structs and enums get a nested `DebugSnapshot` value type, while
/// classes get a nested `DebugSnapshot` reference wrapper backed by `DebugSnapshotValue`.
/// Instances of these types can be returned from the ``snapshot(_:)`` function when it is handed
/// a ``DebugSnapshotConvertible`` type.
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
/// By default, ``DebugSnapshot()`` ignores properties with more private access control than the
/// type itself, underscored properties, as well as computed properties. To override this behavior,
/// apply `@DebugSnapshotTracked`, instead.
@attached(peer)
public macro DebugSnapshotTracked() =
  #externalMacro(module: "DebugSnapshotsMacros", type: "DebugSnapshotTrackedMacro")

/// Tells `@DebugSnapshot` to ignore a property.
@attached(peer)
public macro DebugSnapshotIgnored() =
  #externalMacro(module: "DebugSnapshotsMacros", type: "DebugSnapshotIgnoredMacro")

/// Tells `@DebugSnapshot` to snapshot a property.
///
/// If a property itself is a ``DebugSnapshotConvertible`` type (including optionals and arrays),
/// apply `@DebugSnapshotConvertible` to snapshot it in the corresponding property of the debug
/// snapshot.
///
/// ```swift
/// @DebugSnapshot
/// @MainActor
/// @Observable
/// final class ParentModel {
///   @DebugSnapshotConvertible
///   var child: ChildModel?
/// }
/// ```
@attached(peer)
public macro DebugSnapshotConvertible() =
  #externalMacro(module: "DebugSnapshotsMacros", type: "DebugSnapshotConvertibleMacro")
