---
tags: review, saga, swift
summary: A hugely important part of any static site generator is of course the parsing of Markdown content. The default parser for Saga is Parsley, a custom wrapper around a cmark fork. While I am generally quite happy with it, there are some problems.
---

#  A review of Markdown parsers for Swift
A hugely important part of any static site generator is of course the parsing of Markdown content. The default parser for Saga is Parsley, a custom wrapper around a cmark fork. While I am generally quite happy with it, there are some problems. In this article I'd like to go over those problems, and see if I could solve them by using a different parsing library under the hood.

Let me first list what I consider to be must-have features for a Markdown parser, to be used in Saga:

- Metadata support
- The ability to split the first title and the main body of the document
- `~~strikethrough~~` support
- Fenced code blocks
- Plugin support, or another way to modify the parsed content
- It needs to run on Linux
- It needs to be fast, so Saga's development server rebuilds your website instantly, no matter how big your site

And some nice-to-haves, still important but not deal-breakers:

- Hard line breaks (so you don't have to add two spaces at the end of a line to force a `<br>`)
- Syntax highlighting in code blocks (but client-side is acceptable)
- Naked links (so if you add a naked link like `www.example.com` in your text, it becomes a clickable link)
- Autolinks, like `<www.example.com>` and `<info@example.com>`

Let's use the following Markdown string to test the different parsers. 

	---
	tags: review, swift, saga
	---
	
	# This is the title
	This **is** a www.example.com *naked* link, and an email: <info@example.com>
	Hard break! ~~strike~~
	- List directly attached
	- Another list item

	> # Title within blockquote!
	
	```swift
	print("Hello world")
	```
	
It has metadata, a naked link and an auto-linked email, a hard break, strikethrough text, a list directly attached to the preceding paragraph, a title within a block quote and a fenced code block. All these things do exist in my actual articles, so if a parser fails to render this, I'd have to go through almost 70 articles to check that they look okay. That's not something I want to do, and not something I want my static site generator to require from other users either.

Anyway, let's start with the default parser for Saga, Parsley.

## [Parsley](https://github.com/loopwerk/Parsley)
This is my own wrapper around [brokenhandsio/cmark-gfm](https://github.com/brokenhandsio/cmark-gfm), adding metadata support and title handling. `brokenhandsio/cmark-gfm` is a fork of [github/cmark-gfm](https://github.com/github/cmark-gfm), which in turn is a fork of the base [commonmark/cmark](https://github.com/commonmark/cmark) project. GitHub adds its own extensions on top of CommonMark, called GitHub Flavored Markdown, and it's absolutely the version of Markdown that I prefer. The fork from brokenhandsio meanwhile adds SwiftPM support around the C code, but it's still not a nice Swift-y API.

What Parsley does is really rather simple: [using a `Scanner`](https://github.com/loopwerk/Parsley/blob/main/Sources/Parsley/Parsley.swift#L65-L83) I first remove the metadata and the first title from the raw Markdown content, then pass the rest of the content onto cmark-gfm. Then I combine the results in a nice struct and return it to you.

```swift
let input = """
---
author: Kevin
tags: Swift, Parsley
---

# Hello World
This is the body
"""

let document = try Parsley.parse(input)
print(document.title) // Hello World
print(document.body) // <p>This is the body</p>
print(document.metadata) // ["author": "Kevin", "tags": "Swift, Parsley"]
```

How does it render my test string?

```html
<p>This <strong>is</strong> a <a href="http://www.example.com">www.example.com</a> <em>naked</em> link, and an email: <a href="mailto:info@example.com">info@example.com</a><br />
Hard break! <del>strike</del></p>
<ul>
<li>List directly attached</li>
<li>Another list item</li>
</ul>
<blockquote>
<h1>Title within blockquote!</h1>
</blockquote>
<pre><code class="language-swift">print(&quot;Hello world&quot;)
</code></pre>
```

Great! The naked link, autolink, strikethrough text and hard break are all as expected. The list which sticks to the preceding paragraph renders correctly, as does the header within the blockquote. Basically the output is flawless, at least with my test string (...and all my articles).

So what's the problem? Well, it's impossible to modify the generated HTML to your liking. Let's say you want to change all external links to have a `target` of `_blank`. Or maybe you want to give all heading tags an anchor id. Or you want to add syntax highlighting to code blocks, also not possible - you're stuck with doing client side highlighting with a JavaScript library such as prism.js.

While cmark does have the ability to generate an AST that you can then modify, that is by no means easy or straightforward. To add some kind of user-friendly plugin system to Parsley, based on cmark under the hood, would be a big undertaking.

So that made me wonder: can I replace cmark-gfm with another library which does support a better way of modifying the output? That way I can keep the API of Parsley as-is, but add more functionality to it. Or, maybe I can replace Parsley in Saga with another library, if I don't have to wrap it to add my own functionality - that would be even better.

## [Ink](https://github.com/JohnSundell/Ink)
There is so much to like about this project. It's fast, it handles metadata, and is very easily extensible where you can target the kind of HTML element you want to modify. If you want to modify all external links to have a `target` of `_blank`, you can. Or if you want to add anchor tags to all headings, you can. It also natively supports getting the first H1-level title from document, although it doesn't support removing it from the body. So if you want to render content between the title and the body, like I do on this website, you'd need to find a way to do this yourself. Not really a problem: worst case scenario I could just handle the metadata and title parsing myself like I do with Parsley, by pre-parsing the raw Markdown before handing it off to Ink.

It also runs on Linux and since it's easy to target `<code>` blocks, trivial to plug in any syntax highlighter you want (not that there are many -or any good- choices, but that's another article).

Sounds like a winner, why look further, right? Sadly it has a few problems parsing real-world content, which has stopped me from using it for my own website. This is how it renders my test string:

	<h1>This is the title</h1>
	<p>This <strong>is</strong> a www.example.com <em>naked</em> link, and an email: <info@example.com>
	Hard break! ~~strike~~
	- List directly attached
	- Another list item
	
	> # Title within blockquote!
	
	```swift
	print(\"Hello world\")
	```</p>
	
That's not good at all, it really gets tripped up by that email address, which it sees as an HTML tag. If I remove those angle brackets, the result is slightly better:

``` html
<h1>This is the title</h1><p>This <strong>is</strong> a www.example.com <em>naked</em> link, and an email: info@example.com Hard break! <s>strike</s> - List directly attached - Another list item</p><blockquote><p># Title within blockquote!</p></blockquote><pre><code class="language-swift">print("Hello world")
</code></pre>
```

The list that's attached to the preceding paragraph doesn't parse as expected, and the title within the blockquote doesn't render properly. It's also weird that all the newlines are gone, but not a big problem probably.

There are a bunch of open Pull Requests fixing a variety of issues, but these PRs have been open for a long time and are not getting any attention from the maintainer. I've thought about forking Ink and merging in all those PRs to end up with a version that would work for my website, but I'm afraid I'd end up having to maintain this fork by myself, and it's a big and complex project. This is not something I want to be responsible for.

I want to love this project, it comes so close to being perfect (or at least can easily be extended to being perfect). But the parsing problems which are not getting fixed, that's really a dealbreaker for me.

## [Down](https://github.com/johnxnguyen/Down)
Basically a Swift wrapper around cmark. Let's start with parsing my test string, which results in the following HTML:

```html
<hr />
<h2>tags: review, swift, saga</h2>
<h1>This is the title</h1>
<p>This <strong>is</strong> a www.example.com <em>naked</em> link, and an email: <a href=\"mailto:info@example.com\">info@example.com</a><br />
Hard break! ~~strike~~</p>
<ul>
<li>List directly attached</li>
<li>Another list item</li>
</ul>
<blockquote>
<h1>Title within blockquote!</h1>
</blockquote>
<pre><code class=\"language-swift\">print(&quot;Hello world&quot;)
</code></pre>
```

It doesn't support metadata or naked links, but does support the `<autolinks>` format. Sadly no strikethrough support, but hard breaks work (when you call Down with the correct option). Also the list renders properly and the title within the blockquote works fine.

Metadata support is easy enough to do myself, like I said before, so I'm not too worried if a project doesn't have built-in metadata support. But what about extensibility? Down does have the ability to spit out an AST of nodes, but there is no easy way to modify this tree as far as I can see. You need to write your own Visitor object which is quite a lot of work. It's definitely not built with ease of modifying content in mind, like Ink clearly was.

I basically see no real reason to use this over `brokenhandsio/cmark-gfm`, which is just as hard to add a user-friendly plugin system to, but has a better starting point when it comes to its generated output.

## [Swift MarkdownKit](https://github.com/objecthub/swift-markdownkit)
This is an interesting parser that is not based on cmark, but does use its own AST before rendering to HTML. Let's see how it renders my test string:

```html
<hr />
<h2>tags: review, swift, saga</h2>
<h1>This is the title</h1>
<p>This <strong>is</strong> a www.example.com <em>naked</em> link, and an email: <a href="mailto:info@example.com">info@example.com</a>
Hard break! ~~strike~~</p>
<ul>
<li>List directly attached</li>
<li>Another list item</li>
</ul>
<blockquote>
<h1>Title within blockquote!</h1>
</blockquote>
<pre><code class="swift">print("Hello world")
</code></pre>
```

So, no hard breaks, no strikethrough, no naked links, and no metadata support. At least the list and title within blockquote are rendered correctly.

MarkdownKit does have a plugin system, but it's really quite complex. Adding support for `~~strikethrough~~` for example takes a lot of effort. On the plus side, modifying the AST to remove the first title is quite easy:

```swift
func findAndRemoveFirstTitle(doc: Block) -> (Block, String?) {
  guard case .document(let topLevelBlocks) = doc else {
    preconditionFailure("markdown block does not represent a document")
  }

  var title: String?
  var blocks = [Block]()

  for block in topLevelBlocks {
    switch block {
      case .heading(1, let text):
        if title == nil {
          title = text.rawDescription
        } else {
          blocks.append(block)
        }
      default:
        blocks.append(block)
    }
  }

  let newDoc = Block.document(.init(blocks))
  return (newDoc, title)
}

let document = MarkdownParser.standard.parse(string)
let (modifiedDocument, title) = findAndRemoveFirstTitle(doc: document)
let html = HtmlGenerator.standard.generate(doc: modifiedDocument)
print(html)
```

That code will remove the first title from the document, and return it separately. Sadly it seems impossible to add support for hard breaks because MarkdownKit has already replaced newlines with spaces, leaving you with nothing to replace.

This project has potential, especially if I can figure out how to create a more elegant plugin system on top of the functionality MarkdownKit gives you out of the box, but it wouldn't be very easy to get there I think.

## [Markingbird](https://github.com/kristopherjohnson/Markingbird)
The README starts with a warning saying the code is no longer being maintained, and indeed the last commit was four years ago. I didn't even bother to try this one.

## [Maaku](https://github.com/KristopherGBaker/Maaku)
"The Maaku framework provides a Swift wrapper around cmark with the addition of a Swift friendly representation of the AST." At least, that's what the GitHub repo says. The issues seem to hint that you're still working with raw cmark nodes. But sadly I wasn't able to try it, as Maaku has a whole lot of compiler errors when trying to use this in a SPM package.

## Swift wrappers around Python parsers
I've created two of such wrappers: [SwiftMarkdown](https://github.com/loopwerk/SwiftMarkdown) and [SwiftMarkdown2](https://github.com/loopwerk/SwiftMarkdown2). They are wrappers around very mature and well-supported Python parsers, with support for extensions, syntax highlighting with Pygments and more. Super promising, but sadly quite slow. It's also not possible to modify the content using Swift code, you'll have to write Python extensions instead. And since I'm looking for a Swift solution, I quickly decided not to bother further with my two Python based parsers.

## What now?
So where does this leave me? Well, for now, and for my own website, the current plugin-less version of Parsley works fine.  Personally I don't have a big need to modify the generated HTML, which is of high quality. Would it be nice to be able to do certain things like opening external links in new tabs? Yes, and I think that Saga deserves a Markdown parser that makes this not only possible, but straight-forward.

Ink comes close to my ideal API and I'd love to use it for my website. There is a reader plugin for Saga which uses Ink, but I am not able to use it myself because of my Markdown files which Ink simply doesn't render correctly.

I'm not sure where this leaves me to be honest. It depends on how much time I want to put into writing my own plugin system on top of cmark I guess. I'll keep you updated.
