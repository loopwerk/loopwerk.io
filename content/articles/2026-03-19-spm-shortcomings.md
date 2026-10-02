---
tags: swift
summary: As I prepare Saga 3, I keep running into fundamental limitations in Swift Package Manager that make maintaining a plugin ecosystem unnecessarily painful.
---

# The shortcomings of Swift Package Manager

As I am working on [Saga](https://github.com/loopwerk/Saga) 3, the next major version of my static site generator, I keep running into limitations of Swift Package Manager. SPM has come a long way since its introduction in 2016, but if you maintain a package with a plugin ecosystem, there are some serious pain points left for Apple to fix.

## 1. No peer dependencies

Let's start with the big one. In npm a plugin can declare "I work with version 2 or 3 of the host package, and the consumer provides it". Sadly SPM has no such concept.

Saga has a plugin architecture: readers like SagaParsleyMarkdownReader, renderers like SagaSwimRenderer, and utilities like SagaUtils. Each of these plugins depends on Saga, because they use its types.

Because SPM doesn't support peer dependencies, each plugin needs to add a dependency to Saga. There's no way to say "I need Saga, but let the consumer provide it". This leads directly to the next two problems.

## 2. Version ceiling by default

When you add a dependency to your Swift project like this:

```swift
.package(url: "https://github.com/loopwerk/Saga", from: "2.0.0")
```

That really means `>= 2.0.0, < 3.0.0`. In other words, there's a major version ceiling. That sounds good in theory, respecting SemVer and all, but for published libraries (such as the Saga plugins) this is actually causing a pretty big problem.

Saga is currently at version 2, and so all the plugins depend on Saga using the `from: "2.0.0"` flag. Everything works, the ecosystem is in sync. But Saga 3 will be released soon, and while it has user-facing breaking changes, the plugin-facing API has no changes at all. All the readers, renderers and other utilities work exactly the same as before. But because every plugin depends on Saga 2, none of them are usable with Saga 3.

This means that I have to update 10 plugins, and change `from: "2.0.0"` to `from: "3.0.0"`. All 10 plugins need their own major version bump because of this, since this is a breaking change for them.

You can sort-of work around this with an explicit range:

```swift
.package(url: "https://github.com/loopwerk/Saga", "2.0.0"..<"4.0.0")
```

It solves the fact that every plugin needs a major version bump, but I'd still need to update all 10 of them. With peer dependencies this simply wouldn't be an issue.

## 3. Package identity conflicts

SPM is a pain when working with local versions of dependencies. Let me explain.

Saga's example app uses a local path dependency to reference Saga itself:

```swift
.package(path: "../")
```

This works fine. But SagaSwimRenderer, which the example app also depends on, also depends on Saga via the real git URL. SPM then complains:

> Conflicting identity for saga: dependency 'github.com/loopwerk/saga' and dependency '/users/kevin/workspace/loopwerk/saga/saga' both point to the same package identity 'saga'.

It's just a warning that I can ignore, but it also says "This will be escalated to an error in future versions of SwiftPM." That sounds ominous.

How am I even supposed to fix this? The suggestion is to "coordinate with the maintainer of the package that introduces the conflicting dependency" - but I am the maintainer of both packages. There is no fix! SPM simply doesn't support this workflow.

With peer dependencies the plugins wouldn't declare where Saga comes from, only that it needs to be available. There would be no conflict.

## 4. Monorepos aren't a real solution

If you're thinking that the obvious answer to all of these problems is a monorepo: great minds think alike.

However, SPM monorepos have their own problem: anyone who depends on one package in the repo has to download all dependencies for all packages. Even if those packages are unused, and their targets never compiled, SPM still fetches and resolves this entire dependency tree. For a project like Saga with a bunch of plugins that in turn have their own sizable dependencies such as SwiftSoup, that's a lot of unnecessary downloading.

I [explored this problem](https://github.com/loopwerk/Saga/issues/24) and tried to make it work, but without success. Apollo GraphQL hit [the exact same problem](https://www.apollographql.com/blog/how-apollo-manages-swift-packages-in-a-monorepo-with-git-subtrees) with their iOS SDK: they wanted a monorepo for development, but separate repos for distribution, so that users don't have to download the whole tree. Their solution was to use Git subtrees with GitHub Actions that automatically split and push changes to the separate repos when PRs are merged. It works for them, but this is a very complex setup for something that should simply be supported by SPM.

## 5. No dev dependencies

Virtually every package manager understands the concept of development-only dependencies, except for SPM. So if your package depends on `swift-docc-plugin` for rendering docs, or a test library like `swift-snapshot-testing`, every user of that package has to download these dependencies.

It's just absurd to me that something as basic as dev dependencies is not supported. It also makes the monorepo problem even worse, since consumers end up downloading all the development tools for all the packages. It's nuts.

## What I'd like to see

SPM should really implement fixes for these problems, which seem table-stakes to me. Peer dependencies and dev dependencies are well known to other package managers, and for good reason. It should make monorepos viable, for example by lazily fetching dependencies. Only download the dependencies for targets that are actually getting compiled - solving dev dependencies as well.

Oh, and a better CLI please. You can't even uninstall a dependency via the command line.