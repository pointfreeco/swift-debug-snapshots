#if IdentifiedCollections
  public import IdentifiedCollections

  extension IdentifiedArray: DebugSnapshotConvertible where Element: DebugSnapshotConvertible {
    public func _debugSnapshot(visitor: inout DebugSnapshots._DebugSnapshotVisitor) -> [Element.DebugSnapshot] {
      var result: [Element.DebugSnapshot] = []
      result.reserveCapacity(count)
      for element in self.elements {
        result.append(element._debugSnapshot(visitor: &visitor))
      }
      return result
    }
  }
#endif
