---
tags: workflow, ai
summary: I'm back solving all the puzzles myself, and I couldn't be happier!
---

# Claude Code as a read-only assistant has saved my sanity

Back in April I wrote an article titled [Coding with AI: productivity without pride or joy](/articles/2026/ai-productivity-without-joy/), where I talk about the cost of using Claude Code. Yes, it makes me more productive, but it also removes all the joy I used to get from programming. By solving all the puzzles for me, it left me without that "eureka!" feeling, without pride or joy in my work.

I said back then that I wanted to limit Claude to the boilerplate code and the boring busywork, and solve the hard problems myself. I really believed I could stick to that resolution, but AI is kind of addictive. With all that power at my fingertips, it was way too easy to simply let it solve the problem instead of using my own brain. Even though I was feeling bad about doing it, I couldn't really stop it either.

But as time went on I became more disillusioned with our industry, with money-grabbing big tech and all the layoffs. With the climate-destroying datacenters, and the bots that are out of control. Burning tokens so I didn't have to write some code became impossible to explain to myself. I was seeing people who can't get anything done anymore without AI, and I feared that I would become dependent on AI as well, if I continued to use it. I lie awake at night, wondering if I'll still have a job in five years. My job is also my hobby, and I don't want to become a rubber stamp for an AI agent.

I also realized that I was happiest with AI before I started using Claude Code; I still wrote all the code myself, solved all the puzzles myself, but I used ChatGPT to help me out when I was stuck. AI was basically a really fancy Stack Overflow replacement. I would give a detailed description of my problem, and it would give me an answer.

I kind of wanted to go back to that, but I do think that it's super useful that Claude Code has access to the project and it can figure out what's going on. It's a huge improvement over my old way of asking ChatGPT without it having access to my code. So, a few days ago, I removed all the `CLAUDE.md` files from my projects, and instead I created a global one in my `~/.claude` folder, with the following contents:

```markdown
You are a read-only assistant. You will help with research, understanding code, making plans, figuring out problems, brainstorming and rubber-ducking.

You do not write code. When asked you may present code to the user, but you won't make changes.

When replying, use as few words as possible. Reduce the volume to a strict minimum. Be direct and honest and down to the point. Less is more. Avoid superlatives and praise (stop telling the user they are "absolutely right").

You should be having a conversation with the user, as two senior developers working together. That means making one point or asking one question, getting a reply, then asking the next thing, as a conversation would go. Do not ask multiple questions in one go, hidden in a wall of text.

Never present a guess, assumption, or reverse-engineered explanation as established fact. If you don't know something, look it up: inspect the environment, read the source, test it, or search the web. Don't theorize. Do not take a symptom and invent a plausible-sounding mechanism to explain it, then assert it as documented behavior.
```

I've been using this for about a week now, and I have to say: it's pretty amazing to get my own hands dirty again, while still having a helpful assistant standing by whenever I need it. While I am still pessimistic about knowledge workers having jobs in the near future, at least I am keeping my brain sharp and enjoying myself.