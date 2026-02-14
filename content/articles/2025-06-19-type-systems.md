---
tags: python, swift, javascript, saga, insights
summary: I recently ported Saga from Swift to both Python and TypeScript. It was a fascinating exercise in cognitive dissonance, especially when it came to their type systems.
---

# A tale of three type systems: Python, TypeScript, and Swift

For the longest time I've been juggling three languages: Python for backends and scripting, TypeScript for web frontends, and Swift for native app development and of course my [static site generator, Saga](https://github.com/loopwerk/Saga). Hopping between them is always an exercise in cognitive dissonance, but this was put into sharp relief recently when I decided to try and [port Saga from Swift to both Python and TypeScript](/articles/2025/saga-in-python-or-typescript/).

What started as an experiment quickly became a perfect case study. It forced me to implement the same complex, generic-heavy logic in three different ecosystems. I learned very viscerally that while they all claim to offer "types," what that means for my day-to-day experience - my productivity, my confidence, my frustration - couldn't be more different.

This isn't a post about which is "best." This is the story of that port, and a tale of three type systems.

## Python's type hints: the headache

Python's type system feels like a well-intentioned friend who offers advice but won't stop you from making a mistake. It's "gradual typing," a layer added on top of a fundamentally dynamic language. The key thing to understand is that **type hints do nothing at runtime.** Python's interpreter completely ignores them; they are metadata, pure and simple.

The safety net is an external tool like `mypy` or `Pylance`, and this is where the DX cracks start to show. The feedback loop feels less like a conversation with a compiler and more like getting notes from two different editors.

### And then there's the syntax…

This "bolted-on" nature shows most clearly in its syntax. When porting Saga, which is full of generic types, this quickly became a headache. Let's say we want to define a generic `Writer` that can write a list of items to a file—a real-world example from Saga's architecture.

Here's how you do it in Python:

```python
from typing import Generic, TypeVar, Callable, List

M = TypeVar("M")

class Writer(Generic[M]):
    run: Callable[[List[Item[M]], str], None]
```

Let's be honest: this is a mess.

1.  **Inheriting from `Generic[M]`:** To make a class generic, you have to _inherit_ from a special `Generic` type. It feels like an implementation detail leaking into my class definition.
2.  **`Callable` is a mouthful:** To define a function signature, you import `Callable` and use a syntax that is both verbose and uninformative.
3.  **Where are the parameter names?** This is the biggest failure. Look at `Callable[[List[Item[M]], str], None]`. What is that `str`? The output path? A header? I have no idea without finding the implementation. The type definition fails to document itself.

Working with this on the Python port of Saga was genuinely painful. The complexity of the generics, combined with this clumsy syntax, made the code hard to read and reason about. It was a constant uphill battle.

## TypeScript: the enjoyable dealbreaker

The TypeScript version, on the other hand, was the most enjoyable to work on. Its type system is incredibly rich, and the developer experience during development is, frankly, fantastic.

Let's look at the same `Writer` type in TypeScript:

```typescript
type Writer<M> = {
  run: (items: Item<M>[], outputPath: string) => void;
};
```

The difference is night and day. The generic declaration `<M>` is concise. The killer feature is the function signature: `(items: Item<M>[], outputPath: string)`. The parameter name, `outputPath`, is part of the type. It's self-documenting in a way the Python version fundamentally isn't.

The entire porting process felt smooth and fast. The editor integration is a dream, and crafting the types was a pleasure. But TypeScript performs a magic trick, and it's one that turned out to be a dealbreaker for me. When it compiles down to JavaScript, **all the types disappear.**

### Runtime? What types?

This is TypeScript's biggest limitation: you can't use its types at runtime. For Saga, I need to parse frontmatter from Markdown files—unstructured data from the outside world. I need to _validate_ that this data conforms to a specific `Metadata` type. You can't do that with TypeScript's types alone.

The community solves this with libraries like Zod, where you define a schema that can both generate a static type and act as a runtime validator. But it's a workaround. For Saga, this lack of built-in runtime safety was a dealbreaker. The delightful development experience didn't matter when the final product lacked the robustness I needed.

## Swift: the complex powerhouse

This brings me back to where it all started: Swift. If Python's types are a suggestion and TypeScript's are a compile-time illusion, Swift's are an undeniable, runtime-enforced reality. The type checker and compiler are one and the same.

Let's see the `Writer` in Swift:

```swift
struct Writer<M> {
  let run: (_ items: [Item<M>], _ path: String) throws -> Void
}
```

This is as clean as TypeScript, but more robust. The `throws` keyword is part of the function's type, telling you this operation can fail—critical information Python's `Callable` also hides.

And because Swift's types are real at runtime, you can inspect, check, and cast them. With Swift's `Codable`, JSON or YAML decoding is type-safe out of the box; invalid data throws an error you can handle. This is the runtime safety I was so desperately missing from TypeScript.

Saga's Swift code is also complex, but it's a manageable complexity. The compiler is a true partner. It holds your hand, guides you through refactoring, and guarantees that if it compiles, it's type-safe. The Python version was a headache of ambiguity; the Swift version, while challenging, is a puzzle with a guaranteed solution.

## Final thoughts from the trenches

The experience of porting Saga crystallized everything for me.

- **Python**'s gradual typing is great for scripts, but for a complex, generic-heavy project, its clumsy syntax and lack of context created a development headache I couldn't ignore.

- **TypeScript** offered a world-class development experience that was genuinely enjoyable. But its compile-time/runtime divide was a dealbreaker. The beautiful types are an illusion that can't protect you from the messy reality of external data.

- **Swift** gives you robust safety. It's complex, for sure, and has its own issues that have led me to [leave native app development behind](/articles/2025/thoughts-on-apple/). But for a project like Saga, that complexity is made manageable by a compiler that works _with_ you. It's harder, but you're building on solid ground.

In the end, I came full circle. The experiment confirmed that, for this specific project, the original choice was the right one. The trade-offs that Swift makes - prioritizing runtime safety and compiler guarantees over simplicity - were the ones that mattered most.
