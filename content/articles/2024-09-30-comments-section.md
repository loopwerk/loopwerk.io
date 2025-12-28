---
tags: news
summary: I've added a comment section to the articles, powered by GitHub Discussions.
---

# Articles now with comments

I don't write that many articles on this site, but when I do I always feel like I am writing for a void: there are no comments, no likes, no reactions at all. Nobody that says thanks for the info, nobody who reports a spelling mistake. Obviously that's my own fault for not having a comment section, and for not being on Twitter. Since I'll never go back to Twitter I figured I'd add a comment section to my articles - but how?

This website is a statically generated site (using [Saga, my own static site generator written in Swift](https://github.com/loopwerk/Saga)) and as such adding a comment section isn't very straightforward. There are third party solutions like [Disqus](https://disqus.com), but those usually track and spy on users, have bad privacy practices, and I don't own the data. On the other side of the spectrum are [webmentions](https://indieweb.org/Webmention) but that seemed rather complicated to set up. In the end I decided to look into two solutions: comments via Mastodon, and comments via GitHub.

## Mastodon

I am a big fan of Mastodon (you can find me on [hachyderm](https://hachyderm.io/@kevinrenskers)) and it seemed pretty cool to embed replies to a toot as comments on an article. I found a [really nice open source project](https://github.com/dpecos/mastodon-comments): just a simple JavaScript file that you embed into the website, it pulls down the replies to a toot with a specific ID, and then inserts them into the DOM. Extremely easy to customize and style however you want! Sadly, that's kind of the only positive things about this solution, with plenty of downsides:

- Every article needs to know the "root” toot ID. So that means publishing the article, tooting about it, then updating the article with that ID. I'd also have to edit all existing articles with their toot ID, but I haven't been on Mastodon for nearly as long as I've had this site, so older articles can't have comments since I've never announced those articles on Mastodon. And it's silly to create such posts now, way after the fact.
- Read-only. This script only shows comments, people can't actually comment or like on the site itself. They have to open the link to that root toot, and comment there.
- Not everyone's on Mastodon, so the possible audience is rather limited.
- It's not possible to moderate or filter replies, so any off-topic replies to the toot are also shown on the site.

So while I loved the simplicity of the script and the ease of which you can style it, I moved on to GitHub.

## GitHub

There are broadly speaking two easy ways to host your comments on GitHub: as replies to Issues, or replies to Discussions. I didn't really like the idea of abusing Issues as comment threads for articles, so I focused my search on using Discussions for this. I only found one open source project that did what I wanted: [giscus](https://giscus.app). The idea is simple: users log in with their GitHub account, and then they can react to and comment on the article. A Discussion for the article is created if it doesn't already exist, and threaded replies to the Discussion are shown as comments below the article. But people can also directly reply in GitHub themselves which is pretty nice.

Compared to the Mastodon solution this has some really big upsides:

- There's no need to edit articles, as discussions are automatically created whenever someone reacts or comments.
- People can react and like directly below the article itself, it's not a read-only system.
- I'd bet that over 90% of my audience has a GitHub account.
- Comments are easy to moderate.

There are a few downsides though:

- When you log in with your GitHub account, the name "giscus” is mentioned rather than "Loopwerk”. While self-hosting the giscus app is possible, it seemed like too much work to maintain just for that reference.
- Since I don't control the frontend script, I can't exactly control the layout and styling. The comments section lives in its own iframe and as such can't be styled with my site CSS which is a bit of a bummer. Custom themes are possible but a hassle, especially when you want those to work locally as well.

I think the upsides by far outweigh the downsides and so I added giscus to this site, and you can now comment on all articles! I have no idea if anyone will actually use the comment section and if it turns out that nobody does then I'll probably remove it again, we'll see :)
