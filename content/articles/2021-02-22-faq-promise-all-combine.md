---
tags: combine, faq, iOS, swift
summary: In JavaScript-world, it's really easy to know when multiple promises completed: just use Promise.all. How do you do the same thing in Combine?
---

# Mentee Question 3: How to know when multiple publishers completed?
In JavaScript-world, it's really easy to know when multiple promises completed: just use `Promise.all`. How do you do the same thing in Combine?

One easy built-in way is a combination of `MergeMany` and `collect`:

```swift
import Combine

let one = PassthroughSubject<Int, Never>()
let two = PassthroughSubject<Int, Never>()

Publishers.MergeMany([one, two])
  .collect()
  .sink {
    print("All done!")
    print($0)
  }

one.send(1)
one.send(completion: .finished)

two.send(2)
two.send(completion: .finished)
```

This will print out `All done!` only when both publishers are completed, and `$0` is the array `[1, 2]`. Please note that the order of that results array (`$0`) is the order in which the publishers received their value, not the order of the publishers array itself.

If the order is important, you cannot rely on `collect`, instead you'll have to use `combineLatest`, which cannot be used on an array of publishers:

```swift
one
  .combineLatest(two)
  .sink {
    print("All done!")
    print($0)
  }

two.send(2)
two.send(completion: .finished)

one.send(1)
one.send(completion: .finished)
```

Here `$0` is the tuple `(1, 2)`, even though `two` completed before `one`. Sounds good, right? Sadly `combineLatest` doesn't scale very well when you have more than two publishers:

```swift
let one = PassthroughSubject<Int, Never>()
let two = PassthroughSubject<Int, Never>()
let three = PassthroughSubject<Int, Never>()
let four = PassthroughSubject<Int, Never>()

one
  .combineLatest(two)
  .combineLatest(three)
  .combineLatest(four)
  .sink {
    print("All done!")
    print($0)
  }

two.send(2)
two.send(completion: .finished)

one.send(1)
one.send(completion: .finished)

four.send(4)
four.send(completion: .finished)

three.send(3)
three.send(completion: .finished)
```

Now `$0` is the deeply nested tuple `(((1, 2), 3), 4)`. 

A much bigger problem with `combineLatest` is that it doesn't work if you have an array of publishers, which is not uncommon. So, how would you know when an array of publishers are all complete, and also get the results in the same order? The answer is CombineExt's [combineLatest function](https://github.com/CombineCommunity/CombineExt#CombineLatestMany), which *does* work on an array of publishers.

```swift
/*HLS*/import CombineExt/*HLE*/
import Combine

let one = PassthroughSubject<Int, Never>()
let two = PassthroughSubject<Int, Never>()
let three = PassthroughSubject<Int, Never>()
let four = PassthroughSubject<Int, Never>()

[one, two, three, four]
  /*HLS*/.combineLatest()/*HLE*/
  .sink {
    print("All done!")
    print($0)
  }

two.send(2)
two.send(completion: .finished)

one.send(1)
one.send(completion: .finished)

four.send(4)
four.send(completion: .finished)

three.send(3)
three.send(completion: .finished)
```

Now `$0` is the simple array `[1, 2, 3, 4]`, all in the order you expect.

So that's the final answer. The easiest way to know when multiple publishers are all completed is by using a third party dependency. It works with an array of any number of publishers, and you get a simple array of results back that is also in the order of the publishers.
