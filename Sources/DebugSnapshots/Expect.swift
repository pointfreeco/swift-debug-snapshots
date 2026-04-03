import CustomDump
import IssueReporting

/// Expects an instance of a snapshottable type has a given set of changes.
///
/// - Parameters:
///   - instance: An instance of a snapshottable type.
///   - message: An optional description of a failure.
///   - operation: An optional operation that causes `instance` to change. When provided, you must
///     "exhaustively" describe how its snapshot changes. When omitted, you can write a
///     "non-exhaustive" assertion by describing just the fields you want to assert against in the
///     `changes` closure.
///   - updateExpectingResult: A closure that asserts how a snapshot of the model changes by
///     supplying a mutable version of the initial value. This value must be modified to match the
///     final value.
///   - fileID: The file where the expectation occurs.
///   - filePath: The file where the expectation occurs.
///   - line: The line number where the expectation occurs.
///   - column: The column where the expectation occurs.
public func expect<Value>(
  _ instance: @autoclosure () -> some DebugSnapshotConvertible<Value>,
  _ message: @autoclosure () -> String? = nil,
  operation: (() throws -> Void)? = nil,
  changes updateExpectingResult: (inout Value) throws -> Void,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) rethrows {
  let original = snap(instance())
  var expected = snap(instance())
  try operation?()
  try updateExpectingResult(&expected)
  expectHelp(
    original,
    expected,
    snap(instance()),
    isExhaustive: operation != nil,
    message(),
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}

/// Expects an instance of a snapshottable type has a given set of changes.
///
/// - Parameters:
///   - instance: An instance of a snapshottable type.
///   - message: An optional description of a failure.
///   - operation: An asynchronous operation that causes `instance` to change. You must
///     "exhaustively" describe how its snapshot changes in `updateExpectingResult`.
///   - updateExpectingResult: A closure that asserts how a snapshot of the model changes by
///     supplying a mutable version of the initial value. This value must be modified to match the
///     final value.
///   - fileID: The file where the expectation occurs.
///   - filePath: The file where the expectation occurs.
///   - line: The line number where the expectation occurs.
///   - column: The column where the expectation occurs.
@_disfavoredOverload
public func expect<Value>(
  _ instance: @autoclosure () -> some DebugSnapshotConvertible<Value>,
  _ message: @autoclosure () -> String? = nil,
  operation: () async throws -> Void,
  changes updateExpectingResult: (inout Value) throws -> Void,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) async rethrows {
  let original = snap(instance())
  var expected = snap(instance())
  try await operation()
  try updateExpectingResult(&expected)
  expectHelp(
    original,
    expected,
    snap(instance()),
    isExhaustive: true,
    message(),
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}

private func expectHelp<Value>(
  _ original: Value,
  _ expected: Value,
  _ actual: Value,
  isExhaustive: Bool,
  _ message: @autoclosure () -> String?,
  fileID: StaticString,
  filePath: StaticString,
  line: UInt,
  column: UInt
) {
  guard
    !isReflectivelyEqual(
      expected,
      actual,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  else {
    if isExhaustive,
      isReflectivelyEqual(
        original,
        actual,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
    {
      reportIssue(
        """
        Expected changes did not occur\(message().map { " - \($0)" } ?? "")
        """,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
      return
    }
    return
  }
  reportReflectiveDifference(
    expected,
    actual,
    message(),
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}

@_spi(Reflection)
public func isReflectivelyEqual<Value>(
  _ lhs: Value,
  _ rhs: Value,
  fileID: StaticString,
  filePath: StaticString,
  line: UInt,
  column: UInt
) -> Bool {
  var visited: Set<_ObjectPair> = []
  return isReflectivelyEqual(
    lhs,
    rhs,
    path: ["\(Value.self)"],
    visited: &visited,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}

private struct _ObjectPair: Hashable {
  let lhs: ObjectIdentifier
  let rhs: ObjectIdentifier
}

private func isReflectivelyEqual(
  _ lhs: Any,
  _ rhs: Any,
  path: [String],
  visited: inout Set<_ObjectPair>,
  fileID: StaticString,
  filePath: StaticString,
  line: UInt,
  column: UInt
) -> Bool {
  let lhsType = type(of: lhs)
  guard lhsType == type(of: rhs) else { return false }

  if let lhs = lhs as? any Equatable {
    return isEqual(lhs, rhs)
  }

  if lhsType is AnyClass {
    if let lhsSnap = lhs as? any _DebugSnapshotObject,
      let rhsSnap = rhs as? any _DebugSnapshotObject
    {
      let lhsObject = lhsSnap as AnyObject
      let rhsObject = rhsSnap as AnyObject
      if lhsObject === rhsObject { return true }

      let pair = _ObjectPair(
        lhs: ObjectIdentifier(lhsObject),
        rhs: ObjectIdentifier(rhsObject)
      )
      if visited.contains(pair) { return true }
      visited.insert(pair)

      let lhsChildren = Array(lhsSnap.customDumpMirror.children)
      let rhsChildren = Array(rhsSnap.customDumpMirror.children)
      guard lhsChildren.count == rhsChildren.count else { return false }

      for (index, (lhsChild, rhsChild)) in zip(lhsChildren, rhsChildren).enumerated() {
        guard lhsChild.label == rhsChild.label else { return false }
        var childPath = path
        childPath.append(lhsChild.label.map { ".\($0)" } ?? "[\(index)]")
        guard
          isReflectivelyEqual(
            lhsChild.value,
            rhsChild.value,
            path: childPath,
            visited: &visited,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
          )
        else {
          return false
        }
      }
      return true
    } else {
      reportIssue(
        """
        Non-snapshottable reference '\(lhsType)' found at '\(path.joined())'.

        Add '@DebugSnapshot' to the type to generate a snapshottable value:

          @DebugSnapshot class \(lhsType)

        Or make the property private to suppress this failure:

          private var \(path.last?.dropFirst() ?? "_"): \(lhsType)

        Or use '@DebugSnapshotIgnored':

          @DebugSnapshotIgnored var \(path.last?.dropFirst() ?? "_"): \(lhsType)
        """,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
      return false
    }
  }

  let lhsMirror = Mirror(reflecting: lhs)
  let rhsMirror = Mirror(reflecting: rhs)
  let lhsChildren = Array(lhsMirror.children)
  let rhsChildren = Array(rhsMirror.children)

  guard lhsChildren.count == rhsChildren.count else { return false }

  if lhsMirror.displayStyle == .optional || lhsMirror.displayStyle == .enum,
    lhsMirror.children.isEmpty,
    rhsMirror.children.isEmpty
  {
    return true
  }

  if lhsChildren.isEmpty,
    lhsMirror.displayStyle == .collection || lhsMirror.displayStyle == .set
  {
    return true
  }

  guard !lhsChildren.isEmpty else {
    guard path.count > 1 else { return true }
    reportIssue(
      """
      Non-equatable '\(lhsType)' found at '\(path.joined())'.

      Make the property private to suppress this failure:

        private var \(path.last?.dropFirst() ?? "_"): \(lhsType)

      Or use '@DebugSnapshotIgnored':

        @DebugSnapshotIgnored var \(path.last?.dropFirst() ?? "_"): \(lhsType)
      """,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
    return false
  }

  for (index, (lhsChild, rhsChild)) in zip(lhsChildren, rhsChildren).enumerated() {
    guard lhsChild.label == rhsChild.label else { return false }
    var childPath = path
    childPath.append(lhsChild.label.map { ".\($0)" } ?? "[\(index)]")
    guard
      isReflectivelyEqual(
        lhsChild.value,
        rhsChild.value,
        path: childPath,
        visited: &visited,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
    else {
      return false
    }
  }

  return true
}

private func isEqual(_ lhs: any Equatable, _ rhs: Any) -> Bool {
  func open<T: Equatable>(_ lhs: T, _ rhs: Any) -> Bool {
    guard let rhs = rhs as? T else { return false }
    return lhs == rhs
  }
  return open(lhs, rhs)
}

private func reportReflectiveDifference<Value>(
  _ expected: Value,
  _ actual: Value,
  _ message: String?,
  fileID: StaticString,
  filePath: StaticString,
  line: UInt,
  column: UInt
) {
  let format = DiffFormat.proportional
  prepareDiffTargets(expected, actual)
  guard let difference = diff(expected, actual, format: format)
  else {
    reportIssue(
      """
      ("\(expected)") is not equal to ("\(actual)"), but no difference was detected\
      \(message.map { " - \($0)" } ?? "").
      """,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
    return
  }
  reportIssue(
    """
    Expected changes do not match\(message.map { " - \($0)" } ?? ""): ...

    \(difference.indenting(by: 2))

    (Expected: \(format.first), Actual: \(format.second))
    """,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}

func prepareDiffTargets(_ expected: Any, _ actual: Any) {
  var actualObjects: [ObjectIdentifier: any _DebugSnapshotObject] = [:]
  _collectSnapshotObjects(from: actual, into: &actualObjects)
  var visited: Set<ObjectIdentifier> = []
  _setDiffTargets(on: expected, using: actualObjects, visited: &visited)
}

private func _snapshotMirror(_ value: Any) -> Mirror {
  if let object = value as? any _DebugSnapshotObject {
    return object.customDumpMirror
  }
  return Mirror(reflecting: value)
}

private func _collectSnapshotObjects(
  from value: Any,
  into objects: inout [ObjectIdentifier: any _DebugSnapshotObject]
) {
  if let object = value as? any _DebugSnapshotObject,
    let identifier = object._originIdentifier
  {
    guard objects[identifier] == nil else { return }
    objects[identifier] = object
  }
  for (_, child) in _snapshotMirror(value).children {
    _collectSnapshotObjects(from: child, into: &objects)
  }
}

private func _setDiffTargets(
  on value: Any,
  using targets: [ObjectIdentifier: any _DebugSnapshotObject],
  visited: inout Set<ObjectIdentifier>
) {
  if let object = value as? any _DebugSnapshotObject,
    let identifier = object._originIdentifier
  {
    guard !visited.contains(identifier) else { return }
    visited.insert(identifier)
    if let target = targets[identifier] {
      object._diffSnapshot = target
    }
  }
  for (_, child) in _snapshotMirror(value).children {
    _setDiffTargets(on: child, using: targets, visited: &visited)
  }
}
