import Foundation
import Testing

extension Trait where Self == ConditionTrait {
  static var requiresXcodeTestRunner: Self {
    .disabled(if: !isXcodeTestRunner, "Requires Xcode's test runner")
  }
}
 
private let isXcodeTestRunner: Bool = {
  ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
}()
