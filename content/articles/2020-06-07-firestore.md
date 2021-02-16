---
tags: firebase, backend
summary: Over a year ago I wrote that I started working on a brand new side project, and that I was building the backend for that project. I started with Vapor 3, then made the same backend in Django REST Framework, and couldn't really choose between the two...
---

# After Vapor and Django comes.. Firestore
Over a year ago I wrote that I started working on a brand new side project, and that I was building the backend for that project. I [started with Vapor 3](/articles/2019/vapor/), then [made the same backend in Django REST Framework](/articles/2019/vapor-vs-drf/), and couldn't really choose between the two. What did I end up choosing? Neither!

I ended up scrapping my backend completely, and went with Firebase's Firestore instead. I actually [wrote about Firebase](/articles/2016/next-gen-backend/) back in 2016 when I was searching for my ideal "next gen backend", when Firestore didn't exist yet (only the older Firebase Realtime Database), and Cloud Functions weren't offered yet either as far as I can remember. But in the summer of 2019 Firebase was mature enough for me to make the switch, and I am super happy that I did.

For those of you who don't know Firestore, let me give you the elevator pitch. Think hosted database, with live queries. So you query the database for all objects in the `Books` collection for example, and when any of these objects change, or one is added or removed, your local collection is immediately updated as well, and you can update the UI. So you don't have to build a REST client with an additional websockets server to supply the client with real-time updates - it's all handled by Firestore. This is saving me an immense amount of time and effort.

Of course you can set permission rules so that for example only logged-in users can access certain collections, or certain documents in those collections, or that only users with a certain value for a certain field can update certain documents. It's all very flexible and powerful, although it can be a bit repetitive to write these rules:

```
service cloud.firestore {
  match /databases/{database}/documents {
    // Block all access to everything by default
    match /{document=**} {
      allow read, write: if false;
    }

    match /users/{userId} {
      allow create: if 
        userId == request.auth.uid && 

        // status and subscription related fields must be omitted
        !("status" in request.resource.data) &&
        !("appleSubscription" in request.resource.data) &&
        !("webSubscription" in request.resource.data);

      allow update: if 
        userId == request.auth.uid &&

        // status must be omitted or must be the same as existing data
        (
          request.resource.data.status == resource.data.status ||
          !("status" in request.resource.data)
        ) &&

        // appleSubscription must be omitted or must be the same as existing data
        (
          request.resource.data.appleSubscription == resource.data.appleSubscription ||
          !("appleSubscription" in request.resource.data)
        ) &&

        // webSubscription must be omitted or must be the same as existing data
        (
          request.resource.data.webSubscription == resource.data.webSubscription ||
          !("webSubscription" in request.resource.data)
        );
  
      allow read: if userId == request.auth.uid;
      allow delete: if false;
    }

    match /calendars/{calendarId} {
      allow read: if true;
      allow create, update, delete: if false;
    }
  }
}
```

Firebase also offers authentication via email and password, sms tokens, one-time tokens that are emailed to you, a host of social logins and Sign in with Apple. Finally, they also offer cloud functions for your server side logic. You can make functions that are triggered by calling an HTTP endpoint, or they can be triggered by Firestore ("if a user document is updated, then do this") or by authentication ("if a user logs in, then do this"). It's all I need for my backend needs.

Lastly they add support for offline access to the database, automatic caching, crash reporting, analytics if you want, and it's available cross-platform - even on the web.

It's not all perfect. Their Swift SDK doesn't natively support Codable models, you simply get dictionaries back. But I wrote a small library for my own use to make it super easy to use Codable models everywhere. The SDK also doesn't offer any kind of reactive framework support, instead all their APIs are block-based, so my library also adds Combine support wherever they use blocks.

There are more problems due the way Firestore stores its data. For example you can't just get a count of documents in a collection without reading all those documents - and you pay per read, so that is not smart. You can also only write to each document just once per second, so Firestore is completely unusable for a bunch of real-time apps. I would also really love it if their permission system with the rules would act like a filter, so that you automatically only get the data that you have permissions for. But instead you still have to basically duplicate the server side rules in the client and query for specific data, or you'll end up getting access errors.

The biggest problem of all though is their JavaScript SDK: it's really really big, pardon the pun. It's literally over 80% of the size of my web client bundle size. But, they're working on reducing it and there is just no way I am going to switch backends *again*!

Overall, I am really super happy with Firestore and would highly recommend anyone to check it out, especially for mobile apps (a bit less for web apps due to the SDK size).

As for my side project: I've recently announced it to the world: https://www.critical-notes.com. It's a note-taking tool for roleplaying games like D&D. It has a web client (written in Svelte), an iOS app (SwiftUI) and a native macOS app (using Catalyst), and I hope to release the web client in a public beta this summer. I'll write about the iOS app and [my experience with SwiftUI](/articles/2020/swiftui-review/) ~~soon~~!
