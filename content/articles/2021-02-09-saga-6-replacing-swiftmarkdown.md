---
tags: swift, saga, open source
summary: I've already replaced my own SwiftMarkdown package...
---

# Building my own static site generator, part 6: replacing SwiftMarkdown
It was only yesterday that I [published an article](/articles/2021/saga-5-replacing-ink/) saying how I replaced Ink and Splash with my own Markdown reader [SwiftMarkdown](https://github.com/loopwerk/SwiftMarkdown). In that article I did say "if I find a pure Swift parser that can match this output, I’ll gladly change over," and well, I did.

I wrote my own wrapper around Github's fork of cmark, and published it as a new package called [Parsley](https://github.com/loopwerk/Parsley). It's very fast — much faster than SwiftMarkdown was with its PythonKit dependency. It also comes with all the Github Flavored Markdown extensions like tables, fenced code blocks, strikethrough, hard line breaks and auto links. I've further enhanced it by adding support for in-document Metadata and I'm able to strip the document title out of the document body.

The only downside is that Parsley doesn't do any sort of code syntax highlighting — at least not yet — so you'll have to use a client side library such as [prism.js](https://prismjs.com). I am now using Saga for my actual live website, so I'll definitely keep working on Saga!

And just like before, I did keep the old Markdown reader as a [separate plugin](https://github.com/loopwerk/SagaPythonMarkdownReader), in case you do want to use SwiftMarkdown.