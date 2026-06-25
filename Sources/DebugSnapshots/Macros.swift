/// Defines a debug snapshot for a given type.
///
/// When applied to a type, a conformance for ``DebugSnapshotConvertible`` is generated. This
/// includes a nested ``DebugSnapshotConvertible/DebugSnapshot``, which is a simple type devoid of
/// logic and behavior. `DebugSnapshot` represents the data of a model instance captured at a
/// specific moment, _i.e._ when it is passed to the ``snap(_:)`` function (or in macros or
/// functions that invoke ``snap(_:)`` internally, like ``LogChanges()`` and
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
  named(_debugSnapshot),
  named(_logChanges)
)
@attached(memberAttribute)
public macro DebugSnapshot(_ options: DebugSnapshotOptions...) =
  #externalMacro(module: "DebugSnapshotsMacros", type: "DebugSnapshotMacro")

/// Options that customize the behavior of ``DebugSnapshot(_:)``.
public struct DebugSnapshotOptions: Sendable {
  /// Applies ``LogChanges()`` to every instance method declared directly on the type.
  ///
  /// Change logging is compiled only in debug builds. In release builds, this option does nothing.
  public static let logChanges = DebugSnapshotOptions()
}

/// Tells `@DebugSnapshot` to track a property.
///
/// ``DebugSnapshot(_:)`` automatically applies this macro to most of a type's stored properties, as
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
/// ``DebugSnapshot(_:)`` automatically applies this macro to properties with less access control than
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

@attached(peer)
public macro _InferenceCheck<T>(_ type: T.Type) =
  #externalMacro(module: "DebugSnapshotsMacros", type: "InferenceCheckPassMacro")

@attached(peer)
public macro _InferenceCheck<T: AnyObject>(_ type: T.Type) =
  #externalMacro(module: "DebugSnapshotsMacros", type: "InferenceCheckFailAnyObjectMacro")

@attached(peer)
public macro _InferenceCheck<T: DebugSnapshotConvertible>(_ type: T.Type) =
  #externalMacro(module: "DebugSnapshotsMacros", type: "InferenceCheckFailConvertibleMacro")

@attached(peer)
public macro _InferenceCheck<T: DebugSnapshotConvertible & AnyObject>(_ type: T.Type) =
  #externalMacro(module: "DebugSnapshotsMacros", type: "InferenceCheckFailConvertibleMacro")

/// Add change-logging to a method of a snapshottable type.
///
/// This macro will capture a snapshot of your model at the beginning of your method and again
/// at the end, and then log a concise diff of what changed (using an `os.Logger` with subsystem
/// "DebugSnapshots"). The macro can be applied to any method of a `@DebugSnapshot` type, or all
/// methods can be logged by using the ``DebugSnapshotOptions/logChanges`` option when specifying
/// `@DebugSnapshot`.
///
/// Change logging is compiled only in debug builds. In release builds, this macro does nothing.
///
/// If you want to print a snapshot diff at multiple points in a method, you can invoke
/// `$logChanges()` at any time:
///
/// ```swift
/// func refreshButtonTapped() async {
///   data = cache.fetch()
///   $logChanges("cache fetch")
///   data = await client.fetch()
/// }
/// ```
///
/// This will log the changes after the `data` assignment, and then again at the end of the method.
///
/// See <doc:LoggingChanges> for more information.
@attached(body)
public macro LogChanges() = #externalMacro(module: "DebugSnapshotsMacros", type: "LogChangesMacro")

/// Disables change logging of a method.
///
/// Useful when providing the ``DebugSnapshotOptions/logChanges`` option to ``DebugSnapshot(_:)``,
/// which automatically applies ``LogChanges()`` to all methods.
@attached(peer)
public macro LogChangesIgnored() =
  #externalMacro(module: "DebugSnapshotsMacros", type: "LogChangesIgnoredMacro")
