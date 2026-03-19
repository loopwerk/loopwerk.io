---
tags: swift
summary: As I prepare Saga 3, I keep running into fundamental limitations in Swift Package Manager that make maintaining a plugin ecosystem unnecessarily painful.
---

# The shortcomings of Swift Package Manager

As I'm preparing [Saga](https://github.com/loopwerk/Saga) 3, the next major version of my static site generator, I keep running into fundamental limitations in Swift Package Manager. SPM has come a long way since its introduction, but for anyone maintaining a package with a plugin ecosystem, there are some serious pain points that still don't have good solutions.

## 1. No peer dependencies

This is the big one. In the npm ecosystem, a plugin can declare "I work with version 2 or 3 of the host package, but the consumer provides it." SPM has no equivalent concept.

Saga has a plugin architecture: readers like [SagaParsleyMarkdownReader](https://github.com/loopwerk/SagaParsleyMarkdownReader), renderers like [SagaSwimRenderer](https://github.com/loopwerk/SagaSwimRenderer), and utilities like [SagaUtils](https://github.com/loopwerk/SagaUtils). Each of these depends on Saga because they use its types (`Reader`, `Item`, etc.). But SPM forces each plugin to declare *exactly* where Saga comes from — a specific git URL with a specific version range. There's no way to say "I need Saga, but let the consumer decide which version and where it comes from."

This leads directly to the next two problems.

## 2. Version ceiling by default

When you declare a dependency like this:

```swift
.package(url: "https://github.com/loopwerk/Saga", from: "2.0.0")
```

SPM interprets this as `>= 2.0.0, < 3.0.0`. There's an implicit major version ceiling. This is semver-correct in theory — a major version bump *might* break your code — but in practice it creates a cascade problem.

Saga 3 changes the *user-facing* API, but the *plugin-facing* API hasn't changed at all. Readers and renderers work identically. Yet because every plugin declares `from: "2.0.0"`, none of them will resolve with Saga 3 without updating their Package.swift.

And here's the kicker: you can't release a minor version of a plugin that depends on a new major version of its host package. That's a breaking change for the plugin's consumers. So every plugin also needs a new major version. For Saga, that's 10 packages that all need coordinated major releases, even though zero lines of plugin code changed.

You *can* work around this with an explicit range:

```swift
.package(url: "https://github.com/loopwerk/Saga", "2.0.0"..<"4.0.0")
```

But this feels like a hack, and you're making a forward-looking promise that your code will work with a version that doesn't exist yet. With peer dependencies, this problem simply wouldn't exist.

## 3. Package identity conflicts

SPM identifies packages by their URL or path. When the same package is referenced by both a git URL and a local path, SPM considers them conflicting identities — even though they're obviously the same package.

This comes up constantly during development. Saga's Example app uses a local path dependency to reference Saga itself:

```swift
.package(path: "../")
```

But SagaSwimRenderer (which the Example also depends on) pulls in Saga via its git URL. SPM then complains:

> Conflicting identity for saga: dependency 'github.com/loopwerk/saga' and dependency '/users/kevin/workspace/loopwerk/saga/saga' both point to the same package identity 'saga'.

And the warning ominously adds: "This will be escalated to an error in future versions of SwiftPM."

How are you supposed to fix this? The suggestion is to "coordinate with the maintainer of the package that introduces the conflicting dependency" — but *I am* the maintainer of both packages. There is no fix. SPM simply doesn't support this workflow.

With peer dependencies, the plugin wouldn't declare where Saga comes from at all. The consumer would provide it, whether that's a git URL or a local path. No conflict.

## 4. Monorepos aren't a real solution

The obvious response to all of the above is: "just put everything in one repo." And yes, that would eliminate the version cascade, the identity conflicts, and the peer dependency problem in one stroke.

But SPM monorepos have their own cost: anyone who depends on *one* package in the repo downloads *all* dependencies for *every* package. Even if those targets never get compiled, SPM still fetches and resolves every dependency in the Package.swift. For a project like Saga with readers that depend on different Markdown parsers, renderers that depend on different template engines, and utilities that depend on SwiftSoup — that's a lot of unnecessary downloading for someone who just wants one reader.

A second problem is that all targets in a monorepo share a single version number. When you tag a release because of a small update in Saga, every plugin appears to have been updated too, even if nothing changed.

I [explored this problem](https://github.com/loopwerk/Saga/issues/24) and tried various workarounds without success. Apollo GraphQL ran into [the exact same problem](https://www.apollographql.com/blog/how-apollo-manages-swift-packages-in-a-monorepo-with-git-subtrees) with their iOS SDK. They wanted a monorepo for development (unified PRs, holistic code review) but separate repos for distribution (so users don't download everything). Their solution? Git subtrees with custom GitHub Actions that automatically split and push changes to individual repos when PRs merge. It works, but it's a significant amount of infrastructure to work around what is fundamentally a missing feature in SPM.

## 5. No dev dependencies

SPM has no concept of development-only dependencies. If your package uses `swift-docc-plugin` to generate documentation, or a testing library like `swift-snapshot-testing`, that dependency is declared at the package level — and every consumer of your library downloads it too, even though they'll never use it.

The `swift-docc-plugin` case is particularly absurd: even though it's added as a dependency of the *project* and not of any *target*, SPM still fetches it for everyone. The only workaround is to [comment out the dependency in Package.swift before tagging a release](https://www.loopwerk.io/articles/2025/docc-spm-need-love/), and uncomment it when you want to generate docs locally. That's not a workflow, that's a hack.

This also makes the monorepo problem worse. It's not just that consumers download dependencies for targets they don't use — they also download your documentation tooling, your test helpers, and anything else that should be scoped to development.

## 6. Missing basic CLI tooling

Most package managers ship with commands for common dependency management tasks: adding, removing, listing outdated packages, updating a single dependency. SPM has... `swift package add-dependency`. And that's about it.

There's no `swift package outdated` to see which dependencies have newer versions available. There's no `swift package update SomePackage` to update a single dependency (it's all or nothing). There's no `swift package remove-dependency`. These are table-stakes features for a package manager in 2026.

## What I'd like to see

SPM doesn't need to copy npm. But a few targeted additions would make a huge difference for anyone maintaining packages with plugins or extensions:

1. **Peer dependencies**: let a package declare that it needs a dependency without specifying the source. Let the consumer provide it.
2. **Dev dependencies**: dependencies that are only fetched during development, not by consumers of your package.
3. **Lazy dependency fetching**: only download dependencies that are actually needed for the targets being compiled. This would make monorepos viable and dev dependencies less urgent in one stroke.
4. **Identity resolution**: if two sources resolve to the same package (same name, same targets), treat them as the same package instead of raising an unsolvable conflict.
5. **Basic CLI commands**: `outdated`, `remove-dependency`, `update --package`. These should have existed years ago.

Until then, maintaining a plugin ecosystem in Swift remains more painful than it needs to be.
