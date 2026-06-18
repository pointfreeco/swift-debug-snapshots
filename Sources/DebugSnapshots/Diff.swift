public import CustomDump
import Foundation

#if canImport(OSLog)
  import OSLog
#endif

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

public func _logChanges<Value>(
  _ previous: Value,
  _ current: Value,
  _ message: String = "",
  quiet: Bool = false,
  fileID: StaticString = #fileID,
  line: UInt = #line,
  function: StaticString = #function
) {
  let diff = _diff(previous, current)
  guard diff != nil || !quiet else { return }
  let string = """
    \(fileID):\(line) \(function):\(message.isEmpty ? "" : " \(message)")
    \((diff ?? "(No changes)").indenting(by: 2))
    """
  if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil {
    print(string)
  } else {
    #if canImport(OSLog)
      if #available(macOS 11, iOS 14, watchOS 7, tvOS 14, *) {
        logger.log("\(string)")
        return
      }
    #endif
    print(string)
  }
}

#if canImport(OSLog)
  @available(macOS 11, iOS 14, watchOS 7, tvOS 14, *)
  private let logger = Logger(subsystem: "DebugSnapshots", category: "LogChanges")
#endif
