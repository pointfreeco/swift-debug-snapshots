import CompilationTesting
import SnapshotTesting
import Testing

@Suite(
  .compilation(mode: .main, imports: ["DebugSnapshots"]),
  .snapshots(record: .failed)
)
struct BaseSuite {}
