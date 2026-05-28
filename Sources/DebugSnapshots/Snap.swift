/// Takes a snapshot of an instance of a snapshottable type.
///
/// - Parameter instance: An instance of a snapshottable type.
/// - Returns: A snapshot.
public func snap<T: DebugSnapshotConvertible>(_ instance: T) -> T.DebugSnapshot {
  var visitor = _DebugSnapshotVisitor()
  return T._debugSnapshot(instance, visitor: &visitor)
}

/// Returns a deep copy of a snapshot.
///
/// Snapshots of value types copy deeply on assignment, but they can transitively hold snapshots of
/// reference types, which share storage and mutations. Use this to obtain an independent copy whose
/// mutations do not affect the original snapshot.
///
/// - Parameter snapshot: A snapshot.
/// - Returns: A deep copy of the snapshot.
public func snap<T: _DebugSnapshotCopyable>(_ snapshot: T) -> T {
  var visitor = _DebugSnapshotVisitor()
  return T._copySnapshot(snapshot, visitor: &visitor)
}
