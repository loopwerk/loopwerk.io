---
tags: swift, saga, news
summary: I've created a new Swift package that does server-side syntax highlighting of HTML content, using Prism.js.
---

# Announcing Moon, a new HTML syntax highlighter for Swift projects

My website is built using [Saga](https://github.com/loopwerk/Saga), a static site generator written in Swift. Overall it's a great experience, but there was always one problem: there are no HTML syntax highlighters for Swift. To get around this I used the [Prism.js](https://prismjs.com) JavaScript library in the browser. It finds all the code blocks and automatically highlights them.

```html
<div>yo</div>
```

This works fine, but it requires every visitor to load quite a bit of JavaScript just for syntax highlighting. This is something that really should be done server side, without the browser having to download any JavaScript files.

I looked at a few existing Swift packages:

- [Splash](https://swiftpackageindex.com/JohnSundell/Splash) looked very promising, but only supports highlighting of Swift code, and hasn't had a new release for four years.
- [Highlightr](https://github.com/raspu/Highlightr) which uses [highlight.js](https://highlightjs.org/) as its core, via JavaScriptCore. Great idea, but JavaScriptCore doesn't work on Linux and it's really meant to return `NSAttributedString` rather than an HTML string with the right css classes applied.
- [SyntaxHighlight](https://github.com/maoyama/SyntaxHighlight) which uses TextMate themes and language definitions. That's a great start as there are a high quality and well-maintained definitions for a ton of languages, but it returns SwiftUI Text views, not HTML strings.
- [TMSyntax](https://github.com/maoyama/TMSyntax), the package used by SyntaxHighlight under the hood. No documentation, no commits for six years, and it's also not built for HTML input and HTML output.

I was thinking about using Claude Code to port Prism.js to Swift, but translating the language definitions from JavaScript regexes to Swift would be a nightmare, and not something I'd want to maintain going forward.

Instead, I was inspired by Highlightr. If I could use JavaScriptCore to run the real Prism.js library, but "server side" rather than in the browser, it would solve all my problems with very little complexity. The biggest issue is the fact that JavaScriptCore is Apple only, it doesn't work on Linux. Luckily I found [JXKi](https://github.com/jectivex/JXKit) which offers a cross-platform module for running JavaScript in Swift.

All the pieces came together quite quickly after that, and the result is [Moon](https://github.com/loopwerk/Moon), a brand new Swift library using Prism.js. You give it an HTML string with `<code>` blocks, and it returns an HTML string with those blocks now properly highlighted. Prism.js supports 290+ languages, which even more available as third-party plugins.

This website now uses Moon to highlight all code blocks, speeding up page load for everyone by no longer needing to load Prism.js in the browser.