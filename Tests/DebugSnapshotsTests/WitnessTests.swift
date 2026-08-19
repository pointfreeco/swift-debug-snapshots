import DebugSnapshots
import Testing

@Suite struct WitnessTests {
  @Test func classDefaultWithoutAnnotation() {
    let model = CountModel()
    model.count.value = 42
    let snapshot = snap(model)
    #expect(snapshot.count.value == 42)
    model.count.value = 100
    #expect(snapshot.count.value == 42)
  }

  @Test func classWrappedPropertyWithoutAnnotation() {
    let snapshot = snap(WrappedModel())
    #expect(snapshot.reminders == [Reminder(title: "fetched")])
  }

  @Test func structWrappedPropertyWithoutAnnotation() {
    let snapshot = snap(WrappedFeature())
    #expect(snapshot.reminders == [Reminder(title: "fetched")])
  }

  @MainActor
  @Test func mainActorModelWithoutAnnotations() {
    let model = IsolatedModel()
    model.count.value = 1
    let snapshot = snap(model)
    #expect(snapshot.reminders == [Reminder(title: "fetched")])
    #expect(snapshot.count.value == 1)
  }

  @Test func convertibleDefaultWithoutAnnotation() {
    let model = ParentModel()
    model.children.append(ChildModel(value: 5))
    let snapshot = snap(model)
    #expect(snapshot.children.first?.value == 5)
    model.children[0].value = 6
    #expect(snapshot.children.first?.value == 5)
  }
}

private struct Reminder: Equatable {
  var title = ""
}

private struct Count {
  var value = 0
}

@propertyWrapper
private struct Fetched {
  var wrappedValue: [Reminder] { [Reminder(title: "fetched")] }
  init(_ query: String) {}
}

@DebugSnapshot
private final class CountModel {
  var count = Count()
}

@DebugSnapshot
private final class WrappedModel {
  @Fetched("all") var reminders
}

@DebugSnapshot
private struct WrappedFeature {
  @Fetched("all") var reminders
}

@DebugSnapshot
@MainActor
private final class IsolatedModel {
  @Fetched("all") var reminders
  var count = Count()
}

@DebugSnapshot
private final class ChildModel {
  var value: Int
  init(value: Int = 0) {
    self.value = value
  }
}

@DebugSnapshot
private final class ParentModel {
  @DebugSnapshotConvertible var children = [ChildModel]()
}
