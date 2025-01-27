---
tags: saga, open source, review
summary: I started building Saga, my own static site generator written in Swift, four years ago. Let’s look at the state of the project.
---

# Looking back at four years of Saga

Back in January of 2021 (four years ago already!) I started working on my own static site generator [Saga](https://github.com/loopwerk/Saga). I wrote a whole [series of articles](/articles/tag/saga/) on the inspiration and goals, the API design, and how it evolved over time.

My main goal was flexibility; specifically the ability to have multiple sets of items, each with their own (strongly typed) metadata. This is something that most other generators do not support. For example you could have a website where you have blog articles under `/blog/`, where each article has one or more tags. You’d have a page for each tag (`/blog/[tag]/`), and you also want an archive per year (`/blog/[year]/`). And of course it all has to be paginated, showing 20 articles per page. You want an RSS feed of all your articles, and a feed per tag. So far, this is nothing special, basically any static site generator can do this.

But what if you also want to show movie reviews on your site? You store the reviews in separate markdown files, one file per review. You store different kinds of metadata, like the year of release, main actors, genre, a rating, a main image. You want to show these reviews on `/movies/`, you want a page per year, per genre, and per actor. And now you also want to add an app portfolio on your site. Each app has its own markdown file with different metadata yet again, like a link to the App Store and a set of screenshots. You want to show this on `/portfolio/`, and maybe you also want to create separate pages for your iOS, Android, and web projects, who knows. Or what about recipes, where you store the cuisine, type of course, and complexity, as metadata.

Point is, most static site generators only deal with blog articles and they come with predefined metadata for this. I wouldn’t be able to build this very site using any of those generators, since my articles, apps, and open source sections are all built from these small markdown files, one for each item. My Open Source section isn’t created from one big markdown file, but [many small files](https://github.com/loopwerk/loopwerk.io/tree/master/content/projects), one for each project.

Saga does offer all this flexibility, and then some. It’s so easy to write your own Swift code to adjust the rendering process. And while Saga only supports markdown files out-of-the-box, it’s quite easy to build your own reStructeredText reader, or a Word document reader, or whatever other files you want to render to HTML. You can use different template languages, from strongly typed DSLs to more mustache-like, and it’s easy to add support for other template languages. It’s easy to add your own processing step, for example to generate a social media preview image for each article.

As far as I know [Hugo](https://gohugo.io) is the only other static site generator flexible enough to render this website using multiple sets of metadata. Out of interest I did have a look at Hugo but I did not like its template language, or the use of configuration over explicit code. With Saga your site is built exactly as you instruct it to do; with Hugo you’re dealing with default config values that you have to override or disable and a lot of hidden behavior. Some things are quite nice though, such as automatic RSS feeds (RSS feeds are certainly possible in Saga but take work to configure), server-side code block syntax highlighting, and the wealth of available themes. Then again a theme is just HTML and CSS and there is no reason this can’t be adapted to Saga quite easily. I like Hugo’s documentation as well, but on the other hand... there is so much documentation! Saga is much simpler in comparison. Not because it’s less flexible, but because the developer is expected to write their own Swift code to setup and configure things. Saga doesn’t need to offer a million config options for every possible feature a site developer might need, now or in the future.

And it’s not like it’s hard to get started with Saga. The bare minimum to get markdown pages rendered to HTML, using a strongly-typed template language, is something like this:

```swift
func renderPage(context: ItemRenderingContext<EmptyMetadata>) -> Node {
  html(lang: "en-US") {
    body {
      div(id: "content") {
        h1 { context.item.title }
        Node.raw(context.item.body)
      }
    }
  }
}

@main
struct Run {
  static func main() async throws {
    try await Saga(input: "content", output: "deploy")
      // All files will be parsed to html.
      .register(
        readers: [.parsleyMarkdownReader()],
        writers: [.itemWriter(swim(renderPage))]
      )

      // Run the step we registered above
      .run()

      // All the remaining files that were not parsed to markdown, so for example 
      // images, raw html files, and css, are copied as-is to the output folder.
      .staticFiles()
  }
}
```

And it’s quite easy to add more steps to this process as you go, building up the way you generate your site. Everything is explicit, type-checked, with autocompletion in Xcode.

It’s now four years since I started building Saga and I am still very proud of it, and I still enjoy using it for this website. Besides Hugo it’s the only static site generator (that I’m aware of) flexible enough to build this website, and I much prefer Swift code over TOML config files and strange HTML templates.

There are however a few things that bother me.

I’m pretty sure that loopwerk.io is the only site using Saga, and it’s a lot of effort to build and maintain a static site generator for an audience of one. I am disappointed that it didn’t gain more traction. [Publish](https://github.com/JohnSundell/Publish), the only other static site generator written in Swift, has over 4900 stars on GitHub even though the last commit to it was over two years ago, its last release was in 2022, and it’s nowhere near as flexible as Saga is.

I think that building a static site generator in Swift might have been a mistake if I wanted more traction and adoption. It’s quite a niche language outside of iOS / macOS app development, and it’s unlikely that many people wanting to build a static site want to install Xcode and learn Swift. Then again, there are a lot of developers who know Swift, and surely some of them need a static site, so I am surprised that Saga barely got over 80 stars on GitHub in four years. 

Another reason why Swift wasn’t the ideal choice is the lack of good markdown readers (I had to create [my own](https://github.com/loopwerk/Parsley)!) and the lack of syntax highlighters for code blocks. Hugo has brilliant syntax highlighting for a ton of languages, but this just doesn’t exist for Swift. There’s only [Splash](https://github.com/JohnSundell/Splash) but that only supports Swift code highlighting, and hasn’t had a release since 2021. Instead I am forced to use client-side syntax highlighting with [prism](https://prismjs.com). Maybe I should’ve built Saga using something like TypeScript? It would’ve had have a much bigger possible audience, and all the markdown parsers and syntax highlighters you could ever want.

If I’m looking at traction and adoption, then I guess I have to call Saga a flop. I really wish that more people would’ve built sites using it, that there were more contributors. I did (very briefly) consider to rebuild my site in Hugo, archive Saga on GitHub, mark it as unmaintained. But no, screw that. I really do enjoy using it, and I honestly do think it’s unique enough that it should stay around, even it’s just me using it. Maybe I *should* port it to TypeScript though? Or Python with type hints? It would be an interesting experiment for sure!

I do invite everyone to [take a look at Saga](https://github.com/loopwerk/Saga) and its [documentation](https://loopwerk.github.io/Saga/documentation/saga/), check out the [source of loopwerk.io](https://github.com/loopwerk/loopwerk.io/blob/master/Sources/Loopwerk/run.swift) for an idea of what Saga can do, and please do let me know if you’ve built something with Saga -- it would really make my day.