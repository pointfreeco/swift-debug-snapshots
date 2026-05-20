# ``DebugSnapshots``

Debugging and testing superpowers for your model data.

## Overview

DebugSnapshots gives you a powerful macro that converts complex model data types into simple, inert
values that can be debugged and tested over time. It is capable of snapshotting every field of a

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
