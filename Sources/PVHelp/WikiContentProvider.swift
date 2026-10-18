// Copyright 2026 iCube Project
// Licensed under the Provenance License (see LICENSE.md).

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Minimal seam over `URLSession` so tests can substitute a fake transport instead of hitting
/// the network (which would also just 404 today, since `icube-wiki` doesn't exist yet).
protocol WikiURLLoading: Sendable {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: WikiURLLoading {}

public final class WikiContentProvider: Sendable {
    public let cache: WikiContentCache
    public let configuration: WikiConfiguration
    private let session: WikiURLLoading
    /// Wiki paths the navigation tree must not list (see ``WikiNavigationTree/removing(paths:)``).
    private let hiddenPaths: Set<String>

    /// - Parameter hiddenPaths: pages to leave out of the navigation tree, whichever source it came from.
    public init(configuration: WikiConfiguration, hiddenPaths: Set<String> = []) {
        self.configuration = configuration
        self.cache = WikiContentCache(configuration: configuration)
        self.session = URLSession.shared
        self.hiddenPaths = hiddenPaths
    }

    /// Test-only seam: inject a fake cache/transport. Not `public` — only reachable from this
    /// package's own test target via `@testable import`.
    init(configuration: WikiConfiguration, session: WikiURLLoading, cache: WikiContentCache, hiddenPaths: Set<String> = []) {
        self.configuration = configuration
        self.session = session
        self.cache = cache
        self.hiddenPaths = hiddenPaths
    }

    // MARK: - Navigation Tree

    /// Load the navigation tree with cache-first strategy.
    /// Returns cached tree immediately if available; refreshes in background if TTL expired.
    public func loadNavigationTree() async -> WikiNavigationTree {
        // Try cache first — re-apply filter in case blocklist has changed since caching
        if let cached = cache.cachedNavigationTree()?.appStoreFiltered().removing(paths: hiddenPaths) {
            if !cache.isNavigationCacheValid() {
                // Refresh in background
                Task { await refreshNavigationTree() }
            }
            return cached
        }

        // Try network (404s until icube-wiki exists; falls through below)
        if let tree = await refreshNavigationTree() {
            return tree.removing(paths: hiddenPaths)
        }

        // Fall back to the bundled SUMMARY.md shipped with the app
        return loadBundledNavigationTree()
    }

    @discardableResult
    private func refreshNavigationTree() async -> WikiNavigationTree? {
        do {
            let content = try await fetchRawContent(WikiConstants.summaryFileName)
            let tree = WikiNavigationTree.parse(markdown: content)
            cache.cacheNavigationTree(tree)
            return tree
        } catch {
            return nil
        }
    }

    private func loadBundledNavigationTree() -> WikiNavigationTree {
        guard let content = bundledContent(forPath: WikiConstants.summaryFileName) else {
            return WikiNavigationTree(sections: [])
        }
        return WikiNavigationTree.parse(markdown: content).removing(paths: hiddenPaths)
    }

    // MARK: - Page Content

    /// Load a wiki page with cache-first strategy and GitBook preprocessing.
    ///
    /// Fallback order: valid cache -> stale cache (+ background refresh) -> live network ->
    /// bundled seed content shipped in this package's `Resources/` (covers `icube-wiki` not
    /// existing yet, or just being offline) -> a plain "not cached yet" placeholder for any
    /// page this app didn't ship a bundled copy of.
    public func loadPage(path: String, title: String) async -> WikiPage {
        // Try cache first
        if let cached = cache.cachedPage(for: path) {
            if !cache.isPageCacheValid(for: path) {
                // Refresh in background
                Task { await refreshPage(path: path) }
            }
            let processed = GitBookPreprocessor.process(cached, assetBaseURL: configuration.baseURL)
            return WikiPage(path: path, title: title, content: processed)
        }

        // Try network
        if let content = await refreshPage(path: path) {
            let processed = GitBookPreprocessor.process(content, assetBaseURL: configuration.baseURL)
            return WikiPage(path: path, title: title, content: processed)
        }

        // Bundled offline fallback — the app must be fully useful with only this content,
        // since it's what ships until icube-wiki exists.
        if let bundled = bundledContent(forPath: path) {
            let processed = GitBookPreprocessor.process(bundled, assetBaseURL: configuration.baseURL)
            return WikiPage(path: path, title: title, content: processed)
        }

        // Last resort: a page we have neither cached nor bundled, and can't reach.
        return WikiPage(path: path, title: title, content: "**Offline** — This page is not yet cached. Connect to the internet and try again.")
    }

    @discardableResult
    private func refreshPage(path: String) async -> String? {
        do {
            let content = try await fetchRawContent(path)
            cache.cachePage(content, for: path)
            return content
        } catch {
            return nil
        }
    }

    // MARK: - Bundled resources

    /// Resolves a wiki-style path (e.g. `"help/web-import.md"` or `"SUMMARY.md"`) to bundled
    /// resource content shipped in `WikiContent/`, mirroring the same relative layout as the
    /// `icube-wiki` repo this will eventually fetch from (see `docs/wiki-seed/` at the repo
    /// root, which is the canonical source these resources are copied from).
    private func bundledContent(forPath path: String) -> String? {
        guard let url = bundledURL(forPath: path),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        return content
    }

    private func bundledURL(forPath path: String) -> URL? {
        guard let bundled = configuration.bundledContent else { return nil }
        let components = path.split(separator: "/").map(String.init)
        guard let filename = components.last else { return nil }
        let ext = (filename as NSString).pathExtension
        let name = (filename as NSString).deletingPathExtension
        // The app ships its pages as a folder (see `WikiConfiguration.BundledContent`), so
        // they keep the wiki repo's layout under `subdirectory`.
        let subdirectory = ([bundled.subdirectory] + components.dropLast()).joined(separator: "/")
        return bundled.bundle.url(
            forResource: name,
            withExtension: ext.isEmpty ? nil : ext,
            subdirectory: subdirectory
        )
    }

    // MARK: - Network

    private func fetchRawContent(_ path: String) async throws -> String {
        let url = configuration.rawURL(for: path)
        let (data, response) = try await session.data(from: url)

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw WikiContentError.httpError(httpResponse.statusCode)
        }

        guard let content = String(data: data, encoding: .utf8) else {
            throw WikiContentError.invalidEncoding
        }

        return content
    }

    /// Clear all cached content and force reload.
    public func clearCache() {
        cache.clearAll()
    }
}

public enum WikiContentError: Error, LocalizedError {
    case httpError(Int)
    case invalidEncoding

    public var errorDescription: String? {
        switch self {
        case .httpError(let code): return "HTTP error \(code)"
        case .invalidEncoding: return "Invalid text encoding"
        }
    }
}
