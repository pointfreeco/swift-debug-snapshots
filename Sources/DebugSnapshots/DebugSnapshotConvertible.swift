public import CustomDump

/// A type with a debug snapshot representation.
///
/// This conformance is automatically applied to a type using the ``DebugSnapshot()`` macro.
public protocol DebugSnapshotConvertible<DebugSnapshot> {
  /// A type representing a "snapshot" of this type.
  associatedtype DebugSnapshot: _DebugSnapshot

  func _debugSnapshot(visitor: inout _DebugSnapshotVisitor) -> DebugSnapshot
}

// TODO: Get rid of this helper?
extension DebugSnapshotConvertible {
  public var _debugSnapshot: DebugSnapshot {
    var visitor = _DebugSnapshotVisitor()
    return _debugSnapshot(visitor: &visitor)
  }
}

extension Array: DebugSnapshotConvertible where Element: DebugSnapshotConvertible {
  public func _debugSnapshot(visitor: inout _DebugSnapshotVisitor) -> [Element.DebugSnapshot] {
    var result: [Element.DebugSnapshot] = []
    result.reserveCapacity(count)
    for element in self {
      result.append(element._debugSnapshot(visitor: &visitor))
    }
    return result
  }
}

extension Optional: DebugSnapshotConvertible where Wrapped: DebugSnapshotConvertible {
  public func _debugSnapshot(visitor: inout _DebugSnapshotVisitor) -> Wrapped.DebugSnapshot? {
    switch self {
    case .none:
      return nil
    case .some(let value):
      return value._debugSnapshot(visitor: &visitor)
    }
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

public protocol _DebugSnapshotObject<Snapshot>: AnyObject, CustomDumpReflectable, _CustomDiffObject,
  _DebugSnapshot
{
  associatedtype Snapshot
  var _snapshot: Snapshot { get set }
  var _originIdentifier: ObjectIdentifier? { get set }
  var _diffSnapshot: (any _DebugSnapshotObject)? { get set }
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
