/// Takes a snapshot of an instance of a snapshottable type.
///
/// - Parameter instance: An instance of a snapshottable type.
/// - Returns: A snapshot.
public func snap<T: DebugSnapshotConvertible>(_ model: T) -> T.DebugSnapshot {
  var visitor = _DebugSnapshotVisitor()
  return T._debugSnapshot(model, visitor: &visitor)
}
