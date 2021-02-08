---
tags: swift, saga, open source
summary: In the third and final part of this series about Saga I'm looking at the pros and cons of the current system and what I might want to change.
---

# Building my own static site generator, part 3: thoughts so far
*I've been designing and building my own static site generator, written in Swift, and an early version has been [released on Github](https://github.com/loopwerk/Saga). In this series of articles I want to go over the inspiration, the constraints and goals, how I got to my current API, and the pros and cons of said API. Finally, I also want to brainstorm about where to go from here.*

*If you missed part 1, where I discuss the inspiration and goals of Saga, you can find it [here](/articles/2021/saga-1-inspiration/). And part 2, where I talk about the API design can be found [here](/articles/2021/saga-2-api-design/).*

# Part 3: Thoughts so far

## Pros and cons of the current setup
I'm quite happy with the [current API](/articles/2021/saga-2-api-design/) - I think it's quite easy to work with, flexible, easy to extend, yet very easy for the simple use-cases. What I am not so happy with, are the third party dependencies that Saga relies on at the moment.

I chose to use [Ink](https://github.com/johnsundell/ink) and [Splash](https://github.com/JohnSundell/Splash) for the actual Markdown parsing and code block highlighting. Sadly both are young projects with lots of missing features. For example Splash, the code highlighter, only supports Swift code, which is obviously not enough for a general-purpose static site generator. And Ink, the Markdown parser, has quite a lot of formatting bugs that have already stopped me from using it for my own website. At the time of writing there are 21 open pull requests with all sorts of fixes, some over a year old, but they're not getting any attention it seems. It doesn't feel smart to rely on these two dependencies going forward, so I'll have to find another Markdown parser and code highlighter. And while there are plenty of high quality choices within the  Python and JavaScript ecosystems, that's not quite the case for Swift. It's going to be a challenge to find good replacements.

The third big dependency is [Stencil](https://github.com/stencilproject/Stencil), a template language with a syntax similar to Django / Mustache / Jinja2. I chose it because I'm very used to the syntax myself, but Stencil has some bugs that might not be dealbreakers but are definitely annoying to work around. And also this project doesn't look like it has a team of maintainers with a lot of free time behind it. But *by far* the biggest problem is that a template language is just not as powerful as an actual programming language. Everything you might want to do in your template needs to be explicitly supported via "filters". For example, if you want to show the five most recent articles on your homepage, that is simply not possible at the moment, since there is no way to filter, sort or limit arrays in Stencil templates. Of course I can add special filters to the Stencil renderer for that, but where does it end? It seems a lot smarter to use a HTML DSL like [Plot](https://github.com/JohnSundell/Plot) or [swift-html](https://github.com/pointfreeco/swift-html), although that's quite a big learning curve for people used to writing HTML templates. Another thing to keep in mind is that these DSLs are limited in what kind of output they can produce — can they make a sitemap XML document? RSS feeds?

My final worry has to due with the `Page` metadata. Currently this metadata is very basic:

``` swift
public protocol Metadata: Decodable {}

public class Page {
  public var metadata: Metadata
  // .. and plenty of other properties
}
```

Just anything that's `Decodable`, but notably it's not using generic types. I would love to be able to turn the `Page` into this:

``` swift
public protocol Metadata: Decodable {}

public class Page<M: Metadata {
  public var metadata: M
  // .. and plenty of other properties
}
```

So that when you have an instance of a `Page`, it's very clear what kind of metadata you're dealing with, it becomes part of the `Page` type itself. It would save you from having to typecast the metadata all the time, like `page.metadata as? ArticleMetadata`, which I would say is a con of the current system. But sadly these kinds of generics end up making it impossible to store an array of *all* pages, since those are now all of different types. Even if I use type erasure to store all pages into one array, that just means that later on you have to typecast after all to get a hold of the proper metadata type. See [this recent article](/articles/2021/swift-generics/) for a bigger explanation of the problems and solutions I looked at.

I thought about combining the read and write steps into one combined step, that you'd execute per different metadata type, so that I wouldn't have to store different kind of pages into one array. While that sounds good at first, it would break a lot of use-cases; what if you want to show a list of recent articles *and* recents apps on your homepage? If I'm building a flexible system that should be usable for any kind of website, this should be possible. Of course I could say "well my website doesn't need it so I am going to build the most simple system just for my use-case," but I'd rather build something that's usable for (almost) everybody.

I'm not lying when I say that this problem has caused me a lot of wasted hours trying to come up with better solutions.

## Top priorities on the todo list
The number one priority is to find replacements for Ink and Splash, since the problems with those dependencies are actively stopping me from using Saga for my own website. Replacing Stencil is a secondary concern, since I *could* add the filters I need to build my existing website using it. I just don't think it's going to scale, so replacing Stencil seems like a wise choice.

I need to add more docs and unit tests. Currently I use the example project as my testbed, but this doesn't scale well - it's too easy to overlook rendering bugs in one of the pages. But I want to finish replacing the dependencies before I start writing all kinds of tests.

## Other considerations and final thoughts
To be honest, I'm not sure how much demand there is for yet another static site generator. Am I building this for an audience of one? How generic should Saga be, or can I just make it work for my use case? How smart is it to even build a static site generator in Swift? The ecosystem of available libraries is so much bigger in the Python and JavaScript worlds. Also, running Swift on Linux is not very straight-forward, but I do really want to be able to automatically build and deploy my website on new commits using a CI system like Netlify. Yet another problem I recently came across is generating Twitter preview images for articles. [Very easy to do with Python](https://github.com/loopwerk/Saga/blob/main/Example/ImageGenerator/image.py), but simply not possible at all using pure Swift. Which makes me ask myself again: why build a static site generator in Swift?

I am having fun working on this project though, it's also been a good exercise to design a nice API. And yes, the fact that Swift is strongly typed is of course a huge advantage (as well as a burden, sometimes - dealing with multiple metadata types would be a lot easier in Python or JavaScript!).

One thing that's kind of a must-have for a static site generator is an auto-watch auto-refresh server mode. This is so handy when writing articles: hit save and your browser immediately refreshes with the latest version of the rendered article. Or while working on the templates or the css files, it's truly a life saver. How would I go about adding this to Saga? I (mostly) know how to do it in Python, but in Swift it's going to be a challenge for sure. Which makes me wonder again: who am I building this for? If it's just for me, why not just stick with [liquidluck](https://github.com/avelino/liquidluck), even though it's unmaintained? 

I think the answer is as follows: if I can make Saga work for my own website without loosing any functionality, I will. I'll switch away from liquidluck and maintain Saga going forward, adding things like an auto-watch server mode. If I can't find good third-party libraries to do the Markdown parsing and code highlighting, I'll write Saga off as a nice experiment that I had fun playing around with, but I won't put more time into it. We'll see how it goes, you can definitely expect at least one more article about Saga in the future.
