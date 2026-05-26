// swift-tools-version: 6.2

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-debug-snapshots",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "DebugSnapshots",
      targets: ["DebugSnapshots"]
    ),
    .library(
      name: "DebugSnapshotsMacrosSupport",
      targets: ["DebugSnapshotsMacrosSupport"]
    ),
  ],
  traits: [
    .trait(
      name: "IdentifiedCollections",
      description: "Adds support for creating DebugSnapshots from IdentifiedArray"
    )
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.6.0"),
    .package(
      url: "https://github.com/pointfreeco/swift-identified-collections",
      from: "1.0.0"
    ),
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.1.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.0.0"),
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0"),
    .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"603.0.0"),
  ],
  targets: [
    .target(
      name: "DebugSnapshots",
      dependencies: [
        "DebugSnapshotsMacros",
        .product(name: "CustomDump", package: "swift-custom-dump"),
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
        .product(
          name: "IdentifiedCollections",
          package: "swift-identified-collections",
          condition: .when(
            traits: ["IdentifiedCollections"]
          )
        )
      ]
    ),
    .target(
      name: "DebugSnapshotsMacrosSupport",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .macro(
      name: "DebugSnapshotsMacros",
      dependencies: [
        "DebugSnapshotsMacrosSupport",
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "DebugSnapshotsTests",
      dependencies: [
        "DebugSnapshots",
        "DebugSnapshotsMacrosSupport",
        .product(name: "IssueReportingTestSupport", package: "xctest-dynamic-overlay"),
      ]
    ),
    .testTarget(
      name: "DebugSnapshotsMacrosTests",
      dependencies: [
        "DebugSnapshotsMacros",
        "DebugSnapshotsMacrosSupport",
        .product(name: "MacroTesting", package: "swift-macro-testing"),
      ]
    ),
  ],
)

for target in package.targets {
  target.swiftSettings = target.swiftSettings ?? []
  target.swiftSettings?.append(contentsOf: [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("ImmutableWeakCaptures"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
  ])
  #if compiler(>=6.4)
    target.swiftSettings?.append(contentsOf: [
      .treatAllWarnings(as: .error)
    ])
  #endif
}
