---
tags: django, personal
summary: Django turned 20! A look back at my 16 years with it, my favorite packages, and what I'd love to see in the future.
---

# Happy 20th birthday, Django

Django turned 20 [a few days ago](https://www.djangoproject.com/weblog/2025/jul/13/happy-20th-birthday-django/), which is a huge milestone for a piece of software. Congratulations to the project, all its maintainers, and the community. Amazingly enough I've been using Django for 16 of those years, and I wanted to share a bit about my journey and my favorite packages.

## My journey

When I started with Django in 2009 I worked for a software agency in Groningen, the Netherlands. We built web apps for local government, and everything was server-rendered HTML, with a bit of jQuery sprinkled in. I [didn't like everything about Python and Django](/articles/2009/things-i-hate-about-python-and-django/), but switching to Jinja2 helped a lot.

In 2012 my focus shifted dramatically. I quit my job as a web developer, moved to Iceland, and started making iOS apps full-time. I was still using Django though; I used Django REST Framework to create the APIs that powered these mobile apps.

Fast forward to 2023, and I've [come full circle](/articles/2025/thoughts-on-apple/), returning to full-time web development. These days, I mostly use SvelteKit on the frontend with Django REST Framework still on the backend. My latest project is pure Django again, [using Alpine AJAX](/articles/2025/alpine-ajax-django/) for interactivity. It feels like returning to the good ol' days of server-rendered apps, except without the full page refreshes and jQuery spaghetti.

The way I deploy my Django apps has also changed a lot over the years. I started with Heroku, which felt pretty magical at the time. That got quite expensive though, so that led me to [self-hosting on a bare metal server](/articles/2023/setting-up-debian-11/). It saved a lot of money, but I also discovered that I don't really enjoy the ops side of things. Too many things that can break in completely unexpected and hard-to-debug ways, bringing down the website.

More recently, I've found a [happy medium with Coolify](/articles/2025/coolify-django/), a self-hosted PaaS that gives me a Heroku-like experience without the bills. It's pretty great, and I highly recommend it.

## My favorite dependencies

Speaking of recommendations: my favorite dependencies that I return to again and again. Some of these should really be included in Django itself.

### Core Django extensions

- [python-dotenv](https://pypi.org/project/python-dotenv/): loads environment variables from `.env` files.
- [dj-database-url](https://pypi.org/project/dj-database-url/): parses database configuration from a URL, perfect in combination with python-dotenv. See the article [How I configure my Django projects](/articles/2024/django-settings/) I wrote in 2024.
- [django-cors-headers](https://pypi.org/project/django-cors-headers/): handles CORS headers. Crucial for when your frontend and backend are on different domains.
- [sentry-sdk](https://pypi.org/project/sentry-sdk/): Sentry's official SDK. I doubt Sentry needs an introduction.
- [parameterized](https://pypi.org/project/parameterized/): I don't use pytest in my Django projects, instead [I prefer to stick with Django's built-in test framework](/articles/2026/django-tests-underrated/). Less is more, use the batteries that are included. But the parameterized package helps a lot when you need to run the same test with different inputs.

### Django REST Framework

- [djangorestframework](https://pypi.org/project/djangorestframework/): still my preferred way to build APIs in Django.
- [djangorestframework-camel-case](https://pypi.org/project/djangorestframework-camel-case/): automatically converts between Python's snake_case and JavaScript's camelCase.
- [drf-spectacular](https://pypi.org/project/drf-spectacular/): generates OpenAPI schemas from your DRF code. Much better than the built-in API docs.
- [drf-nested-routers](https://pypi.org/project/drf-nested-routers/): provides nested routing for DRF viewsets.
- [drf-action-serializers](https://pypi.org/project/drf-action-serializers/): my own package that allows different serializers for different viewset actions.

### Frontend

- [django-tailwind-cli](https://pypi.org/project/django-tailwind-cli/): integrates Tailwind CSS with Django using the standalone CLI. No Node.js required! Check out [this article](/articles/2025/django-tailwind-production/) to learn about cache-busting Tailwind's generated CSS in production.
- [django-template-partials](https://pypi.org/project/django-template-partials/): reusable template fragments that work great with Alpine AJAX.
- [django-browser-reload](https://pypi.org/project/django-browser-reload/): automatically reloads your browser during development. A massive time-saver.

### Infrastructure

- [django-mailer](https://pypi.org/project/django-mailer/): queues emails for sending later, preventing email sending from blocking requests.
- [django-apscheduler](https://pypi.org/project/django-apscheduler/): a simple way of adding scheduling features to Django, with minimal dependencies. I use it for django-mailer and other tasks that need to run on a schedule.
- [django-storages](https://pypi.org/project/django-storages/): custom storage backends for Django. Essential for S3 or other cloud storage.

## Django's biggest strengths

There's got to be a reason I'm still happily using Django after 16 years, right? I've actually [written about it before](/articles/2024/django-vs-flask-vs-fastapi/), but in short it's the ORM, the migration system, and the Admin. 

And then there's the community, which is famously friendly. You can find an answer to almost any problem, and there are countless high-quality packages to extend the framework. You also don't have to worry about crazy breaking changes every six months, unlike some other ecosystems (looking at you, Svelte).

Of course Django isn't perfect. For example I think it's high time that the Admin gets a modern overhaul. I also think a REST framework should be included in the core. And finally, I'd love for the ORM to lean more on Python type hints and Pydantic-style models, like FastAPI does.

## Shameless plugs

Over the years, I've created several Django packages to scratch my own itches:

- [django-generic-mail](https://pypi.org/project/django-generic-mail/): makes sending transactional emails easier with a template-based approach.
- [django-generic-notifications](https://pypi.org/project/django-generic-notifications/): a flexible notification system.
- [django-jinja-render-block](https://pypi.org/project/django-jinja-render-block/): render specific blocks from Jinja2 templates.
- [django-rss-filter](https://pypi.org/project/django-rss-filter/): filter and transform RSS feeds. Powers [RSSFilter.com](https://rssfilter.com).
- [django-vrot](https://pypi.org/project/django-vrot/): a collection of Django templatetags and middleware for common web development tasks.
- [drf-action-serializers](https://pypi.org/project/drf-action-serializers/): use different serializers for different viewset actions in Django REST Framework.

I've also written [quite a few](/articles/tag/django/) articles on Django, and have been made a [Django Software Foundation member](https://www.djangoproject.com/foundation/individual-members/).

Here's to another 20 years. Happy birthday, Django!
