---
tags: python, django, news
summary: A modern, flexible rewrite of django-generic-notifications is here. Easily send website and email notifications, create digests, group similar messages, and much more.
---

# Announcing django-generic-notifications 1.0.0

Back in 2011, I started a small Django package called [django-generic-notifications](https://github.com/loopwerk/django-generic-notifications). It was built for a project I was working on at the time, got seven releases over a few months... and then it more or less died. Once I moved on from that original project, there wasn't much reason to keep maintaining the library. It never gained a big user base, no pull requests or issues came in, and eventually I archived the repository.

Fast forward to a few weeks ago, and I found myself needing a good, flexible notification system for a new Django project. I checked out a few third-party options, but none of them quite fit what I had in mind. I wasn't super eager to revive django-generic-notifications — it was very old, still using South for migrations (yes, that old) — but in the end, I decided to bring it back to life. Or rather, to start fresh.

So here it is: version 1.0.0 of django-generic-notifications. A complete rewrite, with the same core architecture but a modern, cleaned-up implementation. It's more flexible, more powerful, and a lot more useful.

## What is django-generic-notifications?

At its core, this package helps you send notifications to your users through different channels like email or your website. It's built around the idea of defining notification types in your code, and then letting the library handle how and when to deliver them to your users.

Want to show a bell icon on your website when a user gets a new comment? Easy. Want to send them a weekly email digest with grouped notifications? Also easy. Want to build your own Slack or push notification integration? Go for it.

## Highlights

- **Channels**: The old concept of "backends" is now called "channels", and we ship two out of the box: `website` and `email`.
- **Website notifications**: Finally a built-in way to show notifications on your site. The old version never included this, which in hindsight is kind of wild.
- **Email digests**: Daily or weekly summaries of all pending notifications, grouped and nicely formatted.
- **Notification grouping**: Avoid spamming users with multiple similar notifications: group them together automatically.
- **Simplified internals**: No more built-in queuing system, no assumptions about how your custom channels should process notifications. Just plug in your own logic.
- **Customizable**: Choose which channels a notification must go through and build your own delivery logic if needed.
- **Tested**: Yes, we have unit tests now 🎉
- **Example project**: Included in the repo to help you get started quickly.

## Get started

Check out the project on GitHub: [github.com/loopwerk/django-generic-notifications](https://github.com/loopwerk/django-generic-notifications).

The README walks you through installation, configuration, and how to define your own notification types. You can be up and running in just a few minutes. Let me know how you like it!
