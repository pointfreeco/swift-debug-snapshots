/// A type with a debug snapshot representation.
///
/// This conformance is automatically applied to a type using the ``DebugSnapshot(_:)`` macro.
public protocol DebugSnapshotConvertible<DebugSnapshot> {
  /// A type representing a "snapshot" of this type.
  associatedtype DebugSnapshot

  static func _debugSnapshot(_ value: Self, visitor: inout _DebugSnapshotVisitor) -> DebugSnapshot
}

extension Array: DebugSnapshotConvertible where Element: DebugSnapshotConvertible {
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

extension Dictionary: DebugSnapshotConvertible where Value: DebugSnapshotConvertible {
  public static func _debugSnapshot(
    _ value: Self,
    visitor: inout _DebugSnapshotVisitor
  ) -> [Key: Value.DebugSnapshot] {
    var result: [Key: Value.DebugSnapshot] = [:]
    result.reserveCapacity(value.count)
    for (key, value) in value {
      result[key] = Value._debugSnapshot(value, visitor: &visitor)
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
