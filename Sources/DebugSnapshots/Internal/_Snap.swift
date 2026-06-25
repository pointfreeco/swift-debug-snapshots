public func _snapshotType<Value>(_ type: Value.Type) -> Value {
  fatalError("'_snapshotType' should not be invoked directly")
}

public func _snapshotType<Value: DebugSnapshotConvertible>(
  _ type: Value.Type
) -> Value.DebugSnapshot {
  fatalError("'_snapshotType' should not be invoked directly")
}

public func _snapshotDefault<Value>(_ value: Value) -> Value {
  value
}

public func _snapshotDefault<Value: DebugSnapshotConvertible>(
  _ value: Value
) -> Value.DebugSnapshot {
  snap(value)
}

@propertyWrapper
public struct _Snap<Value> {
  private var box: Box

  public var wrappedValue: Value {
    get { box.get() }
    set {
      if isKnownUniquelyReferenced(&box) {
        box.set(newValue)
      } else {
        box = Box(value: newValue)
      }
    }
  }

  public init(wrappedValue lazyValue: @escaping @autoclosure () -> Value) {
    box = Box(lazyValue: lazyValue)
  }

  private init(_ value: Value) {
    box = Box(value: value)
  }

  private final class Box: @unchecked Sendable {
    private var lazyValue: (() -> Value)?
    private var value: Value?
    init(lazyValue: @escaping () -> Value) { self.lazyValue = lazyValue }
    init(value: Value) { self.value = value }
    func get() -> Value {
      if let value { return value }
      let v = lazyValue!()
      value = v
      lazyValue = nil
      return v
    }
    func set(_ newValue: Value) {
      value = newValue
      lazyValue = nil
    }
  }
}

extension _Snap: Equatable where Value: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.wrappedValue == rhs.wrappedValue
  }
}

extension _Snap: Hashable where Value: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(wrappedValue)
  }
}

extension _Snap: Identifiable where Value: Identifiable {
  public var id: Value.ID {
    wrappedValue.id
  }
}

extension _Snap: Encodable where Value: Encodable {
  public func encode(to encoder: any Encoder) throws {
    try wrappedValue.encode(to: encoder)
  }
}

extension _Snap: Decodable where Value: Decodable {
  public init(from decoder: any Decoder) throws {
    self.init(try Value(from: decoder))
  }
}

extension _Snap: Sendable where Value: Sendable {}

extension _Snap: CustomReflectable {
  public var customMirror: Mirror {
    Mirror(reflecting: wrappedValue)
  }
}
