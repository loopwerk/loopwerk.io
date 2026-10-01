---
tags: insights, ai
summary: You can't just say "make an app", you still need to know how to build a good app. AI might help with the code, but we're still the ones with the technical expertise and taste.
---

# Garbage in, garbage out (why good developers are still necessary in the age of LLMs)

I've been a developer for almost 25 years, and I've seen plenty of hype cycles in my time. Most of them came and went without leaving a real impact. The latest hype, AI (and LLMs in particular), seems different though: it's actually changing the way we work, in a big way.

I've seen a lot of people who think that AI is going to make all developers obsolete. They think that you can ask it to "make an app", and it will spit out a perfect, finished project. I'm sorry to burst your bubble, but that's not the case. The old saying "garbage in, garbage out" is still true, maybe now more than ever.

You still need to know how to build a good app. You might not be the one writing most of the code, but you are the one steering the code generation. You're in control of the features and the UX. You still need to spot the problems.

## My first experience with Claude Code

I've been using ChatGPT for about a year now, including for work. But it's always been a matter of me asking a very specific question, getting the answer, and then applying that answer to my code. Basically, a glorified Stack Overflow, and most of the time it was really good. But I didn't give any LLM direct access to my code, until recently.

I was working on [Saga](https://getsaga.dev), my static site generator written in Swift. I wanted to make it faster by introducing parallelization to its processing pipeline. I had a pretty good idea of how to do it, but my own experiments only resulted in modest speed increases. I hit the ceiling of my Swift expertise and needed help. I could've asked ChatGPT (or Stack Overflow), but I wouldn't have gotten a solution to my very specific problem. So, I decided to try out Claude Code.

It went way better than I expected. I gave it access to the Saga project, told it to make it faster by adding parallelization, and it went to work. It took a while, but it made Saga quite a bit faster. My own site, which used to take 2.5 seconds to generate, now only takes 1 second.

I don't think I could've done it without Claude Code. But here's the thing: I don't think Claude Code could've done it without me either. For example it wanted to parallelize *everything*, including the registered pipeline steps. But those steps always need to run sequentially, because the order of the steps is important. My domain knowledge was exactly the kind of thing that AI didn't have. It would've made Saga faster at generating subtly broken websites.

Claude also had no idea how to fix broken unit tests now that Saga was running a bunch of processing in parallel. It went on a wild goose chase, making weirder and weirder changes all over the code. I had to step in and stop it, and explain what had to be mocked, among other things.

## Our role is changing

I did enjoy my time with Claude Code, and I have started using it in more projects since then. And I have noticed that my role has changed, from pure developer to more of a manager.

AI coding assistants are incredibly skilled, but definitely junior developers. They have perfect syntax knowledge and are pretty good at debugging problems, but they don't know good UX. They can implement any design pattern you describe, but they can't tell which patterns make sense for your project. They can refactor your messes, but they won't know which messes are worth cleaning up.

So when I was working with Claude Code, I was constantly making decisions and steering it. Which parts of the codebase to touch (and more importantly, which to leave alone). Telling it to stop when it was good enough (making the code massively more complex for a 2% speed increase isn't worth it).

I actually had to stop it quite often because it was trying to be *too* helpful. Ask Claude to add a simple feature and it might throw in logging, 15 tests with a bunch of mocks, config options, and abstraction layers (it absolutely loves to overcomplicate things with more layers). And now you've ended up with 500 lines when 50 would've been worked.

On the other hand, it also often doesn't do enough. When working on a Django site, it happily writes the bare minimum ORM query without dealing with N+1 queries, unless you tell it to. It doesn't think about race conditions, unless you make it. This is the kind of experience that's still important to have.

I was spending less time coding, but way more time reviewing. I want to maintain ownership of my projects, and know every line that goes into them. And of course I want to maintain my high standard of quality: just because AI has written some code doesn't mean I am not responsible for it. If I wouldn't have written it like this, I tell it to change it.

## Are we doomed?

I don't think so. A junior developer using Claude Code will get a worse result than a senior developer using Claude Code, because we know what to look out for. We know which architecture patterns we like, and won't let it turn our projects into spaghetti. When debugging problems, we already have at least a rough idea of where to look, and whether the suggested solution actually makes sense. We know when to stop Claude, when to steer it in a different direction, and when to point out things it missed.

The need for good developers won't go away, but I do think we'll be typing less code ourselves.
