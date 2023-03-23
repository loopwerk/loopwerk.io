import XCTest
@testable import Loopwerk

final class LoopwerkTests: XCTestCase {
  func testImproveHtml_ExternalLink_HTTP() {
    let input = #"<a href="http://www.example.com">Link</a>"#
    let expectedOutput = #"<a href="http://www.example.com" target="_blank" rel="nofollow">Link</a>"#
    XCTAssertEqual(input.improveHTML(), expectedOutput)
  }

  func testImproveHtml_ExternalLink_HTTPS() {
    let input = #"<a href="https://www.example.com">Link</a>"#
    let expectedOutput = #"<a href="https://www.example.com" target="_blank" rel="nofollow">Link</a>"#
    XCTAssertEqual(input.improveHTML(), expectedOutput)
  }

  func testImproveHtml_InternalLink_Email() {
    let input = #"<a href="mailto:me@example.com">Link</a>"#
    let expectedOutput = #"<a href="mailto:me@example.com">Link</a>"#
    XCTAssertEqual(input.improveHTML(), expectedOutput)
  }

  func testImproveHtml_InternalLink_Path() {
    let input = #"<a href="/articles">Link</a>"#
    let expectedOutput = #"<a href="/articles">Link</a>"#
    XCTAssertEqual(input.improveHTML(), expectedOutput)
  }

  func testImproveHtml_InternalLink_Hash() {
    let input = "<a href=\"#content\">Link</a>"
    let expectedOutput = "<a href=\"#content\">Link</a>"
    XCTAssertEqual(input.improveHTML(), expectedOutput)
  }

  func testImproveHtml_Heading() {
    let input = "<h1>Heading 1</h1><h2>2 - Heading 2</h2>"
    let expectedOutput = """
<h1><a name="heading-1"></a>Heading 1</h1>
<h2><a name="2-heading-2"></a>2 - Heading 2</h2>
"""
    XCTAssertEqual(input.improveHTML(), expectedOutput)
  }

  func testImproveHtml_Toc() {
    let input = "<h1>Table Of Contents</h1><p>%TOC%</p><h1>Heading 1</h1><h2>2 - Heading 2</h2>"
    let expectedOutput = """
<h1><a name="table-of-contents"></a>Table Of Contents</h1>
<ul>
<li><a href="#heading-1">Heading 1</a>
<ul>
<li><a href="#2-heading-2">2 - Heading 2</a></li>
</ul>
</li>
</ul>

<h1><a name="heading-1"></a>Heading 1</h1>
<h2><a name="2-heading-2"></a>2 - Heading 2</h2>
"""
    XCTAssertEqual(input.improveHTML(), expectedOutput)
  }
}
