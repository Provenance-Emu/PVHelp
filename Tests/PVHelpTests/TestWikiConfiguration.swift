import Foundation
@testable import PVHelp

/// A configuration whose bundled content is the iCube fixture in this test target.
enum TestWiki {
    static let jitGuide = "guide/jit.md"

    static let configuration = WikiConfiguration(
        baseURL: URL(string: "https://raw.githubusercontent.com/Provenance-Emu/icube-wiki/master/")!,
        webBaseURL: URL(string: "https://icube-emu.com/")!,
        cacheNamespace: "PVHelpTests",
        bundledContent: .init(bundle: .module, subdirectory: "WikiContent")
    )
}
