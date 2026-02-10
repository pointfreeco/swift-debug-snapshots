#if IdentifiedCollections
  public import IdentifiedCollections

  extension IdentifiedArray: DebugSnapshotConvertible
  where Element: DebugSnapshotConvertible & Identifiable, Element.DebugSnapshot: Identifiable<ID> {
    public static func _debugSnapshot(
      _ value: IdentifiedArray<ID, Element>,
      visitor: inout _DebugSnapshotVisitor
    ) -> IdentifiedArray<ID, Element.DebugSnapshot> {
      var result: IdentifiedArray<ID, Element.DebugSnapshot> = []
      result.reserveCapacity(value.count)
      for element in value {
        result.append(Element._debugSnapshot(element, visitor: &visitor))
      }
      return result
    }
  }
#endif
