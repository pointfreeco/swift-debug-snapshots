package import SwiftSyntax

extension AttributeSyntax {
  package func isEquivalent(to other: AttributeSyntax) -> Bool {
    let lhs = normalizedAttributeNameComponents(of: attributeName)
    let rhs = normalizedAttributeNameComponents(of: other.attributeName)

    return lhs == rhs
      || lhs == droppingKnownModulePrefix(from: rhs)
      || droppingKnownModulePrefix(from: lhs) == rhs
  }
}

extension DeclSyntaxProtocol {
  func addIfNeeded(
    _ attribute: AttributeSyntax?,
    in keyPath: KeyPath<Self, AttributeListSyntax>,
    to attributes: inout [AttributeSyntax]
  ) {
    guard let attribute else { return }
    if !hasAttribute(in: keyPath, equivalentTo: attribute) {
      attributes.append(attribute)
    }
  }

  func hasAttribute(
    in keyPath: KeyPath<Self, AttributeListSyntax>,
    equivalentTo attribute: AttributeSyntax
  ) -> Bool {
    for attr in self[keyPath: keyPath] {
      switch attr {
      case .attribute(let attr):
        if attr.isEquivalent(to: attribute) {
          return true
        }
      default:
        break
      }
    }
    return false
  }
}

private func normalizedAttributeNameComponents(of type: TypeSyntax) -> [String] {
  if let type = type.as(IdentifierTypeSyntax.self) {
    return [type.name.text]
  }
  if let type = type.as(MemberTypeSyntax.self) {
    return normalizedAttributeNameComponents(of: type.baseType) + [type.name.text]
  }
  if let type = type.as(AttributedTypeSyntax.self) {
    return normalizedAttributeNameComponents(of: type.baseType)
  }
  return [type.trimmedDescription]
}

private func droppingKnownModulePrefix(from components: [String]) -> [String] {
  guard components.first == moduleName else { return components }
  return Array(components.dropFirst())
}
