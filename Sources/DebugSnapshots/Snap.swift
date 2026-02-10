/// Takes a snapshot of an instance of a snapshottable type.
///
/// - Parameter instance: An instance of a snapshottable type.
/// - Returns: A snapshot.
public func snap<Value>(_ model: some DebugSnapshotConvertible<Value>) -> Value {
  var visitor = _DebugSnapshotVisitor()
  return model._debugSnapshot(visitor: &visitor)
}
