import DebugSnapshots
import Testing

struct StandardLibraryConformancesTests {
  @Test func optional() {
    let model = Model()
    expect(model) {
      model.present()
    } changes: {
      $0.presented = Counter.DebugSnapshot()
    }
  }

  @Test func array() {
    let model = Model(counters: [Counter(count: 1), Counter(count: 2)])
    expect(model) {
      model.increment(at: 1)
    } changes: {
      $0.counters[1] = Counter.DebugSnapshot(count: 3)
    }
  }

  @Test func dictionary() {
    let model = Model(counterLookup: ["blob": Counter(count: 1), "blob_jr": Counter(count: 2)])
    expect(model) {
      model.increment(id: "blob_jr")
    } changes: {
      $0.counterLookup["blob_jr"] = Counter.DebugSnapshot(count: 3)
    }
  }

  @Test func set() {
    let model = Model()
    expect(model) {
      model.insert(count: 1)
    } changes: {
      $0.counterSet = [Counter.DebugSnapshot(count: 1)]
    }
  }
}

@DebugSnapshot private struct Counter: Hashable {
  var count = 0
}

extension Counter.DebugSnapshot: Hashable {}

@DebugSnapshot private final class Model {
  @DebugSnapshotConvertible var presented: Counter?
  @DebugSnapshotConvertible var counters: [Counter] = []
  @DebugSnapshotConvertible var counterLookup: [String: Counter] = [:]
  @DebugSnapshotConvertible var counterSet: Set<Counter> = []

  init(
    presented: Counter? = nil,
    counters: [Counter] = [],
    counterLookup: [String: Counter] = [:],
    counterSet: Set<Counter> = []
  ) {
    self.presented = presented
    self.counters = counters
    self.counterLookup = counterLookup
    self.counterSet = counterSet
  }

  func present() {
    presented = Counter()
  }

  func increment(at index: Int) {
    counters[index].count += 1
  }

  func increment(id: String) {
    counterLookup[id]?.count += 1
  }

  func insert(count: Int) {
    counterSet.insert(Counter(count: count))
  }
}
