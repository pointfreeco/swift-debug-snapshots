import CompilationTesting
import Testing

extension BaseSuite {
  @Suite
  struct DebugSnapshotsCompilationTests {
    @Test func `snapshots of enums must have an associated value`() async {
      await assertCompilation {
        """
        @DebugSnapshot
        enum Parent { case empty }
        """
      } 
    }

    @Test func `snapshot convertible fields are diagnosed`() async {
      await assertCompilation {
        """
        @DebugSnapshot class ChildModel {
          static let shared = ChildModel()
          var count = 0
        }
        @DebugSnapshot class ParentModel {
          let childWithDefault = ChildModel()
          let childWithAnnotation: ChildModel
          let childWithStaticDefault = ChildModel.shared
        }
        """
      } diagnostics: {
        """
        import DebugSnapshots

        @DebugSnapshot class ChildModel {
          static let shared = ChildModel()
          var count = 0
        }
        @DebugSnapshot class ParentModel {
                             ˄
                             ╰─ error: class 'ParentModel' has no initializers
          let childWithDefault = ChildModel()
          ˄
          ╰─ warning: Property must be annotated '@DebugSnapshotConvertible' to snapshot (from macro 'DebugSnapshots.DebugSnapshotCheck')
          ╰─ note: Apply '@DebugSnapshotConvertible' to snapshot
          ╰─ note: Apply '@DebugSnapshotIgnored' to ignore
          ╰─ note: Apply '@DebugSnapshotTracked' to track reference identity in snapshot
          let childWithAnnotation: ChildModel
          ˄
          ╰─ warning: Property must be annotated '@DebugSnapshotConvertible' to snapshot (from macro 'DebugSnapshots.DebugSnapshotCheck')
          ╰─ note: Apply '@DebugSnapshotConvertible' to snapshot
          ╰─ note: Apply '@DebugSnapshotIgnored' to ignore
          ╰─ note: Apply '@DebugSnapshotTracked' to track reference identity in snapshot
              ˄
              ╰─ note: stored property 'childWithAnnotation' without initial value prevents synthesized initializers
          let childWithStaticDefault = ChildModel.shared
          ˄
          ╰─ warning: Property must be annotated '@DebugSnapshotConvertible' to snapshot (from macro 'DebugSnapshots.DebugSnapshotCheck')
          ╰─ note: Apply '@DebugSnapshotConvertible' to snapshot
          ╰─ note: Apply '@DebugSnapshotIgnored' to ignore
          ╰─ note: Apply '@DebugSnapshotTracked' to track reference identity in snapshot
        }
        """
      }
    }

    @Test func `private properties are private in snapshots`() async {
      await assertCompilation {
        """
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
