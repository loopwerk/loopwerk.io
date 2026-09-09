---
tags: ai, deployment, howto
summary: AI agents ask for Markdown via their Accept header, so why not give it to them?
---

# Serving Markdown to AI agents

When Claude Code fetches a web page, it sends this request header:

```
Accept: text/markdown, text/html, */*
```

It's asking for Markdown, saying that HTML is also fine, and promising to make do with whatever else you throw at it. Pretty much every website ignores the first part and responds with HTML, which the agent then has to convert back into something readable, burning tokens on nav bars, footers and syntax highlighting markup along the way.

This website now actually honors that header. Request any article with `Accept: text/markdown` and you get the article's raw Markdown source, the exact file I wrote, served from the same URL as the HTML version:

```
curl -H "Accept: text/markdown" https://www.loopwerk.io/articles/2026/serving-markdown-to-agents/
```

Why bother? Mostly size: the HTML version of this article weighs 24 KB, the Markdown version just 6 KB. An agent pays for every token it reads, and everything it doesn't have to read leaves more room in its context window for actual work. Plus the Markdown isn't some lossy HTML-to-markdown conversion; it's the source itself, with headings, links, and code blocks with their language annotations all intact.

There are other approaches to this problem. There's the [llms.txt proposal](https://llmstxt.org), and some documentation sites serve a parallel set of URLs where you can append `.md` to any page. But HTTP has had content negotiation since forever: the client says what it wants in the Accept header, and the server picks the best representation it has. One URL for humans and agents alike. It's great when old standards turn out to be exactly the right tool!

## Nginx

This site is just HTML plain files on disk, so there's no server-side code that can look at request headers. Instead I copy a Markdown twin next to every article's `index.html` (more on that below), and nginx picks which of the two files to serve. Turns out the `index` directive accepts variables, which makes this whole thing pleasantly small. Here's the config, trimmed to the relevant parts:

```nginx title="/etc/nginx/conf.d/default.conf"
map $http_accept $negotiated_index {
    default           "index.html";
    "~*text/markdown" "index.md";
}

types {
    text/markdown md;
}

server {
    listen 80;
    index $negotiated_index index.html;

    charset utf-8;
    charset_types text/html text/xml text/plain application/javascript application/rss+xml text/markdown;

    add_header Vary "Accept" always;

    # ...
}
```

The map turns the Accept header into a filename: if it mentions `text/markdown` anywhere, `$negotiated_index` becomes `index.md`, otherwise `index.html`, and the `index` directive then serves that file. And because `index` takes a list of files to try, pages that don't have a Markdown twin simply fall through to `index.html`.

The `types` block is there because nginx's built-in `mime.types` table has no entry for `.md` files, and the charset lines because Markdown has no way to declare its own charset like HTML does with a meta tag. Finally, since one URL can now produce two different responses, the `Vary` header tells caches to key on the Accept header. Keep that one in mind, we'll get back to it.

## Saga

As I said, I copy a Markdown twin next to every article's `index.html`. This site is built with [Saga](https://github.com/loopwerk/Saga), where it's a single `afterWrite` step:

```swift title="main.swift"
try await Saga(input: "content", output: "deploy")
  .register(...)
  .afterWrite { saga in
    let articles = saga.allItems.compactMap { $0 as? Item<ArticleMetadata> }

    for article in articles {
      let markdown: String = try article.absoluteSource.read()
      let destination = saga.outputPath + article.relativeDestination.parent() + "index.md"
      try destination.parent().mkpath()
      try destination.write(markdown)
    }
  }
  .run()
```

All it does is copy each article's source file into the output folder as `index.md`. If you're using a different static site generator the same idea applies: your source files are already Markdown, you just have to copy them into the output.

## Cloudflare

loopwerk.io sits behind Cloudflare with pretty aggressive edge caching: pages are cached for a year and purged via the Cloudflare API on every deploy. And here's the gotcha: by default Cloudflare ignores the `Vary` header. It caches one response per URL, so whoever requests a page first decides what everybody else gets. If an agent asks for the Markdown version first, every human visitor after that would get raw Markdown in their browser. Not great.

Luckily Cloudflare's Cache Rules have a Vary setting for exactly this. I added it to my "cache everything" rule so that it normalizes the `accept` header into two media types (`text/html` and `text/markdown`), normalizes `accept-encoding`, and bypasses the cache for any other `Vary` value:

![](/articles/images/serving-markdown-to-agents.webp)

The normalizing part matters. Real-world headers are all over the place, and if Cloudflare keyed the cache on the raw header value, every unique string would get its own cached copy and the hit rate would fall off a cliff. Normalizing collapses all of that into the two media types I listed, so each URL has exactly two variants at the edge: one HTML, one Markdown, both served with `cf-cache-status: HIT`.

Is it a bit odd to optimize my site for robots when I have [mixed feelings about AI](/articles/2026/ai-productivity-without-joy/) and my robots.txt tells crawlers not to train on my articles? Maybe. But an agent fetching an article to answer somebody's question is, in the end, just a reader too. Might as well hand it an optimized version.
