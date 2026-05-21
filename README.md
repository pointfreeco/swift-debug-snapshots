# DebugSnapshots

Better debugging and testing for your data model.

> [!WARNING]
> This library is in beta preview and has not yet been officially released. The API is subject to
> change. We welcome community participation:
>
> - **Questions?** Open a [discussion][discussions].
> - **Found a bug or typo?** Open an [issue][issues] for non-controversial fixes.
>
> [discussions]: https://github.com/pointfreeco/swift-debug-snapshots/discussions
> [issues]: https://github.com/pointfreeco/swift-debug-snapshots/issues

## Overview

DebugSnapshots gives you a powerful macro that converts complex model data types into simple, inert
values that can be easily debugged and tested over time.

### Debugging

Apply the [`@DebugSnapshot`] macro with the `.logChanges` option to turn any class into an instantly
debuggable object:

[`@DebugSnapshot`]: https://github.com/todo

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

DebugSnapshots leverages our [CustomDump] library to print minimal and concise differences between
values, so if an array contains 100 elements and only a single one changes, the diff focuses on
just the element:

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

### Testing

The [`@DebugSnapshot`](<doc:DebugSnapshot()>) macro gives you the ability to exhaustively test the
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

The first trailing closure of 
[`expect`](<doc:expect(_:_:operation:changes:fileID:filePath:line:column:)>) allows you to perform
any number of actions on your model, and the second argument asserts on how the state changes
after the actions are performed.

If you assert the wrong thing, or do not assert on _everything_ that changed, you will get a test
failure message that tells you exactly what went wrong:

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

> 🛑 Issue recorded: Expected changes do not match: ...
> 
> ```
>     #1 FeatureModel.DebugSnapshot(
>   −   count: 2,
>   +   count: 1,
>       favoriteNumbers: []
>     )
> 
> (Expected: −, Actual: +)
> ```

That is the basics of using the library, but be sure to read the articles and documentation to learn
more.

---

<!--
## A Point-Free Production

DebugSnapshots is part of the [Point-Free] ecosystem. [Become a member] to support the development
of this library and get access to expert Swift knowledge, [beta previews], [AI skills],
behind-the-scenes [videos], and more.

[Point-Free]: https://www.pointfree.co
[Become a member]: https://www.pointfree.co/pricing
[beta previews]: https://www.pointfree.co/beta-previews
[AI skills]: https://www.pointfree.co/the-way
[videos]: https://www.pointfree.co/episodes
-->

© 2026 Point-Free, Inc. All rights reserved.
