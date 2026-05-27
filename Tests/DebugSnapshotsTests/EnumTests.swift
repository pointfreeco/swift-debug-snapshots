import CustomDump
import DebugSnapshots
import Foundation
import Observation
import Testing

@Suite struct EnumTests {
  @Test func `non-equatable enum handles void cases`() {
    var destination = Destination.one(42)
    expect(destination) {
      destination = .three
    } changes: {
      $0 = .three
    }
  }

  @Test func `optional non-equatable enum handles void cases`() {
    var destination: Destination?
    expect(destination) {
      destination = .three
    } changes: {
      $0 = .three
    }
  }

  @Test func `non-equatable enum expectation failure`() {
    var destination = Destination.one(42)
    withKnownIssue {
      expect(destination) {
        destination = .three
      } changes: {
        $0 = .two("Forty two")
      }
    } matching: {
      $0.description.hasSuffix(
        """
        Expected changes do not match: ...

          − Destination.DebugSnapshot.two("Forty two")
          + Destination.DebugSnapshot.three

        (Expected: −, Actual: +)
        """)
    }
  }

  @Test func `equatable enum handles void cases`() {
    var destination = EquatableDestination.one(42)
    expect(destination) {
      destination = .three
    } changes: {
      $0 = .three
    }
  }
}

@DebugSnapshot
private enum Destination {
  case one(Int)
  case two(String)
  case three
}

@DebugSnapshot
private enum EquatableDestination: Equatable {
  case one(Int)
  case two(String)
  case three
}

@Suite
@DebugSnapshot
private class DestinationModelTests {
  @DebugSnapshotConvertible
  var destination: Destination?
  func settingsButtonTapped() {
    destination = .settings(Settings())
  }
  func toggleButtonTapped() {
    guard case .settings(let settings) = destination
    else { return }
    settings.isOn.toggle()
  }
  func detailButtonTapped() {
    destination = .detail(Detail())
  }
  @DebugSnapshot
  enum Destination {
    @DebugSnapshotConvertible
    case settings(Settings)
    @DebugSnapshotConvertible
    case detail(Detail)
  }
  @DebugSnapshot
  class Settings {
    var isOn: Bool
    init(isOn: Bool = false) {
      self.isOn = isOn
    }
  }
  @DebugSnapshot
  class Detail {
    var text: String
    init(text: String = "") {
      self.text = text
    }
  }

  @Test func `change destination`() {
    let model = DestinationModelTests()
    expect(model) {
      model.settingsButtonTapped()
    } changes: {
      $0.destination = .settings(Settings.DebugSnapshot(isOn: false))
    }
    expect(model) {
      model.toggleButtonTapped()
    } changes: {
      $0.destination = .settings(Settings.DebugSnapshot(isOn: true))
    }
  }
}
