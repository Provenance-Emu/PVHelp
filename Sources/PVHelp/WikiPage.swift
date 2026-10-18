// Copyright 2026 iCube Project
// Licensed under the Provenance License (see LICENSE.md).

import Foundation

/// A single loaded wiki page: its path (used as a cache/nav key), display title, and
/// fully preprocessed Markdown content ready to render.
public struct WikiPage: Sendable {
    public let path: String
    public let title: String
    public let content: String

    public init(path: String, title: String, content: String) {
        self.path = path
        self.title = title
        self.content = content
    }
}
