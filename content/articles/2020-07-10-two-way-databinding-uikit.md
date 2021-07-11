---
tags: swift, iOS, combine
summary: With SwiftUI we have the @Binding property wrapper that makes it really easy to create a two-way databinding between a form field and a model, but in the UIKit world it's slightly less easy. Let's explore some solutions.
---

# Exploring two-way databinding solutions in UIKit
It's quite common to have to build some kind of (reusable) component to edit some piece of state. For example, let's say we have a `User` model, and we want to build a form to edit a user. With SwiftUI we have the `@Binding` property wrapper that makes it really easy to create a two-way databinding between a form field and a model, but in the UIKit world it's slightly less easy.

You can image that we'd build a `UITableView` with a `UITableViewCell` for every field of the user that we want to edit. Every cell has a `UITextField`, which is instantiated with the current value of the field we want to edit. And when the value is changed, we of course want to update the field on the user model.

Let's start off with a version without two-way databinding to set a baseline. Simplified, it can look something like this:

``` swift
import UIKit

struct User {
  var firstName: String
  var lastName: String
}

class TextFieldCell {
  let textField = UITextField()

  init(value: String) {
    textField.text = value
  }
}

class MyViewController {
  var user = User(firstName: "Kevin", lastName: "Renskers")
  var nameTextField: TextFieldCell

  init() {
    nameTextField = TextFieldCell(value: user.firstName)
  }
}
```

We create a `TextFieldCell` for the user's `firstName` field and instantiate it with the current value of the first name ("Kevin"). There is no databinding going on at all; if you'd edit the text inside the `UITextField`, nothing happens to the actual user model, its name is forever stuck to be "Kevin".

We need to introduce a way to communicate changes back to the model. A simple way is to use a closure:

``` swift
class TextFieldCell {
  let textField = UITextField()
  private let onUpdate: (String) -> Void

  init(initialValue: String, onUpdate: @escaping (String) -> Void) {
    self.onUpdate = onUpdate
    textField.text = initialValue
    textField.addTarget(self, action: #selector(updated), for: .valueChanged)
  }

  @objc func updated() {
    onUpdate(textField.text ?? "")
  }
}

class MyViewController {
  var user = User(firstName: "Kevin", lastName: "Renskers")
  var nameTextField: TextFieldCell!

  init() {
    nameTextField = TextFieldCell(initialValue: user.firstName) { newName in
      self.user.firstName = newName
    }
  }
}

let vc = MyViewController()
print(vc.user.firstName) // prints "Kevin"

vc.nameTextField?.textField.text = "Bob"
vc.nameTextField?.updated()

print(vc.user.firstName) // prints "Bob" 🎉
```

*I'm calling the `updated` function by hand in the second to last line since programmatically changing the text value of a `UITextField` doesn't trigger the `valueChanged` action.*

We start off with a user called "Kevin", update the value to "Bob", and the user's `firstName` property now holds "Bob". It feels a bit iffy to have to pass in the `user.firstName` and also do the `user.firstName = newName` dance - it would be much nicer if this could be combined into one.

One improvement that we can make is to use KeyPaths.

``` swift
class TextFieldCell<Model> {
  let textField = UITextField()
  private let model: Model
  private let keyPath: ReferenceWritableKeyPath<Model, String>

  init(model: Model, keyPath: ReferenceWritableKeyPath<Model, String>) {
    self.model = model
    self.keyPath = keyPath
    textField.text = model[keyPath: keyPath]
    textField.addTarget(self, action: #selector(updated), for: .valueChanged)
  }

  @objc func updated() {
    model[keyPath: keyPath] = textField.text ?? ""
  }
}

class MyViewController {
  var user = User(firstName: "Kevin", lastName: "Renskers")
  var nameTextField: TextFieldCell<MyViewController>!

  init() {
    nameTextField = TextFieldCell(model: self, keyPath: \.user.firstName)
  }
}
```

Creating an instance of `TextFieldCell` is now a lot simpler, as you don't have to give an initial value and also an `onUpdate` closure. Instead we give a `ReferenceWritableKeyPath`. 

However, it can be slightly disorienting to work with this, due to the usage of `ReferenceWritableKeyPath`. For example since the `User` model is a struct (a value type), I need to pass in the view controller itself as the model, with the keyPath `\.user.firstName`.

Can we use SwiftUI's `Binding` inside UIKit? Yes we can, provided that we are building an iOS 13+ app of course.

``` swift
class TextFieldCell {
  let textField = UITextField()
  private let value: Binding<String>

  init(value: Binding<String>) {
    self.value = value
    textField.text = value.wrappedValue
    textField.addTarget(self, action: #selector(updated), for: .valueChanged)
  }

  @objc func updated() {
    value.wrappedValue = textField.text ?? ""
  }
}

class MyViewController {
  var user = User(firstName: "Kevin", lastName: "Renskers")
  var nameTextField: TextFieldCell!

  init() {
    nameTextField = TextFieldCell(value: 
      Binding(
        get: { self.user.firstName }, 
        set: { self.user.firstName = $0 }
      )
    )
  }
}
```

It solves the `ReferenceWritableKeyPath` weirdness, but now we're back to needing to give both a getter and a setter, so it's not an ideal solution either. It can be improved by also using `@State`, but at the cost of turning the `User` model into a class:

``` swift
class User {
  var firstName: String
  var lastName: String

  init(firstName: String, lastName: String) {
    self.firstName = firstName
    self.lastName = lastName
  }
}

class TextFieldCell {
  let textField = UITextField()
  private let value: Binding<String>

  init(value: Binding<String>) {
    self.value = value
    textField.text = value.wrappedValue
    textField.addTarget(self, action: #selector(updated), for: .valueChanged)
  }

  @objc func updated() {
    value.wrappedValue = textField.text ?? ""
  }
}

class MyViewController {
  @State var user = User(firstName: "Kevin", lastName: "Renskers")
  var nameTextField: TextFieldCell!

  init() {
    nameTextField = TextFieldCell(value: $user.firstName)
  }
}
```

How about we use Combine, with a `PassthroughSubject`, instead?

``` swift
class TextFieldCell {
  let textField = UITextField()
  private let subject: PassthroughSubject<String, Never>
  private var cancellable: AnyCancellable?

  init(subject: PassthroughSubject<String, Never>) {
    self.subject = subject
    textField.addTarget(self, action: #selector(updated), for: .valueChanged)

    cancellable = subject.sink {
      self.textField.text = $0
    }
  }

  @objc func updated() {
    subject.send(textField.text ?? "")
  }
}

class MyViewController {
  var user = User(firstName: "Kevin", lastName: "Renskers")
  var nameTextField: TextFieldCell!
  private var cancellable: AnyCancellable?

  init() {
    let subject = PassthroughSubject<String, Never>()
    subject.send(user.firstName)
    cancellable = subject.assign(to: \.user.firstName, on: self)
    nameTextField = TextFieldCell(subject: subject)
  }
}
```

It works, but at the cost of even more boilerplate. Definitely not an improvement!

And using `@Published` gets us back to needing to both initialize and then observe a value:

``` swift
class TextFieldCell {
  let textField = UITextField()
  @Published var value = ""

  init() {
    textField.addTarget(self, action: #selector(updated), for: .valueChanged)
  }

  @objc func updated() {
    value = textField.text ?? ""
  }
}

class MyViewController {
  var user = User(firstName: "Kevin", lastName: "Renskers")
  var nameTextField: TextFieldCell!
  private var cancellable: AnyCancellable?

  init() {
    nameTextField = TextFieldCell()

    nameTextField.value = user.firstName

    cancellable = nameTextField.$value.sink { [weak self] value in
      self?.user.firstName = value
    }
  }
}
```

So honestly at that point you might as well just use the closure method.

At the moment my solution of choice is the `ReferenceWritableKeyPath` when I have a class as the model (or a class ViewModel for example that holds a value type model). If that is not possible and it's an iOS 13+ app, then the `Binding` approach would work pretty well too. But it feels like there is no really nice ideal solution with the same ease of use as SwiftUI.
