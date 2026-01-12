---
tags: apple, swift, review
summary: Apple's DocC project and the Swift Package Manager have been missing pretty crucial features for years now. It's time that Apple gave them some love and attention.
---

# DocC and SPM need some love and attention from Apple

The documentation for [Saga](https://github.com/loopwerk/Saga), and many other Swift projects (including most of Apple's own projects), is created using [DocC](https://www.swift.org/documentation/docc/), Apple's documentation compiler. It takes your annotated source code, supplementary documents you write in markdown, and even interactive tutorials you can create using markdown, and makes this documentation available within Xcode. Better yet; it can also create an HTML version with the same look and feel as official Apple documentation, which you can host pretty much anywhere, even on GitHub Pages.

Hosting this generated documentation actually used to be really hard to do at first, see [this article](https://www.jessesquires.com/blog/2021/06/29/apple-docc-great-but-useless-for-oss/) from 2021. At least this part got improved and DocC can now generate a normal static site without a need for a server and access to redirect rules. But it's not exactly great at doing this, and there haven't been serious improvements since the initial public release back in May 2022.

By far the biggest problem is the way the generated documentation site is structured. When I create the documentation site for Saga using [`swift-docc-plugin`](https://github.com/swiftlang/swift-docc-plugin), it creates a structure such as this:

```
docs/
├── css/
├── data/
├── js/
├── images/
└── documentation/
    └── saga/
        └── index.html
```

The site root is `/docs/`, and the result is that the documentation lives on the URL https://loopwerk.github.io/Saga/documentation/saga/ instead of just https://loopwerk.github.io/Saga/, which is what I want. Or let's say I want to host the documentation on https://saga.loopwerk.io - that doesn't work, it has to be accessed as https://saga.loopwerk.io/documentation/saga/, and this is just extremely silly.

I can't just point the site root to `/docs/documentation/saga/` either, because the HTML files depend on resources from the upper folders, which would no longer be accessible. Basically what I am looking for is that `/docs/documentation/saga/*` gets moved to `/docs/` and it just keeps working, and this is just not possible.

Making all of this even worse is that DocC doesn't even generate a landing page, so when you go to https://loopwerk.github.io/Saga/ you get a 404 page. Same for https://loopwerk.github.io/Saga/documentation/. Why doesn't Apple at least create a landing page in the website's root that links to the documentation target(s)? It's been asked for repeatedly in their open source repo.

The second problem is that `swift-docc-plugin` has to be added to your Swift project as a dependency, so that you are able to generate the static documentation site. This results that anyone _using_ or _depending on_ your Swift package now also has to download `swift-docc-plugin` for absolutely no reason. I don't understand why the Swift Package Manager doesn't support something like development dependencies, or why it downloads dependencies which are not added to the actual target.

Here's a simplified version of Saga's `Package.swift` file:

```swift
let package = Package(
  name: "Saga",
  platforms: [
    .macOS(.v12),
  ],
  products: [
    .library(name: "Saga", targets: ["Saga"]),
  ],
  dependencies: [
    .package(url: "https://github.com/kylef/PathKit", from: "1.0.1"),
    <mark>.package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),</mark>
  ],
  targets: [
    .target(
      name: "Saga",
      dependencies: ["PathKit"]
    ),
  ]
)
```

You can see that even though `swift-docc-plugin` has been added as a dependency of the _project_, it has not been added as a dependency to any of the _targets_. So when someone adds Saga as a dependency, then why does Xcode download `swift-docc-plugin`? It makes no sense.

There's also no command line command to add and remove dependencies to your Swift project, ala npm or uv. That would enable me to create a script that first adds the `swift-docc-plugin` dependency to Saga, then generates the documentation, and then it can remove `swift-docc-plugin` again. Instead I had to create this script:

```bash
#! /bin/bash

set -e

PACKAGE_SWIFT="Package.swift"
DOCC_PLUGIN_LINE=".package(url: \"https://github.com/swiftlang/swift-docc-plugin\", from: \"1.1.0\"),"

# Enable the swift-docc-plugin dependency
sed -i '' "s|//\s*$DOCC_PLUGIN_LINE|$DOCC_PLUGIN_LINE|" "$PACKAGE_SWIFT"

# Pretty print DocC JSON output so that it can be consistently diffed between commits
export DOCC_JSON_PRETTYPRINT="YES"

# Generate documentation
swift package \
  --allow-writing-to-directory ./docs \
  generate-documentation \
  --target Saga \
  --disable-indexing \
  --output-path ./docs \
  --transform-for-static-hosting \
  --hosting-base-path Saga

# Restore Package.swift by commenting out the dependency again
if grep -q "$DOCC_PLUGIN_LINE" "$PACKAGE_SWIFT"; then
  sed -i '' "s|$DOCC_PLUGIN_LINE|//$DOCC_PLUGIN_LINE|" "$PACKAGE_SWIFT"
fi

echo "Documentation generated successfully."
```

So now I have a commented-out dependency to `swift-docc-plugin` in my `Package.swift` file, which this script can enable before generating the documentation, and then it can comment it out again. It's just so weird that this is necessary, and so clunky.

> [!UPDATE]
> It turns out that there is now a command to add a new dependency to your project: `swift package add-dependency`. It was added with Swift 6.0, see the proposal [here](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0301-package-editing-commands.md). But there's no command to delete a dependency, so it's still not very useful in the context of temporarily adding the `swift-docc-plugin` dependency just to generate documentation. Thanks [Ole](https://hachyderm.io/@ole@chaos.social/114037168018204405) for letting me know!

If Xcode simply wouldn't download unused dependencies none of this would be necessary. It would even make monorepos for Swift packages a viable thing. Right now if you have a monorepo with multiple targets, each of which has one or more dependencies, the result is that anyone using even a single target from the monorepo ends up downloading _all dependencies of all targets_. Apollo [ran into the exact same problem](https://www.apollographql.com/blog/how-apollo-manages-swift-packages-in-a-monorepo-with-git-subtrees) and ended up with a complex workflow where they use git subtrees.

So to recap: DocC can't create a documentation site where the actual docs just start in the root. It doesn't create a landing page either. SPM doesn't support development dependencies, and downloads all dependencies for all targets. It doesn't have a command line interface for adding and removing dependencies. It makes it incredible hard to have a monorepo.

Oh and Foundation on Linux is a minefield where you don't know what works and what doesn't, or what needs a special guarded import to work. For example if you want to use `XMLDocument` on Linux you have to add this import:

```swift
#if canImport(FoundationXML)
import FoundationXML
#endif
```

But when you look at [Apple's documentation for `XMLDocument`](https://developer.apple.com/documentation/foundation/xmldocument) none of this is documented. It just says this is part of Foundation, and that's it. Linux is an afterthought and it's up to you to see what works and what doesn't. Better set up CI which tries to build and test your project on Linux!

These are just some of the things I ran into in the past few days while working on Saga, and honestly it's really not a good motivator to use Swift for (future) projects like this, which need to run on the server, on Linux, and have a plugin system which would be much easier to work on in a monorepo. Apple really needs to up their game and give their tools more love and attention.
