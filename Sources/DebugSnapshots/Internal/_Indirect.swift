@propertyWrapper
public struct _Indirect<Value> {
  private var box: Box

  public var wrappedValue: Value {
    get { box.value }
    set {
      if isKnownUniquelyReferenced(&box) {
        box.value = newValue
      } else {
        box = Box(newValue)
      }
    }
    _modify {
      if !isKnownUniquelyReferenced(&box) {
        box = Box(box.value)
      }
      yield &box.value
    }
  }

  public init(wrappedValue: Value) {
    box = Box(wrappedValue)
  }

  private final class Box: @unchecked Sendable {
    var value: Value
    init(_ value: Value) { self.value = value }
  }
}

extension _Indirect: Decodable where Value: Decodable {
  public init(from decoder: any Decoder) throws {
    try self.init(wrappedValue: Value(from: decoder))
  }
}

extension _Indirect: Encodable where Value: Encodable {
  public func encode(to encoder: any Encoder) throws {
    try wrappedValue.encode(to: encoder)
  }
}

extension _Indirect: Equatable where Value: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.wrappedValue == rhs.wrappedValue
  }
}

extension _Indirect: Hashable where Value: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(wrappedValue)
  }
}

extension _Indirect: Identifiable where Value: Identifiable {
  public var id: Value.ID {
    wrappedValue.id
  }
}

extension _Indirect: Sendable where Value: Sendable {}

extension _Indirect: CustomReflectable {
  public var customMirror: Mirror {
    Mirror(reflecting: wrappedValue)
  }
}
