@propertyWrapper
public struct _Indirect<Value>: @unchecked Sendable {
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
