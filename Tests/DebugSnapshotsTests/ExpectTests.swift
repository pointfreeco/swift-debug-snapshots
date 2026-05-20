import CustomDump
import DebugSnapshots
import Foundation
import Observation
import Testing

@Suite struct ExpectTests {
  @Test func exhaustive() throws {
    let model = FeatureModel()
    expect(model) {
      model.perturb()
    } changes: {
      $0.title = "!"
    }
  }

  @Test func equatableReferences() throws {
    let wrapper = Wrapper()
    expect(wrapper) {
      wrapper.keyPath = \String.count
    } changes: {
      $0.keyPath = \String.count
    }
  }

  @Test func noChanges() throws {
    let model = FeatureModel()
    withKnownIssue {
      expect(model) {
      } changes: {
        $0.title = ""
      }
    } matching: {
      $0.description.hasSuffix("Expected changes did not occur")
    }
  }

  @Test func nonexhaustive() throws {
    let model = FeatureModel()
    model.perturb()
    expect(model) {
      $0.title = "!"
    }

    withKnownIssue {
      expect(model) {
        $0.title = "?"
      }
    } matching: {
      $0.description.hasSuffix(
        """
        Expected changes do not match: ...

            #1 FeatureModel.DebugSnapshot(
          −   title: "?",
          +   title: "!",
              isLoading: false
            )

        (Expected: −, Actual: +)
        """
      )
    }
  }

  @Test func async() async throws {
    let model = FeatureModel()
    await expect(model) {
      await model.perturb()
    } changes: {
      $0.title = "!"
    }
//    customDump(model as Any)
//    customDump(model)
//    customDump(snap(model))
    // customDumpSnapshot(model)
    // dumpSnapshot(model)
  }

  @Test func computed() throws {
    let model = FeatureModel()
    expect(model) {
      model.load()
    } changes: {
      $0.isLoading = true
    }
  }

  @Test func references() {
    let blobJr = UserModel(name: "Blob Jr")
    expect(blobJr) {
      _ = blobJr.refer(name: "Blob")
    } changes: {
      $0.referred.append(UserModel.DebugSnapshot(name: "Blob", referrer: $0))
    }
  }

  @Test func recursiveSnapshot() {
    let blobJr = UserModel(name: "Blob Jr")
    blobJr.referrer = blobJr

    let snapshot = snap(blobJr)

    #expect(snapshot.referrer != nil)
    #expect(snapshot.referrer! === snapshot)
  }

  @Test func customDumpReferences() {
    let blobJr = UserModel(name: "Blob Jr")
    _ = blobJr.refer(name: "Blob")

    #expect(
      String(customDumping: snap(blobJr))
        == #"""
        #1 UserModel.DebugSnapshot(
          name: "Blob Jr",
          referred: [
            [0]: #2 UserModel.DebugSnapshot(
              name: "Blob",
              referred: [],
              referrer: #1 UserModel.DebugSnapshot(↩︎)
            )
          ],
          referrer: nil
        )
        """#
    )
  }

  @Test func snapshotDiffReferences() {
    let blobJr = UserModel(name: "Blob Jr")
    let blob = blobJr.refer(name: "Blob")
    let before = snap(blobJr)

    blob.name = "Blob!"
    let after = snap(blobJr)

    let difference = _diff(before, after)
    #expect(difference?.contains(#"-       name: "Blob""#) == true)
    #expect(difference?.contains(#"+       name: "Blob!""#) == true)
    #expect(difference?.contains(#"referrer: #1 UserModel.DebugSnapshot(↩︎)"#) == true)
  }
}

@DebugSnapshot
@Observable
private final class FeatureModel: CustomDumpRepresentable {
  private var privateCount: Int
  var title: String
  var onChange: (Int) -> Void
  @DebugSnapshotIgnored var id: UUID
  @DebugSnapshotTracked var isLoading: Bool {
    task != nil
  }
  private var task: Task<Void, Never>?

  init(
    count: Int = 0,
    title: String = "",
    onChange: @escaping (Int) -> Void = { _ in },
    ignored: UUID = UUID()
  ) {
    self.privateCount = count
    self.title = title
    self.onChange = onChange
    self.id = ignored
  }

  func perturb() {
    privateCount += 1
    title += "!"
    id = UUID()
  }

  //@LogChanges
  func perturb() async {
    privateCount += 1
    title += "!"
    id = UUID()
  }

  func load() {
    task = Task {
      let never = AsyncStream<Never> { _ in }
      for await _ in never {}
    }
  }
}

@DebugSnapshot
@Observable
final class UserModel {
  var name: String
  @DebugSnapshotConvertible var referred: [UserModel] = []
  @DebugSnapshotConvertible var referrer: UserModel?

  init(name: String, referred: [UserModel] = [], referrer: UserModel? = nil) {
    self.name = name
    self.referred = referred
    self.referrer = referrer
  }

  @discardableResult
  func refer(name: String) -> UserModel {
    let user = UserModel(name: name, referrer: self)
    referred.append(user)
    return user
  }
}

@DebugSnapshot
private final class Wrapper {
  var keyPath: AnyKeyPath = \Wrapper.keyPath
}
