import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public enum DebugSnapshotAttribute {
  case convertible, ignored, tracked
}

public enum DebugSnapshotMacro {}

extension DebugSnapshotMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    guard !hasDebugSnapshotConvertibleConformance(declaration) else {
      return []
    }

    let conformanceIsolation: String
    #if compiler(>=6.2)
      conformanceIsolation = hasMainActorAnnotation(declaration) ? "@MainActor " : ""
    #else
      conformanceIsolation = ""
    #endif
    return [
      DeclSyntax(
        """
        extension \(type.trimmed): \
        \(raw: conformanceIsolation)\(raw: moduleName).DebugSnapshotConvertible {}
        """
      )
      .cast(ExtensionDeclSyntax.self)
    ]
  }
}

extension DebugSnapshotMacro: MemberAttributeMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingAttributesFor member: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AttributeSyntax] {
    return try expansion(
      of: node,
      attachedTo: declaration,
      providingAttributesFor: member,
      in: context,
      debugSnapshotAttribute: { _ in nil }
    )
  }

  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingAttributesFor member: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext,
    debugSnapshotAttribute: (DeclSyntax) -> DebugSnapshotAttribute?
  ) throws -> [AttributeSyntax] {
    let requiredAccess = effectiveAccessLevel(for: declaration, in: context)
    if let variable = member.as(VariableDeclSyntax.self),
      variable.bindings.count == 1,
      !variable.hasAttribute(in: \.attributes, equivalentTo: "@DebugSnapshotIgnored"),
      !variable.hasAttribute(in: \.attributes, equivalentTo: "@DebugSnapshotTracked"),
      !variable.hasAttribute(in: \.attributes, equivalentTo: "@DebugSnapshotConvertible")
    {
      let attribute: DebugSnapshotAttribute
      if let override = debugSnapshotAttribute(DeclSyntax(variable)) {
        attribute = override
      } else if let binding = variable.bindings.first,
        isTrackedByDefault(variable, binding: binding, requiredAccess: requiredAccess)
      {
        attribute = .tracked
      } else {
        attribute = .ignored
      }
      var attributes: [AttributeSyntax] = []
      switch attribute {
      case .convertible:
        variable.addIfNeeded("@DebugSnapshotConvertible", in: \.attributes, to: &attributes)
      case .tracked:
        variable.addIfNeeded("@DebugSnapshotTracked", in: \.attributes, to: &attributes)
      case .ignored:
        variable.addIfNeeded("@DebugSnapshotIgnored", in: \.attributes, to: &attributes)
      }
      return attributes
    }

    if let enumCase = member.as(EnumCaseDeclSyntax.self),
      !enumCase.hasAttribute(in: \.attributes, equivalentTo: "@DebugSnapshotIgnored"),
      !enumCase.hasAttribute(in: \.attributes, equivalentTo: "@DebugSnapshotTracked"),
      !enumCase.hasAttribute(in: \.attributes, equivalentTo: "@DebugSnapshotConvertible")
    {
      let attribute = debugSnapshotAttribute(DeclSyntax(enumCase)) ?? .tracked
      var attributes: [AttributeSyntax] = []
      switch attribute {
      case .convertible:
        enumCase.addIfNeeded("@DebugSnapshotConvertible", in: \.attributes, to: &attributes)
      case .tracked:
        enumCase.addIfNeeded("@DebugSnapshotTracked", in: \.attributes, to: &attributes)
      case .ignored:
        enumCase.addIfNeeded("@DebugSnapshotIgnored", in: \.attributes, to: &attributes)
      }
      return attributes
    }

    return []
  }
}

extension DebugSnapshotMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    try expansion(
      of: node,
      providingMembersOf: declaration,
      conformingTo: protocols,
      in: context,
      attributeConformanceMapping: [:],
      filterPropagatedAttributes: { _ in [] },
      debugSnapshotAttribute: { _ in nil }
    )
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext,
    attributeConformanceMapping: [String: [String]] = [:],
    filterPropagatedAttributes: (AttributeListSyntax) -> AttributeListSyntax,
    debugSnapshotAttribute: (DeclSyntax) -> DebugSnapshotAttribute?
  ) throws -> [DeclSyntax] {
    guard
      let modelDecl = ModelDecl(
        declaration: declaration,
        context: context,
        debugSnapshotAttribute: debugSnapshotAttribute
      )
    else {
      return []
    }

    return memberDeclarations(
      for: modelDecl,
      declaration: declaration,
      filterPropagatedAttributes: filterPropagatedAttributes,
      attributeConformanceMapping: attributeConformanceMapping
    )
  }
}

private func memberDeclarations(
  for modelDecl: ModelDecl,
  declaration: some DeclGroupSyntax,
  filterPropagatedAttributes: (AttributeListSyntax) -> AttributeListSyntax,
  attributeConformanceMapping: [String: [String]]
) -> [DeclSyntax] {
  switch modelDecl.kind {
  case .classOrStruct(let properties, let isClass):
    return classOrStructMemberDeclarations(
      for: modelDecl,
      declaration: declaration,
      properties: properties,
      isClass: isClass,
      filterPropagatedAttributes: filterPropagatedAttributes,
      attributeConformanceMapping: attributeConformanceMapping
    )
  case .enumeration(let enumCases):
    return enumMemberDeclarations(
      name: modelDecl.name,
      declaration: declaration,
      enumCases: enumCases,
      filterPropagatedAttributes: filterPropagatedAttributes,
      attributeConformanceMapping: attributeConformanceMapping
    )
  }
}

private func classOrStructMemberDeclarations(
  for modelDecl: ModelDecl,
  declaration: some DeclGroupSyntax,
  properties: [ModelDecl.Property],
  isClass: Bool,
  filterPropagatedAttributes: (AttributeListSyntax) -> AttributeListSyntax,
  attributeConformanceMapping: [String: [String]]
) -> [DeclSyntax] {
  if isClass {
    return classMemberDeclarations(
      for: modelDecl,
      declaration: declaration,
      properties: properties,
      filterPropagatedAttributes: filterPropagatedAttributes,
      attributeConformanceMapping: attributeConformanceMapping
    )
  } else {
    return structMemberDeclarations(
      for: modelDecl,
      declaration: declaration,
      properties: properties,
      filterPropagatedAttributes: filterPropagatedAttributes,
      attributeConformanceMapping: attributeConformanceMapping
    )
  }
}

private func structMemberDeclarations(
  for modelDecl: ModelDecl,
  declaration: some DeclGroupSyntax,
  properties: [ModelDecl.Property],
  filterPropagatedAttributes: (AttributeListSyntax) -> AttributeListSyntax,
  attributeConformanceMapping: [String: [String]]
) -> [DeclSyntax] {
  let propagatedAttributes = propagatedAttributesOutput(
    from: declaration,
    filterPropagatedAttributes: filterPropagatedAttributes,
    attributeConformanceMapping: attributeConformanceMapping
  )
  let debugSnapshotConformances = deduplicatedConformances(
    debugSnapshotConformances(
      for: declaration,
      properties: properties
    ) + propagatedAttributes.conformances
  )
  let propertyLines = snapshotPropertyLines(for: properties, modelName: modelDecl.name)
  let hasIndirectProperties = properties.contains(where: \.isDebugSnapshotConvertible)
  var allConformances = debugSnapshotConformances
  if hasIndirectProperties {
    allConformances.append("CustomReflectable")
  }
  let conformancesDescription =
    snapshotConformanceDescription(allConformances)
  let customMirrorDecl: String
  if hasIndirectProperties {
    let mirrorChildren =
      properties
      .map { "\"\($0.name)\": \($0.name) as Any" }
      .joined(separator: ", ")
    customMirrorDecl = """
      \npublic var customMirror: Mirror {
      Mirror(self, children: [\(mirrorChildren)], displayStyle: .struct)
      }
      """
  } else {
    customMirrorDecl = ""
  }
  let representation =
    DeclSyntax(
      """
      \(raw: propagatedAttributes.description)\
      public struct DebugSnapshot\(raw: conformancesDescription) {
      \(raw: propertyLines.joined(separator: "\n"))\(raw: customMirrorDecl)
      }
      """
    )

  let visitorInitArguments =
    properties
    .map {
      "\($0.name): \($0.isDebugSnapshotConvertible ? "\(moduleName)._debugSnapshot(value.\($0.name), visitor: &visitor)" : "value.\($0.name)")"
    }
    .joined(separator: ", ")
  let _debugSnapshot =
    DeclSyntax(
      """
      public static func _debugSnapshot(_ value: \(raw: modelDecl.name), visitor: inout \(raw: moduleName)._DebugSnapshotVisitor) -> DebugSnapshot {
      DebugSnapshot(\(raw: visitorInitArguments))
      }
      """
    )
  return [representation, _debugSnapshot]
}

private func classMemberDeclarations(
  for modelDecl: ModelDecl,
  declaration: some DeclGroupSyntax,
  properties: [ModelDecl.Property],
  filterPropagatedAttributes: (AttributeListSyntax) -> AttributeListSyntax,
  attributeConformanceMapping: [String: [String]]
) -> [DeclSyntax] {
  let propagatedAttributes = propagatedAttributesOutput(
    from: declaration,
    filterPropagatedAttributes: filterPropagatedAttributes,
    attributeConformanceMapping: attributeConformanceMapping
  )
  let snapshotConformances = deduplicatedConformances(
    debugSnapshotConformances(
      for: declaration,
      properties: properties
    ) + propagatedAttributes.conformances
  )
  let snapshotConformancesDescription =
    snapshotConformances.isEmpty
    ? ""
    : ": \(snapshotConformances.joined(separator: ", "))"

  let propertyLines = snapshotPropertyLines(
    for: properties,
    modelName: modelDecl.name,
    snapshotTypeName: "DebugSnapshot",
    applyIndirection: false
  )
  let snapshotStruct =
    DeclSyntax(
      """
      \(raw: propagatedAttributes.description)\
      public struct DebugSnapshotValue\(raw: snapshotConformancesDescription) {
      \(raw: propertyLines.joined(separator: "\n"))
      }
      """
    )

  let initParams = classInitParams(for: properties, modelName: modelDecl.name)
  let snapshotInitArguments = properties.map { "\($0.name): \($0.name)" }.joined(separator: ", ")
  let debugSnapshotClass =
    DeclSyntax(
      """
      @dynamicMemberLookup
      public final class DebugSnapshot: \(raw: moduleName)._DebugSnapshotObject {
      public var _snapshot: DebugSnapshotValue
      public var _originIdentifier: ObjectIdentifier?
      public var _diffSnapshot: (any \(raw: moduleName)._DebugSnapshotObject)?
      public init(\(raw: initParams)) {
      self._snapshot = DebugSnapshotValue(\(raw: snapshotInitArguments))
      }
      public subscript<T>(dynamicMember keyPath: WritableKeyPath<DebugSnapshotValue, T>) -> T {
      get { _snapshot[keyPath: keyPath] }
      set { _snapshot[keyPath: keyPath] = newValue }
      }
      }
      """
    )

  let nonConvertibleInitArguments =
    properties
    .filter { !$0.isDebugSnapshotConvertible }
    .map { "\($0.name): value.\($0.name)" }
    .joined(separator: ", ")
  let convertibleAssignments =
    properties
    .filter { $0.isDebugSnapshotConvertible }
    .map { "snapshot.\($0.name) = \(moduleName)._debugSnapshot(value.\($0.name), visitor: &visitor)" }
  let convertibleAssignmentsCode =
    convertibleAssignments.isEmpty
    ? ""
    : "\n" + convertibleAssignments.joined(separator: "\n")
  let _debugSnapshotMethod =
    DeclSyntax(
      """
      public static func _debugSnapshot(_ value: \(raw: modelDecl.name), visitor: inout \(raw: moduleName)._DebugSnapshotVisitor) -> DebugSnapshot {
      if let existing: DebugSnapshot = visitor.lookup(value) { return existing }
      let snapshot = DebugSnapshot(\(raw: nonConvertibleInitArguments))
      snapshot._originIdentifier = ObjectIdentifier(value)
      visitor.register(value, snapshot: snapshot)\(raw: convertibleAssignmentsCode)
      return snapshot
      }
      """
    )

  return [snapshotStruct, debugSnapshotClass, _debugSnapshotMethod]
}

private func snapshotPropertyLines(
  for properties: [ModelDecl.Property],
  modelName: String,
  snapshotTypeName: String = "DebugSnapshot",
  applyIndirection: Bool = true
) -> [String] {
  properties.map { property in
    let indirectPrefix = applyIndirection && property.isDebugSnapshotConvertible
      ? "@\(moduleName)._Indirect "
      : ""
    switch property.kind {
    case .type(let type):
      let snapshotType =
        property.isDebugSnapshotConvertible
        ? snapshotTypeDescription(for: type, snapshotTypeName: snapshotTypeName)
        : type
      return "\(indirectPrefix)public var \(property.name): \(snapshotType)"
    case .initializer(let defaultValue):
      let defaultValue = rewriteDefaultValue(
        defaultValue,
        modelTypeName: modelName,
        propertyTypeName: nil
      )
      .trimmedDescription
      if property.isDebugSnapshotConvertible {
        return "\(indirectPrefix)public var \(property.name) = \(moduleName).snap(\(defaultValue))"
      } else {
        return "public var \(property.name) = \(defaultValue)"
      }
    case .pair(let type, initializer: let defaultValue):
      let snapshotType =
        property.isDebugSnapshotConvertible
        ? snapshotTypeDescription(for: type, snapshotTypeName: snapshotTypeName)
        : type
      let defaultValue = rewriteDefaultValue(
        defaultValue,
        modelTypeName: modelName,
        propertyTypeName: type
      )
      .trimmedDescription
      if property.isDebugSnapshotConvertible {
        return """
          \(indirectPrefix)public var \(property.name): \(snapshotType) = \
          \(moduleName).snap(\(defaultValue))
          """
      } else {
        return "public var \(property.name): \(type) = \(defaultValue)"
      }
    }
  }
}

private func classInitParams(
  for properties: [ModelDecl.Property],
  modelName: String
) -> String {
  properties.map { property in
    let (type, defaultValue) = classInitParamTypeAndDefault(for: property, modelName: modelName)
    let defaultSuffix = defaultValue.map { " = \($0)" } ?? ""
    return "\(property.name): \(type)\(defaultSuffix)"
  }
  .joined(separator: ", ")
}

private func classInitParamTypeAndDefault(
  for property: ModelDecl.Property,
  modelName: String
) -> (type: String, default: String?) {
  switch property.kind {
  case .type(let type):
    let snapshotType =
      property.isDebugSnapshotConvertible
      ? snapshotTypeDescription(for: type, snapshotTypeName: "DebugSnapshot")
      : type
    let defaultValue: String? =
      if property.isDebugSnapshotConvertible {
        convertibleDefaultValue(for: type)
      } else {
        nil
      }
    return (snapshotType, defaultValue)

  case .initializer(let defaultValue):
    let defaultValue = rewriteDefaultValue(
      defaultValue,
      modelTypeName: modelName,
      propertyTypeName: nil
    )
    .trimmedDescription
    if property.isDebugSnapshotConvertible {
      return ("_", "\(moduleName).snap(\(defaultValue))")
    } else {
      return ("_", defaultValue)
    }

  case .pair(let type, initializer: let defaultValue):
    let snapshotType =
      property.isDebugSnapshotConvertible
      ? snapshotTypeDescription(for: type, snapshotTypeName: "DebugSnapshot")
      : type
    let defaultValue = rewriteDefaultValue(
      defaultValue,
      modelTypeName: modelName,
      propertyTypeName: type
    )
    .trimmedDescription
    if property.isDebugSnapshotConvertible {
      if let simpleDefault = convertibleDefaultValue(for: type) {
        return (snapshotType, simpleDefault)
      }
      return (snapshotType, "\(moduleName).snap(\(defaultValue))")
    } else {
      return (snapshotType, defaultValue)
    }
  }
}

private func convertibleDefaultValue(for type: String) -> String? {
  if type.hasSuffix("?") || type.hasSuffix("!") {
    return "nil"
  }
  if type.hasPrefix("[") {
    return "[]"
  }
  return nil
}

private func enumMemberDeclarations(
  name: String,
  declaration: some DeclGroupSyntax,
  enumCases: [ModelDecl.EnumCase],
  filterPropagatedAttributes: (AttributeListSyntax) -> AttributeListSyntax,
  attributeConformanceMapping: [String: [String]]
) -> [DeclSyntax] {
  let propagatedAttributes = propagatedAttributesOutput(
    from: declaration,
    filterPropagatedAttributes: filterPropagatedAttributes,
    attributeConformanceMapping: attributeConformanceMapping
  )
  let isIndirect =
    modifiers(of: declaration).contains { $0.name.tokenKind == .keyword(.indirect) }
  let debugSnapshotConformances = deduplicatedConformances(
    debugSnapshotConformances(
      for: declaration,
      properties: []
    ) + propagatedAttributes.conformances
  )
  let conformanceDescription =
    snapshotConformanceDescription(debugSnapshotConformances)
  let snapshotCaseLines = enumCases.map(debugSnapshotCaseDeclaration)
  let representation =
    DeclSyntax(
      """
      \(raw: propagatedAttributes.description)\
      public \(raw: isIndirect ? "indirect " : "")enum DebugSnapshot\(raw: conformanceDescription) {
      \(raw: snapshotCaseLines.joined(separator: "\n"))
      }
      """
    )
  let switchCases = enumCases.map(debugSnapshotSwitchCase)
  let _debugSnapshot =
    DeclSyntax(
      """
      public static func _debugSnapshot(_ value: \(raw: name), visitor: inout \(raw: moduleName)._DebugSnapshotVisitor) -> DebugSnapshot {
      switch value {
      \(raw: switchCases.joined(separator: "\n"))
      }
      }
      """
    )
  return [representation, _debugSnapshot]
}

private func debugSnapshotCaseDeclaration(_ enumCase: ModelDecl.EnumCase) -> String {
  let name = enumCase.element.name.text
  let indirectPrefix = enumCase.isIndirect ? "indirect " : ""
  guard !enumCase.isIgnored else {
    return "\(indirectPrefix)case \(name)"
  }
  guard var parameterClause = enumCase.element.parameterClause else {
    return "\(indirectPrefix)case \(name)"
  }
  if enumCase.isDebugSnapshotConvertible {
    for index in parameterClause.parameters.indices {
      parameterClause.parameters[index].type = debugSnapshotType(
        parameterClause.parameters[index].type)
    }
  }
  return "\(indirectPrefix)case \(name)\(parameterClause.trimmedDescription)"
}

private func debugSnapshotSwitchCase(_ enumCase: ModelDecl.EnumCase) -> String {
  let name = enumCase.element.name.text
  let parameters = Array(enumCase.element.parameterClause?.parameters ?? [])
  let bindings = parameters.indices.map { "v\($0 + 1)" }
  let pattern =
    if bindings.isEmpty {
      ".\(name)"
    } else {
      ".\(name)(\(bindings.map { "let \($0)" }.joined(separator: ", ")))"
    }

  if enumCase.isIgnored {
    return """
      case .\(name):
        return .\(name)
      """
  }

  if bindings.isEmpty {
    return """
      case \(pattern):
        return .\(name)
      """
  }

  let valueArguments = zip(parameters, bindings)
    .map { parameter, binding in
      let mappedValue =
        enumCase.isDebugSnapshotConvertible
        ? "\(moduleName)._debugSnapshot(\(binding), visitor: &visitor)"
        : binding
      return "\(caseParameterLabelPrefix(parameter))\(mappedValue)"
    }
    .joined(separator: ", ")
  return """
    case \(pattern):
      return .\(name)(\(valueArguments))
    """
}

private func debugSnapshotType(_ type: TypeSyntax) -> TypeSyntax {
  if let optionalType = type.trimmed.as(OptionalTypeSyntax.self) {
    return TypeSyntax(
      OptionalTypeSyntax(
        wrappedType: debugSnapshotType(optionalType.wrappedType),
        questionMark: optionalType.questionMark
      )
    )
  }
  if let implicitlyUnwrappedOptionalType = type.trimmed.as(
    ImplicitlyUnwrappedOptionalTypeSyntax.self)
  {
    return TypeSyntax(
      ImplicitlyUnwrappedOptionalTypeSyntax(
        wrappedType: debugSnapshotType(implicitlyUnwrappedOptionalType.wrappedType),
        exclamationMark: implicitlyUnwrappedOptionalType.exclamationMark
      )
    )
  }
  return TypeSyntax(MemberTypeSyntax(baseType: type.trimmed, name: .identifier("DebugSnapshot")))
}

private func snapshotTypeDescription(
  for type: String,
  snapshotTypeName: String = "DebugSnapshot"
) -> String {
  var base = type
  var optionalSuffix = ""
  while let last = base.last, last == "?" || last == "!" {
    optionalSuffix.insert(last, at: optionalSuffix.startIndex)
    base.removeLast()
  }
  if base.hasPrefix("["), base.hasSuffix("]") {
    let element = String(base.dropFirst().dropLast())
    return "[\(element).\(snapshotTypeName)]\(optionalSuffix)"
  }
  return "\(base).\(snapshotTypeName)\(optionalSuffix)"
}

private func caseParameterLabelPrefix(_ parameter: EnumCaseParameterSyntax) -> String {
  guard
    let label = parameter.firstName,
    label.tokenKind != .wildcard
  else { return "" }
  return "\(label.text): "
}

private struct ModelDecl {
  struct Property {
    var name: String
    var kind: Kind
    var isDebugSnapshotConvertible: Bool

    enum Kind {
      case type(String)
      case initializer(ExprSyntax)
      case pair(type: String, initializer: ExprSyntax)
    }
  }

  struct EnumCase {
    var element: EnumCaseElementSyntax
    var isDebugSnapshotConvertible: Bool
    var isIgnored: Bool
    var isIndirect: Bool
  }

  enum Kind {
    case classOrStruct([Property], isClass: Bool)
    case enumeration([EnumCase])
  }

  var name: String
  var kind: Kind

  init?(
    declaration: some DeclGroupSyntax,
    context: some MacroExpansionContext,
    debugSnapshotAttribute: (DeclSyntax) -> DebugSnapshotAttribute?
  ) {
    if let classDecl = declaration.as(ClassDeclSyntax.self) {
      let requiredAccess = effectiveAccessLevel(for: declaration, in: context)
      self.name = classDecl.name.text
      self.kind = .classOrStruct(
        Self.storedProperties(
          from: declaration,
          context: context,
          requiredAccess: requiredAccess,
          debugSnapshotAttribute: debugSnapshotAttribute
        ),
        isClass: true
      )
      return
    } else if let structDecl = declaration.as(StructDeclSyntax.self) {
      let requiredAccess = effectiveAccessLevel(for: declaration, in: context)
      self.name = structDecl.name.text
      self.kind = .classOrStruct(
        Self.storedProperties(
          from: declaration,
          context: context,
          requiredAccess: requiredAccess,
          debugSnapshotAttribute: debugSnapshotAttribute
        ),
        isClass: false
      )
      return
    } else if let name = declaration.as(EnumDeclSyntax.self)?.name {
      self.name = name.text
      self.kind = .enumeration(
        Self.enumCases(
          from: declaration,
          debugSnapshotAttribute: debugSnapshotAttribute
        )
      )
      return
    } else {
      context.diagnose(
        Diagnostic(
          node: Syntax(declaration),
          message: MacroExpansionErrorMessage(
            "'@DebugSnapshot' can only be applied to classes, structs, and enums."
          )
        )
      )
      return nil
    }
  }

  static func storedProperties(
    from declaration: some DeclGroupSyntax,
    context: some MacroExpansionContext,
    requiredAccess: AccessLevel,
    debugSnapshotAttribute: (DeclSyntax) -> DebugSnapshotAttribute?
  ) -> [ModelDecl.Property] {
    declaration.memberBlock.members.compactMap { member -> [ModelDecl.Property]? in
      guard
        let variable = member.decl.as(VariableDeclSyntax.self),
        modifiers(of: variable).contains(where: {
          $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
        }) != true,
        !variable.hasAttribute(in: \.attributes, equivalentTo: "@DebugSnapshotIgnored")
      else { return nil }

      let isDebugSnapshotTracked = variable.hasAttribute(
        in: \.attributes,
        equivalentTo: "@DebugSnapshotTracked"
      )
      let hasDebugSnapshotConvertibleAttribute = variable.hasAttribute(
        in: \.attributes,
        equivalentTo: "@DebugSnapshotConvertible"
      )
      guard
        accessControl(for: variable).effectiveAccessLevel >= requiredAccess
          || isDebugSnapshotTracked
          || hasDebugSnapshotConvertibleAttribute
      else { return nil }

      return variable.bindings.compactMap { binding in
        guard
          let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
          !identifier.hasPrefix("_")
        else { return nil }

        guard
          isStoredProperty(binding)
            || isDebugSnapshotTracked
            || hasDebugSnapshotConvertibleAttribute
        else {
          return nil
        }

        let typeAnnotation = binding.typeAnnotation?.type
        let defaultValue = binding.initializer?.value
        let attribute = debugSnapshotAttribute(DeclSyntax(variable))
        guard attribute != .ignored else { return nil }
        let isDebugSnapshotConvertible =
          hasDebugSnapshotConvertibleAttribute
          || attribute == .convertible

        switch (typeAnnotation, defaultValue) {
        case (nil, nil):
          context.diagnose(
            Diagnostic(
              node: Syntax(binding),
              message: MacroExpansionErrorMessage(
                "'@DebugSnapshot' requires explicit type annotations for stored properties."
              ),
              fixIt: .replaceChild(
                message: MacroExpansionFixItMessage("Insert ': <#Type#>'"),
                parent: binding,
                replacingChildAt: \.typeAnnotation,
                with: TypeAnnotationSyntax(
                  colon: .colonToken(trailingTrivia: .space),
                  type: TypeSyntax(IdentifierTypeSyntax(name: .identifier("<#Type#>")))
                )
              )
            )
          )
          return nil
        case (nil, let defaultValue?):
          guard !isClosureInitializer(defaultValue)
          else { return nil }

          return ModelDecl.Property(
            name: identifier,
            kind: .initializer(defaultValue),
            isDebugSnapshotConvertible: isDebugSnapshotConvertible
          )
        case (let typeAnnotation?, nil):
          guard !isClosureType(typeAnnotation)
          else { return nil }

          return ModelDecl.Property(
            name: identifier,
            kind: .type(typeAnnotation.trimmedDescription),
            isDebugSnapshotConvertible: isDebugSnapshotConvertible
          )
        case (let typeAnnotation?, let defaultValue?):
          guard
            !isClosureType(typeAnnotation),
            !isClosureInitializer(defaultValue) || isDebugSnapshotConvertible
          else { return nil }

          return ModelDecl.Property(
            name: identifier,
            kind: .pair(
              type: typeAnnotation.trimmedDescription,
              initializer: defaultValue
            ),
            isDebugSnapshotConvertible: isDebugSnapshotConvertible
          )
        }
      }
    }
    .flatMap(\.self)
  }

  static func enumCases(
    from declaration: some DeclGroupSyntax,
    debugSnapshotAttribute: (DeclSyntax) -> DebugSnapshotAttribute?
  ) -> [ModelDecl.EnumCase] {
    declaration.memberBlock.members.compactMap { member -> [ModelDecl.EnumCase]? in
      guard let enumCase = member.decl.as(EnumCaseDeclSyntax.self)
      else { return nil }

      let isIgnored = enumCase.hasAttribute(
        in: \.attributes,
        equivalentTo: "@DebugSnapshotIgnored"
      )
      let hasDebugSnapshotConvertibleAttribute = enumCase.hasAttribute(
        in: \.attributes,
        equivalentTo: "@DebugSnapshotConvertible"
      )
      let attribute = debugSnapshotAttribute(DeclSyntax(enumCase))
      let isIndirect =
        modifiers(of: enumCase).contains { $0.name.tokenKind == .keyword(.indirect) }
      return enumCase.elements.map {
        ModelDecl.EnumCase(
          element: $0,
          isDebugSnapshotConvertible:
            hasDebugSnapshotConvertibleAttribute || attribute == .convertible,
          isIgnored: isIgnored || attribute == .ignored,
          isIndirect: isIndirect
        )
      }
    }
    .flatMap(\.self)
  }
}

private func isStoredProperty(_ binding: PatternBindingSyntax) -> Bool {
  guard let accessorBlock = binding.accessorBlock else { return true }
  switch accessorBlock.accessors {
  case .accessors(let accessors):
    return !accessors.contains { accessor in
      switch accessor.accessorSpecifier.tokenKind {
      case .keyword(.get), .keyword(.set), .keyword(._modify), .keyword(._read):
        return true
      default:
        return false
      }
    }
  case .getter:
    return false
  }
}

private func isTrackedByDefault(
  _ variable: VariableDeclSyntax,
  binding: PatternBindingSyntax,
  requiredAccess: AccessLevel
) -> Bool {
  guard
    modifiers(of: variable).contains(where: {
      $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
    }) != true
  else { return false }

  guard accessControl(for: variable).effectiveAccessLevel >= requiredAccess else {
    return false
  }

  guard
    let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
    !identifier.hasPrefix("_"),
    isStoredProperty(binding)
  else { return false }

  switch (binding.typeAnnotation?.type, binding.initializer?.value) {
  case (nil, nil):
    return true
  case (nil, let defaultValue?):
    return !isClosureInitializer(defaultValue)
  case (let typeAnnotation?, nil):
    return !isClosureType(typeAnnotation)
  case (let typeAnnotation?, let defaultValue?):
    return !isClosureType(typeAnnotation) && !isClosureInitializer(defaultValue)
  }
}


private func isClosureType(_ type: TypeSyntax) -> Bool {
  if type.as(FunctionTypeSyntax.self) != nil {
    return true
  }
  if let type = type.as(OptionalTypeSyntax.self) {
    return isClosureType(type.wrappedType)
  }
  if let type = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
    return isClosureType(type.wrappedType)
  }
  if let type = type.as(AttributedTypeSyntax.self) {
    return isClosureType(type.baseType)
  }
  return false
}

private func isClosureInitializer(_ initializer: ExprSyntax) -> Bool {
  initializer.as(ClosureExprSyntax.self) != nil
}

private enum AccessLevel: Int, Comparable {
  case `private`
  case `fileprivate`
  case `internal`
  case `package`
  case `public`

  static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

extension AccessLevel? {
  fileprivate var effectiveAccessLevel: AccessLevel {
    self ?? .internal
  }
}

private func accessControl(for declaration: some DeclGroupSyntax) -> AccessLevel? {
  switch accessControl(from: modifiers(of: declaration)) {
  case .private: return .fileprivate
  case let access: return access
  }
}

private func accessControl(for varDecl: VariableDeclSyntax) -> AccessLevel? {
  accessControl(from: modifiers(of: varDecl))
}

private func accessControl(from modifiers: DeclModifierListSyntax) -> AccessLevel? {
  let accessLevels: [TokenKind] = [
    .keyword(.public),
    .keyword(.open),
    .keyword(.package),
    .keyword(.internal),
    .keyword(.fileprivate),
    .keyword(.private),
  ]
  for modifier in modifiers where accessLevels.contains(modifier.name.tokenKind) {
    switch modifier.name.tokenKind {
    case .keyword(.open), .keyword(.public):
      return .public
    case .keyword(.package):
      return .package
    case .keyword(.internal):
      return .internal
    case .keyword(.fileprivate):
      return .fileprivate
    case .keyword(.private):
      return .private
    default:
      break
    }
  }
  return nil
}

private func effectiveAccessLevel(
  for declaration: some DeclGroupSyntax,
  in context: some MacroExpansionContext
) -> AccessLevel {
  min(
    accessControl(for: declaration).effectiveAccessLevel,
    enclosingAccessLevel(in: context)
  )
}

private func enclosingAccessLevel(in context: some MacroExpansionContext) -> AccessLevel {
  var access: AccessLevel = .internal
  for node in context.lexicalContext {
    if let decl = node.as(ClassDeclSyntax.self) {
      access = min(access, accessControl(for: decl).effectiveAccessLevel)
    } else if let decl = node.as(StructDeclSyntax.self) {
      access = min(access, accessControl(for: decl).effectiveAccessLevel)
    } else if let decl = node.as(EnumDeclSyntax.self) {
      access = min(access, accessControl(for: decl).effectiveAccessLevel)
    } else if let decl = node.as(ActorDeclSyntax.self) {
      access = min(access, accessControl(for: decl).effectiveAccessLevel)
    }
  }
  return access
}

private func hasMainActorAnnotation(_ declaration: some DeclGroupSyntax) -> Bool {
  attributes(of: declaration).contains { attribute in
    guard let attribute = attribute.as(AttributeSyntax.self) else { return false }
    let name = attribute.attributeName.trimmedDescription
    return name.split(separator: ".").last == "MainActor"
  }
}

private func hasDebugSnapshotConvertibleConformance(_ declaration: some DeclGroupSyntax) -> Bool {
  return hasConformance(named: "DebugSnapshotConvertible", in: declaration)
}

private func debugSnapshotConformances(
  for declaration: some DeclGroupSyntax,
  properties: [ModelDecl.Property]
) -> [String] {
  var conformances: [String] = []
  if let sendableConformance = sendableConformance(in: declaration) {
    conformances.append(sendableConformance)
  }
  if hasConformance(named: "Identifiable", in: declaration),
    properties.contains(where: { $0.name == "id" })
  {
    conformances.append("Identifiable")
  }
  return conformances
}

private func snapshotConformanceDescription(
  _ conformances: [String]
) -> String {
  let conformances = deduplicatedConformances(conformances)
  return conformances.isEmpty ? "" : ": \(conformances.joined(separator: ", "))"
}

private func hasConformance(
  named conformanceName: String,
  in declaration: some DeclGroupSyntax
) -> Bool {
  inheritedTypes(in: declaration).contains { inheritedType in
    conformanceBaseName(of: inheritedType.type) == conformanceName
  }
}

private func sendableConformance(in declaration: some DeclGroupSyntax) -> String? {
  for inheritedType in inheritedTypes(in: declaration) {
    guard conformanceBaseName(of: inheritedType.type) == "Sendable" else { continue }
    return hasUncheckedSpecifier(in: inheritedType.type) ? "@unchecked Sendable" : "Sendable"
  }
  return nil
}

private func inheritedTypes(in declaration: some DeclGroupSyntax) -> [InheritedTypeSyntax] {
  guard
    let inheritedTypes =
      declaration.as(ClassDeclSyntax.self)?.inheritanceClause?.inheritedTypes
      ?? declaration.as(StructDeclSyntax.self)?.inheritanceClause?.inheritedTypes
      ?? declaration.as(EnumDeclSyntax.self)?.inheritanceClause?.inheritedTypes
  else { return [] }
  return Array(inheritedTypes)
}

private func conformanceBaseName(of type: TypeSyntax) -> String? {
  if let type = type.as(IdentifierTypeSyntax.self) {
    return type.name.text
  }
  if let type = type.as(MemberTypeSyntax.self) {
    return type.name.text
  }
  if let type = type.as(AttributedTypeSyntax.self) {
    return conformanceBaseName(of: type.baseType)
  }
  return nil
}

private func hasUncheckedSpecifier(in type: TypeSyntax) -> Bool {
  guard let type = type.as(AttributedTypeSyntax.self) else { return false }
  let hasUnchecked =
    type.attributes.contains { attribute in
      guard let attribute = attribute.as(AttributeSyntax.self) else { return false }
      let name = attribute.attributeName.trimmedDescription
      return name.split(separator: ".").last == "unchecked"
    }
  return hasUnchecked || hasUncheckedSpecifier(in: type.baseType)
}

private struct PropagatedAttributesOutput {
  var conformances: [String]
  var description: String
}

private func propagatedAttributesOutput(
  from declaration: some DeclGroupSyntax,
  filterPropagatedAttributes: (AttributeListSyntax) -> AttributeListSyntax,
  attributeConformanceMapping: [String: [String]]
) -> PropagatedAttributesOutput {
  let propagatedAttributes = filterPropagatedAttributes(attributes(of: declaration))

  var conformances: [String] = []
  for element in propagatedAttributes {
    guard let attribute = element.as(AttributeSyntax.self) else { continue }
    if let shortName = shortAttributeName(attribute),
      let mappedConformances = attributeConformanceMapping[shortName]
        ?? attributeConformanceMapping[attribute.attributeName.trimmedDescription]
    {
      conformances.append(contentsOf: mappedConformances)
    }
  }

  let description =
    propagatedAttributes.isEmpty
    ? ""
    : propagatedAttributes
      .map(\.trimmedDescription)
      .joined(separator: "\n")
      + "\n"
  return PropagatedAttributesOutput(
    conformances: deduplicatedConformances(conformances),
    description: description
  )
}

private func shortAttributeName(_ attribute: AttributeSyntax) -> String? {
  attribute.attributeName.trimmedDescription.split(separator: ".").last.map(String.init)
}

private func deduplicatedConformances(_ conformances: [String]) -> [String] {
  var seen: Set<String> = []
  return conformances.filter { seen.insert($0).inserted }
}

private func attributes(of declaration: some DeclGroupSyntax) -> AttributeListSyntax {
  #if compiler(>=6)
    return declaration.attributes
  #else
    return declaration.attributes ?? []
  #endif
}

private func modifiers(of declaration: some DeclGroupSyntax) -> DeclModifierListSyntax {
  #if compiler(>=6)
    return declaration.modifiers
  #else
    return declaration.modifiers ?? []
  #endif
}

private func modifiers(of varDecl: VariableDeclSyntax) -> DeclModifierListSyntax {
  #if compiler(>=6)
    return varDecl.modifiers
  #else
    return varDecl.modifiers ?? []
  #endif
}

private func modifiers(of enumCaseDecl: EnumCaseDeclSyntax) -> DeclModifierListSyntax {
  #if compiler(>=6)
    return enumCaseDecl.modifiers
  #else
    return enumCaseDecl.modifiers ?? []
  #endif
}

private func rewriteSelf(in expression: ExprSyntax, with typeName: String) -> ExprSyntax {
  SelfRewriter(typeName: typeName).rewrite(expression).cast(ExprSyntax.self)
}

private func rewriteDefaultValue(
  _ expression: ExprSyntax,
  modelTypeName: String,
  propertyTypeName: String?
) -> ExprSyntax {
  let expression = rewriteSelf(in: expression, with: modelTypeName)
  guard let propertyTypeName else { return expression }

  if let array = expression.as(ArrayExprSyntax.self), array.elements.isEmpty {
    return ExprSyntax(stringLiteral: "([] as \(propertyTypeName))")
  }

  let implicitMemberBaseTypeName = optionalWrappedTypeName(in: propertyTypeName)

  if var memberAccess = expression.as(MemberAccessExprSyntax.self),
    memberAccess.base == nil
  {
    memberAccess.base = ExprSyntax(stringLiteral: implicitMemberBaseTypeName)
    return ExprSyntax(memberAccess)
  }

  if var functionCall = expression.as(FunctionCallExprSyntax.self),
    var calledExpression = functionCall.calledExpression.as(MemberAccessExprSyntax.self),
    calledExpression.base == nil
  {
    calledExpression.base = ExprSyntax(stringLiteral: implicitMemberBaseTypeName)
    functionCall.calledExpression = ExprSyntax(calledExpression)
    return ExprSyntax(functionCall)
  }

  return expression
}

private func optionalWrappedTypeName(in typeName: String) -> String {
  var typeName = typeName
  while let last = typeName.last, last == "?" || last == "!" {
    typeName.removeLast()
  }
  return typeName
}

private final class SelfRewriter: SyntaxRewriter {
  let typeName: String

  init(typeName: String) {
    self.typeName = typeName
  }

  override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
    guard node.baseName.tokenKind == .keyword(.Self) || node.baseName.text == "Self"
    else { return ExprSyntax(node) }
    var node = node
    node.baseName = .identifier(self.typeName)
    return ExprSyntax(node)
  }

  override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
    guard node.name.tokenKind == .keyword(.Self) || node.name.text == "Self"
    else { return TypeSyntax(node) }
    var node = node
    node.name = .identifier(self.typeName)
    return TypeSyntax(node)
  }
}
