import XCTest
import SwiftTreeSitter
import TreeSitterTokudae

final class TreeSitterTokudaeTests: XCTestCase {
    func testCanLoadGrammar() throws {
        let parser = Parser()
        let language = Language(language: tree_sitter_tokudae())
        XCTAssertNoThrow(try parser.setLanguage(language),
                         "Error loading Tokudae grammar")
    }
}
