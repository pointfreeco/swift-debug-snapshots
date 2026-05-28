import DebugSnapshots
import Testing

@Suite struct CopyTests {
  @Test func mutatingCopyDoesNotAffectOriginal() {
    let original = snap(Model(counter: Counter()))
    let copy = snap(original)
    copy.counter.count = 99
    #expect(original.counter.count == 0)
    #expect(copy.counter.count == 99)
  }

  @Test func aliasingIsPreserved() {
    let shared = Counter()
    let original = snap(Model(counter: shared, other: shared))
    let copy = snap(original)
    #expect(copy.counter === copy.other)
    copy.counter.count = 7
    #expect(copy.other.count == 7)
  }

  @Test func nestedAndCollectionsCopyDeeply() {
    let original = snap(
      Model(counter: Counter(), list: [Counter(count: 1), Counter(count: 2)])
    )
    let copy = snap(original)
    copy.list[0].count = 100
    #expect(original.list[0].count == 1)
    #expect(copy.list[0].count == 100)
  }
}

@DebugSnapshot private final class Counter: @unchecked Sendable {
  var count: Int
  init(count: Int = 0) { self.count = count }
}

@DebugSnapshot private struct Model {
  @DebugSnapshotConvertible var counter: Counter
  @DebugSnapshotConvertible var other: Counter
  @DebugSnapshotConvertible var list: [Counter] = []
  init(counter: Counter, other: Counter? = nil, list: [Counter] = []) {
    self.counter = counter
    self.other = other ?? counter
    self.list = list
  }
}
