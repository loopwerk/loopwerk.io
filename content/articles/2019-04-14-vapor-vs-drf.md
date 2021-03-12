---
tags: review, backend, swift, django
---

# Vapor 3 vs. Django REST Framework
A little while ago [I wrote about starting a new side project](/articles/2019/vapor/), where I was using Vapor 3 to build the backend. My initial impressions were extremely positive, but I ended up running into a few issues that made working with the framework a little bit of a struggle. The conclusion of that article was that I didn't know how to continue: stick with Vapor 3 despite the problems I was having, or switch to Python.

Well, as an exercise I rebuilt the entire backend in Python using Django and Django REST Framework (DRF), while also adding new features and unit tests to both versions of my backend. Here are my findings now that I have two more-or-less identical backends.

## Getting started
For me, it was a lot easier to get started with Vapor. The command line tool to start a new project gives you a new project with a router, a model, and a controller. From there, the compiler holds your hand with auto-completion. While the documentation of Vapor is not the best, I found it very easy to get up and running quickly.

When I started with the DRF version of my backend, I felt overwhelmed with all the files and settings. I also didn't have a project template that included DRF specific things, so I had to figure out how to do things like routers and controllers (views in Django lingo). Luckily, the DRF documentation is very good, with a tutorial and lots of examples, so once I was over the initial shock, it was easy enough to get going. One thing that did confuse the hell out of me initially was the difference between Views, Generic Views, ViewSets, ModelViewSets, all the view mixings... it's a lot to take in.

## Different responses for different situations
One of the things that I complained about with Vapor, was how tedious it was to keep having to write different versions of my models for the GET vs the POST. And while yes, it is a little bit tedious, it's also honestly quite easy to do and the compiler does help you when you convert from one model to another for example.

In DRF on the other hand I had a lot more problems getting the responses that I wanted to have. For example, when I get a list of objects with `GET /my/type`, I want a simpler version of the model compared to the full `GET /my/type/1`, where I want all the properties, even nested ones. Or consider the situation where in the POST you simply want to provide the ID of some relationship, like when you create a new car, you simply want to provide the ID of the manufacturer. Yet in the response, I do want that manufacturer object given back. This was extremely easy to do in Vapor due to the need to have these strongly typed models for every situation anyway, but I was struggling quite a bit with DRF to have the same behavior.

I did get it to work exactly as I wanted in both versions, but again I have to give a point to Vapor here. I felt much less like I was struggling with the framework to make it behave in the way I wanted it to.

## Unit tests
A much bigger difference between the two frameworks became obvious when I added unit tests to both backends. Not only was it a lot easier to get started with Django and DRF to write my first test, it also has far superior support for loading fixtures into the test database, automatically cleaning the database for every single test case, plus the tests are very fast to run: 38 tests take about 0.6 seconds to complete.

On the other hand, the strongly typed nature of Swift and Vapor made actually writing the tests easier, even though the initial set up was a lot harder.

```swift
func testLocationsUnauthorized() throws {
  let (result, status) = try app.getResponse(to: "/api/locations", decodeTo: [Location].self)
  XCTAssertEqual(status, .ok)
  XCTAssertEqual(result.count, 1)
  XCTAssertEqual(result[0].name, "Location 2")
}
```

As you can see above, `result[0]` is actually an instance of `Location`, and the compiler will autocomplete things like `.name` for you.

In the Python version, you work with lists and dictionaries with no help from a compiler:

```python
def test_locations_unauthorized_user(self):
    response = self.client.get('/api/locations/')
    self.assertEqual(response.status_code, status.HTTP_200_OK)
    self.assertEqual(len(response.data), 1)
    self.assertEqual(response.data[0].get('name'), 'Location 2')
```

There's nothing here that helps you, nothing that tells you that `response.data` is a list, and the first element is a `Location` that has a `name` property, and so on.

So, while it was a lot easier to get up and running with unit tests in Django, I do find them faster to write in Vapor because there is a lot less guesswork involved. Too bad that the same tests take 23 seconds to complete in Vapor. A huge difference!

## Swift versus Python
This is of course super subjective, but I simply enjoy writing Swift code a lot more than I do Python code. I find that I make a lot fewer mistakes that result in an error 500 because I made some typo or tried to access a property that didn't exist. This is by far the biggest reason why I stuck with the Vapor version of my backend, and why I now have two identical backends instead of me simply switching everything over to Python.

## Nested routes
With nested routes I mean a route like `/city/1/locations` or `/city/1/locations/2`. While maybe not strictly "REST" (according to some people), I much prefer it to `/location/2?city=1`, especially when it's only one level deep.  Nested routes are not a problem at all in Vapor, since you write every route and its handler from scratch. Sadly they're a lot more work in DRF, with a third party dependency needed. It all works, but I spent a couple of hours compared to nothing extra in Vapor.

## SQL queries and performance
While the Django ORM makes it very easy to get data from the database, it does result in a lot more queries. For one particular page, the Vapor version is using 5 queries where the Django version was using 23. Now, that was before some `select_related` and `prefetch_related` magic sprinkled on top, after which it went down to 9 queries. That's still almost twice as many to get the exact same data. On the other hand, in Vapor I have to do a lot more manual work to get the data that I want, make the table JOINs myself, but it does result in a lot fewer queries. And while Django's `select_related` and `prefetch_related` do help a lot, this is something that you have to remember to do yourself, with no help from a compiler. With the Vapor version there just is no way to make a naive query that ends up doing 14 extra queries to the database.

I also found it a lot easier to do some other things in Vapor. For example, I have a middleware function that checks permissions for the entire tree of my nested routes. So no matter if you request `/city/1/locations` or `/city/1/locations/2`, the system checks if you actually have access to `city` with id 1. And then it stores that city object in the request context, ready to be used in any of the route handlers without doing an extra query.

Sadly, the same permission checks in DRF always result in extra queries since the magic of ModelViewSet (where you give one generic query for the whole list, and then DRF does a subquery to get the single entity for the GET request to a single object) works completely separate from the permission checks. I did not find a solution where some piece of middleware would end up doing fewer requests.

Is this all a problem in the end? Well, not really. The 5 vs 9 queries is not a huge deal for this endpoint, and most of the endpoints use way fewer queries anyway. Still, it's kind of a theme, where yes, the Vapor version initially needs a bit more work (write my own queries and joins), it ends up doing exactly what I want right away, where with DRF it's usually a lot quicker to get that initial result working, but it could end up being very naive (and doing 14 extra queries), or I end up spending a lot more time tweaking the behavior with no help from a compiler to guide me along.

In the end I do think the win goes to Vapor, since it's doing the right thing by default, has fewer foot-guns, and no magic means that it's a lot easier to make it do exactly what you want, as I did with the permission checking middleware that stores the root object in nested routes.

## Batteries included
Django comes with a very usable admin interface and this is honestly a big deal. When I was hired to write a backend for a client, I didn't even really think about using Vapor. All this indecisiveness that I have with my own side project was simply not an issue at all with an actual paid project for a client that also needs a way to view and edit the data in his system. With Django's admin interface, I can offer him exactly this with only a few minutes work. Vapor just doesn't have something like this. Of course, Vapor is young with a small ecosystem, so I don't hold this against the framework at all! And for my side project, where I don't really need an admin interface, it's not really a problem not to have it. Still, would be nice though, and definitely a huge selling point of Django.

Then there is DRF which comes with automatic API docs, an interactive API browser where you can execute requests and see the response right there in the browser without needing a tool like Postman. Combined with Django Debug Toolbar's SQL debugger, this gives you an extremely good insight into the queries each endpoint does, have many it does, how long they take, etc. This is a huge difference from Vapor where it can print out the queries to the console, but that's about it.

## Storage, S3
It's very easy to support file uploads in Django and DRF, where static files and user uploaded media can automatically be stored on Amazon's S3 when running in production, or just locally when running the local dev server. Django has an ImageField model type that does all the file storing work and then stores the image URL in the database. And when you then get that image field from the database again, you'll get a full URL to the stored file. All of this is abstracted away and it's great.

Sadly, all of this is manual work in Vapor. And to be honest, right now this is by far the biggest pain point I have with Vapor, and a big reason to possibly go forward with the Django version of my backend.

## Magic vs everything manual
With DRF you can register one route for a model, with one ModelViewSet as its handler, and it will automatically handle the GET requests to the list of models and a single entity, POST to create a new entity, PUT to make changes, DELETE and even OPTIONS and PATCH. All of this is done automatically.

```python
router = routers.SimpleRouter()
router.register(r'', CityViewSet, basename='cities')

city_router = routers.NestedSimpleRouter(router, r'', lookup='city')
city_router.register(r'locations', LocationViewSet, basename='city-locations')

class LocationViewSet(ModelViewSet):
    serializer_class = LocationSerializer
    permission_classes = (OnlyMembersCanChangeAndDelete,)

    def get_queryset(self):
        return Location.objects.filter(city=self.kwargs['city_pk'])

    def perform_create(self, serializer):
        serializer.save(city_id=self.kwargs['city_pk'])
        

class LocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Location
        fields = '__all__'
```

That one little LocationViewSet class does it all: GET, POST, PUT, DELETE and the rest. With nested routes, so `location` falls under a `city`. It's quite magical! But sadly, that's also a little bit of the problem. When something doesn't quite behave the way you want it to, you end up fighting the magic.

The Vapor version is a lot more code (and it doesn't even do PATCH and OPTIONS), but I fully control everything:

```swift
struct LocationController: RouteCollection {
  func boot(router: Router) throws {
    let route = router.grouped("locations")
    route.get(use: getAllHandler)
    route.post(LocationCreateData.self, use: createHandler)
    route.delete(Location.parameter, use: deleteHandler)
    route.put(LocationCreateData.self, at: Location.parameter, use: updateHandler)
  }
}

extension LocationController {
  func getAllHandler(_ req: Request) throws -> Future<[Location]> {
    let city = try req.requireCity()
    return try city.locations.query(on: req).all()
  }

  func createHandler(_ req: Request, entryData: LocationCreateData) throws -> Future<Location> {
    let city = try req.requireCity()
    let location = try Location(name: entryData.name, content: entryData.content, cityID: city.requireID())
    return location.save(on: req)
  }

  func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
    let city = try req.requireCity()
    return try req.parameters.next(Location.self).lockedTo(city).flatMap(to: HTTPStatus.self) { location in
      return location.delete(on: req).transform(to: HTTPStatus.ok)
    }
  }

  func updateHandler(_ req: Request, updateData: LocationCreateData) throws -> Future<Location> {
    let city = try req.requireCity()
    return try req.parameters.next(Location.self).lockedTo(city).flatMap(to: Location.self) { location in
      location.name = updateData.name
      location.content = updateData.content
      return location.save(on: req)
    }
  }
}
```

To be fair, there is bunch of code behind the `OnlyMembersCanChangeAndDelete` function in the Django version, which checks all kinds of permissions, including if you have access to the top level `city` from the nested route, and if the `location` actually belongs to that `city` (to prevent you from doing a PUT to `/city/1/location/123` even though location 123 belongs to city 2 for example). 

In the Vapor version, I have the permission middleware I talked about before (not shown here) that checks if you have access to the `city`, and then there is the `.lockedTo(city)` call, which checks if the `location` does, in fact, belong to the `city`. And this is where the Django version is doing extra queries inside of the `OnlyMembersCanChangeAndDelete` class (since it doesn't have access to the top level object by itself), as I mentioned before.

## Conclusion
I think both versions had three phases:

In Vapor, it was super fast, easy and fun to get started. Then came the disappointment of writing all that manual code and missing some of the Django magic. Realizing that I had to write manual JOINs. But then came phase three, when I noticed that there was no need to fight any framework magic or assumptions, and it did exactly what I wanted it to, because I wrote all of it. Positive, negative, positive.

With DRF, it was a bit harder to get started, to get to the first endpoint. Then it became easier to quickly add all the endpoints with all their different methods (GET, POST, etc). But after that came phase three, and I noticed a lot more swearing when I wanted something to behave just a little bit different. Negative, positive, negative.

I still have to decide which of the backends to continue with, because it's just silly to keep both of them. I now realize that a lot of the initial disappointments I had with Vapor actually ended up helping me a lot.

What was more enjoyable in the end? The Vapor version or the DRF version? Probably the first one, even though I was [complaining about it at first](/articles/2019/vapor/). Yes, I end up writing more manual code in the Vapor version of my backend, but it immediately does exactly what I want. No matter if it's nested routes or doing very few queries or easy permission checking with middleware.

For me the biggest wins for each framework are:

**Django**: size of ecosystem and community, how easy it is to get help or answers, out-of-the-box solutions for file storage. It's also very easy to get it hosted. And less important but absolutely worth a mention: the speed of running unit tests.

**Vapor** wins when it comes to the compiler, being a strongly typed language with strongly typed Codable objects for everything. Having easier control over the output without feeling like I have to fight the framework. Better performance and fewer queries, although for my side project that's definitely less important. Most importantly though, I simply enjoy writing Swift code a lot more than I do writing Python code.

Which one will I use going forward? Honestly, it's probably going to be the size of the ecosystem and community (plus the file handling situation) that's pushing me towards **Django**. Everything else is kind of a toss-up with good and bad things about both frameworks. But no matter how much I love Swift and like working with Vapor; Django and DRF are simply much more mature.
