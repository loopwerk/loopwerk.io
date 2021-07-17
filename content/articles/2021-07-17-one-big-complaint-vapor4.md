---
tags: backend, review, swift
summary: I'm trying out Vapor 4 for a side project, and one thing that I am constantly running into is the amount of boilerplate and copy-pasted code. Are there no better solutions for this?
---

# My one big complaint working with Vapor 4

I'm trying out Vapor 4 for a side project, and one thing that I am constantly running into is the amount of boilerplate and copy-pasted code. Are there no better solutions for this?

For example, I have a simple User model.

```swift
final class User: Model, Content {
  struct FieldKeys {
    static var avatar: FieldKey { "avatar" }
    static var avatarCrop: FieldKey { "avatar_crop" }
    static var appleToken: FieldKey { "appleToken" }
    static var email: FieldKey { "email" }
    static var name: FieldKey { "name" }
    static var subscribedUntil: FieldKey { "subscribed_until" }
    static var createdAt: FieldKey { "created_at" }
    static var updatedAt: FieldKey { "updated_at" }
  }

  static let schema = "users"

  @ID(key: .id)
  var id: UUID?

  @OptionalField(key: FieldKeys.avatar)
  var avatar: String?

  @OptionalField(key: FieldKeys.avatarCrop)
  var avatarCrop: String?

  @Field(key: FieldKeys.name)
  var name: String

  @OptionalField(key: FieldKeys.email)
  var email: String?

  @OptionalField(key: FieldKeys.appleToken)
  var appleToken: String?

  @OptionalField(key: FieldKeys.subscribedUntil)
  var subscribedUntil: Date?

  @Timestamp(key: FieldKeys.createdAt, on: .create)
  var createdAt: Date?

  @Timestamp(key: FieldKeys.updatedAt, on: .update)
  var updatedAt: Date?

  init() { }

  init(id: UUID? = nil, name: String, email: String? = nil, appleToken: String? = nil) {
    self.id = id
    self.name = name
    self.email = email
    self.appleToken = appleToken
  }
}
```

Of course's we're also going to need a database migration to actually create the table.

```swift
struct CreateUserMigration: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    database.schema(User.schema)
      .id()
      .field(User.FieldKeys.avatar, .string)
      .field(User.FieldKeys.avatarCrop, .string)
      .field(User.FieldKeys.name, .string, .required)
      .field(User.FieldKeys.email, .string)
      .field(User.FieldKeys.appleToken, .string)
      .field(User.FieldKeys.subscribedUntil, .datetime)
      .field(User.FieldKeys.createdAt, .datetime, .required)
      .field(User.FieldKeys.updatedAt, .datetime)
      .unique(on: User.FieldKeys.email)
      .unique(on: User.FieldKeys.appleToken)
      .create()
  }

  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema(User.schema).delete()
  }
}
```

Already there is so much copied code, every single property that is added to the User model has to be copied to the migration, and to prevent stringly-typed field names, to the `User.FieldKeys` struct as well. And that's not all the boilerplate either; for every property you have to choose the correct field type, even though it's part of the actual property signature. For example, `email` needs to be an `@OptionalField` even though it's already an optional string. And in the migration you also need to repeat its type and if it's required or not. Now, I get why it's necessary in the migration since field types can change over time so you can't rely on the current version of the properties, but when setting up a new model and its migration it's just a whole lot of boilerplate. How I wish there was automated migration handling like with Django!

Finally, and perhaps even worse, is the need for "Data Transfer Objects", or DTOs. We need this when we want to return a different version of a model, for example I don't want to expose the user's `appleToken` to the API. So I need to create a different version of the model, like this:

```swift
struct PublicUser: Content {
  let id: UUID
  let avatar: String?
  let avatarCrop: String?
  let name: String
  let email: String?
  let subscribedUntil: Date?
  let createdAt: Date?
  let updatedAt: Date?

  init(from: User) throws {
    try self.id = from.requireID()
    self.avatar = from.avatar
    self.avatarCrop = from.avatarCrop
    self.name = from.name
    self.email = from.email
    self.subscribedUntil = from.subscribedUntil
    self.createdAt = from.createdAt
    self.updatedAt = from.updatedAt
  }
}
```

The amount of work that's needed to create public versions of my models is getting out of hand, and it's too easy to forget to update them when you're changing the main model. If I'm adding a new property to the `User` model that I want to make available in the public version, I have to add it there too, and add it to the initializer.

Then there are usually different DTOs for when you want to create or update a model. For example when I have a `Book` model with an `owner` field, I want to automatically set that to the logged-in user creating the book object. But that means I need to create a DTO without the `owner` property, or the decoder will fail with an error since `owner` is required but not given in the request payload.
	
Don't get me wrong, Vapor is a really cool framework especially when you're using its async/await branch, but it kinda feels like 50% of the time I spend with it is spent on copy-and-pasting properties 😩 So here's my question to you, the reader: how do you deal with all this? How do you make certain properties of a model hidden to the outside world for example?