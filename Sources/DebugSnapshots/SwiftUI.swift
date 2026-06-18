#if canImport(SwiftUI)
  public import SwiftUI

  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  extension Bindable where Value: AnyObject & DebugSnapshotConvertible {
    public subscript<Subject>(
      dynamicMember keyPath: ReferenceWritableKeyPath<Value, Subject>
    ) -> Binding<Subject> {
      func erase<T: AnyObject>(
        _ object: Bindable<T>,
        keyPath: ReferenceWritableKeyPath<T, Subject>
      ) -> Binding<Subject> {
        object[dynamicMember: keyPath]
      }
      return erase(self, keyPath: \.[logChanges: keyPath])
    }
  }

  fileprivate extension DebugSnapshotConvertible where Self: AnyObject {
    subscript<Subject>(logChanges keyPath: ReferenceWritableKeyPath<Self, Subject>) -> Subject {
      get { self[keyPath: keyPath] }
      set {
        guard Self._logChanges.contains(keyPath) else {
          self[keyPath: keyPath] = newValue
          return
        }
        let before = snap(self)
        self[keyPath: keyPath] = newValue
        let after = snap(self)
        DebugSnapshots._logChanges(before, after, function: "Binding")
      }
      _modify {
        guard Self._logChanges.contains(keyPath) else {
          yield &self[keyPath: keyPath]
          return
        }
        let before = snap(self)
        yield &self[keyPath: keyPath]
        let after = snap(self)
        DebugSnapshots._logChanges(before, after, function: "Binding")
      }
    }
  }
#endif
