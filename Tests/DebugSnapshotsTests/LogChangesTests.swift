import DebugSnapshots
import Testing

@Suite struct LogChangesTests {
  @Test func basics() {
    let model = FeatureModel()
    model.incrementButtonTapped()
    model.saveButtonTapped()
  }
}

@DebugSnapshot
fileprivate class FeatureModel {
  var count = 0
  var favoriteNumbers: [Int] = []
  @LogChanges
  func incrementButtonTapped() {
    count += 1
    $logChanges()
    count += 1
    $logChanges()
  }
  @LogChanges
  func saveButtonTapped() {
    favoriteNumbers.append(count)
  }
}
