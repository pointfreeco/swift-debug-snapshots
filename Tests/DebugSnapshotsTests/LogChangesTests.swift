import DebugSnapshots
import OSLog
import Testing

@Suite struct LogChangesTests {
  let store = try! OSLogStore(scope: .currentProcessIdentifier)
  var startPosition: OSLogPosition
  init() {
    startPosition = store.position(date: .now)
  }

  @Test mutating func basics() async throws {
    let model = FeatureModel()
    model.incrementButtonTapped()
    try await expectLog(
      """
      incrementButtonTapped():
          #1 FeatureModel.DebugSnapshot(
        -   count: 0,
        +   count: 1,
            favoriteNumbers: []
          )
      """
    )
    try await expectLog(
      """
      incrementButtonTapped():
          #1 FeatureModel.DebugSnapshot(
        -   count: 1,
        +   count: 2,
            favoriteNumbers: []
          )
      """
    )
    model.saveButtonTapped()
    try await expectLog(
      """
      saveButtonTapped():
          #1 FeatureModel.DebugSnapshot(
            count: 2,
            favoriteNumbers: [
        +     [0]: 2
            ]
          )
      """
    )
  }

  private mutating func expectLog(
    _ message: String,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) async throws {
    let start = Date()
    while Date().timeIntervalSince(start) < 1 {
      try await Task.sleep(for: .seconds(0.1))
      let entries = try store.getEntries(
        at: startPosition,
        matching: NSPredicate(format: "subsystem == %@", "DebugSnapshots")
      )
      for entry in entries {
        guard entry.composedMessage.hasSuffix(message)
        else {
          continue
        }
        startPosition = store.position(date: .now)
        return
      }
    }
    Issue.record(
      "Log not found",
      sourceLocation: SourceLocation(
        fileID: fileID.description,
        filePath: filePath.description,
        line: Int(line),
        column: Int(column)
      )
    )
  }
}

@DebugSnapshot
private class FeatureModel {
  var count = 0
  var favoriteNumbers: [Int] = []
  @LogChanges
  func incrementButtonTapped() {
    count += 1
    $logChanges()
    count += 1
    $logChanges()
  }
}
extension FeatureModel {
  func saveButtonTapped() {
    favoriteNumbers.append(count)
  }
}
