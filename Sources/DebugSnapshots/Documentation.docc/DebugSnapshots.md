# ``DebugSnapshots``

Debugging and testing superpowers for your model data.

## Overview

DebugSnapshots gives you a powerful macro that converts complex model data types into simple, inert
values that can be easily debugged and tested over time.

### Debugging

Apply the [`@DebugSnapshot`](<doc:DebugSnapshot(_:)>) macro with the
``DebugSnapshotOptions/logChanges`` option to turn any class into an instantly debuggable object:

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

With the macro applied, every invocation of a method on `FeatureModel` will automatically log how
the state changes:

```swift
model.incrementButtonTapped()
// incrementButtonTapped():
//     #1 FeatureModel.DebugSnapshot(
//   -   count: 0,
//   +   count: 1,
//       favoriteNumbers: []
//     )

model.saveButtonTapped()
// saveButtonTapped():
//     #1 FeatureModel.DebugSnapshot(
//       count: 1,
//       favoriteNumbers: [
//   +     [0]: 1
//       ]
//     )
```

> Note: Changes are logged only in debug builds. All logging is disabled in release builds.

DebugSnapshots leverages our [CustomDump] library to print minimal and concise differences between
values, so if an array contains 100 elements and only a single one changes, the diff focuses on just
that element:

[CustomDump]: https://github.com/pointfreeco/swift-custom-dump

```swift
model.saveButtonTapped()
// saveButtonTapped():
//     #1 FeatureModel.DebugSnapshot(
//       count: 101,
//       favoriteNumbers: [
//         … (99 unchanged),
//   +     [100]: 100
//       ]
//     )
```

You can also log changes in the middle of a method by invoking `$logChanges()`:

```swift
func refreshButtonTapped() async {
  data = cache.fetch()
  $logChanges("cache.fetch")
  data = await client.fetch()
}
```

### Testing

The [`@DebugSnapshot`](<doc:DebugSnapshot(_:)>) macro gives you the ability to exhaustively test the
logic and behavior in your classes using
[`expect`](<doc:expect(_:_:operation:changes:fileID:filePath:line:column:)>). Start by applying
the macro to your class:

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

With that done you can now write tests that invoke the various methods on the class and assert
exhaustively how the state in the class changes:

```swift
@Test func testIncrement() {
  let model = FeatureModel()
  expect(model) {
    model.incrementButtonTapped()
  } changes: {
    $0.count = 1
  }
}
```

> Important: If your code is in an Xcode app target with default settings (i.e. main actor isolation
and Swift 5 mode), then you will have to additionally mark all tests as `@MainActor`.

The first trailing closure of
[`expect`](<doc:expect(_:_:operation:changes:fileID:filePath:line:column:)>) allows you to perform
any number of actions on your model, and the second argument asserts on how the state changes after
the actions are performed.

If you assert the wrong thing, or do not assert on _everything_ that changed, you will get a test
failure that tells you exactly what went wrong:

```swift
@Test func testIncrement() {
  let model = FeatureModel()
  expect(model) {
    model.incrementButtonTapped()
  } changes: {
    $0.count = 2
  }
}
```

> ❌ Issue recorded: Expected changes do not match: ...
>
> ```diff
>     #1 FeatureModel.DebugSnapshot(
> -     count: 2,
> +     count: 1,
>       favoriteNumbers: []
>     )
>
> (Expected: −, Actual: +)
> ```

That is the basics of using the library, but be sure to read the articles and documentation to learn
more.

## Topics

### Defining snapshots

- <doc:Customization>
- ``DebugSnapshot(_:)``

### Testing and debugging

- <doc:TestingChanges>
- <doc:LoggingChanges>
- ``LogChanges()``
- ``expect(_:_:operation:changes:fileID:filePath:line:column:)``
- ``expect(_:_:changes:fileID:filePath:line:column:)``
- ``diff(_:operation:)``

### Generating snapshots

- ``snap(_:)``
