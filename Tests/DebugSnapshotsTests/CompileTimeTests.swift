import DebugSnapshots

private class Model {
  var count = 0
  var isLoading = false
}

@DebugSnapshot fileprivate class Parent {
  @DebugSnapshotConvertible var child: Child = .init()
  @DebugSnapshotConvertible var children: [Child] = [.init()]
  @DebugSnapshotConvertible var optionalChild: Child? = .init()
  @DebugSnapshotConvertible var staticChild: Child = .make()
  @DebugSnapshotConvertible var staticChildren: [Child] = [.make()]
  @DebugSnapshotConvertible var staticOptionalChild: Child? = .make()
  @DebugSnapshot fileprivate class Child {
    init() {}
    static func make() -> Child { Child() }
  }
}
