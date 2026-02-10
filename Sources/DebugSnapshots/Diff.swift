public import CustomDump

/// Prints how an instance of a snapshottable type changes over the course of an operation.
///
/// ```swift
/// try await diff(model) {
///   try await model.login()
/// }
/// // Difference: ...
/// //
/// //     AppModel(
/// //   -   loggedInUser: nil
/// //   +   loggedInUser: User(
/// //   +     name: "Blob"
/// //   +   )
/// //     )
/// //
/// // (Before: -, After: +)
/// ```
///
/// - Parameters:
///   - instance: An instance of a snapshottable type.
///   - operation: An operation that causes `instance` to change.
/// - Returns: The result of the operation.
public func diff<Value, Result, Failure: Error>(
  _ instance: @autoclosure () -> some DebugSnapshotConvertible<Value>,
  operation: () throws(Failure) -> Result
) throws(Failure) -> Result {
  let format = DiffFormat.proportional
  let original = snap(instance())
  let result = try operation()
  let actual = snap(instance())
  if let difference = actual.difference(from: original, format: format) {
    print(
      """
      Difference: ...

      \(difference.indenting(by: 2))

      (Before: \(format.first), After: \(format.second))
      """
    )
  }
  return result
}

/// Prints how an instance of a snapshottable type changes over the course of an operation.
///
/// ```swift
/// try await diff(model) {
///   try await model.login()
/// }
/// // Difference: ...
/// //
/// //     AppModel(
/// //   -   loggedInUser: nil
/// //   +   loggedInUser: User(
/// //   +     name: "Blob"
/// //   +   )
/// //     )
/// //
/// // (Before: -, After: +)
/// ```
///
/// - Parameters:
///   - instance: An instance of a snapshottable type.
///   - operation: An asynchronous operation that causes `instance` to change.
/// - Returns: The result of the operation.
public func diff<Value, Result, Failure: Error>(
  _ instance: @autoclosure () -> some DebugSnapshotConvertible<Value>,
  operation: () async throws(Failure) -> Result
) async throws(Failure) -> Result {
  let format = DiffFormat.proportional
  let original = snap(instance())
  let result = try await operation()
  let actual = snap(instance())
  if let difference = actual.difference(from: original, format: format) {
    print(
      """
      Difference: ...

      \(difference.indenting(by: 2))

      (Before: \(format.first), After: \(format.second))
      """
    )
  }
  return result
}

public protocol _DebugSnapshot {
  func difference(from previous: Self, format: DiffFormat) -> String?
}

extension Array: _DebugSnapshot where Element: _DebugSnapshot {}

extension _DebugSnapshot {
  public func difference(from previous: Self, format: DiffFormat = .default) -> String? {
    prepareDiffTargets(previous, self)
    return CustomDump.diff(previous, self, format: format)
  }
}

extension Optional: _DebugSnapshot where Wrapped: _DebugSnapshot {}
