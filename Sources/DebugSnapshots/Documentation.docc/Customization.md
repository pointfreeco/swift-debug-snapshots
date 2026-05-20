# Snapshot customization

Configure your debug snapshots to precisely track the data you want to test and debug.

## Overview

Add snapshots to your model data to unlock exhaustive testability and powerful debug tools. Apply
the ``DebugSnapshot()`` macro to a type to define its snapshot, and use the
``DebugSnapshotTracked()``, ``DebugSnapshotIgnored()``, and ``DebugSnapshotConvertible()``
attributes to customize the snapshot's definition.

## Snapshot defaults

By default the ``DebugSnapshot()`` macro uses a few rules to determine if a property should be
tracked or ignored:

  - Private properties, or properties with access control that is less than the access control of
    their enclosing type, are ignored.
  - Underscored properties are ignored.
  - Computed properties are ignored: you must opt into tracking them in the snapshot.
  - Closure properties are ignored: closures are black boxes and cannot be meaningfully tested or
    debug-printed.

For example:

```swift
@DebugSnapshot final class FeatureModel {
  let id: UUID
  var number = 0
  var fact: String?
  var isLoading: Bool {
    task != nil
  }
  var onLoad: () -> Void
  private var task: Task<Void, Never>?
  // ...
}
```

The snapshot generated for this model will include the `id`, `number`, and `fact` attributes, while
`isLoading`, `onLoad`, and `task` will be omitted.

It is also possible to apply `@DebugSnapshot` to struct and enum types to snapshot their properties
and cases respectively. The same rules that apply to classes apply to structs and enums, but ignored
cases are not omitted entirely, just the contents of its associated value.

Default rules can be overridden using `@DebugSnapshotTracked` and `@DebugSnapshotIgnored`, while
nested snapshots can be generated using `@DebugSnapshotConvertible`, each of which is covered below.

## Explicitly tracking properties

To track a property that would otherwise be ignored, apply the ``DebugSnapshotTracked()`` attribute.
It allows you to track computed properties that rely on private data that shouldn't be snapshot:

```swift
@DebugSnapshotTracked var isLoading: Bool {
  task != nil
}
private var task: Task<Void, Never>?
```

The `isLoading` property will now be included in any snapshot taken, allowing you to exhaustively
test logic involving it when using the library's testing tools.

You can also track private, encapsulated properties without changing broadening their access
control:

```swift
@DebugSnapshotTracked private var isStale = false
```

This property is now testable, even exhaustively so, despite being inaccessible outside of the type
it is defined on.

## Explicitly ignoring properties

To ignore a property that would otherwise be tracked, apply the ``DebugSnapshotIgnored()``
attribute. For example, your model data may contain properties that aren't currently testable:

```swift
@DebugSnapshotIgnored var id: UUID
```

> Tip: Use the [Dependencies](https://github.com/pointfreeco/swift-dependencies) package to control
> UUID generation in your application, making properties like the above fully deterministic and
> testable.

## Nesting snapshots

When a type annotated with `@DebugSnapshot` nests another type that is annotated with
`@DebugSnapshot`, apply the ``DebugSnapshotConvertible()`` attribute to recursively snapshot the
nested type:

```swift
@DebugSnapshotConvertible var child: ChildModel
```

This works with arrays of snapshot-convertible elements, as well as optional elements, and circular
references are automatically handled:

```swift
@DebugSnapshot class User {
  @DebugSnapshotConvertible var friends: [User] = []
  @DebugSnapshotConvertible var referrer: User?
  // ...
}
```

It also applies to enum cases containing snapshot-convertible values:

```swift
@DebugSnapshot enum Destination {
  @DebugSnapshotConvertible case detail(DetailModel)
  @DebugSnapshotConvertible case settings(SettingsModel)
  // ...
}
```
