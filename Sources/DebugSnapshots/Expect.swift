import CustomDump
import IssueReporting

/// Expects an instance of a snapshottable type has a given set of changes.
///
/// This function allows you exhaustively assert how a model changes after executing a series of
/// actions:
///
/// ```swift
/// expect(model) {
///   model.incrementButtonTapped()
/// } changes: {
///   $0.count = 1
///   $0.countIsEven = false
/// }
/// ```
///
/// It performs the following steps:
///
/// * Takes a snapshot of the model.
/// * Executes the first trailing closure.
/// * Takes another snapshot of the model.
/// * Passes a mutable version of the first snapshot to the second trailing closure.
///
/// In the second trailing closure you must mutate the previous snapshot to match the current
/// snapshot, otherwise the test will fail. Failures are presented as a nicely formatted diff:
///
/// ```swift, highlight=[1]
/// ❌ expect(model) {
///      model.incrementButtonTapped()
///    } changes: {
///      $0.count = 1
///      $0.countIsEven = true
///    }
/// ```
///
/// > ❌ Issue recorded: Expected changes do not match: ...
/// >
/// > ```diff
/// >     #1 FeatureModel.DebugSnapshot(
/// >       count: 1,
/// > -     countIsEvent: true
/// > +     countIsEvent: false
/// >     )
/// >
/// > (Expected: −, Actual: +)
/// > ```
///
/// - Parameters:
///   - instance: An instance of a snapshottable type.
///   - message: An optional description of a failure.
///   - operation: An operation that causes `instance` to change. When provided, you must
///     "exhaustively" describe how its snapshot changes.
///   - updateExpectingResult: A closure that asserts how a snapshot of the model changes by
///     supplying a mutable version of the initial value. This value must be modified to match the
///     final value.
///   - fileID: The file where the expectation occurs.
///   - filePath: The file where the expectation occurs.
///   - line: The line number where the expectation occurs.
///   - column: The column where the expectation occurs.
public func expect<Value, Result>(
  _ instance: @autoclosure () -> some DebugSnapshotConvertible<Value>,
  _ message: @autoclosure () -> String? = nil,
  operation: () throws -> Result,
  changes updateExpectingResult: (inout Value) throws -> Void,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) rethrows -> Result {
  var expected = snap(instance())
  let result = try operation()
  try updateExpectingResult(&expected)
  expectHelp(
    expected,
    snap(instance()),
    message(),
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
  return result
}

/// Expects an instance of a snapshottable type has a given set of changes.
///
/// Takes a snapshot of the model so that you can assert against it's current state:
///
/// ```swift
/// let model = FeatureModel()
/// expect(model) {
///   $0.count = 1
///   $0.isLoading = false
///   $0.fact = nil
/// }
/// ```
///
/// The argument handed to the trailing closure is the current snap, and so only changes you perform
/// in that closure as taken into consideration for the assertion.
///
/// - Parameters:
///   - instance: An instance of a snapshottable type.
///   - message: An optional description of a failure.
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
  changes updateExpectingResult: (inout Value) throws -> Void,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) rethrows {
  var expected = snap(instance())
  try updateExpectingResult(&expected)
  expectHelp(
    expected,
    snap(instance()),
    message(),
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}

/// Expects an instance of a snapshottable type has a given set of changes.
///
/// See <doc:expect(_:_:operation:changes:fileID:filePath:line:column:)-6w0fd> for more information.
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
public func expect<Value, Result>(
  _ instance: @autoclosure () -> some DebugSnapshotConvertible<Value>,
  _ message: @autoclosure () -> String? = nil,
  operation: () async throws -> Result,
  changes updateExpectingResult: (inout Value) throws -> Void,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) async rethrows -> Result {
  var expected = snap(instance())
  let result = try await operation()
  try updateExpectingResult(&expected)
  expectHelp(
    expected,
    snap(instance()),
    message(),
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
  return result
}

private func expectHelp<Value>(
  _ expected: Value,
  _ actual: Value,
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
    lazy var name = path.last?.dropFirst() ?? "_"
    reportIssue(
      """
      Non-equatable '\(lhsType)' found at '\(path.joined())'.

      Make the property private to suppress this failure:

        private var \(name): \(lhsType)

      Or use '@DebugSnapshotIgnored':

        @DebugSnapshotIgnored var \(name): \(lhsType)
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

private func isEqual<T: Equatable>(_ lhs: T, _ rhs: Any) -> Bool {
  guard let rhs = rhs as? T else { return false }
  return lhs == rhs
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
  guard let difference = _diff(expected, actual, format: format)
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
  var visited: Set<ObjectIdentifier> = []
  _collectSnapshotObjects(from: actual, into: &actualObjects, visited: &visited)
  visited = []
  _setDiffTargets(on: expected, other: actual, using: actualObjects, visited: &visited)
}

private func _snapshotMirror(_ value: Any) -> Mirror {
  if let object = value as? any _DebugSnapshotObject {
    return object.customDumpMirror
  }
  return Mirror(reflecting: value)
}

private func _collectSnapshotObjects(
  from value: Any,
  into objects: inout [ObjectIdentifier: any _DebugSnapshotObject],
  visited: inout Set<ObjectIdentifier>
) {
  if type(of: value) is AnyClass {
    guard visited.insert(ObjectIdentifier(value as AnyObject)).inserted else { return }
  }
  if let object = value as? any _DebugSnapshotObject,
    let identifier = object._originIdentifier
  {
    objects[identifier] = object
  }
  for (_, child) in _snapshotMirror(value).children {
    _collectSnapshotObjects(from: child, into: &objects, visited: &visited)
  }
}

private func _setDiffTargets(
  on value: Any,
  other: Any?,
  using targets: [ObjectIdentifier: any _DebugSnapshotObject],
  visited: inout Set<ObjectIdentifier>
) {
  let object = value as? any _DebugSnapshotObject
  var target: (any _DebugSnapshotObject)?
  if let object {
    if let identifier = object._originIdentifier, let matched = targets[identifier] {
      target = matched
    } else if let other = other as? any _DebugSnapshotObject {
      object._originIdentifier = other._objectIdentifier
      target = other
    }
    object._diffSnapshot = target
  }
  if type(of: value) is AnyClass {
    guard visited.insert(ObjectIdentifier(value as AnyObject)).inserted else { return }
  }
  let other = object != nil ? target : other
  let otherChildren = other.map { Array(_snapshotMirror($0).children) }
  for (index, child) in _snapshotMirror(value).children.enumerated() {
    var otherChild: Any? {
      guard let otherChildren else { return nil }
      if let label = child.label, let match = otherChildren.first(where: { $0.label == label }) {
        return match.value
      }
      guard otherChildren.count > index else { return nil }
      return otherChildren[index].value
    }
    _setDiffTargets(
      on: child.value,
      other: otherChild,
      using: targets,
      visited: &visited
    )
  }
}
