public import DebugSnapshots

#if canImport(Observation)
  import Observation
#endif

private class Model {
  var count = 0
  var isLoading = false
}

struct InternalValue {}

@DebugSnapshot public struct PublicTrackedStruct {
  @DebugSnapshotTracked var value = InternalValue()
  @DebugSnapshotTracked private var count = 0
}

@DebugSnapshot public final class PublicTrackedClass {
  @DebugSnapshotTracked var value = InternalValue()
  @DebugSnapshotTracked private var count = 0
}

private func trackedSnapshotsCompile() {
  let structure = snap(PublicTrackedStruct())
  _ = structure.value
  let object = snap(PublicTrackedClass())
  _ = object.value
}

@DebugSnapshot private class Parent {
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
  @DebugSnapshot fileprivate enum Grandparent {
    @DebugSnapshotConvertible case child(Child = .init())
  }
}

@DebugSnapshot(.logChanges)
class RedundantLogChanges {
  var count = 0
  @LogChanges
  func incrementButtonTapped() { count += 1 }
}

#if canImport(Observation)
  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  @DebugSnapshot
  @MainActor
  @Observable
  private class MainActorObservable {
    var count = 0
  }
#endif

@MainActor
@DebugSnapshot(.logChanges)
final class MainActorWithNonisolatedMethod {
  nonisolated func noop() {}
}

@globalActor actor MyGlobalActor: GlobalActor {
  static let shared = MyGlobalActor()
}
@MyGlobalActor
@DebugSnapshot(.logChanges)
final class CustomGlobalActor {
  var count = 0
  func increment() { count += 1 }
}
