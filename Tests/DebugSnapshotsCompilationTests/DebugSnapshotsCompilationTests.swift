import CompilationTesting
import Testing

extension BaseSuite {
  @Suite
  struct DebugSnapshotsCompilationTests {
    @Test func `private properties are private in snapshots`() async {
      await assertCompilation {
        """
        import DebugSnapshots
        @DebugSnapshot class Model {
          var internalField = 0
          private var privateField = 0
          @DebugSnapshotTracked private var trackedPrivateField = 0
        }
        let model = Model()
        expect(model) {
          $0.internalField = 0
          $0.privateField = 0
          $0.trackedPrivateField = 0
        }
        """
      } diagnostics: {
        """
        import DebugSnapshots
        @DebugSnapshot class Model {
          var internalField = 0
          private var privateField = 0
          @DebugSnapshotTracked private var trackedPrivateField = 0
        }
        let model = Model()
        expect(model) {
          $0.internalField = 0
          $0.privateField = 0
             ˄
             ╰─ error: value of type 'Model.DebugSnapshot' has no dynamic member 'privateField' using key path from root type 'Model.DebugSnapshotValue'
          $0.trackedPrivateField = 0
        }
        """
      }
    }
  }
}
