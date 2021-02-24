---
tags: FAQ, iOS
summary: In JavaScript-world, it's really easy to know when multiple promises completed: just use Promise.all. How do you do the same thing in Combine?
---

# Mentee Question 3: How to know when multiple publishers completed?
In JavaScript-world, it's really easy to know when multiple promises completed: just use `Promise.all`. How do you do the same thing in Combine?

The easiest way, when dealing with an array of publishers, is a combination of `MergeMany` and `collect`:

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

If the order is important, you can not rely on `collect`, instead you'll have to use `combineLatest`.

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

Here `$0` is the tuple `(1, 2)`, even though `two` completed before `one`. Sadly `combineLatest` doesn't scale well when you have more than two publishers:

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

A bigger problem is that this doesn't work if you have an array of publishers. So, how would you know when an array of publishers are all complete, and get the results in the same order? The answer is CombineExt's [CombineLatestMany function](https://github.com/CombineCommunity/CombineExt#CombineLatestMany).

```swift
import CombineExt
import Combine

let one = PassthroughSubject<Int, Never>()
let two = PassthroughSubject<Int, Never>()
let three = PassthroughSubject<Int, Never>()
let four = PassthroughSubject<Int, Never>()

[one, two, three, four]
  .combineLatest()
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

Now `$0` is a simple array `[1, 2, 3, 4]`, all in the order you expect.