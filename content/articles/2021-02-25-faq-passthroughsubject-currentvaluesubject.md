---
tags: combine, faq, iOS, swift
---

# Mentee Question 4: When to use PassthroughSubject and CurrentValueSubject?

That's a great question! And actually one I asked myself too, when I just got started with Combine. Let's first explain what `PassthroughSubject` and `CurrentValueSubject` *are* though.

Subjects are a kind of publisher that you can subscribe to, but can also send values to. It's kind of like a serving hatch where you pass items through, from one side to the other. It's mostly used to turn imperative code that uses closures and delegates, into declarative and reactive code using publishers.

Consider this simple example, where we have a `SomeBookSDK` that has a `fetchBooks` method that returns an array of books via a callback closure. If you'd want to expose those books as a publisher that you can subscribe to, you can use `PassthroughSubject`:

```swift
struct ViewModel {
  let books = /*HLS*/PassthroughSubject<[Book], Never>()/*HLE*/

  func fetchBooks() {
    SomeBookSDK.fetchBooks { fetchedBooks in
      /*HLS You can send values to PassthroughSubject*/self.books.send(fetchedBooks)/*HLE*/
    }
  }
}

class ViewController: UIViewController {
  let viewModel = ViewModel()
  let subscriptions = Set<AnyCancellebles>()

  override func viewDidLoad() {
    viewModel.fetchBooks()
  
    viewModel.books
      .sink { books in
        print("Books got updated!")
      }
      .store(in: &subscriptions)
  }
  
  @IBAction func reloadBooks() {
    viewModel.fetchBooks()
  }
}
```

Why would you want to have a publisher you can subscribe to, instead of just using that `SomeBookSDK` `.fetchBooks` callback closure in your ViewController? Well, if you're already using Combine then you know that publishers are extremely powerful, can be combined with other publishers, and can be transformed in lots of ways. Maybe you want to do something when fetching books and fetching movies [are both completed](/articles/2021/faq-promise-all-combine/).

Let's look at another example. When you're dealing with a library or framework that uses the delegate pattern, using a `PassthroughSubject` makes it very easy to wrap all that logic into a publisher:

```swift
struct ViewModel {
  let books = PassthroughSubject<[Book], Never>()
  let bookSDK = SomeBookSDK()
  
  init() {
    bookSDK.delegate = self
  }

  func fetchBooks() {
    bookSDK.fetchBooks()
  }
}

extension ViewModel: SomeBookSDKDelegate {
  func fetchedBooks(books: [Book]) {
    self.books.send(books)
  }
}
```

Now you can simply subscribe to the `books` publisher without worrying about delegate callbacks at all. In the end, no matter how you get data from a library, framework, SDK, network manager or whatever, you can turn everything into a publisher and have a consistent way of working with asynchronous streams of values.

`CurrentValueSubject` is very similar to `PassthroughSubject` with one big difference: it's stateful, meaning you can read the current value. This can come in very handy, for example when dealing with `UITableViewDataSource`. In the example below we're subscribing to the `CurrentValueSubject`, and when it emits a new array of books, we reload the tableview. In the `UITableViewDataSource` methods, we need to know what the current array of books is, which we can now easily access:

```swift
struct ViewModel {
  let books = /*HLS*/CurrentValueSubject<[Book], Never>([])/*HLE*/
  // You need to give CurrentValueSubject an initial value,
  // here I'm simply using an empty array. 

  func fetchBooks() {
    SomeBookSDK.fetchBooks { books in
      books.value = books
    }
  }
}

class ViewController: UIViewController {
  @IBOutlet var tableView: UITableView!
  let viewModel = ViewModel()
  let subscriptions = Set<AnyCancellebles>()

  override func viewDidLoad() {
    tableView.dataSource = self
    
    // Whenever books changes, we reload the table
    viewModel.books
      .sink { [tableView] books in
        tableView?.reloadData()
      }
      .store(in: &subscriptions)
  }
}

extension ViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return /*HLS*/viewModel.books.value.count/*HLE*/
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let book = /*HLS*/viewModel.books.value[indexPath.row]/*HLE*/
    let cell = tableView.dequeueReusableCell(withIdentifier: "BookCell") as! BookCell
    cell.configure(with: book)
    return cell
  }
}
```

This wouldn't be possible with `PassthroughSubject`, where you don't have access to the "current value" of the publisher.

I hope these examples helped!
