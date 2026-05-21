# ``DebugSnapshots``

Debugging and testing superpowers for your model data.

## Overview

DebugSnapshots gives you a powerful macro that converts complex model data types into simple, inert
values that can be debugged and tested over time.

### Debugging

Apply the [`@DebugSnapshot()`](<doc:DebugSnapshot()>) macro with the `.logChanges` option to turn
any class into an instantly debuggable object:

```swift
@DebugSnapshot(.logChanges)
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

With the macro applied, every invocation of a method on `FeatureModel` will automatically print
how the state changed:

@Row(numberOfColumns: 2) {
  @Column {
    **Method invocation**
  }
  @Column {
    **Printed to console**
  }
  @Column {
    ```swift
    model.incrementButtonTapped()
    ```
  }
  @Column {
    ```
    incrementButtonTapped():
        #1 FeatureModel.DebugSnapshot(
      -   count: 0,
      +   count: 1,
          favoriteNumbers: []
        )
    ```
  }
  @Column {
    ```swift
    model.saveButtonTapped()
    ```
  }
  @Column {
    ```
    saveButtonTapped():
        #1 FeatureModel.DebugSnapshot(
          count: 1,
          favoriteNumbers: [
      +     [0]: 1
          ]
        )
    ```
  }
}

### Testing

---


```swift
@DebugSnapshot
@Observable
final class FeatureModel {
  var number = 0
  var fact: String?
  @DebugSnapshotConvertible
  var child: ChildModel?
  @DebugSnapshotTracked
  var isLoading: Bool {
    task != nil
  }
  private var task: Task<Void, Never>?
  @DebugSnapshotIgnored
  let id = UUID()
  func incrementButtonTapped() {
    number += 1
  }
  func getNumberFactButtonTapped() async {
    defer { task = nil }
    task = await Task {
      fact = try? await FactClient.default.getFact(for: number)
    }
    .value
  }
}
  
let model = FeatureModel()
await model.getNumberFactButtonTapped()
snap(model)
```

## Topics

### Defining snapshots

- <doc:Customization>
- ``DebugSnapshot()``

### Testing and debugging

- <doc:Testing>
- ``expect(_:_:operation:changes:fileID:filePath:line:column:)``
- ``expect(_:_:changes:fileID:filePath:line:column:)``
- ``diff(_:operation:)``

### Generating snapshots

- ``snap(_:)``
