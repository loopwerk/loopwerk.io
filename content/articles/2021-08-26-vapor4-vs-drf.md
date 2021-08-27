---
tags: review, backend, swift, django
summary: Over two years ago I wrote an article where I compared Vapor 3 to Django REST Framework. It's time for a rematch with Vapor 4.
---

# Vapor 4 vs. Django REST Framework

Over two years ago I wrote [an article](/articles/2019/vapor-vs-drf/) where I compared Vapor 3 to Django REST Framework. Back then I was building a REST API for a [side project](https://www.critical-notes.com) using Vapor 3, got stuck with some problems and decided to try to build the same system using DRF, and to compare the two. At the end of the article I came to the conclusion that there wasn't a clear winner; both had their pros and cons. So which one did I end up choosing?

Neither.

Nope, [I went with Firebase's Firestore instead](/articles/2020/firestore/), because it offered real time synching without having to implement my own solution with WebSockets. My side project has been doing pretty good for the past two years running on Firebase, but I want to move away from it. Their JavaScript SDK is huge and doesn't really work well with SvelteKit and server side rendering, which is something I really want to use to improve the initial page load, which is currently pretty bad. There are too many spinners and other loading indicators involved in different parts of the UI, because all the content has to be fetched asynchronously in the browser. Having the entire page served ready-to-go from the server right away (using server side rendering) would be a massive improvement. The privacy implications of ditching Firebase are also a good motivator.

So, I'm back to that old question: do I use Vapor (which has now reached version 4 and has an async-await branch for Swift 5.5) or Django REST Framework?

This time I've written the code for only one the features of my project, first in Vapor and then in DRF. Let's look at this feature: the models, model migrations and the view code (router logic and the controller) for managing D&D campaigns. Campaigns have members, and each member can have a role (player or DM), so we're dealing with a many-to-many relationship that needs to store an extra field.

# Models

## Django

``` python
class User(models.Model):
    name = models.CharField(max_length=50)
    email = models.EmailField(blank=True, null=True, unique=True)
    avatar = models.URLField(blank=True, null=True)
    avatar_crop = models.URLField(blank=True, null=True)
    subscribed_until = models.DateTimeField(blank=True, null=True, default=None)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

class Campaign(models.Model):
    name = models.CharField(max_length=50)
    description = models.TextField(blank=True)
    backgroundImage = models.CharField(max_length=255)
    is_private = models.BooleanField(default=True, db_index=True)
    is_featured = models.BooleanField(default=False, db_index=True)
    owner = models.ForeignKey(User, related_name='owned_campaigns', on_delete=models.CASCADE)
    members = models.ManyToManyField(User, related_name='campaigns', through='Membership')
    calendar = models.CharField(max_length=50)
    starting_year = models.IntegerField()
    months = models.JSONField()
    invite_code = models.CharField(max_length=50, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

class Membership(models.Model):
    campaign = models.ForeignKey(Campaign, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    is_dm = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
```

## Vapor

``` swift
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

  @Siblings(through: Member.self, from: \.$user, to: \.$campaign)
  public var campaigns: [Campaign]

  @Timestamp(key: FieldKeys.createdAt, on: .create)
  var createdAt: Date?

  @Timestamp(key: FieldKeys.updatedAt, on: .update)
  var updatedAt: Date?
}

final class Campaign: Model, Content {
  struct FieldKeys {
    static var name: FieldKey { "name" }
    static var description: FieldKey { "description" }
    static var backgroundImage: FieldKey { "background_image" }
    static var isPrivate: FieldKey { "is_private" }
    static var isFeatured: FieldKey { "is_featured" }
    static var owner: FieldKey { "owner_id" }
    static var calendar: FieldKey { "calendar" }
    static var startingYear: FieldKey { "starting_year" }
    static var months: FieldKey { "months" }
    static var inviteCode: FieldKey { "invite_code" }
    static var createdAt: FieldKey { "created_at" }
    static var updatedAt: FieldKey { "updated_at" }
  }

  static let schema = "campaigns"

  @ID(key: .id)
  var id: UUID?

  @Field(key: FieldKeys.name)
  var name: String

  @OptionalField(key: FieldKeys.description)
  var description: String?

  @Field(key: FieldKeys.backgroundImage)
  var backgroundImage: String

  @Field(key: FieldKeys.isPrivate)
  var isPrivate: Bool

  @Field(key: FieldKeys.isFeatured)
  var isFeatured: Bool

  @Parent(key: FieldKeys.owner)
  var owner: User

  @Field(key: FieldKeys.calendar)
  var calendar: String

  @Field(key: FieldKeys.startingYear)
  var startingYear: Int

  @Field(key: FieldKeys.months)
  var months: [Month]

  @Field(key: FieldKeys.inviteCode)
  var inviteCode: String

  @Timestamp(key: FieldKeys.createdAt, on: .create)
  var createdAt: Date?

  @Timestamp(key: FieldKeys.updatedAt, on: .update)
  var updatedAt: Date?

  @Siblings(through: Member.self, from: \.$campaign, to: \.$user)
  public var users: [User]

  @Children(for: \.$campaign)
  var members: [Member]
}

final class Member: Model {
  struct FieldKeys {
    static var campaign: FieldKey { "campaign_id" }
    static var user: FieldKey { "user_id" }
    static var isDm: FieldKey { "is_dm" }
    static var createdAt: FieldKey { "created_at" }
    static var updatedAt: FieldKey { "updated_at" }
  }

  static let schema = "members"

  @ID(key: .id)
  var id: UUID?

  @Parent(key: FieldKeys.campaign)
  var campaign: Campaign

  @Parent(key: FieldKeys.user)
  var user: User

  @Field(key: FieldKeys.isDm)
  var isDm: Bool

  @Timestamp(key: FieldKeys.createdAt, on: .create)
  var createdAt: Date?

  @Timestamp(key: FieldKeys.updatedAt, on: .update)
  var updatedAt: Date?

  init() { }
}
```

Winner: a big win for Django. Not only because there is a lot less repeating of strings and field names, but also because we get to specify things like `db_index`, `unique`, and `auto_now_add` directly in the fields. With Vapor that is done in the migrations, which brings us to..

# Migrations

## Django
It's all done automatically. When you create or change your models, you run `manage.py makemigrations` to create the migration definitions, and then run `manage.py migrate` to apply them to the database. It couldn't be more simple. It's one of the best features of Django.

## Vapor
Sadly, a *lot* of work is involved.

``` swift
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
    database.schema(User.schema)
      .delete()
  }
}

struct CreateCampaignMigration: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    database.schema(Campaign.schema)
      .id()
      .field(Campaign.FieldKeys.name, .string, .required)
      .field(Campaign.FieldKeys.description, .string)
      .field(Campaign.FieldKeys.backgroundImage, .string, .required)
      .field(Campaign.FieldKeys.isPrivate, .bool, .required)
      .field(Campaign.FieldKeys.owner, .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
      .field(Campaign.FieldKeys.calendar, .string, .required)
      .field(Campaign.FieldKeys.startingYear, .int, .required)
      .field(Campaign.FieldKeys.months, .array(of: .dictionary), .required)
      .field(Campaign.FieldKeys.inviteCode, .string, .required)
      .field(Campaign.FieldKeys.createdAt, .datetime, .required)
      .field(Campaign.FieldKeys.updatedAt, .datetime)
      .unique(on: Campaign.FieldKeys.inviteCode)
      .create()
  }

  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema(Campaign.schema)
      .delete()
  }
}

struct AddIsFeaturedMigration: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    database.schema(Campaign.schema)
      .field(Campaign.FieldKeys.isFeatured, .bool, .required, .sql(.default(false)))
      .update()
  }

  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema(Campaign.schema)
      .deleteField(Campaign.FieldKeys.isFeatured)
      .update()
  }
}

struct AddIsFeaturedIndexToCampaign: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    let sqlDB = (database as! SQLDatabase)
    
    return sqlDB
      .create(index: "is_featured_idx")
      .on(Campaign.schema)
      .column("is_featured")
      .run()
  }

  func revert(on database: Database) -> EventLoopFuture<Void> {
    let sqlDB = (database as! SQLDatabase)
    return sqlDB
      .drop(index: "is_featured_idx")
      .run()
  }
}

struct AddIsPrivateIndexToCampaign: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    let sqlDB = (database as! SQLDatabase)

    return sqlDB
      .create(index: "is_private_idx")
      .on(Campaign.schema)
      .column("is_private")
      .run()
  }

  func revert(on database: Database) -> EventLoopFuture<Void> {
    let sqlDB = (database as! SQLDatabase)
    return sqlDB
      .drop(index: "is_private_idx")
      .run()
  }
}

struct CreateMemberMigration: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    database.schema(Member.schema)
      .id()
      .field(Member.FieldKeys.campaign, .uuid, .required, .references("campaigns", "id", onDelete: .cascade))
      .field(Member.FieldKeys.user, .uuid, .required, .references("users", "id", onDelete: .cascade))
      .field(Member.FieldKeys.isDm, .bool, .required)
      .field(Member.FieldKeys.createdAt, .datetime, .required)
      .field(Member.FieldKeys.updatedAt, .datetime)
      .unique(on: Member.FieldKeys.campaign, Member.FieldKeys.user)
      .create()
  }

  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema(Member.schema)
      .delete()
  }
}
```

That is an example of only three database tables: `users`, `campaigns` and `members`, plus I added the `isFeatured` and `isPrivate` fields to the `campaigns` table as a new migration. All that code is written by hand, and it's a drag. The repetition of writing models and their migrations is demotivating.

Winner: Django, with a HUGE margin.

# Views
Let's take a look at 3 endpoints: `GET /campaigns`, `POST /campaigns` and `GET /campaigns/[id]`. One thing to note is that the public representation of a campaign (the response of these endpoints) is not the same as the actual Campaign database model. There are some fields that we don't want to include, for example the `is_featured` field, or for the owner and the members we definitely don't want to include all user model fields: the email address for example is private. So how do both frameworks make this possible?

## Django
``` python
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'name', 'avatar', 'avatar_crop', 'subscribed_until']

class MembershipSerializer(serializers.ModelSerializer):
    user = UserSerializer()

    class Meta:
        model = Membership
        fields = ['is_dm', 'user']

class CampaignSerializer(serializers.ModelSerializer):
    owner = UserSerializer()
    members = MembershipSerializer(many=True, read_only=True, source='membership_set')

    class Meta:
        model = Campaign
        exclude = ['is_featured', 'calendar']

class CreateCampaignPayload(serializers.ModelSerializer):
    calendar_id = serializers.IntegerField(read_only=True)

    class Meta:
        model = Campaign
        exclude = ['owner', 'members', 'months', 'invite_code', 'calendar']

class CampaignsController(viewsets.ModelViewSet):
    permission_classes = (_CampaignPermission,)

    def get_queryset(self):
        if self.kwargs.get('pk'):
            return Campaign.objects.all()\
                .select_related('owner') \
                .prefetch_related(
                    Prefetch('membership_set', queryset=Membership.objects.all().select_related('user'))
                )

        return self.request.user\
            .campaigns\
            .select_related('owner') \
            .prefetch_related(
                Prefetch('membership_set', queryset=Membership.objects.all().select_related('user'))
            )

    def list(self, request, *args, **kwargs):
        self.serializer_class = CampaignSerializer
        return super(CampaignsController, self).list(request, *args, **kwargs)

    def retrieve(self, request, *args, **kwargs):
        self.serializer_class = CampaignSerializer
        return super(CampaignsController, self).retrieve(request, *args, **kwargs)

    def create(self, request, *args, **kwargs):
        # Create the campaign
        payload_serializer = CreateCampaignPayload(data=request.data)
        payload_serializer.is_valid(raise_exception=True)
        campaign = self.perform_create(payload_serializer)

        # Add yourself as a member
        membership = Membership(user=request.user, campaign=campaign, is_dm=True)
        membership.save()

        # And return the public representation of the campaign
        response_serializer = CampaignSerializer(campaign, context={'request': request})
        headers = self.get_success_headers(response_serializer.data)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def perform_create(self, serializer):
        try:
            calendar = Calendar.objects.get(pk=serializer.initial_data.get('calendar_id'))
        except Calendar.DoesNotExist:
            raise serializers.ValidationError('This is not a calendar_id')

        return serializer.save(
            months=calendar.months,
            owner=self.request.user,
            calendar=calendar.name,
            starting_year=calendar.default_starting_year,
            invite_code=uuid.uuid4().hex
        )
```

Okay, that's a lot of code, so let's go through it. At the top are four serializer subclasses: first we have `UserSerializer`, `MembershipSerializer` and `CampaignSerializer` which are used for returning the public representation of users, memberships and campaigns. Plus `CreateCampaignPayload` which represents the payload that is posted to the server when we want to create a new campaign.

Then there is the `CampaignsController` which includes all the logic for returning the list of campaigns, a single campaign, and for creating a new campaign.

Hooking all this up to the router is very simple:

``` python
router = SimpleRouter(trailing_slash=False)
router.register('/?', CampaignsController, basename='campaign')
urlpatterns = router.urls
```

## Vapor
``` swift
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

struct PublicCampaign: Content {
  let id: UUID
  let name: String
  let description: String?
  let backgroundImage: String
  let isPrivate: Bool
  let calendar: String
  let startingYear: Int
  let months: [Month]
  let createdAt: Date?
  let updatedAt: Date?
  let owner: PublicUser
  let members: [PublicMember]
  let inviteCode: String

  init(from: Campaign) throws {
    try self.id = from.requireID()
    self.name = from.name
    self.description = from.description
    self.backgroundImage = from.backgroundImage
    self.isPrivate = from.isPrivate
    self.calendar = from.calendar
    self.startingYear = from.startingYear
    self.months = from.months
    self.createdAt = from.createdAt
    self.updatedAt = from.updatedAt
    self.owner = try PublicUser(from: from.joined(User.self))
    self.members = try from.members.map(PublicMember.init(from:))
    self.inviteCode = from.inviteCode
  }
}

struct CreateCampaign: Content {
  var name: String
  var description: String?
  let backgroundImage: String
  let isPrivate: Bool
  let calendarId: Calendar.IDValue
  let startingYear: Int

  mutating func afterDecode() throws {
    if name.isEmpty {
      throw Abort(.badRequest, reason: "name must not be empty.")
    }

    if backgroundImage.isEmpty {
      throw Abort(.badRequest, reason: "backgroundImage must not be empty.")
    }
  }
}

extension Campaign {
  convenience init(from: CreateCampaign, calendar: Calendar, owner: User) throws {
    self.init()
    self.name = from.name
    self.description = from.description
    self.backgroundImage = from.backgroundImage
    self.isPrivate = from.isPrivate
    self.calendar = calendar.name
    self.startingYear = calendar.defaultStartingYear
    self.months = calendar.months
    try self.$owner.id = owner.requireID()
    self.inviteCode = UUID().uuidString
  }

  func userIsMember(userId: UUID?) -> Bool {
    guard let userId = userId else {
      return false
    }

    return self.members.contains { member in
      member.user.id == userId
    }
  }

  static func fetchCampaign(id: UUID, req: Request) async throws -> Campaign? {
    let token = req.auth.get(Token.self)

    let campaign = try await Campaign
      .query(on: req.db)
      .join(User.self, on: \Campaign.$owner.$id == \User.$id)
      .join(children: \.$members)
      .with(\.$members) {
        $0.with(\.$user)
      }
      .find(id)
      .get()

    guard let campaign = campaign else {
      return nil
    }

    if !campaign.userIsMember(userId: token?.userID) && campaign.isPrivate {
      return nil
    }

    return campaign
  }
}
```

Let's start with the models before I add the view code. Unlike Django where the serializer for a model can simply exclude a few fields without having to redefine the whole model, in Vapor it's par for the course to create these so-called "data transfer objects"; different versions of your database model for the public representation, the payload for creating a model, one for updating a model, and so on.

Then, in `CreateCampaign` you can see that had I to add my own validation logic to make sure that `name` and `backgroundImage` are not empty strings - logic that is not needed in Django since that information is already available in the model definition itself (`blank=False`, which is the default), and automatically validated.

Let's move on to the view code.

``` swift
struct CampaignController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.group("campaigns") { unprotectedRoutes in
      // Protected
      unprotectedRoutes.group(Token.guardMiddleware()) { protectedRoutes in
        protectedRoutes.get(use: list)
        protectedRoutes.post(use: create)

        protectedRoutes.group(":campaignID") { campaignRoutes in
          campaignRoutes.get(use: get)
          campaignRoutes.put(use: update)
          campaignRoutes.delete(use: delete)
        }
      }
    }
  }

  /// GET /api/campaigns
  func list(req: Request) async throws -> [PublicCampaign] {
    let token = try req.auth.require(Token.self)

    return try await Campaign
      .query(on: req.db)
      .join(User.self, on: \Campaign.$owner.$id == \User.$id)
      .join(children: \.$members)
      .filter(Member.self, \.$user.$id == token.userID)
      .with(\.$members) {
        $0.with(\.$user)
      }
      .all()
      .get()
      .map { try PublicCampaign.init(from: $0) }
  }
  
  /// GET /api/campaigns/:campaignID
  func get(req: Request) async throws -> PublicCampaign {
    let campaign = try await Campaign
      .fetchCampaign(id: req.parameters.require("campaignID"), req: req)
      .unwrap(or: Abort(.notFound, reason: "Campaign not found, or you don't have access to it"))

    return try PublicCampaign.init(from: campaign)
  }

  /// POST /api/campaigns
  func create(req: Request) async throws -> Response {
    let token = try req.auth.require(Token.self)
    let user = try await User.find(token.userID, on: req.db)
      .unwrap(or: Abort(.forbidden))
      .get()

    // Create campaign
    let createCampaign = try req.content.decode(CreateCampaign.self)

    let calendar = try await Calendar.find(createCampaign.calendarId, on: req.db)
    guard let calendar = calendar else {
      throw Abort(.notFound)
    }

    let campaign = try Campaign(from: createCampaign, calendar: calendar, owner: user)
    try await campaign.save(on: req.db)

    // Add yourself as a member (DM role)
    try await campaign.addMember(user: user, isDm: true, on: req.db)

    // Refetch the campaign so that all the relationships (like the members) are properly loaded
    return try await Campaign
      .fetchCampaign(id: campaign.requireID(), req: req)
      .map { try PublicCampaign.init(from: $0) }
      .encodeResponse(status: .created, for: req).get()
  }
}
```

The view code is pretty nice actually, it's one of the best parts of working with Vapor. The fact that everything is strongly typed and checked by the compiler is honestly super useful and something I do miss when working with Django. If it compiles, I can be pretty sure it'll work fine when calling these endpoints. There might be bugs in the logic of course, but it's not like Django where you can write a whole bunch of code and you won't know if it works until you call the endpoints and test every single branch of logic.

Another nice thing is that everything is very explicit, it's easy to read the code from top to bottom and know exactly what a view does. It's very easy to customize logic, since all the logic is your own. For example fetching a campaign and failing if you're not a member and it's not a publicly available campaign: very easy to do.

But boy, working with the data transfer objects and having to write all those really is a huge bummer.

# Conclusion
I hate writing models, model migrations and the data transfer objects in Vapor - it's so much *boring* repeated code to write! Validation needs to be witten by hand as well. But on the other hand, the view code is pretty nice to write. Yes, it's a bit longer than the DRF version, but it's understandable, fully customizable to exactly how I want it to work, and I know that if it compiles, that I won't have weird crashes because some property wasn't found on an object.

DRF on the other hand really excels in the models, automatic migrations and the serializers which are based on the models but really easily modified without having to redefine the entire model minus one field or something like that. The one controller that I showed above was also very readable and understandable. In reality most controllers for most of my apps's features would be a lot simpler, making the difference with Vapor even bigger.

For example, here is the entire controller for the party loot feature. You can fetch the list of all loot, post a new one, get, update or delete an existing one:

``` python
class LootSerializer(serializers.ModelSerializer):
    class Meta:
        model = Loot
        exclude = ['author', 'campaign']

class LootController(viewsets.ModelViewSet):
    permission_classes = (CampaignMemberOrPublicReadOnlyPermission,)
    serializer_class = LootSerializer

    def get_queryset(self):
        return Loot.objects.filter(campaign_id=self.kwargs['campaign_id'])

    def perform_create(self, serializer):
        return serializer.save(author=self.request.user, campaign_id=self.kwargs['campaign_id'])
```

The equivalent Vapor code is something like this, and that doesn't even include the DELETE endpoint!

``` swift
struct CreateLoot: Content {
  var text: String
  var isHidden: Bool?

  mutating func afterDecode() throws {
    if text.isEmpty {
      throw Abort(.badRequest, reason: "text must not be empty.")
    }

    self.text = try clean(text)
  }
}

extension Loot {
  convenience init(from: CreateLoot, campaignId: Campaign.IDValue, authorId: User.IDValue) {
    self.init()
    self.text = from.text
    self.isHidden = from.isHidden ?? false
    self.$author.id = authorId
    self.$campaign.id = campaignId
  }
}

struct PublicLoot: Content {
  var id: UUID
  var text: String
  var createdAt: Date?
  var updatedAt: Date?

  init(from: Loot) throws {
    self.id = try from.requireID()
    self.text = from.text
    self.createdAt = from.createdAt
    self.updatedAt = from.updatedAt
  }
}

struct LootController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes
      .grouped(Token.guardMiddleware(), CampaignMemberOrPublicReadOnlyAuthMiddleware())
      .group("campaigns", ":campaignID", "loot") { protectedRoutes in
        protectedRoutes.get(use: list)
        protectedRoutes.post(use: create)
        protectedRoutes.put(":lootID", use: update)
      }
  }

  /// GET /api/campaigns/:campaignID/loot
  func list(req: Request) async throws -> [PublicLoot] {
    return try await Loot
      .query(on: req.db)
      .filter(\.$campaign.$id == req.parameters.require("campaignID"))
      .sort(\.$updatedAt)
      .all()
      .map(PublicLoot.init(from:))
  }

  /// POST /api/campaigns/:campaignID/loot
  func create(req: Request) async throws -> PublicLoot {
    let token = try req.auth.require(Token.self)

    let createLoot = try req.content.decode(CreateLoot.self)
    let loot = try Loot(from: createLoot, campaignId: req.parameters.require("campaignID"), authorId: token.userID)
    try await loot.save(on: req.db)

    return try PublicLoot(from: loot)
  }

  /// PUT /api/campaigns/:campaignID/loot/:lootID
  func update(req: Request) async throws -> PublicLoot {
    let updateLoot = try req.content.decode(CreateLoot.self)

    let loot = try await Loot.findInCampaign(
      req.parameters.require("lootID"),
      campaignId: req.parameters.require("campaignID"),
      on: req.db
    )

    loot.text = updateLoot.text
    loot.isHidden = updateLoot.isHidden ?? false
    try await loot.save(on: req.db)

    return try PublicLoot(from: loot)
  }
}
```

So even though writing the controller in Vapor is kind of fun to do and extremely explicit and customizable.. there is just *so much of it to write*! It takes a bit longer to figure out how to do certain things with Django REST Framework (there are so many layers involved) but once you do, everything is super fast.

Not to mention simple developer quality-of-life things like Django automatically restarting the server on code changes, or not having to compile first, which can literally take four minutes with my tiny Vapor project. It's a lot easier to get the Django server hosted somewhere, it should use less memory, has a much bigger community around it when you hit a dead-end, many more packages are available to use, the list goes on honestly.

All that is to say: I love you Vapor 4, your async/await support is really great, but I will build my backend with Django and Django REST Framework. Please let me know when writing models and dealing with the data transfer objects has gotten less boilerplate-y, and migrations are done automatically. I'll definitely have another look then, but for now, I must say goodbye.