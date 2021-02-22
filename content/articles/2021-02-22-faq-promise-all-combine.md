---
tags: FAQ, iOS
summary: In JavaScript-world, it's really easy to know when multiple promises completed: just use Promise.all. How do you do the same thing in Combine?
---

# Mentee Question 3: How to know when multiple publishers completed?
In JavaScript-world, it's really easy to know when multiple promises completed: just use `Promise.all`. How do you do the same thing in Combine?

The easiest way is a combination of `MergeMany` and `collect`:

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

This will print out `All done!` only when both publishers are completed, and `$0` is the array `[1, 2]`.