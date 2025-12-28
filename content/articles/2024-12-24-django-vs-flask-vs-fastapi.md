---
tags: python, django, insights
summary: I started using Django in 2009, and fifteen years later I am still a happy user. When I compare this to the number of JavaScript frameworks I've gone through during the same fifteen years, it's clear that Django is rather special.
---

# Why I still choose Django over Flask or FastAPI

I started using Django in 2009, and fifteen years later I am still a happy user. When I compare this to the number of JavaScript frameworks I've gone through during the same fifteen years, it's clear that Django is rather special. Here are a few of my reasons why.

## Batteries included

Django comes with a database ORM, authentication, a way to email users, a template language, static files handling, forms and validation, a testing framework, support for localization, RSS feeds, the built-in admin interface for your database models, and a bunch of other things.

Sure, not all the batteries are equally good, but I really appreciate that I don't have to think about having to find an ORM, how to do database migrations when changing my models, how to build a simple admin interface, how to send emails.

Would I be able to setup Flask with SQLAlchemy as the ORM and Alembic for migrations? Why, yes. But do I want to have to do that? Absolutely not. While some people see Django's way as limiting, I see it as freeing myself from having to piece together a working system by myself from scratch.

## The ORM

While I'd prefer a simpler syntax for the models based on types ala Pydantic, the ORM is still really simple to use. I honestly prefer it above SQLAlchemy when it comes to filtering, fetching, updating and creating database models. You have to be careful to not run into the dreadful N+1 queries problem when using related tables, but overall the ORM is a joy to use.

## Database migrations

I cannot overstate what a gem of a feature Django's automatic database migrations is. Compared to basically any other migration system for any other ORM, Django wins quite easily. It's completely effortless and I never have to worry or even think about changing my database models. It is simply brilliant. For me this is actually the number one selling point of Django, and the main reason why [I chose it over Vapor 4](/articles/2021/vapor4-vs-drf/) for example.

## The admin interface

We all wish the Django admin would be modernized but you can't put a price on having the admin interface - warts or not. I use it for every Django site I build: from small APIs I build for myself (so that I can quickly add test content before all the endpoints are in place) to big projects for international clients (so that their site admins can easily view and edit all the site data). Of course the admin site isn't suitable for every admin task and I do wish it would be easier to include your own custom pages into the greater admin interface so that site administrators have a single environment to work from, but the fact that we can edit any database model with extremely little effort is one of Django's top selling points. Probably my number two favorite thing right after the migrations.

## Django REST Framework

One of the reasons why I keep choosing Django for building APIs is Django REST Framework. It's by far my preferred way to build APIs of all size and complexity, and it especially shines when things get complex and I need lots of flexibility. Django Ninja is good for simple APIs, but [I wouldn't choose it over DRF myself](/articles/2024/drf-vs-ninja/).

## Versatility

It doesn't matter if I need to build a website using HTML templates, or a JSON API: Django can do both. FastAPI is strictly meant for building APIs and while it's absolutely a more performant option for building APIs than Django, I gladly trade that extra performance for the ORM, the migrations, the admin interface, and Django REST Framework.

I also don't really want to use two different systems; FastAPI for APIs and Django (or Flask) for websites. I'd rather be very good at using one hammer for two different jobs where maybe technically speaking that hammer isn't the optimal choice, compared to using two separate tools and not having the time to master either of them, if that makes sense.

## Community

There are countless open source packages available for Django, and when you run into a problem it's extremely easy to get help. Good chance someone else has run into the same problem and the answer is already on StackOverflow, and otherwise there's a huge pool of Django experts on StackOverflow and the Django forum and Discord server. The community is also very beginner-friendly, which didn't always seem the case with Flask (to be honest my experience is from a long time ago).

Come for the framework, stay for the community ❤️
