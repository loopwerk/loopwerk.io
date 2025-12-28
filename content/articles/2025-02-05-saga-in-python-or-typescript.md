---
tags: saga, swift
summary: What would Saga look like if it were written in Python or TypeScript, rather than in Swift? Is it worth the effort to port Saga to another language?
---

# Saga... but in Python? Or TypeScript?

About a week and a half ago I wrote [an article](/articles/2025/saga-four-years/) looking back at four years of [Saga](https://github.com/loopwerk/Saga), my static site generator written in Swift. As I said in that article, overall I am very happy with Saga's API and capabilities, but I do wonder if choosing Swift over Python or TypeScript was a mistake. The initial compilation step is slow, there aren't many good options for markdown parsers, nor code syntax highlighters, nor HTML template languages, and Swift probably isn't a logical choice for most (web) developers who want a static site. I ended the article wondering if I should port Saga to Python or TypeScript - which is exactly what I've been working on for the past few days.

I have working prototypes in both languages, and I have some thoughts I want to share. Now, both these prototypes are quite limited compared to the full Swift version: only the item writer works for example. But it is possible to render markdown files, using embedded metadata (with different metadata per folder!), to HTML files using renderers, which opens up the possibility to use any template language you could ever want.

Let's start by looking at how an end-user would use the Swift version of Saga, so we have a basis to compare the new versions to.

## Swift

```swift
struct ArticleMetadata: Metadata {
  let tags: [String]
  let summary: String?
}

struct AppMetadata: Metadata {
  let images: [String]
  let roundOffImages: Bool?
  let breakImages: Int?
  let url: String?
}

try await Saga(input: "content", output: "deploy")
  .register(
    folder: "articles",
    metadata: ArticleMetadata.self,
    readers: [.parsleyMarkdownReader()],
    writers: [.itemWriter(swim(renderArticle))]
  )
  .register(
    folder: "apps",
    metadata: AppMetadata.self,
    readers: [.parsleyMarkdownReader()],
    writers: [.listWriter(swim(renderApps))]
  )
  .register(
    readers: [.parsleyMarkdownReader()],
    writers: [.itemWriter(swim(renderPage))]
  )
  .run()
```

This example assumes there's a `content` folder, which contains both an `articles` subfolder and an `apps` subfolder. Markdown files in the `articles` folder contain embedded metadata such as this:

```
---
tags: saga, open source, swift
summary: What would Saga look like if it were written in Python or TypeScript, rather than in Swift?
---
```

And markdown files in the `apps` folder contain embedded metadata like this:

```
---
images: cn_1.png, cn_2.png
roundOffImages: false
breakImages: 1
url: https://www.critical-notes.com
date: 2020-06-23
---
```

This maps to the `ArticleMetadata` and `AppMetadata` types, respectively. We tell Saga explicitly that it should parse markdown files in the `articles` folder parsing the `ArticleMetadata` from those files, and the same for `AppMetadata` inside of the `apps` folder. Finally, all other markdown files in all other folders will be parsed without metadata at all.

Saga validates and transforms the metadata. For example a markdown file inside of the `articles` folder that doesn't include any `tags` in its metadata will not be parsed, it won't be part of the HTML output. The user will get an error in the console telling them about the validation error. It also automatically transforms a comma-separated string (like `saga, open source, swift`) to an array of strings, fully automatic, by leveraging Swift's `Decodable` protocol and a [pretty gnarly custom decoder](https://github.com/loopwerk/Saga/blob/main/Sources/Saga/MetadataDecoder.swift). All that a user of Saga has to deal with are simple native Swift structs, strongly typed. Saga does the rest.

The render functions (`renderArticle`, `renderApps`, and `renderPage`) all get handed an `Item<T>` instance where `T` is that strongly typed metadata - `ArticleMetadata` or `AppMetadata`. If the user opts to use a strongly typed template language or DSL such as [Swim](https://github.com/robb/Swim), everything is strongly typed from top to bottom. Pretty great!

## Python

Using the Python prototype looks like this:

```python
class ArticleMetadata(Metadata):
    tags: List[str]
    summary: str

class AppMetadata(Metadata):
    images: List[str]
    roundoffimages: bool = True
    breakimages: Optional[int] = None
    url: Optional[str] = None

Saga(input="content", output="deploy")
  .register(
    metadata=ArticleMetadata,
    folder="articles",
    readers=[MarkdownReader()],
    writers=[item_writer(jinja("article_template.html"))],
  )
  .register(
    metadata=AppMetadata,
    folder="apps",
    readers=[MarkdownReader()],
    writers=[item_writer(jinja("article_template.html"))],
  )
  .register(
    readers=[MarkdownReader()],
    writers=[item_writer(jinja("page_template.html"))],
  )
  .run()
```

As you can see, the API looks remarkably similar to the Swift version. We have two metadata types, using type hints. We use the same system of specifying readers and writers, where the writers use a renderer to turn an `Item` into a string. In this case the renderer uses the Jinja2 template language.

By using [Pydantic](https://docs.pydantic.dev/latest/) the Python version of Saga also validates and transforms metadata. So also in this case a missing `tag` in an article would result in an error, and a comma-separated string of tags results in an array of strings.

There are very good markdown readers (with support for code block syntax highlighting!) for Python. The only thing is that there aren't any strongly typed template languages or DSLs as far as I know. So while the strongly-typed metadata is absolutely useful for validating and auto-transforming the embedded metadata inside markdown files, it's a shame that the HTML templates are unaware of exactly what kind of metadata they're dealing with. It's not strongly typed "top to bottom", as in the Swift version.

## TypeScript

And finally, using the TypeScript prototype looks like this:

```typescript
type ArticleMetadata = {
  tags: string[];
  summary: string;
};

type AppMetadata = {
  images: string[];
  roundOffImages?: boolean;
  breakImages?: number;
  url?: string;
};

new Saga("content", "deploy")
  .register<ArticleMetadata>({
    folder: "articles",
    readers: [markdownReader()],
    writers: [itemWriter(renderArticle)],
  })
  .register<AppMetadata>({
    folder: "apps",
    readers: [markdownReader()],
    writers: [itemWriter(renderApp)],
  })
  .register<never>({
    readers: [markdownReader()],
    writers: [itemWriter(renderPage)],
  })
  .run();
```

Just as with the Swift and Python versions we have strongly typed metadata, and the shape of the code is very similar once again. One annoying thing about TypeScript (and JavaScript) is a lack of keyword arguments, which results in `Saga("content", "deploy")` without the `input` and `output` labels. One way to solve this is to always pass in an object, as I did with the `register` function. It's the only way to come close to keyword arguments with default values, but the added curly braces are a bit annoying.

The render functions get a fully typed `Item<T>` instance, where `T` is the metadata type. And unlike Python it's more useful here, as you could use TSX as your template language, in which case the strong types absolutely help a lot and we're strongly typed from top to bottom once again.

However, this version of Saga does not validate the metadata, and it can't transform it as needed, because the TypeScript types can't be used like that in runtime. Saga can't check if a JSON object confirms to `T`, since it doesn't know what `T` is. So it also can't transform the data to the expected type. This means that while the `ArticleMetadata` says that `tags` is an array or strings, in reality it'll be a comma-separated string. The type and the actual metadata instance are not aligned, which will definitely cause problems when you try to use the metadata in your templates.

The only way to solve this is to force users of Saga to describe their metadata using something else than pure TypeScript type notation, for example using [zod](https://zod.dev):

```typescript
const ArticleMetadata = z.object({
  tags: z.string().transform(str => str.split(",").map(tag => tag.trim())),
  summary: z.string(),
});

const AppMetadata = z.object({
  images: z.string().transform(str => str.split(",").map(tag => tag.trim())),
  roundOffImages: z.coerce.boolean().optional(),
  breakImages: z.number().optional(),
  date: z.string().optional(),
});
```

Only using something like this could Saga validate and transform the metadata, and it's pretty horrible. It's up to the end-user to add the `coerce` calls to make sure strings get casted to the right types, it's up to the user to transform that comma-separated string to an array of strings. It's such a big step back in usability that I can't believe validating data isn't possible using pure TypeScript types!

## Thoughts so far

As a developer working on these prototypes, I found the TypeScript version easier and more enjoyable to work on than the Python version, because Python's type hints kinda suck -- especially when working with generics. It's a pain in the butt and the syntax is ugly and hard to understand. For example here's the `Writer` class which is used internally:

```python
@dataclass
class Writer(Generic[M]):
    run: Callable[[List[Item[M]], Path, str], None]
```

All those square brackets! And while it's clear that the `run` property is a callable and what its parameter's types and return type are (once you understand the syntax), it's not clear at all what those parameters actually are. A list of items, a path, and a string.. sure? A path to what? A string of what? What the hell?

Compare that to the TypeScript version:

```typescript
export type Writer<M> = {
  run: (
    items: Item<M>[],
    outputPath: string,
    relativeDestination: string
  ) => void;
};
```

Here's it's immediately clear what those parameters are. And it's the same with the Swift version:

```swift
public struct Writer<M: Metadata> {
  let run: (_ items: [Item<M>], _ allItems: [AnyItem], _ outputRoot: Path, _ outputPrefix: Path, _ fileIO: FileIO) throws -> Void
}
```

Ignore the fact that this version takes more parameters than my two prototypes, because my point is the same: you can tell what those parameters are. Not so with the Python version.

Alright, so the Python type system kind of sucks, had me scratching my head quite a few times, and was slower to build than the TypeScript version. As an end-user simply using Saga that doesn't matter at all though, and I think for the user the Python version is much better, because metadata is properly validated and transformed.

And while I found the TypeScript version much more enjoyable to work on, there is the matter of TypeScript itself. People really would need to install [bun](https://bun.sh) to run this version of Saga as intended, in pure TypeScript, since Node doesn't run TypeScript code (at least not yet). And while I could distribute a JavaScript version to NPM that people could import into their Node script, the whole point of Saga is to have strongly typed metadata.

I think realistically speaking, the TypeScript version would never be used as TypeScript but rather the compiled-to-JavaScript version. And when you add something like zod to the mix to describe the metadata, there really isn't anything strongly typed left. Which is probably fine, since almost no template languages are strongly typed either.

So those are some of my conflicting thoughts at the moment. In conclusion:

- The Python version is great for the end-user. Strongly typed metadata works, which is validated and transformed as needed.
- But, the Python version is less enjoyable for me to work on.
- The TypeScript version is quite enjoyable for me to work on! I really do enjoy its type system and syntax. While it doesn't have keyword arguments, it can be approximated with passing objects.
- But, for end-users the TypeScript version simply doesn't make sense. They can't run it without installing bun, and even when they do that, the strongly-typed metadata cannot be validated, let alone automatically transformed.

Once you add zod to facilitate the metadata validation and transformation, the need for TypeScript's types basically goes away and thus it makes total sense to distribute Saga as JavaScript code. I have quite a strong negative feeling about requiring users to describe the metadata using zod though. I mean... `z.string().transform(str => str.split(",").map(tag => tag.trim()))` - really?

Until I find a better solution to deal with metadata validation and parsing in TypeScript / JavaScript, I don't think TypeScript is a good fit for Saga. I say that with some disappointment, as I really do enjoy TypeScript as a language. Also, the TypeScript version is slightly faster to run than the Python version, especially when writing files to disk. Writing a bunch of files took 0.3 ms in TypeScript, and the same amount of files took 22 ms with Python. Not a huge difference, but interesting to note.

That leaves me with the Python version, which arguably makes way more sense for a lot of people than the Swift version. I don't enjoy the type system so much while _working on_ Saga, but as a user _using_ Saga it's pretty great! And in the end that's the goal of course.

The big question is then if I will finish porting the Swift version to Python. Is it worth the effort? If I am doing this just for myself then the answer is a pretty clear "no". After all, I am already a happy user of the Swift version and the strongly typed HTML DSL. I personally have no need for a Python version. Would there be an audience for a Python version of Saga? Would it get any usage when there are already so many static site generators? Sure, they don't do the same, are not as flexible, not as explicit, but they do have users. There's also [Hugo](https://gohugo.io) which I personally did not like at all, but which has many users. It can do the same as Saga, and is much faster than any Python-based generator can be. Would a Python version of Saga get any users when there's Hugo, and a whole bunch of other Python-based generators? I don't know.

So please let me know if you're interested in Saga's syntax, flexibility and functionality yet were turned off because it's written in Swift. Would you use a Python version of Saga?

> **Update June 18, 2025**: I completed the Python port of Saga, and I was able to port this website from the Swift version to the Python version in an evening (with a lot of help from Claude Code). It all works, it's basically feature complete, but it's a bit slow. Where the Swift version takes about 1 second to generate this website, the Python version takes slightly more than 2 seconds. It's literally twice as slow. Still, with Python being a dynamic scripting language it's not a bad result, compared to the compiled Swift version of Saga.
> But here's the thing: even though I was able to port this website to the Python version of Saga, that was just a test that won't be published. This site will stay with the Swift version of Saga, because Saga is just better in Swift. Like I said above: "I personally have no need for a Python version."
> So yes, the Python port of Saga is basically feature complete and ready in a private GitHub repo, but I think it'll stay private for ever. I don't want to take on the burden of supporting and maintaining this Python port going forward, as I won't be a user myself.
