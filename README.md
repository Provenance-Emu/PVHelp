# PVHelp

In-app help backed by a GitBook-style wiki repo. Shared by iCube and Provenance. It:

- fetches `SUMMARY.md` and pages over raw GitHub;
- caches them on disk, with a 24 h TTL;
- converts GitBook markup (hints, tabs, HTML tables, details blocks, asset paths) to plain markdown;
- filters App Store–unsafe pages out of the navigation;
- falls back to pages the app ships.

```swift
.package(url: "https://github.com/Provenance-Emu/PVHelp.git", .upToNextMajor(from: "1.0.0"))
```

Each app passes its own wiki:

```swift
let wiki = WikiConfiguration(
    baseURL: URL(string: "https://raw.githubusercontent.com/<org>/<wiki-repo>/master/")!,
    webBaseURL: URL(string: "https://<site>/")!,
    cacheNamespace: "AppHelp",
    bundledContent: .init(bundle: .main, subdirectory: "WikiContent")   // optional offline copy
)
let provider = WikiContentProvider(configuration: wiki, hiddenPaths: [/* pages to hide */])
```

The package ships no pages. Bundle yours as a folder, laid out like the wiki repo, using a folder
reference or SwiftPM `.copy`. Don't use `.process`, and don't name the folder `Resources`,
`Contents` or `Versions` (see `WikiConfiguration.BundledContent`). Keep your well-known page paths
in the app.

Extracted with history on 2026-10-17 from iCube's `Source/iOS/PVHelp` (Provenance-Emu/iCube
`093cefdccc`). iCube's copy was itself a port of Provenance's `PVHelp`, with added test seams.

## Prebuilt XCFramework

A version tag resolves to a prebuilt XCFramework: the tag's `Package.swift` is a
`binaryTarget` pointing at the tag's GitHub Release, so an app that depends on a version
compiles none of this package. `main` and every other branch build from source.

To build a tagged version from source (to step into it in the debugger, say), set
`PV_BUILD_FROM_SOURCE=1` in the environment `xcodebuild` or Xcode starts in, then resolve
packages again.

To release, run **Release XCFramework** from the Actions tab with the new version. Do not
push version tags by hand: such a tag has no binary and builds from source.
[How releases work](https://github.com/Provenance-Emu/.github/blob/main/docs/xcframework-releases.md).
