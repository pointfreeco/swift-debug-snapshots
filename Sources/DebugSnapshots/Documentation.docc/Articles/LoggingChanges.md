# Logging changes to model data

Automatically log changes to your model when methods are invoked.

## Overview

The [`@DebugSnapshot`](<doc:DebugSnapshot()>) macro can be customized to automatically log how
your model changes when each method is invoked, or a more focused 
 [`@LogChanges`](<doc:LogChanges()>) macro can be applied on a per-method basis.

To log changes for every method in your model, supply the `.logChanges` option to the macro:

  ```swift
  @DebugSnapshots(.logChanges)
  class FeatureModel {
    // ...
  }
  ```

When any method is invoked in this class, a nicely formatted diff will be logged that shows you
exactly how the state changed once the method finished:

  ```swift
  await model.searchButtonTapped()
  // searchButtonTapped():
  //     #1 FeatureModel.DebugSnapshot(
  //  -    results: []
  //  +    results: [
  //  +      "Blob",
  //  +      "Blob Jr",
  //  +      "Blob Sr",
  //  +    ]
  //     )
  ```

Further, you can apply `@DebugSnapshots(.logChanges)` to an extension of your model to log the 
changes from the methods in the extension:

  ```swift
  @DebugSnapshots(.logChanges)
  extension FeatureModel {
    func refreshButtonTapped() {
      // Changes logged automatically for this method
      // ...
    }
  }
  ```

If you prefer to be more precise about which methods log their changes, you can use the 
[`@LogChanges`](<doc:LogChanges()>) macro on any method:

  ```swift
  @DebugSnapshots
  class FeatureModel {
    // ...
    @LogChanges
    func searchButtonTapped() {
      // ...
    }
  }
  ```

That can help prevent too much from logging to the console at once.

You can also log changes in the middle of your method's execution by invoking `$logChanges()`
at any point:

  ```swift
  func onAppear() async {
    for await value in stream {
      values.append(value)
      $logChanges()
    }
  }
  ```

That will print what has changed in the method since the last time `$logChanges()` was invoked.
