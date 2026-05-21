# Testing changes to model data

Ergonomically and exhaustively test how your model data evolves over time.

## Overview

A primary benefit of adding debug snapshots to your model data is the ability to write more
ergonomic and "[exhaustive](#exhaustive-testing)" tests using the 
[`expect`](<doc:expect(_:_:operation:changes:fileID:filePath:line:column:)>) function. It snapshots
the state of your model before and after a series of actions are executed, and then you assert
on exactly how the state changed in the process.

## Exhaustive testing

Consider the following model:

  ```swift
  @DebugSnapshot
  class FeatureModel {
    var count = 0
    var favoriteNumbers: [Int] = []
    func incrementButtonTapped() {
      count += 1
    }
    func saveButtonTapped() {
      favoriteNumbers.append(count)
    }
  }
  ```

This can be tested using `expect` like so:

  ```swift
  @Test func basics() {
    let model = FeatureModel()
    expect(model) {
      model.incrementButtonTapped()
    } changes: {
      $0.count = 1
    }
    expect(model) {
      model.saveButtonTapped()
    } changes: {
      $0.favoriteNumbers = [1]
    }
  }
  ```

The first trailing closure allows you to execute any number of actions you want to. The second 
trailing closure is handed a mutable representation of the snapshot data in the model, and it's your
job to mutate it to match the state of the model after the actions execute.

This may not seem too different from using `#expect`. In fact, `#expect` is a little less verbose:

  ```swift
  @Test func basics() {
    let model = FeatureModel()
    model.incrementButtonTapped()
    #expect(model.count == 1)
    model.saveButtonTapped()
    #expect(model.favoriteNumbers == [1])
  }
  ```

However, there are some differences. First, when an assertion is incorrect, the resulting failure
message can be inscrutable. For example, if `favoriteNumbers` has 100 numbers and you get one wrong,
you will be met with the following error message:
  
  > 🛑 Expectation failed: (model.favoriteNumbers → [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100]) == (Array(0...100) → [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100])

In contrast, `expect` shows you exactly what went wrong with the assertion (there's an extra 0 at
the beginning of the array that should not be there):

  > 🛑 Issue recorded: Expected changes do not match: ...
  > 
  > ```
  >     #1 FeatureModel.DebugSnapshot(
  >       count: 100,
  >       favoriteNumbers: [
  >   −     [0]: 0,
  >         … (100 unchanged)
  >       ]
  >     )
  > 
  > (Expected: −, Actual: +)
  > ```

The second difference is that `expect` forces you to assert on all changes in the model. If 
something else changes that you did not assert on, you will get a test failure. For example,
suppose the model is updated to keep track of the max `count` ever seen:

  ```swift, highlight=[3,4,5,6]
  @DebugSnapshot
  class FeatureModel {
    var count = 0 {
      didSet { max = Swift.max(max, count) }
    }
    var max = 0
    var favoriteNumbers: [Int] = []
    func incrementButtonTapped() {
      count += 1
    }
    func saveButtonTapped() {
      favoriteNumbers.append(count)
    }
  }
  ```

That change will instantly cause this test to fail:

  ```swift, highlight=[3]
    @Test func basics() {
      let model = FeatureModel()
  🛑  expect(model) {
        model.incrementButtonTapped()
      } changes: {
        $0.count = 1
      }
    }
  ```

…with the following failure message:

  > 🛑 Issue recorded: Expected changes do not match: ...
  > 
  > ```
  >     #1 FeatureModel.DebugSnapshot(
  >       count: 1,
  >  −    max: 0,
  >  +    max: 1,
  >       favoriteNumbers: []
  >     )
  > 
  > (Expected: −, Actual: +)
  > ```

This forces you to assert on all of the state in the model, helping you catch potential bugs as
new features are added. To fix the failure we must assert on the `max` state in addition to the
`count` state:

  ```swift, highlight=[7]
  @Test func basics() {
    let model = FeatureModel()
   expect(model) {
      model.incrementButtonTapped()
    } changes: {
      $0.count = 1
      $0.max = 1
    }
  }
  ```

In contrast, this is not possible with `#expect`. It is your responsibility to assert on each
piece of state individually, and nothing is keeping you in check to make sure you assert on new 
state when it is added to your feature:

  ```swift, highlight=[5]
  @Test func basics() {
    let model = FeatureModel()
    model.incrementButtonTapped()
    #expect(model.count == 1)
    #expect(model.max == 1)
  }
  ```

## Testing nested models

Nested models can also be exhaustively tested, but it requires a little extra work. First, when
holding onto a child model (either directly, or as an optional, or in a collection), you must
annotate it with the [`@DebugSnapshotConvertible`](<doc:DebugSnapshotConvertible()>) macro:

  ```swift
  @DebugSnapshot
  class Counter {
    var count = 0 {
      didSet { max = Swift.max(max, count) }
    }
    var max = 0
    func incrementButtonTapped() {
      count += 1
    }
  }
    
  @DebugSnapshot
  class FeatureModel {
    @DebugSnapshotConvertible var counters: [Counter] = []
    func addButtonTapped() {
      counters.append(Counter())
    }
  }
  ```

This will nest the snapshot for `Counter` in the snapshot of `FeatureModel`, which allows
you to assert on all changes easily. Keep in mind that when new `Counter` objects are
added to the collection you will need to assert on that change using `Counter.DebugSnapshot` (
``DebugSnapshotConvertible/DebugSnapshot`` is the mutable snapshot type of the model):

  ```swift, highlight=[6]
  @Test func increment() {
    let model = FeatureModel()
    expect(model) {
      model.addButtonTapped()
    } changes: {
      $0.counters = [Counter.DebugSnapshot(count: 0)]
    }
    expect(model) {
      model.counters[0].incrementButtonTapped()
    } changes: {
      $0.counters[0].count = 1
      $0.counters[0].max = 1
    }
  ```

