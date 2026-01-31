---
tags: insights
summary: Trying to "master" a programming language is a trap. Real expertise comes from learning what you need, when you need it, and ignoring the rest on purpose.
---

# Expertise is the art of ignoring

I’ve been writing code professionally for about 25 years.

The first eight of those years were spent writing PHP, and then I made the switch to Python. Here’s something that still feels counter-intuitive to say out loud:

**I felt more like an expert after eight years of PHP than I do after seventeen years of Python.**

This isn’t impostor syndrome. It isn’t a lack of confidence. And it isn’t because I somehow regressed as a developer. It’s because the idea of "mastering a language" no longer makes sense, if it ever did.

## When mastery felt possible

Early-2000s PHP had a very narrow job: generate HTML and talk to a database.

If you understood string manipulation, forms, sessions, and a handful of database functions, you essentially knew PHP. The official manual was finite. The ecosystem was small. The distance between "language knowledge" and "shipping a product" was almost zero.

You could realistically reach a point where you felt done. Not perfect, but complete. That feeling of mastery wasn’t arrogance. It was a side effect of a small problem space.

## The problem space exploded

Python didn’t replace PHP with something slightly bigger. It replaced it with a language that can be almost anything.

Python runs web applications, scientific simulations, machine learning pipelines, embedded systems, automation scripts, and even space hardware. Its standard library alone covers domains most developers will never touch in a lifetime.

After seventeen years, I know my slice extremely well. I can design, build, scale, and maintain Django applications with confidence. But I can open the Python documentation today and find entire modules I’ve never had a reason to touch. Large parts of `asyncio` internals, `ctypes`, low-level `multiprocessing` edge cases, or anything involving scientific computing.

That doesn’t make me uncomfortable. It makes me honest. It doesn’t mean I don’t know Python well enough. It means the language outgrew the idea of total knowledge.

## Frameworks didn’t make you worse

Modern development adds another layer of confusion.

When I write Python day to day, I’m not thinking in terms of the language as a whole. I’m thinking in Django concepts: models, queries, migrations, background tasks, deployment constraints.

Large frameworks deliberately hide most of the language from you. That isn’t a flaw. It’s the point. They compress complexity so you can solve a specific class of problems well. Being an expert today isn’t about knowing how the engine’s valves are timed. It’s about knowing how to drive the car at 100 mph without crashing.

This is why newer iOS developers can be productive in SwiftUI without having a deep mental model of Swift itself. They aren’t failing to learn the language. They’re learning at the level where work actually happens.

Expertise has moved up the stack.

## Just-In-Time beats Just-In-Case

Many developers, especially early in their careers, respond to this sprawl by trying to learn everything.

Every module. Every feature. Every corner case.  
Just in case it’s needed someday.

That instinct is understandable. It’s also deeply counter-productive. After decades of doing this professionally, I’m convinced of the opposite approach.

At this point, a cynical reader might object: "Isn’t this just an excuse to be a mediocre developer who doesn’t understand how things work under the hood?"

That’s a fair concern. It’s also not what I’m arguing for.

Just-In-Time learning doesn’t mean surface-level learning. It means **deep learning, applied narrowly**. Don’t be a generalist who knows nothing deeply. Be a specialist who knows exactly when to dig a new hole. When something matters for the problem you’re solving, you go all the way down. You just don’t dig every hole in advance.

Some lessons I wish I’d learned much earlier:

1. **You don’t need to master the language. You need to master your slice.**  
   Being a great Django developer does not require knowing how to write Python C extensions. Value comes from solving real problems, not from encyclopedic recall.

2. **Learning everything up front is wasted effort.**  
   Knowledge that isn’t immediately applied decays fast. Learn what the problem demands, when it demands it.

3. **Experience changes what you pay attention to.**  
   Senior developers don’t necessarily know more facts. They’re better at recognising which details matter right now, and which ones don’t.

> [!SIDENOTE]
> ### Interviews still often expect mastery
>
> Many hiring processes still reward Just-In-Case knowledge: whiteboard algorithms, trivia-style questions, and LeetCode exercises that test how much you can recall under pressure rather than how you work day to day. That pressure is real, and pretending otherwise would be dishonest.
>
> It’s worth separating passing interviews from being effective at the job. The former often incentivizes breadth without context. The latter rewards depth, judgment, and the ability to learn quickly when something new actually matters. If you’re studying for interviews, some Just-In-Case learning is unavoidable. Just don’t confuse that game with the thing it’s supposed to measure.

## Final thought

"Mastering a programming language" is a comforting idea, especially when you’re starting out. It’s also a lie that creates unnecessary pressure.

The goal isn’t mastery. The goal is usefulness.

Learn deeply where it matters. Learn quickly when you must. Ignore the rest without guilt. That’s not a shortcut.

That’s what experience actually looks like.