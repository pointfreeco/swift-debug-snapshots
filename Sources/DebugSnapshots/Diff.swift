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
  if let difference = _diff(original, actual, format: format) {
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
  if let difference = _diff(original, actual, format: format) {
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

public func _diff<Value>(
  _ previous: Value,
  _ current: Value,
  format: DiffFormat = .default
) -> String? {
  prepareDiffTargets(previous, current)
  return CustomDump.diff(previous, current, format: format)
}

@available(macOS 11, iOS 14, watchOS 7, tvOS 14, *)
public func _logChanges<Value>(
  _ previous: Value,
  _ current: Value,
  suppressIfUnchanged: Bool = false,
  fileID: StaticString = #fileID,
  line: UInt = #line,
  function: StaticString = #function
) {
  let diff = _diff(previous, current)
  if suppressIfUnchanged && diff == nil { return }
  let string = """
  \(fileID):\(line) \(function):
  \((diff ?? "(No changes)").indenting(by: 2))
  """
  if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil {
    print(string)
  } else {
    logger.log("\(string)")
  }
}

import Foundation
import os
@available(macOS 11, iOS 14, watchOS 7, tvOS 14, *)
private let logger = Logger()

