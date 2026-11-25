// swift-tools-version:6.0
import Foundation
import PackageDescription

// A version tag resolves to the prebuilt XCFramework from that tag's GitHub release;
// `main` always builds from source. The release workflow fills this in on the tagged
// commit only, so it stays `nil` on every branch.
// Set PV_BUILD_FROM_SOURCE=1 to build a tagged version from source instead.
let binaryRelease: (version: String, checksums: [String: String])? = ("1.0.1", ["PVHelp": "bb47f5e36bc7a4a4009c9a3007e9de863fb46bc9e3574c53485c32684ac9a07e"])

let environment = ProcessInfo.processInfo.environment
let buildFromSource = binaryRelease == nil || environment["PV_BUILD_FROM_SOURCE"] != nil
// The release workflow builds the framework it publishes from a dynamic product.
let libraryType: Product.Library.LibraryType? = environment["PV_XCFRAMEWORK_BUILD"] != nil ? .dynamic : nil

let sourceTargets: [Target] = [
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
]

let binaryTargets: [Target] = binaryRelease.map { release in
    release.checksums.sorted { $0.key < $1.key }.map { module, checksum in
        .binaryTarget(
            name: module,
            url: "https://github.com/Provenance-Emu/PVHelp/releases/download/\(release.version)/\(module).xcframework.zip",
            checksum: checksum
        )
    }
} ?? []

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
        .library(name: "PVHelp", type: buildFromSource ? libraryType : nil, targets: ["PVHelp"])
    ],
    dependencies: [],
    targets: buildFromSource ? sourceTargets : binaryTargets,
    swiftLanguageModes: [.v5]
)
