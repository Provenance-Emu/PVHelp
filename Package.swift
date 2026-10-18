// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "PVHelp",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v9),
        .macOS(.v14),
        .macCatalyst(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "PVHelp",
            targets: ["PVHelp"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            // Ships no wiki pages: each app passes its own (WikiConfiguration.bundledContent).
            name: "PVHelp"
        ),
        .testTarget(
            name: "PVHelpTests",
            dependencies: ["PVHelp"],
            // iCube's pages, as a fixture for the bundled-content fallback. `.copy`
            // keeps the guide/ and help/ subfolders (see WikiConfiguration.BundledContent).
            resources: [.copy("Fixtures/WikiContent")]
        ),
    ],
    swiftLanguageModes: [.v5]
)
