public import CustomDump

public func _debugSnapshot<T: DebugSnapshotConvertible>(
  _ value: T,
  visitor: inout _DebugSnapshotVisitor
) -> T.DebugSnapshot {
  T._debugSnapshot(value, visitor: &visitor)
}

@dynamicMemberLookup
public protocol _DebugSnapshotObject<Snapshot>: AnyObject, CustomDumpReflectable, _CustomDiffObject
{
  associatedtype Snapshot
  var _snapshot: Snapshot { get set }
  var _originIdentifier: ObjectIdentifier? { get set }
  var _diffSnapshot: (any _DebugSnapshotObject)? { get set }
  subscript<T>(dynamicMember keyPath: WritableKeyPath<Snapshot, T>) -> T { get set }
}

extension _DebugSnapshotObject {
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<Snapshot, T>) -> T {
    get { _snapshot[keyPath: keyPath] }
    set { _snapshot[keyPath: keyPath] = newValue }
  }
}

extension _DebugSnapshotObject {
  public var _customDiffValues: (Any, Any) {
    if let diffSnapshot = _diffSnapshot {
      return (self, _DebugSnapshotDump(diffSnapshot))
    }
    return (self, _DebugSnapshotDump(self))
  }

  public var _customDiffType: Any.Type? {
    Self.self
  }

  public var _objectIdentifier: ObjectIdentifier {
    _originIdentifier ?? ObjectIdentifier(self)
  }

  public var customDumpMirror: Mirror {
    Mirror(self, children: Mirror(reflecting: _snapshot).children, displayStyle: .struct)
  }
}

public struct _DebugSnapshotDump: CustomDumpReflectable {
  let mirror: Mirror

  public init(_ snapshot: some CustomDumpReflectable) {
    self.mirror = snapshot.customDumpMirror
  }

  public var customDumpMirror: Mirror {
    mirror
  }
}

public struct _DebugSnapshotVisitor: @unchecked Sendable {
  var cache: [ObjectIdentifier: AnyObject] = [:]

  public init() {}

  public func lookup<Snapshot: AnyObject>(_ object: some AnyObject) -> Snapshot? {
    cache[ObjectIdentifier(object)] as? Snapshot
  }

  public mutating func register(_ object: some AnyObject, snapshot: some AnyObject) {
    cache[ObjectIdentifier(object)] = snapshot
  }
}
