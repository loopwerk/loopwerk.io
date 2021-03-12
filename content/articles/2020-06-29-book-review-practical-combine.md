---
tags: review, iOS, swift, combine
review: Practical Combine
rating: 4.5
summary: It's almost exactly 10 years since I wrote my last book review. Time flies! Also, it makes me realize that the way I've been learning has changed dramatically. I am much more guided by autocomplete and documentation within Xcode, and in-depth articles and videos about one particular topic, instead of reading books.
---

# Book review: Practical Combine
**Practical Combine: an introduction to Combine with real examples**  
*Donny Wals*

*It's almost exactly 10 years since I wrote my [last book review](/articles/2010/book-review-beginning-iphone-3-development/), which made me realize that the way I've been learning has changed dramatically. I am much more guided by autocomplete and documentation within Xcode, and in-depth articles and videos about one particular topic or problem, instead of reading books that touch on more broad topics. When I wanted to adopt Apple's Combine framework a few months back (switching away from ReactiveKit and Bond), it wasn't too hard to get started. In my opinion [Apple's documentation](https://developer.apple.com/documentation/combine) is pretty weak for beginners: it's a fine API reference, but lacks a good introduction with solid examples. Luckily the community has stepped in with plenty of articles and videos showing you the first steps. Plus I already had some experience with reactive programming, so I wasn't starting from scratch - that really helped too.*

*But as I got further into my project I started to struggle a little bit with some more advanced concepts of Combine and I found that most of these articles and videos that were so helpful in the beginning only touched the surface, with extremely simple examples. I needed something much more in-depth, with larger examples that touch on real-world problems. The subtitle of the [Practical Combine](https://practicalcombine.com) book by Donny Wals is "an introduction to Combine with real examples", so that was very promising and as such I bought my first programming book in quite a long time.*

**Practical Combine** starts off with a gentle introduction to functional reactive programming: what it is, why you'd want to use it, what problems it solves. I really liked how it immediately showed a great example of non-reactive code (doing a network request) made both shorter *and* more readable by using Combine. The introduction chapter  also promises to compare Combine with RxSwift, but sadly it doesn't really do much more than mentioning one is open source and the other belongs to Apple. I would've expected some syntax comparison, handy for people already familiar with RxSwift to quickly understand the most important concepts. 

After the introduction come 11 chapters, going over publishers, subscribers, subjects, schedulers, operators, property wrappers, how to update your UI, how to respond to user input... it's a lot. It shows all the important built-in methods and operators, all with clear examples and marble diagrams. It also shows how to build a networking stack based on Combine, how to use Combine as your `UICollectionView` datasource, how to use Combine to ask for push permissions - all real world examples that you can use in your app right away.

The chapter that I keep going back to is the one about combining multiple user inputs into a single publisher, which explains the differences between `Publishers.Zip`, `Publishers.Merge`, and `Publishers.CombineLatest`. No matter how long I've been using Combine now, these are still not easy for me to understand. So maybe this chapter didn't help me that much since I keep having to check it - I do also think this part of the book uses the weakest examples of all the book.

In my opinion one of the best chapters is the one on testing, which also goes over how to best write your code to make it easily testable in the first place, and how to mock side effects like doing network requests or using `NoticationCenter`. Very valuable skills to have, and Donny does a good job teaching them. 

One problem I had with the EPUB version of the book (which I use with Apple Books) is that there is no syntax highlighting at all, which make the examples less than ideal to read. I guess this is a flaw in EPUB and not the book, but I would recommend to use the PDF version when you can.

Overall I think it's a great book, and well worth the $25. There are just so many real-world examples that make it so much easier to understand what's going on and *why* this is useful. Whenever I see code that deals with very abstract tiny toy examples, I often struggle to see the point: "I can do this without using this library". Donny clearly shows how your code gets shorter, more understandable, testable, and more powerful. Bravo!

*p.s. if you're already familiar with RxSwift, check out [this RxSwift to Combine cheatsheet](https://github.com/CombineCommunity/rxswift-to-combine-cheatsheet)*
