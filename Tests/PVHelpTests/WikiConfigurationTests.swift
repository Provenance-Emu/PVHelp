import XCTest
@testable import PVHelp

final class WikiConfigurationTests: XCTestCase {
    func testNamespacesDoNotShareTheNavigationCache() {
        var otherConfig = TestWiki.configuration
        otherConfig.cacheNamespace = "PVHelpTests-Other"
        let mine = WikiContentCache(configuration: TestWiki.configuration)
        let other = WikiContentCache(configuration: otherConfig)
        mine.clearAll(); other.clearAll()
        defer { mine.clearAll(); other.clearAll() }

        mine.cacheNavigationTree(WikiNavigationTree(sections: [WikiSection(title: "Mine", items: [])]))
        XCTAssertNotNil(mine.cachedNavigationTree())
        XCTAssertNil(other.cachedNavigationTree(), "another app's namespace must not see this cache")
    }

    func testURLsComeFromTheConfiguration() {
        let config = TestWiki.configuration
        XCTAssertEqual(config.rawURL(for: "help/web-import.md").absoluteString,
                       "https://raw.githubusercontent.com/Provenance-Emu/icube-wiki/master/help/web-import.md")
        XCTAssertEqual(config.webURL(for: "help/web-import.md").absoluteString, "https://icube-emu.com/help/web-import")
    }
}
