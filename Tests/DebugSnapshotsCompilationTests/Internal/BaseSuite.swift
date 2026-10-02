import CompilationTesting
import SnapshotTesting
import Testing

@Suite(
  .compilation(mode: .main),
  .snapshots(record: .failed)
)
struct BaseSuite {}
