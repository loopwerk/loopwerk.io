---
tags: django, news
summary: A modern, flexible rewrite of django-generic-notifications is here. Send website and email notifications, create digests, and group similar messages.
---

# Announcing django-generic-notifications 1.0.0

Back in 2011, I started a small Django package called [django-generic-notifications](https://github.com/loopwerk/django-generic-notifications). It was built for a project I was working on at the time, got seven releases over a few months... and then it more or less died. Once I moved on from that original project, there wasn't much reason to keep maintaining the library. It never gained a big user base, no pull requests or issues came in, and eventually I archived the repository.

Fast forward to a few weeks ago, and I found myself needing a good, flexible notification system for a new Django project. I checked out a few third-party options, but none of them quite fit what I had in mind. I wasn't super eager to revive django-generic-notifications - it was very old, still using South for migrations (yes, that old) - but in the end, I decided to bring it back to life.

So here it is: version 1.0.0 of django-generic-notifications. A complete rewrite, with the same core architecture but a modern, cleaned-up implementation. It's more flexible, and a lot more useful.

## What is django-generic-notifications?

This package helps you send notifications to your users through different channels like email or your website. It's built around the idea of defining notification types in your code, and then letting the library handle how and when to deliver them to your users.

It allows you to do things like sending weekly email digests with grouped notifications, or showing notifications on your website with a bell icon. And if you want to build your own Slack or push notification? The sky's the limit.

## Highlights

- Channels: the old concept of "backends" is now called "channels", and we ship two out of the box: `website` and `email`.
- Website notifications: finally a built-in way to show notifications on your site. For some reason that I can't remember the old version never included this.
- Email digests: daily or weekly summaries of all pending notifications, grouped and nicely formatted.
- Notification grouping: avoid spamming users with multiple similar notifications by grouping them together automatically.
- Simplified internals: no more built-in queuing system, no assumptions about how your custom channels should process notifications. Just plug in your own logic.
- Highly customizable: choose which channels a notification must go through and build your own delivery logic if needed.

## Get started

Check out the project [on GitHub](https://github.com/loopwerk/django-generic-notifications). The README walks you through installation, configuration, and how to define your own notification types. You should be up and running in just a few minutes. Let me know how you like it!
