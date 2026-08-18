// The import is public because the models are: their generated `DebugSnapshotConvertible`
// conformance is public API. Nothing about the properties below requires it.
public import DebugSnapshots

// Every property is mirrored at its own access level, bounded below by `internal`, so a public
// model publishes only what it declares public while an explicitly tracked `private` property stays
// readable within the module. The assertions live in `AccessLevelTests`, in another file, so that a
// mirror emitted below `internal` would fail to compile there.
@DebugSnapshot public struct AccessLevelState {
  public var title = ""
  package var identifier = 0
  var theme = 0
  @DebugSnapshotTracked private var isStale = false

  public init() {}
}

@DebugSnapshot public final class AccessLevelModel {
  public var title = ""
  var theme = 0
  @DebugSnapshotTracked private var isStale = false

  public init() {}
}
