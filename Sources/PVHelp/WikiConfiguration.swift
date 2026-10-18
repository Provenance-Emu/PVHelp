import Foundation

/// Where an app's in-app documentation comes from. Each app builds one and passes
/// it to `WikiContentProvider`; the package has no app's URLs or pages in it.
///
/// ```swift
/// let wiki = WikiConfiguration(
///     baseURL: URL(string: "https://raw.githubusercontent.com/Provenance-Emu/icube-wiki/master/")!,
///     webBaseURL: URL(string: "https://icube-emu.com/")!,
///     cacheNamespace: "iCubeHelp",
///     bundledContent: .init(bundle: .main, subdirectory: "WikiContent")
/// )
/// ```
public struct WikiConfiguration: Sendable {
    /// A folder of wiki pages shipped in the app, laid out like the wiki repo
    /// (`SUMMARY.md`, `guide/…`, `help/…`). Used when a page is neither cached
    /// nor reachable. Ship it with a folder reference (or SwiftPM `.copy`), not
    /// `.process`, which flattens the subfolders; and don't name the folder
    /// `Resources`, `Contents` or `Versions` (codesign reads that as a deep
    /// bundle layout and rejects the bundle).
    public struct BundledContent: Sendable {
        public var bundle: Bundle
        public var subdirectory: String

        public init(bundle: Bundle, subdirectory: String) {
            self.bundle = bundle
            self.subdirectory = subdirectory
        }
    }

    /// Raw-content base of the wiki repo (pages are fetched as `baseURL/<path>`).
    public var baseURL: URL
    /// Human-facing base for "View on Web" links.
    public var webBaseURL: URL
    /// Cache TTL for page content and the navigation tree.
    public var cacheTTL: TimeInterval
    /// Names the Caches subdirectory and the UserDefaults keys, so two
    /// configurations never share a cache.
    public var cacheNamespace: String
    /// Offline copy of the wiki, or nil when the app ships none.
    public var bundledContent: BundledContent?

    public init(
        baseURL: URL,
        webBaseURL: URL,
        cacheTTL: TimeInterval = 24 * 60 * 60,
        cacheNamespace: String = "PVHelp",
        bundledContent: BundledContent? = nil
    ) {
        self.baseURL = baseURL
        self.webBaseURL = webBaseURL
        self.cacheTTL = cacheTTL
        self.cacheNamespace = cacheNamespace
        self.bundledContent = bundledContent
    }

    public func rawURL(for path: String) -> URL {
        baseURL.appendingPathComponent(path)
    }

    public func webURL(for path: String) -> URL {
        let webPath = path
            .replacingOccurrences(of: ".md", with: "")
            .replacingOccurrences(of: "/README", with: "")
        return webBaseURL.appendingPathComponent(webPath)
    }

    var navigationCacheKey: String { "\(cacheNamespace)_NavigationTree" }
    var navigationTimestampKey: String { "\(cacheNamespace)_NavigationTimestamp" }
}
