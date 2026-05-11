# ``DebugSnapshots``

Debugging and testing superpowers for your model data.

## Overview

DebugSnapshots gives you a powerful macro that converts complex model data types into simple, inert
values that can be debugged and tested over time.

```swift
@DebugSnapshot
@MainActor
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
  var id = UUID()
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
```

## Topics

### Defining snapshots

- ``DebugSnapshot()``
- ``DebugSnapshotTracked()``
- ``DebugSnapshotIgnored()``
- ``DebugSnapshotConvertible()``

### Generating snapshots

- ``snap(_:)``

### Diffing snapshots

- ``diff(_:operation:)``

### Exhaustive testing

- ``expect(_:_:operation:changes:fileID:filePath:line:column:)``

### Non-exhaustive testing

- ``expect(_:_:changes:fileID:filePath:line:column:)``
