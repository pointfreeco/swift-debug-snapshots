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
  @_LogChanges
  func incrementButtonTapped() {
    count += 1
    _$logChanges()
    count += 1
    _$logChanges()
  }
  @_LogChanges
  func saveButtonTapped() {
    favoriteNumbers.append(count)
  }
}
