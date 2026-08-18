import DebugSnapshots
import Testing

@Suite struct AccessLevelTests {
  @Test func structMirrorsEveryProperty() {
    let snapshot = snap(AccessLevelState())
    #expect(snapshot.title == "")
    #expect(snapshot.identifier == 0)
    #expect(snapshot.theme == 0)
    #expect(snapshot.isStale == false)
  }

  @Test func classMirrorsEveryProperty() {
    let snapshot = snap(AccessLevelModel())
    #expect(snapshot.title == "")
    #expect(snapshot.theme == 0)
    #expect(snapshot.isStale == false)
  }
}
