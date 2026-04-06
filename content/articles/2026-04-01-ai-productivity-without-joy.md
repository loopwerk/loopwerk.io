---
tags: personal, ai
summary: I just finished my most productive quarter in a long time, made possible by Claude Code, and there are two conflicting feelings that I want to talk about.
---

# Coding with AI: productivity without pride or joy

I just finished [my most productive quarter](/articles/2026/q1-2026-in-review/) in a long time. Seven new open source projects, plus about forty releases to my existing projects. Fueled by a combination of too much free time (I'm still [available for new projects](/hire-me/)!) and Claude Code. Looking back at all the code that I've released, there are two quite strong and conflicting feelings that I want to talk about.

## The productivity gain is real

Claude Code still needs quite a lot of hand-holding to get production-quality code that you'd be proud to ship under your name. I still go over almost every line that it produces, and I either tell it to change things or manually fix a good chunk of what it spits out. So if I look purely at code-writing output, using Claude Code isn't that much faster than just doing it myself.

However, as a solo developer working on a bunch of open source projects, there's a lot of boilerplate that's hard to get motivated for, as well as genuinely complicated features where I'm not sure how to even get started. And it's in both these scenarios where Claude Code shines for me. As a janitor doing the boring work, and as someone to talk to, get ideas from, and brainstorm with. Once we've gone over all the ins and outs and come to a plan, it can then build a prototype much faster than I can. Yes, creating the plan takes a lot of work, but it's the same kind of time I'd be spending without Claude Code too; researching solutions, trying things out, seeing what API design feels right. The stakes to build something are higher when you do it all yourself, whereas now I feel much more comfortable trying wacky ideas, seeing what sticks, and throw the rest away to start again.

## But at what cost?

There's no way I would've been able to build all the recent features and improvements to Saga in the same amount of time, if it wasn't for Claude Code's help.

But would that have been bad? Nobody was asking for seven new projects and forty releases. There's nobody setting deadlines for me. I work on this stuff because I enjoy making well-designed software. My profession is also my hobby.

And that's the biggest issue. Have I actually enjoyed myself releasing all this code? On the one hand it feels very good to make so many improvements to Saga and other projects. It absolutely became a better tool, and I benefit from the improvements myself as well. But instead of solving the puzzles myself, coming up with the best API design and the simplest solution to a hard problem and getting that "eureka!" feeling that I love so very much... I was basically a manager telling Claude what to do, and then I had to review its code and fix its mistakes.

AI let me skip the journey and jump right to the destination. But usually arriving at the destination comes with a euphoric feeling of accomplishment, and that was just gone. I was the most productive I've maybe ever been, and yet I got very little joy out of it. There was no pride.

I also feel less connected to this new code. Even though I went over all the changes and I feel like I understand how it all works, it's not quite the same as solving the puzzle yourself, building the solution from scratch, writing every line by hand.

## And now?

Apparently, plenty of people are fine with this new way of working. "I release projects where I've not written a single line" is a new boast. But why did you become a programmer? Purely for the end result, or for the craft of making that product? For me it's always mostly been about the craft. I love the feeling of starting with a blank file, writing line by line, improving things as it grows, coming up with elegant and pragmatic solutions to hard problems, and then literally pumping my fist in the air at 2:00 a.m. when it all comes together. The thing that I built is usually less important to me. It could be an e-commerce site for a client or a static site generator for myself, it doesn't really matter that much what I work on. Every project has its unique puzzles to solve and its own interesting challenges.

If I let AI solve those puzzles for me, then what's left? What's in it for me? The ability to quickly churn out more code doesn't make *my* life better. It will come with the expectation of ever-higher productivity, more and more AI usage, until we’re just babysitters, rubber-stamping pull requests we barely touched.

What does this mean for my own AI usage in my own open source projects? I don't think it'll ever be gone completely, as it is an immensely useful tool. But instead of Claude Code writing the solution and me just checking its output, I want to reduce it to a very advanced rubber duck. Not only able to listen to my plans, ideas, and problems, but also to offer suggestions and brainstorm solutions with me. But that’s where it should stop. I want the puzzles back.

## Links

Other people have witten better articles about the pros and con of, and their feelings about AI, which I'd like to recommend.

> Working with coding agents feels like a slot machine. You send a prompt, wait 30 seconds, and get something great or something useless. I found myself at 1am thinking "one more prompt" even when I knew it wouldn't work. When I was tired, my prompts got vague, the output got worse, and I'd try again anyway. It is a dopamine trap that prioritizes shipping over thinking.

From [Eight years of wanting, three months of building with AI](https://lalitm.com/post/building-syntaqlite-ai/) by Lalit Maganti.

> Bob has none of this. Take away the agent, and Bob is still a first-year student who hasn't started yet. The year happened around him but not inside him. He shipped a product, but he didn't learn a trade.

From [The machines are fine. I'm worried about us.](https://ergosphere.blog/posts/the-machines-are-fine/) by Minas Karamanis.

> "AI"-assisted programming’s a bit like pedal-assist on electric bicycles. It makes progress feel easy, but we might not realise the impact that’s having on our coding "muscles" – our ability to comprehend and reason about code. That is, until we run out of juice and have to pedal unaided. That’s when it becomes obvious just how much of our Code Fu we’ve lost as we’ve come to rely on that assistance more and more. Increasingly, I hear developers say "I’ve hit my token limit, so I’m blocked."

From [Rely On AI And Get Left Behind](https://codemanship.wordpress.com/2026/02/21/is-comprehension-debt-in-your-risk-register/) by Jason Gorman.

> I got into computers because solving puzzles was fun, and building worlds was fun, and making things — the process of making things — was fun, down at the granular level. It was nice to have something at the end, but the act of creation was the exciting part. [...] The journey actually was the reward for some subset of weird little freaks, but you can now skip all that crap and just jump to the end and get on with it.

From [Lose Myself](https://www.eod.com/blog/2026/02/lose-myself/) by Greg Knauss.

> I also just have trouble with the idea that this is my career and the thing I spend my limited time on earth doing and the quality of it doesn't matter. I delight in craftsmanship when I encounter it in almost any discipline. I love it when you walk into an old house and see all the hand crafted details everywhere that don't make economic sense but still look beautiful. I adore when someone has carefully selected the perfect font to match something.

From [I Sold Out for $20 a Month and All I Got Was This Perfectly Generated Terraform](https://matduggan.com/i-sold-out-for-200-a-month-and-all-i-got-was-this-perfectly-generated-terraform/) by Mat Duggan