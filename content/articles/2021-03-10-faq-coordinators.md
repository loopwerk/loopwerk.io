---
tags: faq, iOS, swift
---

# Mentee Question 5: What's the deal with coordinators?

A few weeks while ago in my [how to get started](/articles/2021/faq-getting-started/) article I mentioned coordinators in the “What architecture should I use?” section, and how they allow you to decouple your view controllers from one another, and improve the way you can test your code. Yesterday one of my mentees asked about the coordinator pattern: how to implement it, how to deal with various scenarios, and what the big deal is about decoupling view controllers.

## What does "decoupling" mean?
View controllers are "coupled" to each other when they know of each other's existence. Let's demonstrate with a very simple view controller which shows a table with four book titles.

```swift
struct Book {
  let title: String
}

class ListViewController: UIViewController {
  @IBOutlet private var tableView: UITableView!

  let books = [
    Book(title: "Thinking in SwiftUI"),
    Book(title: "Practical Combine"),
    Book(title: "Guide to Swift Codable"),
    Book(title: "Server Side Swift with Vapor"),
  ]
}

extension ListViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return books.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let book = books[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    cell.textLabel?.text = book.title
    return cell
  }
}
```

When you tap on one of the book rows, we want to open a detail view controller, for example like so:

```swift
extension ListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let detailViewController = DetailViewController()
    detailViewController.book = books[indexPath.row]
    navigationController?.pushViewController(detailViewController, animated: true)
  }
}
```

Or perhaps you're using a storyboard with segues:

```swift
extension ListViewController {
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let nextViewController = segue.destination as? DetailViewController,
       let row = tableView.indexPathForSelectedRow?.row {
      nextViewController.book = books[row]
    }
  }
}
```

Either way, the `ListViewController` now knows about, configures, and shows the `DetailViewController`. Decoupling is the process of eliminating these kinds of hard dependencies between view controllers.

## Why does this matter?
View controllers are a lot easier to reuse in different kinds of flows when they are unaware of how they are being used. It's also a lot easier to make changes to big flows when the various view controllers that make up a flow don't know where in that flow they are positioned. Consider this real-world example:

In an app I used to work on we had a long sign-up flow, where the user had to go through multiple steps before they were registered. Every step had a button to go to the next step, which would instantiate the next view controller and push it onto a `UINavigationViewController`. This made it quite annoying to change the order of the steps, because now every view controller had to be changed to instantiate a different "next" view controller, even though their own UI had not be changed at all.

Even worse: at some point one of these view controllers needed to be reused in a different place in the app. This meant that the view controller now had to know in which context it was being used, so it could instantiate the right view controller to go to next. It was now tightly coupled with even more view controllers!

Another example of coupling is when view controllers are not coupled to other view controllers, but to the *way they're being presented*. In the previous tiny example app we assume that the `DetailViewController` will always be pushed, but what if we want to *sometimes* show it modally? For example in another flow of the app, or on iPad. Now `DetailViewController` has to know if it's shown modally or not, so it can show a "close" button in the navigation bar for example.

Finally, when view controllers simply push other view controllers onto their navigation controller, it makes testing these flows really hard. Let's look back at the earlier code to open a detail view controller with a book:

```swift
extension ListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let detailViewController = DetailViewController()
    detailViewController.book = books[indexPath.row]
    navigationController?.pushViewController(detailViewController, animated: true)
  }
}
```

How would you write a unit test that makes sure that when a row is selected, that it goes to the correct view controller? You can't, because there is nothing to hook into - this code doesn't return anything, it doesn't call anything that we control, it's just one big UIKit side effect.

All of these things make our view controllers harder to reuse, refactor and test.

## So how do we solve this?
The Coordinator Pattern moves all navigation related logic to a different layer above the view controllers. The view controllers are no longer aware of each other or how they're being shown; all of this code is moved to a different object, the coordinator.

We'll start with the most basic form of a coordinator for our tiny example app.

```swift
protocol CoordinatorProtocol {
  func openDetail(book: Book)
}

struct Coordinator: CoordinatorProtocol {
  let navigationController: UINavigationController

  func openDetail(book: Book) {
    let detailViewController = DetailViewController()
    detailViewController.book = book
    navigationController.pushViewController(detailViewController, animated: true)
  }
}
```

And we'll use it in our `ListViewController`:

```swift
class ListViewController: UIViewController {
  //... other properties
  var coordinator: CoordinatorProtocol?
}

extension ListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    /*HLS*/coordinator?.openDetail(book: books[indexPath.row])/*HLE*/
  }
}
```

Just like that, the `ListViewController` no longer needs to know about the existence of the `DetailViewController`, it only needs to tell its coordinator that it wants to open the details for a book. And since you can give different instances of the `ListViewController` different instances of a `Coordinator`, you can have that `openDetail` function do different things for different flows. And it's easily testable as well, by passing in a mock coordinator that tests if you're calling `openDetail` with the expected book object.

Of course the coordinator as shown above is extremely simplistic, but it should hopefully illustrate the very basic concept of what coordinators are responsible for and how they can decouple view controllers. Simply said, every time you instantiate or configure a view controller within a different view controller, that's moved to the coordinator. Every time you would directly use a view controller's parent `navigationController`, or `present` from within a view controller, that's moved to the coordinator as well.

Think of a coordinator as a delegate that handles all flow related code.

## Doesn't this just couple view controllers to coordinators?
It depends on how you set up your coordinators. In my example above, the `ListViewController` would be tightly coupled to the `CoordinatorProtocol`, but not the actual `Coordinator` struct, so it's possible to pass in different versions of the coordinator for different flows, that do different things. A different way is to make the view controller completely unaware of the coordinator by using delegates or closures.

Let's look at an example that uses closures:

```swift
class ListViewController: UIViewController {
  /*HLS*/var openDetail: ((Book) -> Void)?/*HLE*/
}

extension ListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    /*HLS*/openDetail?(books[indexPath.row])/*HLE*/
  }
}

struct Coordinator {
  let navigationController: UINavigationController

  func showList() {
    let listViewController = ListViewController()
    /*HLS*/listViewController.openDetail = self.openDetail(book:)/*HLE*/
    navigationController.pushViewController(listViewController, animated: false)
  }

  func openDetail(book: Book) {
    let detailViewController = DetailViewController()
    detailViewController.book = book
    navigationController.pushViewController(detailViewController, animated: true)
  }
}
```

Now, `ListViewController` doesn't even know about the existence of a coordinator or a coordinator's protocol, it just knows there's a closure to call to open a detail screen. It's the job of the coordinator that instantiates the `ListViewController` to give it an implementation for that closure.

You can get the same effect using delegates, which is what most coordinator implementations use:

```swift
/*HLS*/protocol ListViewControllerDelegate/*HLE*/: AnyObject {
  func openDetail(book: Book)
}

class ListViewController: UIViewController {
  /*HLS*/weak var delegate: ListViewControllerDelegate?/*HLE*/
}

extension ListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    /*HLS*/delegate?.openDetail(book: books[indexPath.row])/*HLE*/
  }
}

class Coordinator {
  let navigationController: UINavigationController

  init(navigationController: UINavigationController) {
    self.navigationController = navigationController
  }

  func showList() {
    let listViewController = ListViewController()
    /*HLS*/listViewController.delegate = self/*HLE*/
    navigationController.pushViewController(listViewController, animated: false)
  }
}

extension Coordinator: /*HLS*/ListViewControllerDelegate/*HLE*/ {
  func openDetail(book: Book) {
    let detailViewController = DetailViewController()
    detailViewController.book = book
    navigationController.pushViewController(detailViewController, animated: true)
  }
}
```

## Side-note about segues in storyboards
The existence of segues between two view controllers in a storyboard by definition means that one view controller is tightly coupled to another, which is exactly the thing we want to avoid. It's fine to use storyboards (I use them, I really like them!), it's fine to have multiple view controllers in one storyboard, but don't use segues between them. If you want a button or a tableview cell to open another view controller, don't use a segue but instead go via the coordinator. So in the case of a button create an `@IBAction` function that calls the coordinator.

## Where to go from here?
I've only touched on the basic principles behind the coordinator pattern without giving a working implementation of a coordinator that you can just plug into your app. I've also not explained how to instantiate the main coordinator from the `AppDelegate` or `SceneDelegate`, the benefits of child coordinators and when to use those, and so much more.

If you want to read more about the why of coordinators, I would suggest Paul Hudson's [article on them](https://www.hackingwithswift.com/articles/71/how-to-use-the-coordinator-pattern-in-ios-apps) where he has you implement a coordinator from scratch. I wouldn't use his version of the coordinator object though, instead I would recommend [this open source coordinator](https://github.com/daveneff/Coordinator) which I've used in the past. It's a very basic "vanilla" implementation of the coordinator pattern that is very close to what you will find in most tutorials about coordinators, but with most edge-cases already taken care of.

Personally I am a fan of [XCoordinator](https://github.com/quickbirdstudios/XCoordinator), which uses the concept of pre-defined routes. It's quite different from how most coordinator patterns work though, so if you'd rather use a more bare-bones coordinator library that's more similar to what most tutorials have you build, XCoordinator is probably not the best choice.

I'd like to close this article by saying that the coordinator pattern is not a holy grail to strive for; if you're just getting started with iOS development, it's completely fine -recommended even- to simply use MVC, forget about coordinators, and just build stuff. At some point you'll probably run into real-world scenarios where you want to decouple your view controllers, and at that point you'll be better equipped to adopt coordinators. But if you're just getting started, I wouldn't worry about using the "perfect" architecture — it'll just slow you down and send you into analysis paralysis. Instead, focus on building apps with the tools you know, the rest will come later.
