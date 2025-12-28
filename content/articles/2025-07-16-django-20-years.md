---
tags: django, python, personal
summary: Celebrating Django's 20th birthday by looking back at 16 years of personal Django usage, how it evolved, favorite packages, and what I'd love to see in the future.
---

# Django at 20: a personal journey through 16 years

Django turned 20 [a few days ago](https://www.djangoproject.com/weblog/2025/jul/13/happy-20th-birthday-django/), which is a remarkable milestone for any software project. I've been along for most of that ride, starting my Django journey in September 2009. That's almost 16 years ago! It's been fascinating to watch both Django and my use of it evolve over time.

## From server-rendered pages to APIs and back

When I started with Django in 2009, it was a different world. Everything was server-rendered, with a bit of jQuery sprinkled in. I wrote my very [first Django article](/articles/2009/how-dynamically-add-fields-django-model/) in November 2009 about dynamically adding fields to models. This was quickly followed by articles on what [I didn't like about Python and Django](/articles/2009/things-i-hate-about-python-and-django/) and [how to use Jinja2 templates in Django](/articles/2009/using-jinja/), which solved some of my pain points.

In 2012, my focus shifted dramatically. I went from full-time web developer to full-time iOS developer. Django didn't disappear from my life though, it just changed roles. Instead of building full websites, I was creating REST APIs to power mobile apps, which is when I discovered Django REST Framework.

Fast forward to 2023, and I've [come full circle](/articles/2025/thoughts-on-apple/), returning to full-time web development. These days, I mostly use SvelteKit on the frontend with Django REST Framework providing the API. But my latest project is pure Django again (without Jinja2 even), [using Alpine AJAX](/articles/2025/alpine-ajax-django/) for interactivity. It feels like returning to the old days of server-rendered apps, except without the full page refreshes and jQuery spaghetti. There's something very refreshing about the simplicity.

## The deployment evolution

My deployment story has changed as much as my use of Django. I started with the push-to-deploy magic of Heroku. Eventually, my desire for more control led me to self-hosting on a bare metal server, where I configured everything myself with systemd scripts and Nginx. I documented this journey in [Setting up a Debian 11 server for SvelteKit and Django](/articles/2023/setting-up-debian-11/). It gave me complete control but came with significant operational overhead.

More recently, I've found a happy medium with Coolify, a self-hosted PaaS that gives me a Heroku-like experience on my own hardware, as I detailed in my article on [hosting Django with Coolify](/articles/2025/coolify-django/). It provides the git-based, zero-downtime deployments I want without the manual configuration overhead.

## My favorite dependencies

No framework is an island, and Django's rich ecosystem of third-party packages is a huge part of its power. Over the years, I've collected a set of favorite dependencies that I return to again and again.

### Core Django extensions

- [**python-dotenv**](https://pypi.org/project/python-dotenv/): Loads environment variables from `.env` files. Essential for local development.
- [**dj-database-url**](https://pypi.org/project/dj-database-url/): Parses database configuration from a URL, perfect in combination with python-dotenv. See the article [How I configure my Django projects](/articles/2024/django-settings/) I wrote in 2024.
- [**django-cors-headers**](https://pypi.org/project/django-cors-headers/): Handles CORS headers for when your frontend and backend are on different domains. Crucial for my SvelteKit-on-the-frontend projects.
- [**sentry-sdk**](https://pypi.org/project/sentry-sdk/): Error tracking that has saved me countless hours of debugging in production.
- [**parameterized**](https://pypi.org/project/parameterized/): I don't use pytest in my Django projects, instead I prefer to stick with Django's built-in test framework. Less is more, use the batteries that are included. But the parameterized package helps a lot when you need to run the same test with different inputs.

### Django REST Framework ecosystem

- [**djangorestframework**](https://pypi.org/project/djangorestframework/): The gold standard for building APIs in Django. Incredibly powerful and well-designed.
- [**djangorestframework-camel-case**](https://pypi.org/project/djangorestframework-camel-case/): Automatically converts between Python's snake_case and JavaScript's camelCase, so that the API feels right in either environment.
- [**drf-spectacular**](https://pypi.org/project/drf-spectacular/): Generates OpenAPI schemas from your DRF code. Much better than the built-in API docs.
- [**drf-nested-routers**](https://pypi.org/project/drf-nested-routers/): Provides nested routing for DRF viewsets. Clean URLs for related resources.
- [**drf-action-serializers**](https://pypi.org/project/drf-action-serializers/): My own package that allows different serializers for different viewset actions.

### Frontend and styling

- [**django-tailwind-cli**](https://pypi.org/project/django-tailwind-cli/): Integrates Tailwind CSS with Django using the standalone CLI. No Node.js required! Check out [this article](/articles/2025/django-tailwind-production/) to learn about cache-busting Tailwind's generated CSS in production.
- [**django-template-partials**](https://pypi.org/project/django-template-partials/): Reusable template fragments that work great with Alpine AJAX.
- [**django-browser-reload**](https://pypi.org/project/django-browser-reload/): Automatically reloads your browser during development. A massive time-saver.

### Infrastructure

- [**django-mailer**](https://pypi.org/project/django-mailer/): Queues emails for sending later. Prevents email sending from blocking requests.
- [**django-apscheduler**](https://pypi.org/project/django-apscheduler/): A pretty simple way of adding scheduling features to Django, with minimal dependencies. I use it for django-mailer and other tasks that need to run on a schedule.
- [**django-storages**](https://pypi.org/project/django-storages/): Custom storage backends for Django. Essential for S3 or other cloud storage.

## Django's enduring strengths

There's a reason I've stuck with Django for so long. While other frameworks have come and gone, Django's core strengths have only become more apparent.

First and foremost are the "big three": the ORM, the migrations system, and the Admin. When I started in 2009, migrations didn't even exist, but today, they are arguably Django's killer feature. The ORM is a joy to use, and the built-in Admin is an unparalleled tool for getting a project off the ground and managing data. As I've written before, these three features are the main reason [why I still choose Django over frameworks like Flask or FastAPI](/articles/2024/django-vs-flask-vs-fastapi/).

Beyond the code, the community is one of Django's greatest assets. It's mature, stable, and welcoming. You can find an answer to almost any problem, and there are countless high-quality packages to extend the framework. This maturity also leads to stability; you don't have to worry about crazy breaking changes every six months, which is a breath of fresh air compared to the churn in other ecosystems.

## Things I'd wish to see differently

Despite my affection for it, Django isn't perfect. I'd love to see the Django Admin get a modern overhaul. It's incredibly functional, but its interface feels dated. I also believe it's time for a capable REST framework to be included in the core. So many Django projects today are APIs that it feels like a natural evolution. Finally, seeing the ORM lean more heavily on standard Python type hints and Pydantic-style models, much like FastAPI does, would be a fantastic modernization.

## My Django contributions

Over the years, I've created several Django packages to scratch my own itches:

- [**django-generic-mail**](https://pypi.org/project/django-generic-mail/): Makes sending transactional emails easier with a template-based approach.
- [**django-generic-notifications**](https://pypi.org/project/django-generic-notifications/): A flexible notification system for Django applications.
- [**django-jinja-render-block**](https://pypi.org/project/django-jinja-render-block/): Render specific blocks from Jinja2 templates. Great for AJAX responses.
- [**django-rss-filter**](https://pypi.org/project/django-rss-filter/): Filter and transform RSS feeds. Powers [RSSFilter.com](https://rssfilter.com).
- [**django-vrot**](https://pypi.org/project/django-vrot/): A collection of Django templatetags and middleware for common web development tasks.
- [**drf-action-serializers**](https://pypi.org/project/drf-action-serializers/): Use different serializers for different viewset actions in Django REST Framework.

I've also written [quite a few](/articles/tag/django/) articles on Django, and have been made a [Django Software Foundation member](https://www.djangoproject.com/foundation/individual-members/).

## Looking forward

Django at 20 is in a great place. It's mature without being stagnant, stable without being boring. The framework has evolved thoughtfully over the years, adding features like async support while maintaining backward compatibility.

For new projects, I still reach for Django. [Not Flask, not FastAPI](/articles/2024/django-vs-flask-vs-fastapi/) — Django. The "batteries included" philosophy means I can focus on building features instead of gluing libraries together. The boring, stable foundation lets me be creative where it matters.

Here's to another 20 years of Django. May it continue to be the reliable, productive framework that lets us turn ideas into working applications with minimum fuss. Happy birthday, Django!
