---
tags: python, javascript, saga, insights
summary: I recently ported Saga from Swift to both Python and TypeScript, giving me a direct comparison of three type systems.
---

# Comparing three type systems: Python, TypeScript, and Swift

As a software developer I mainly work with three programming languages: Python, TypeScript, and Swift. When I am switching from one to the other it always takes a bit of time to get used to it again, same as when I am switching between Dutch and English.

I like all three of these languages, they all have their own pros and cons. But until recently I've never had the exact same project done in all three. That changed when I [ported Saga from Swift to Python and TypeScript](/articles/2025/saga-in-python-or-typescript/), finally giving me a direct comparison.

## Python

Python is fundamentally a dynamic language, with types kind of bolted on top of it. It took until Python 3.6 for them to become usable, and I never used them until Python 3.9, in 2021. I think types make Python a much better language for big projects, but it's still a rather weak type system, because Python itself completely ignores it. You need to install an external tool such as mypy, and use that to lint your code. There's no compiler telling you about errors, and if you don't run mypy, nothing will tell you about type errors until you run into them in production.

And then there's the syntax. Oh boy.

When I was porting Saga, Python's syntax quickly became a headache. Let's look at this real code, coming from Saga: a generic `Writer` that writes a list of items to one file.

```python
from typing import Callable

class Writer[M]:
    run: Callable[[list[Item[M]], str], None]
```

I'll be honest: I find this an absolute mess of square-braces soup that doesn't tell me much. What is that `str` that it accepts? The output path? An HTML body? I have no idea without digging into the implementation, because the type definition itself isn't self-documenting. And why do I have to import `Callable`?

Honestly, porting Saga to Python was painful. Its syntax made the code hard to read and reason about.

## TypeScript

Working on the TypeScript port was so much more enjoyable. I liked its type system and syntax much more, and the editor experience was fantastic.

Here's that same `Writer` from before, now in TypeScript:

```typescript
type Writer<M> = {
  run: (items: Item<M>[], outputPath: string) => void;
};
```

Much better, right? No imports needed. And that unknown string from before? It's now very clear what that string is for. It's self-documenting in a way that Python simply isn't.

Porting Saga to TypeScript was smooth and easy, and writing the type definitions felt natural to me in a way that Python simply didn't. I never had to look up the syntax for example. On top of that you have the compiler that immediately tells you when you're making a mistake, no need to reach for external tools.

However, types completely disappear at runtime, which turned out to be a dealbreaker for me. Saga parses Markdown documents which contain frontmatter. It needs to validate that this data conforms to a specific `Metadata` type. Sadly, that's not possible with TypeScript's types alone. Instead, you're forced to use a library like Zod, where you define a schema which is used by a validator. To me, this feels wrong. When I've already provided the strongly typed `Metadata`, I don't want to also have to provide a separate validation schema. I can't ask that of Saga users.

## Swift

Back to where I started, with Swift. The type checker and the compiler are the same thing, and types are usable at runtime.

The same `Writer`, in its original Swift form:

```swift
struct Writer<M> {
  let run: (_ items: [Item<M>], _ path: String) throws -> Void
}
```

It's very similar to the TypeScript version, with the same benefits, but even more expressive: it even tells you the function can throw an error.

And because Swift's types are usable at runtime, you can use them to validate data against them. With Swift's `Codable`, decoding JSON is type-safe out of the box, without any other tools necessary. Trying to parse invalid data throws an error you can handle, which I heavily rely on in Saga.

Swift is quite a complex language though, and it seems to be getting more and more complex as time goes on, but the compiler helps a lot.

## Final thoughts

Porting Saga from Swift to Python and then to TypeScript made it very easy to compare these three type systems, and allowed me to come to some conclusions that were only hunches until then.

Python's types are a huge improvement over no types at all. But for a complex, generics-heavy project such as Saga, I hated its syntax. I really wouldn't want to maintain a Python port of Saga, because I simply wouldn't enjoy my time with it.

TypeScript was a joy to work with. Its type system just feels natural to me. Sadly the lack of type info at runtime was a dealbreaker, because I wouldn't want Saga to not be fully type-safe from top to bottom, which includes the frontmatter in Markdown files. Yes, there's Zod, but when everything is already strongly typed, I really don't want to force Saga users to use such a library.

Joy-wise, Swift sits in the middle for me. I do think it's too complex, and it has its own issues which contributed to me [leaving native app development behind](/articles/2025/thoughts-on-apple/), but for a big project like Saga it's the right choice. It might not be as enjoyable as TypeScript, but it handles the complexity and types well.

So, in the end I came full circle, but more convinced than ever that Swift is the right choice for Saga. If TypeScript's types were usable at runtime though... I'd switch in a heartbeat.