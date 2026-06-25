import DebugSnapshots

@DebugSnapshot private struct Child {
  var value = 0
}

@DebugSnapshot private struct ParentStructure {
  var count = 0
  var name = ""
  var child = Child()
}

@DebugSnapshot private enum ParentEnumeration {
  case count(Int)
  case name(String)
  @DebugSnapshotConvertible case child(Child)
}

@DebugSnapshot private final class ParentObject {
  var count = 0
  var name = ""
  @DebugSnapshotConvertible var child: Child = Child()
}

private func snapshots() {
  let parentStruct = snap(ParentStructure())
  let _: Child.DebugSnapshot = parentStruct.child

  let parentEnum = snap(ParentEnumeration.child(Child()))
  if case .child(let child) = parentEnum {
    let _: Child.DebugSnapshot = child
  }

  let parentObject = snap(ParentObject())
  let _: Child.DebugSnapshot = parentObject.child
}
