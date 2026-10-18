import Foundation

/// Wiki conventions shared by every app. App-specific settings (URLs, cache
/// namespace, bundled pages) are in `WikiConfiguration`; each app keeps its own
/// list of well-known page paths.
public enum WikiConstants {
    /// GitBook's navigation file, at the root of the wiki repo and of bundled content.
    public static let summaryFileName = "SUMMARY.md"
}
