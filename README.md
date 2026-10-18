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
