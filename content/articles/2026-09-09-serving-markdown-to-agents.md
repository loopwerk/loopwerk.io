---
tags: ai, deployment, howto
summary: AI agents ask for Markdown via their Accept header, so why not give it to them?
---

# Serving Markdown to AI agents

When Claude Code fetches a web page, it sends this request header:

```
Accept: text/markdown, text/html, */*
```

It's asking for Markdown, saying that HTML is also fine, and promising to make do with whatever else you throw at it. Pretty much every website responds with HTML, which the agent then has to convert back into pure text, burning tokens on nav bars and syntax highlighting markup along the way.

As of today my website honors that header. Request any article with `Accept: text/markdown` and you get the article's raw Markdown source:

```shell-session
$ curl -H "Accept: text/markdown" https://www.loopwerk.io/articles/2026/serving-markdown-to-agents/
```

This greatly reduces the size of the response, which means fewer tokens are needed to read the article. And instead of having to convert HTML to Markdown by stripping away all tags, the response is now immediately usable to the agent.

Some sites serve a parallel set of URLs where you can append `.md` to any page, but HTTP has had content negotiation since forever. If the client asks for a certain format, why not just give it to them while keeping one URL for humans and agents alike?

## Nginx

This site is just static HTML files on disk, so there's no server-side code that can look at request headers. Instead I copy a Markdown twin next to every article's `index.html` (more on that below), and nginx picks which of the two files to serve. Here's the config, trimmed to the relevant parts:

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

The map turns the Accept header into a filename: if it mentions `text/markdown` anywhere, `$negotiated_index` becomes `index.md`, otherwise `index.html`, and the `index` directive then serves that file. And because `index` takes a list of files to try, pages that don't have a Markdown version simply fall back to `index.html`.

The `types` block is there because nginx's built-in `mime.types` table has no entry for `.md` files, and the charset lines because Markdown has no way to declare its own charset like HTML does with a meta tag. Finally, since one URL can now produce two different responses, the `Vary` header tells caches to key on the Accept header. Keep this in mind, we'll get back to it in the Cloudflare section below.

## Saga

As I said, I copy a Markdown twin next to every article's `index.html`. This site is built with [Saga](https://github.com/loopwerk/Saga), where it's a simple `afterWrite` step:

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

If you're using a different static site generator the same idea applies: your source files are already Markdown, you just have to copy them into the output.

## Cloudflare

loopwerk.io sits behind Cloudflare with pretty aggressive edge caching where pages are cached for a year, and purged via the Cloudflare API on every deploy. 

Here's something you need to know: by default Cloudflare ignores the `Vary` header. It caches *one response per URL*, so whoever requests a page first decides what everybody else gets. If an agent asks for the Markdown version first, every human visitor after that would get raw Markdown in their browser.

Luckily Cloudflare's Cache Rules have a Vary setting for exactly this scenario. I added it to my "cache everything" rule so that it normalizes the `accept` header into two media types (`text/html` and `text/markdown`), normalizes `accept-encoding`, and bypasses the cache for any other `Vary` value:

![](/articles/images/serving-markdown-to-agents.webp)

We need to normalize the accept header, because in the real world, headers are all over the place with all kinds of combinations of values. If Cloudflare keyed the cache on the raw header, every unique string would get its own cached copy and the hit rate would fall off a cliff.

Is it a bit odd to optimize my site for robots when my robots.txt tells crawlers not to train on my articles? Maybe. But an agent fetching an article to answer somebody's question is, in the end, just a reader too. Might as well hand it an optimized version.
