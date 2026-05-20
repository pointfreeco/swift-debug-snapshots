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

DebugSnapshots generates lightweight, test-friendly snapshots of your classes so that you can diff
state changes and write assertions against them in tests. Apply the `@DebugSnapshot` macro to a
class, and the library generates a snapshot type that captures only the properties you care about,
with support for nested models, circular references, enums, `@Observable`, and SwiftData.

  * [`@DebugSnapshot`](#debugsnapshot)
  * [`expect`](#asserting-state-changes)
  * [`@DebugSnapshotTracked` and `@DebugSnapshotIgnored`](#tracking-and-ignoring-properties)
  * [`@DebugSnapshotConvertible`](#nested-models)

## `@DebugSnapshot`

Apply `@DebugSnapshot` to a class to generate a test-friendly snapshot type that mirrors its stored
properties:

```swift
@DebugSnapshot
@Observable
final class FeatureModel {
  var count = 0
  var title = ""
  // Other properties and methods...
}
```

The macro generates a `FeatureModel.DebugSnapshot` type with `count` and `title` properties. You
never need to write or maintain this type by hand.

## Asserting state changes

Use `expect` to assert that an operation produces exactly the state changes you describe and nothing
more:

```swift
let model = FeatureModel()

expect(model) {
  model.incrementTapped()
} changes: {
  $0.count = 1
}
```

If the operation changes a property you didn't account for, or if your expected value doesn't match,
the test fails with a detailed diff:

```diff
❌ Expected changes do not match: ...

  FeatureModel.DebugSnapshot(
-   count: 2,
+   count: 1,
    title: ""
  )

(Expected: −, Actual: +)
```

By default you must exhaustively assert on all changes in the object, but the library also supports
non-exhaustive assertions. By omitting the first trailing closure you can succinctly assert
on the current state of the object:

```swift
model.incrementTapped()
expect(model) {
  $0.count = 1
}
```

If there are other changes to the object besides `count` the test will still pass, but if you
make an incorrect assertion you will still get a test failure:

```swift
model.incrementTapped()
expect(model) {
  $0.count = 1
  $0.title = "Hello!"
}
```

```diff
❌ Expected changes do not match: ...

  FeatureModel.DebugSnapshot(
    count: 1,
-   title: "Hello!"
+   title: ""
  )

(Expected: −, Actual: +)
``` 

## Tracking and ignoring properties

By default the macro includes stored properties that match the type's access level and excludes
closures, private properties, and properties prefixed with `_`. You can override these defaults:

```swift
@DebugSnapshot
@Observable
final class FeatureModel {
  var count = 0
  var title = ""
  // Automatically ignored
  var onChange: () -> Void

  // Include a private property:
  @DebugSnapshotTracked
  private var secret = ""

  // Include a computed property:
  @DebugSnapshotTracked
  var isLoading: Bool { task != nil }

  // Exclude a property:
  @DebugSnapshotIgnored
  var id = UUID()
}
```

Tracking computed properties is particularly powerful because it allows you to get exhaustive test
coverage on them:

```swift
let model = FeatureModel()

await expect(model) {
  await model.fetchButtonTapped()
} changes: {
  $0.isLoading = true
}
```

## Nested models

When a property is itself a `@DebugSnapshot`-annotated type, mark it with
`@DebugSnapshotConvertible` so that it snapshots recursively. This works with optionals and arrays,
and handles circular references automatically:

```swift
@DebugSnapshot
@Observable
final class UserModel {
  var name: String
  @DebugSnapshotConvertible var friends: [UserModel] = []
  @DebugSnapshotConvertible var referrer: UserModel?
}
```

## Enums

`@DebugSnapshot` works on enums too, generating a parallel snapshot enum. Mark individual cases
with `@DebugSnapshotConvertible` to convert their associated values:

```swift
@DebugSnapshot
enum Destination {
  @DebugSnapshotConvertible
  case detail(DetailModel)
  @DebugSnapshotConvertible
  case settings(SettingsModel)
  case dismissed
}
```

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
