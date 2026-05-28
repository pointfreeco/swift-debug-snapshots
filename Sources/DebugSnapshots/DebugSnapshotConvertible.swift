/// A type with a debug snapshot representation.
///
/// This conformance is automatically applied to a type using the ``DebugSnapshot(_:)`` macro.
public protocol DebugSnapshotConvertible<DebugSnapshot> {
  /// A type representing a "snapshot" of this type.
  associatedtype DebugSnapshot: _DebugSnapshotCopyable

  static func _debugSnapshot(_ value: Self, visitor: inout _DebugSnapshotVisitor) -> DebugSnapshot
}

extension Array: DebugSnapshotConvertible where Element: DebugSnapshotConvertible {
  public static func _debugSnapshot(
    _ value: Self,
    visitor: inout _DebugSnapshotVisitor
  ) -> [Element.DebugSnapshot] {
    value.map { Element._debugSnapshot($0, visitor: &visitor) }
  }
}

extension Dictionary: DebugSnapshotConvertible where Value: DebugSnapshotConvertible {
  public static func _debugSnapshot(
    _ value: Self,
    visitor: inout _DebugSnapshotVisitor
  ) -> [Key: Value.DebugSnapshot] {
    value.mapValues { Value._debugSnapshot($0, visitor: &visitor) }
  }
}

extension Optional: DebugSnapshotConvertible where Wrapped: DebugSnapshotConvertible {
  public static func _debugSnapshot(
    _ value: Self,
    visitor: inout _DebugSnapshotVisitor
  ) -> Wrapped.DebugSnapshot? {
    value.map { Wrapped._debugSnapshot($0, visitor: &visitor) }
  }
}

extension Set: DebugSnapshotConvertible
where Element: DebugSnapshotConvertible, Element.DebugSnapshot: Hashable {
  public static func _debugSnapshot(
    _ value: Self,
    visitor: inout _DebugSnapshotVisitor
  ) -> Set<Element.DebugSnapshot> {
    var result: Set<Element.DebugSnapshot> = []
    result.reserveCapacity(value.count)
    for element in value {
      result.insert(Element._debugSnapshot(element, visitor: &visitor))
    }
    return result
  }
}

extension Array: _DebugSnapshotCopyable where Element: _DebugSnapshotCopyable {
  public static func _copySnapshot(_ value: Self, visitor: inout _DebugSnapshotVisitor) -> Self {
    value.map { Element._copySnapshot($0, visitor: &visitor) }
  }
}

extension Dictionary: _DebugSnapshotCopyable where Value: _DebugSnapshotCopyable {
  public static func _copySnapshot(_ value: Self, visitor: inout _DebugSnapshotVisitor) -> Self {
    value.mapValues { Value._copySnapshot($0, visitor: &visitor) }
  }
}

extension Optional: _DebugSnapshotCopyable where Wrapped: _DebugSnapshotCopyable {
  public static func _copySnapshot(_ value: Self, visitor: inout _DebugSnapshotVisitor) -> Self {
    value.map { Wrapped._copySnapshot($0, visitor: &visitor) }
  }
}

extension Set: _DebugSnapshotCopyable where Element: _DebugSnapshotCopyable {
  public static func _copySnapshot(_ value: Self, visitor: inout _DebugSnapshotVisitor) -> Self {
    var result: Self = []
    result.reserveCapacity(value.count)
    for element in value {
      result.insert(Element._copySnapshot(element, visitor: &visitor))
    }
    return result
  }
}
