---
tags: insights
summary: Luckily for us, good developers are still necessary in the age of LLMs. You can't just say "make an app", you still need to know how to build a good app.
---

# Garbage in, garbage out: why good developers are still necessary in the age of LLMs

I've been a developer for a long time, and I've seen a lot of technologies come and go. I've seen hype cycles, I've seen technologies that were supposed to change everything, and I've seen technologies that actually did. I think it's safe to say that Large Language Models fall into the latter category. They are a genuinely transformative technology that is changing the way we work.

But I've also seen a lot of people who think that LLMs are going to make developers obsolete. They think that you can just tell an LLM to "make an app" and it will spit out a perfect, finished product. This is, to put it mildly, not the case. The old adage "garbage in, garbage out" has never been more relevant.

You still need to know how to build a good app. You might not be the one typing all the code, but you're the one steering the code generation, the features, the UX, and spotting the problems. You are the architect, the project manager, and the quality assurance all rolled into one. The LLM is a powerful tool, but it's still just a tool. And like any tool, it's only as good as the person using it.

## My experience with Claude Code and Saga

I recently had a chance to put this to the test with my own project, [Saga](https://github.com/loopwerk/Saga), a static site generator written in Swift. I wanted to make it faster by [parallelizing its processing](https://github.com/loopwerk/Saga/pull/34). I had a good idea of how to do it, because I had in fact already done it myself in a [previous PR](https://github.com/loopwerk/Saga/pull/33), but I wasn't happy with the modest speed increase. So I decided to try using Claude Code to help me make a better version.

I'm happy to report that it was a resounding success. By working with Claude, I was able to make Saga 60% faster. My own site, which is built with Saga, used to take 2.5 seconds to generate. Now it only takes 1 second. That's a huge improvement, and I couldn't have done it without Claude's help.

But here's the thing: I couldn't have done it _without my own expertise either_. When I decided to make Saga faster, I didn't just throw the problem at Claude and hope for the best. I had specific ideas about what could be parallelized:

- File reading operations
- Writer execution
- Static file copying

But here's where it gets interesting. Claude initially suggested parallelizing _everything_, including the processing steps. Sounds great, right? More parallelization = more speed? Not quite. I knew that the processing steps needed to remain sequential, because every step depends on knowing which files were handled by previous steps.

Claude also had no idea how to fix broken unit tests now that Saga was running all these things in parellel, and it went on a wild goose chase making weirder and weirder changes all over the codebase. I had to step in, stop Claude, and tell it how to properly mock things that needed to be mocked, that it should make array access safe in concurrent code, things like that.

This is exactly the kind of domain knowledge that separates "someone who uses AI" from "a developer who uses AI." Without understanding the architecture of Saga and the importance of deterministic output, you'd end up with a faster but broken static site generator.

## The developer as helmsman

This is what I mean when I say that developers are still necessary in the age of LLMs. We are the helmsmen, steering the ship. The LLM is the engine, providing the power. But without a skilled helmsman, the ship will just go in circles, or worse, crash into the rocks.

Think of AI coding assistants as incredibly skilled junior developers with perfect syntax knowledge but zero context about your project. They can implement any pattern you describe, optimize any algorithm you point out, and refactor any mess you identify. But they can't tell you which patterns make sense for your use case, which optimizations are worth pursuing, or which messes actually need cleaning up.

When working on that Saga PR, I was constantly making decisions:

- Which parts of the codebase to touch (and more importantly, which to leave alone)
- How to maintain backward compatibility
- Where to add concurrency primitives without introducing race conditions
- When to stop optimizing (making the code massively more complex for a 2% speed increase isn't worth it)

None of these decisions could be made by Claude. It could suggest options, sure, but evaluating those options required understanding the broader context of the project, its users, and its goals.

## The UX still matters

Here's another thing AI can't do: design good user experiences. Sure, it can implement any interface you describe, but knowing what interface to build? That's on you.

For instance, imagine you're building an admin interface for a content management system. An AI might generate a perfectly functional system with all the CRUD operations working correctly. But it wouldn't know that your editors need to see a preview of how the article will look on the site before publishing. It wouldn't think to add custom actions for common workflows like "duplicate this article as a draft" or "schedule for next Monday at 9 AM".

These aren't groundbreaking features, but they're the difference between software that technically works and software that people actually enjoy using.

## Feature creep is real

One danger I've noticed when using AI assistants: they're _too_ helpful. Ask Claude to add a simple feature, and it might throw in logging, error handling, configuration options, and three different ways to extend it. Sounds great until you realize you've just added 500 lines of code for a feature that needed 50.

Good developers know when to say "no" - to features, to complexity, to clever solutions that solve problems you don't have. AI assistants don't have this restraint. They'll happily implement whatever you ask for, even if what you're asking for is a bad idea.

## You need to spot the problems

Perhaps most importantly, you need to be able to spot when things go wrong. AI-generated code often _looks_ right but contains subtle bugs:

- Race conditions in concurrent code
- Memory leaks from retain cycles
- Security vulnerabilities from improper input validation
- Performance issues from accidentally doing N+1 queries

During the Saga parallelization, I caught several of these. Claude's concurrent code was mostly correct, but it introduced bugs that would've resulted in sites being broken, and with flaky unit tests that didn't always spot the problem. Spotting these requires not just knowing the language, but understanding the runtime environment, the platform differences, and the kinds of things that can go wrong.

## The future is bright

AI coding assistants are game-changers. I'm writing more code faster than ever before. But they're tools, not replacements. The need for good developers hasn't gone away - it's just shifted.

Instead of typing out every line, we're now:

- Architecting systems that make sense
- Designing APIs that feel good
- Spotting problems before they hit production
- Making judgment calls about trade-offs
- Knowing when to stop adding features

In other words, we're doing what we've always done: thinking about problems and designing solutions. We're just spending less time on the typing part.

So, the next time you hear someone say that LLMs are going to make developers obsolete, you can tell them that they are missing the point. The role of the developer is changing, but it's not going away. In fact, I would argue that it's becoming more important than ever. We are the ones who can bridge the gap between the power of LLMs and the needs of the real world. We are the ones who can turn "garbage in" into "gold out".

The future isn't developers vs. AI. It's developers with AI, building better software faster. And that's a skill that will always be in demand.
