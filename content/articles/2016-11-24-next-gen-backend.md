---
tags: review, backend
---

# Searching for a next gen back end
A while ago I started to think: if I were to build a brand new web app plus back end today, what would I use for the back end, and how would the client talk to it? So far my APIs have been very standard REST affairs: endpoints per model that get/save info from/to a database, with a separate websocket server to deliver real time updates to the client. But we all know the main problem with this: the amount of endpoints keeps on growing as features get added or different clients have different data needs. You don't always need all the data an endpoint gives you, which is just a waste of bandwidth - especially a problem on mobile. And doing the real time updates is just a pain, manually sending messages for created, updated and deleted objects, to the correct connected clients based on their permissions. And then on the client side you need to listen to all these messages to then manually alter your local state.

So, if I were to start from scratch today, what would I use instead?

My main goals are simple:

1. I want one endpoint where the client asks for the data it needs, instead of an endpoint per model and the usual problems of under- and over fetching.
2. I want real time updates without the manual hassle of updating the local state.

And some other wishes:

1. I would like to not end up having to write two separate schemas and shuffling data between them (for example a GraphQL schema and then the database schema).
2. It should be easy to add caching.
3. Optimistic UI updates on mutations.
4. I'd like it if all queries for the entire component tree end up sending one request to the server.
5. On the client side the data should preferably end up in Redux so it can be persisted, debugged with dev tools, sent to
[LogRocket](https://logrocket.com), etc.
6. It should be possible to have custom server-side logic.

What follows is bunch of frameworks and technologies that I looked into, roughly in chronological order.

## GraphQL
It probably makes sense that I looked into [GraphQL](http://graphql.org) first: it's part of the same Facebook stack that I already use (React, React Native, Flow), and specifically talks about one endpoint, client side queries colocated in components, no more under- and over fetching, all that good stuff. It has lots of potential, I like the schema definition language and I'd definitely like to use it. However, GraphQL is just a spec, by itself it doesn't do anything. You need to setup a server, and use client side libraries to talk to that server. "GraphQL" by itself isn't something you can just install and it works.

The biggest drawback to me is that you have to deal with the communication from the schema to and from the database. So for example when your schema is something like this:

```javascript
const schema = `
  type Author {
    id: Int
    firstName: String
    lastName: String
    posts: [Post]
  }
  type Post {
    id: Int
    title: String
    text: String
    views: Int
    author: Author
  }
  type Query {
    author(firstName: String, lastName: String): Author
  }
  schema {
    query: Query
  }
`;
```

Then you have to write your own resolver function for that `author` path and for the `Author` and `Post` types. You have to deal with getting the data from your database (or REST endpoint or in-memory storage or whatever - the point is that it's all up to you).

For example, your resolvers could look something like this:

```javascript
const resolvers = {
  Query: {
    author(_, args) {
      return Author.find({ where: args });
    },
  },

  Author: {
    posts(author) {
      return author.getPosts();
    },
  },

  Post: {
    author(post) {
      return post.getAuthor();
    },
  },
};
```

But that would require you to write database models and query them yourself. And these examples don't even show anything like filtering or ordering, which you would have to handle in the resolvers as well, or mutations, or subscriptions.

It's all super flexible of course but it does feel like a lot of duplicate work. I'd much rather have something that takes care of all this for me.

So, the search for servers began.

## Scaphold
[Scaphold](https://scaphold.io) is a hosted solution where you can define your schema in a neat online editor and it gives you real time updates too via GraphQL subscriptions. However, you can't add server side logic; you can add webhooks to call a remote service on get/set and that sort of stuff, but it's not exactly ideal. 

There are other hosted solutions too, but none of them offer real time updates nor server side logic. So, maybe just run my own server instead?

## Postgraphql
I started by looking into servers that deal with the resolve functions automatically, so the schema automatically connects to a database, so to speak. [Postgraphql](https://github.com/calebmer/postgraphql) is kind of the reverse: it looks at your Postgres database tables, views and functions, and creates a GraphQL schema plus server for you based on that. Querying and mutations just work as if by magic, and you use the built-in Postgres features for access control. Pretty neat! However, there is no support for real time time updates so you'd have to write that entire part yourself. It also seems impossible to integrate custom server side logic into this; you'd have to run a separate micro service next to it basically.

## graphene-django
Maybe an all-in-one fully automatic solution like Postgraphql is not flexible enough, which brought me to [graphene-django](https://github.com/graphql-python/graphene-django). It's a Django package that simply connects your Django ORM models to a GraphQL schema. Everything is then taking care of for you, but you still have the possibility to override fields, add extra computed fields to the schema, anything you want really. Plus all the extra server side logic right there where you want it.

Once again though, no real time updates. At this point I found out that subscriptions are not officially part of the GraphQL spec yet, so that explains quite a lot.

In the end I think graphene-django is a very good solution to setup a GraphQL server - as long you don't need real time updates, or don't mind bolting that on yourself.

## Graffiti
One slight problem with graphene-django is that it's Python instead of JavaScript, and I would prefer the entire back end plus front end stack to be the same language, so that I don't have to switch languages. [Graffiti](https://github.com/RisingStack/graffiti) is similar to graphene-django: it sits between Express and MongoDB and creates a GraphQL scheme plus server based on your MongoDB models.

Once again though, no real time support. Also they only do a strict one-to-one mapping from Mongo to GraphQL, so no real chance to override or add stuff to the schema. I think graphene-django would be a more flexible solution, long term. Graffiti, you're out.

## express-graphql
[This](https://github.com/graphql/express-graphql) is a bare-bones do-everything-yourself GraphQL server middleware for Express. You write your own schema and you deal with all the resolvers yourself. You gain 100% control and flexibility, but you need to do everything. I couldn't figure out from the documentation how I'd add real time updates though, until I stumbled across the Apollo project.

## Apollo
[Apollo](http://www.apollodata.com) is a set of tools and products that help you to create a GraphQL server with subscription (real time updates) support. You still have to deal with the resolve functions yourself, but at least the subscription support is there. Finally! I actually went ahead and created a small trial project with this stack.

Currently on the server I am using express, graphql-server-express and graphql-tools just for the GraphQL part,
and then graphql-subscriptions plus subscriptions-transport-ws for the real time updates support. On the client I am
using React, apollo-client, react-apollo and graphql-tag, plus subscriptions-transport-ws.

This whole stack feels.. big. A lot of moving parts and packages, a lot of manual setting up of stuff as well. I do like to write my own GraphQL schema but I really don't want to deal with the resolve function, the ordering, the filtering, mutation data, etc etc. And while Apollo does support GraphQL subscriptions, it's far from my ideal solution because you still need to manually deal with created, updated, and deleted objects, mutate your local state when these real time messages come in.

What I really want is "live" queries so that if anything changes in the data set, it's automatically updated, without
setting up subscriptions on the server and on the client. And I also want that my GraphQL schema can automatically be
persisted to a database, without me having to write database models and then having to manually deal with shifting data
from and to GraphQL and the database.

Sadly it just doesn't seem like this is possible at the moment. None of the servers offer the connection between GraphQL and database that I want plus real time updates, especially not in a way that I want.

## Cashay
This is not a server, but a [client side library](https://github.com/mattkrick/cashay) to add easier subscriptions to GraphQL with the `@live` decorator, and it writes all your mutations for you. However, you still have to deal with the incoming real time updates yourself, and the documentation is.. not great. And like I said, you still have to write the server, which Cashay doesn't say anything about.

It was at this point that I started to look in alternative non-GraphQL solutions. I just want to best end result and don't care about a specific technology in the end.

## Firebase
I think many webdevelopers have heard about Firebase: a [hosted real time database](https://firebase.google.com/docs/database/) (plus other features like authentication, remote config, storage). In many ways it solves the same problems: no endpoints to maintain: check. Proper real time updates: check.
iOS and JS: check. All hosted for you, hassle free. Even the real time support is better than what you get with Apollo, since you don't need to manually deal with incoming object mutations. It's easy to integrate with React and Redux as well. Surely a winner, right? Well.. as with most hosted solutions, there is no way to add server side logic other than webhooks to a remote service.

## Parse
Parse actually seemed to offer basically everything that I want: live queries and cloud based server side JavaScript logic. Sadly they are shutting down though. They do offer an open source self-hosted server, so maybe that's something to try out? On the other hand, the ParseReact client library does not support the latest Parse features like live queries, which is why I was interested in Parse in the first place. So I think Parse is out.

## Horizon
One of the more interesting alternatives I've found is [Horizon](http://horizon.io), built on top of [RethinkDB](https://rethinkdb.com). It has full real time support and there are examples on how to integrate it with React and Redux. However, it seems it's just a bit too early to use it as there are some problems and missing features. For example: when the connection between the client and the Horizon server is lost it doesn't reconnect, instead all the connected components loose their current data and you basically end up with an empty screen. Last but not least, RethinkDB as a company shut down and progress on the open source stuff seems painfully slow (support for optimistic updates, the reconnection handling, paginating, just to name some missing features). I think that Horizon is out, but RethinkDB is still in.

## Meteor
Another very interesting alternative is [Meteor](https://www.meteor.com), a platform to build real time apps. There are some complaints I've read about it being monolithic and bad to scale, but it seems quite easy to integrate with React and the syntax is nice (with proper live objects). But yeah, something like `meteor npm install --save react react-dom` definitely looks off to me. I just want a data library to include in my React app, not a whole platform that even replaces NPM. But maybe it's a fair tradeoff for all the problems it would solve?

## Falcor
Netflix has created some very cool open source projects, and [Falcor](https://github.com/Netflix/falcor) is one of them. They seek to solve the same problems as GraphQL: one endpoint, one model everywhere. "The data is the API" as they say it, which is exactly what I want. Sadly they have the same drawbacks as well: you need to deal with resolving the data yourself and there is no support for real time updates in the spec. I also like GraphQL much better as a schema and query language. So Falcor is out.

## Meatier
If Meteor is too monolithic then [Meatier](https://github.com/mattkrick/meatier) attempts to solve that by combining GraphQL with RethinkDB and Redux. It says it has proper real time support thanks to RethinkDB, so I am definitely going to give this one a try. One big drawback is its documentation and tutorials: definitely not for beginners. It's not very user friendly it seems, but hey if I can get it working then this could be the winner. Of course you'd still need to deal with the resolve functions yourself but at this point, considering there is no perfect solutions, I'll just have to deal with that.

## react-rethinkdb
Since RethinkDB has real time support itself and (from what I've heard) an awesome query language - why no simply use RethinkDB directly without worrying about GraphQL? This is what [react-rethinkdb](https://github.com/mikemintz/react-rethinkdb) gives you: render real time RethinkDB results in React. Definitely super interesting.

## Conclusions
After looking into all these options for more than a week now, I am a bit disappointed that it's so hard to get the future that I want, now.

At the moment I am most interested in Scaphold and Firebase for hosted solutions. Scaphold gives you a GraphQL server with subscription support, but dealing with those subscriptions on the client isn't exactly great. I have high hopes that this will get better as Facebook adds new stuff to the GraphQL spec though. Firebase would pretty much solve all my problems except for server side logic.

Meatier and react-rethinkdb are the two self-hosted solutions that I most interested in. I just have to dive in and try both of them.

I'll keep updating this article with new findings and thoughts!

## Update December 19, 2016
I've looked into RethinkDB because it seemed like a very good option. 

My conclusion is that RethinkDB by itself doesn't seem very suitable to use directly from apps, since there is no permission system for example. You'd need to put your own server in between RethinkDB and the client.

One such server is Horizon, which does add the permission system quite nicely, but it has [issues](http://horizon.io/docs/limitations/) with reconnection handling and React Native. There are also no iOS libraries yet, and it has problems with mobile Safari. And since RethinkDB the company is shut down, who knows what progress will be like going forward.

With Horizon the real time changefeeds from RethinkDB would still need to be handled manually, updating local state. Actually, react-rethinkdb handles that better but it has problems of its own like the [mixin syntax](https://github.com/mikemintz/react-rethinkdb/issues/8) that I don't want to use.

One other problem with RethinkDB is that it doesn't have any schemas, it's a free-for-all JSON storage. Not sure how big of a problem this is, but I actually like the idea of a schema ala GraphQL.

So in the end RethinkDB is not what I am looking for, at least not yet. It does have a really interesting foundation though, so I hope really hope it continues to grow and get better.
