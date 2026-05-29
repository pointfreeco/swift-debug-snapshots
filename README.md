# DebugSnapshots

[![CI](https://github.com/pointfreeco/swift-debug-snapshots/actions/workflows/ci.yml/badge.svg)](https://github.com/pointfreeco/swift-debug-snapshots/actions/workflows/ci.yml)
[![Slack](https://img.shields.io/badge/slack-chat-informational.svg?label=Slack&logo=slack)](https://www.pointfree.co/slack-invite)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-debug-snapshots%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/pointfreeco/swift-debug-snapshots)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-debug-snapshots%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pointfreeco/swift-debug-snapshots)

Better debugging and testing for your data model.

## A Point-Free Production

DebugSnapshots is part of the [Point-Free] ecosystem. [Become a member] to support the development
of this library and get access to expert Swift knowledge, [beta previews], [AI skills],
behind-the-scenes [videos], and more.

<a href="https://www.pointfree.co/">
  <img alt="video poster image" src="https://d3rccdn33rt8ze.cloudfront.net/social-assets/twitter-card-large.png" width="600">
</a>

[Point-Free]: https://www.pointfree.co
[Become a member]: https://www.pointfree.co/pricing
[beta previews]: https://www.pointfree.co/beta-previews
[AI skills]: https://www.pointfree.co/the-way
[videos]: https://www.pointfree.co/episodes

## Overview

DebugSnapshots gives you a powerful macro that converts complex model data types into simple, inert
values that can be easily debugged and tested over time.

### Debugging

Apply the [`@DebugSnapshot`] macro with the `.logChanges` option to turn any class into an instantly
debuggable object:

[`@DebugSnapshot`]: https://swiftpackageindex.com/pointfreeco/swift-debug-snapshots/main/documentation/debugsnapshots/debugsnapshot(_:)

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

> [!NOTE]
> Changes are logged only in debug builds. All logging is disabled in release builds.

DebugSnapshots leverages our [CustomDump] library to print minimal and concise differences between
values, so if an array contains 100 elements and only a single one changes, the diff focuses on
just that element:

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

> [!IMPORTANT]
> If your code is in an Xcode app target with default settings (i.e. main actor isolation
and Swift 5 mode), then you will have to additionally mark all tests as `@MainActor`.

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

## Documentation

The documentation for the latest unstable and stable releases are available here:

  * [`main`](https://swiftpackageindex.com/pointfreeco/swift-debug-snapshots/main/documentation/debugsnapshots/)
  * [0.x.x](https://swiftpackageindex.com/pointfreeco/swift-debug-snapshots/~/documentation/debugsnapshots/)

## Installation

Add DebugSnapshots to your `Package.swift` dependencies:

```swift
dependencies: [
  .package(
    url: "https://github.com/pointfreeco/swift-debug-snapshots",
    from: "0.1.0"
  )
]
```

And add the product to your target:

```swift
targets: [
  .target(
    name: "MyFeature",
    dependencies: [
      .product(name: "DebugSnapshots", package: "swift-debug-snapshots")
    ]
  )
]
```

This package currently requires Swift 6.2 or later and supports iOS 13+, macOS 10.15+, tvOS 13+,
and watchOS 6+.

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
