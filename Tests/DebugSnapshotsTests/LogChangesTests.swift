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
  }
  @LogChanges
  func saveButtonTapped() {
    favoriteNumbers.append(count)
  }
}

// TODO: optional for @DebugSnapshot to log changes on all methods/inits? '@DebugSnapshot(._logChanges)'
// TODO: should you be able to log changes in the middle of the method too?
// TODO: diagnose static functions
// TODO: diagnose that we are in a `@DebugSnapshot` if possible
// TODO: Rename to @_LogChanges? @DebugChanges? @DebugSnapshotChanges?
//@DebugSnapshot
//fileprivate class Model {
//  var count = 0
//  @DebugSnapshotTracked
//  var isEven: Bool {
//    count.isMultiple(of: 2)
//  }
//  @LogChanges
//  // @_LogChanges
//  // @DebugChanges
//  // @DebugSnapshotChanges
//  func incrementButtonTapped() {
//    count += 1
//  }
//}
//
//// TODO: allow this @DebugSnapshot(._logChanges) 
//extension Model {
//  func decrementButtonTapped() {
//    count -= 1
//  }
//}

