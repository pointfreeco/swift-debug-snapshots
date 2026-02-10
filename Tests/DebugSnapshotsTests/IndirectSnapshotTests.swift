import DebugSnapshots
import Testing

@Suite
struct IndirectSnapshotTests {
  @Test func optionalNestedSnapshotMutation() {
    var s = Parent.DebugSnapshot(name: "parent", child: nil)
    s.child = Child.DebugSnapshot(count: 0)
    s.child?.count = 42
    #expect(s.name == "parent")
    #expect(s.child?.count == 42)
  }

  @Test func snapshotMutationIndependentOfSource() {
    let original = Parent(name: "p", child: Child(count: 5))
    var snapshot = snap(original)
    snapshot.child?.count = 999
    #expect(snapshot.child?.count == 999)
    let fresh = snap(original)
    #expect(fresh.child?.count == 5)
  }

  @Test func customMirrorLabels() {
    let s = Parent.DebugSnapshot(name: "hi", child: Child.DebugSnapshot(count: 7))
    let mirror = Mirror(reflecting: s)
    let labels = mirror.children.compactMap(\.label)
    #expect(labels == ["name", "child"])
  }
}

@DebugSnapshot
private struct Child {
  var count: Int = 0
}

@DebugSnapshot
private struct Parent {
  var name: String = ""
  @DebugSnapshotConvertible var child: Child?
}
