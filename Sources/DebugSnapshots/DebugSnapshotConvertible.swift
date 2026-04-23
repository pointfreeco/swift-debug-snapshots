public import CustomDump

/// A type with a debug snapshot representation.
///
/// This conformance is automatically applied to a type using the ``DebugSnapshot()`` macro.
public protocol DebugSnapshotConvertible<DebugSnapshot> {
  /// A type representing a "snapshot" of this type.
  associatedtype DebugSnapshot

  static func _debugSnapshot(_ value: Self, visitor: inout _DebugSnapshotVisitor) -> DebugSnapshot
}


public func _debugSnapshot<T: DebugSnapshotConvertible>(
  _ value: T,
  visitor: inout _DebugSnapshotVisitor
) -> T.DebugSnapshot {
  T._debugSnapshot(value, visitor: &visitor)
}

extension Array where Element: DebugSnapshotConvertible {
  public static func _debugSnapshot(
    _ value: Self,
    visitor: inout _DebugSnapshotVisitor
  ) -> [Element.DebugSnapshot] {
    var result: [Element.DebugSnapshot] = []
    result.reserveCapacity(value.count)
    for element in value {
      result.append(Element._debugSnapshot(element, visitor: &visitor))
    }
    return result
  }
}

extension Optional: DebugSnapshotConvertible where Wrapped: DebugSnapshotConvertible {
  public static func _debugSnapshot(
    _ value: Self,
    visitor: inout _DebugSnapshotVisitor
  ) -> Wrapped.DebugSnapshot? {
    switch value {
    case .none:
      return nil
    case .some(let wrapped):
      return Wrapped._debugSnapshot(wrapped, visitor: &visitor)
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

public protocol _DebugSnapshotObject<Snapshot>: AnyObject, CustomDumpReflectable, _CustomDiffObject
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
