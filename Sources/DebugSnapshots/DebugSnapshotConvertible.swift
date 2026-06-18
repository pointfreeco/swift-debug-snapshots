/// A type with a debug snapshot representation.
///
/// This conformance is automatically applied to a type using the ``DebugSnapshot(_:)`` macro.
public protocol DebugSnapshotConvertible<DebugSnapshot> {
  /// A type representing a "snapshot" of this type.
  associatedtype DebugSnapshot: DebugSnapshotConvertible<DebugSnapshot>

  static var _logChanges: Set<AnyKeyPath> { get }

  static func _debugSnapshot(_ value: Self, visitor: inout _DebugSnapshotVisitor) -> DebugSnapshot
}

extension DebugSnapshotConvertible {
  public static var _logChanges: Set<AnyKeyPath> { [] }
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
