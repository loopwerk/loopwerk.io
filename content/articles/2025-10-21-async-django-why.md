---
tags: django, insights
summary: Async Django is a huge technical achievement, but it has been quietly rejected by the community it was built for; most developers stick to simpler, proven solutions.
---

# Async Django: a solution in search of a problem?

A client recently asked me a seemingly simple question:

> If we switch our Django backend to run on an ASGI server, will it get faster?

The short answer is no. The slightly longer answer is that switching the server from WSGI to ASGI does nothing on its own. To see any change, you have to start rewriting your views to be `async`, and even then, the benefits are marginal at best for 99% of web applications. For their specific workload, offloading heavy tasks to a background worker is a far simpler and more effective solution.

This conversation got me thinking. My experience with async in the Django ecosystem is limited to Django Channels for WebSocket support. It works, but the setup is complex. If I were starting today, I'd probably use Server-Sent Events, or maybe build a tiny, separate WebSocket server in TypeScript and have my Django app post updates to it. Simple, decoupled, and way less complex. But I have never used async views, and nobody that I know has used Async Django apart from Channels. No async views or async database calls.

So if the performance gains are elusive and the complexity is high, why did the Django team pour countless hours into a multi-year effort to bolt async onto a fundamentally synchronous framework? I decided to dig in. The more I looked, the more it felt like a feature whose complexity just doesn't match its usefulness for the average Django developer.

## The promise: why bother with async at all?

The official justification for async Django is to better handle I/O-bound workloads. In simple terms, this is any task where your code spends most of its time waiting for something else: a database query to return, an external API to respond, or a file to be read.

In a traditional synchronous (WSGI) world, when a request is waiting, it holds a worker process hostage. If you have four workers and four requests are all waiting on slow API calls, your entire server is blocked. A fifth user has to wait in line.

Async (ASGI) flips this model. An `async` view can say, "I'm waiting for this API call", and hand control back to the event loop, which can then start work on another request. When the API call finishes, the event loop picks the original task back up. This allows a single process to juggle hundreds or even thousands of concurrent connections, making it a good fit for:

- **High-concurrency APIs:** Handling a massive number of simultaneous, slow requests.
- **Real-time features:** WebSockets, live notifications, and chat applications.
- **Long-polling/Streaming:** Keeping a connection open to stream data to a client.

As Andrew Godwin, the champion of this effort, [put it](https://github.com/django/deps/blob/main/accepted/0009-async.rst), the goal is to let Django handle things like ORM queries in parallel, views to query external APIs without blocking, and serve slow-response/long-poll endpoints alongside each other efficiently.

It's not about making your code run faster; it's about making your server _not block the world_ while it waits.

## The reality: a more complicated framework

The practical reality is that after years of effort to add async functionality to Django, it is now a dual-mode framework. For many features, there are two ways of doing things: `save()` and `asave()`, a sync cache and an async cache.

And the heart of Django - the ORM - is still a work in progress. To call a synchronous piece of code from an `async` view, you must wrap it in `sync_to_async`. It works, but it's a constant reminder that the async story is far from done. It also makes the documentation harder to navigate for new developers.

If you really need async-first performance, frameworks like FastAPI [might be better](https://github.com/AakarSharma/fastapi-vs-django-benchmark). Built on Starlette, FastAPI is async from the ground up and consistently outperforms Django in high-concurrency benchmarks. That's partly because of async, and partly because it's a lighter framework with less built-in machinery. No batteries included.

> [!UPDATE]
> Hackeryarn wrote a really interesting [article with benchmarks](https://hackeryarn.com/post/async-python-benchmarks/) showing that in most real-world scenarios, like when a database is involved, sync Django actually outperforms FastAPI. His conclusion: _"If your service talks to a database directly, it is unlikely that your service is the bottleneck. To get the best performance you should stick with a sync webserver and ensure that you pool your database connections. As the ecosystem stands, async introduces too much overhead to make sense."_

## A massive and unending effort

The work on async Django officially began in 2018 with Godwin's proposal ([DEP 0009](https://github.com/django/deps/blob/main/accepted/0009-async.rst)) and has been a part of every major release since.

- **Django 3.0 (2019):** Introduced basic ASGI support.
- **Django 3.1 (2020):** Delivered the first `async` views, middleware, and tests.
- **Django 4.0 (2021):** Added an async cache interface.
- **Django 4.1 (2022):** Delivered async-capable class-based views and the first async ORM methods.
- **Django 4.2 & 5.0 (2023):** Continued the rollout with more async model methods, signals, and helpers.
- **Django 5.2 (2025):** Delivered async user model methods, permissions, and auth backends.

This is a colossal amount of work by many core contributors. I wonder if it was worth it, and I am certainly not alone with this question. Will it ever be finished? And at what cost? Even Andrew Godwin [said](https://forum.djangoproject.com/t/is-dep009-async-capable-django-still-relevant/30132/2) the following:

> I do think we'll never be able to make it fully async only in the ORM core, as the slowdown in sync mode will just be too much. Given that, I'm very realistic about the fact that we may just not be able to write and maintain what are two parallel ORM cores

## My verdict: an impressive feat for a problem that rarely exists

Adding async support to Django is an impressive piece of open-source engineering. The core team managed to graft a fundamentally different programming model onto a mature, synchronous framework without breaking it for the millions of users who rely on it.

But a feature's success is measured by how useful it is, and to justify the permanent complexity it adds, it needs to solve a common problem better than existing solutions do. Async Django doesn't.

For the most common performance bottlenecks in a web application (sending emails, processing images, generating reports) the answer has never been to make the web request itself asynchronous. The established solution is to offload the work to a background task runner like Celery. That pattern is simpler to reason about, and it scales better for heavy loads.

Django's greatest strength has always been its pragmatic philosophy: the "framework for perfectionists with deadlines". It provides sensible defaults and clear solutions so you can build things quickly. Async support, with its dual APIs, feels like a departure from that.

So, was it worth it? For the developer in the trenches, my answer is a clear no.

And hardly anybody is using it. I personally know nobody who reaches for `async def` in their Django projects, apart from the necessity of using Channels. The data backs this up: according to the official [Django Developer Survey from 2024](https://blog.jetbrains.com/pycharm/2024/06/the-state-of-django/), conducted by JetBrains and the Django Software Foundation with around 4,000 respondents, only 14% of Django developers actually use async views. And that's despite this feature being available since 2020. Worse: when Django developers do need async capabilities, they're more likely to reach for FastAPI than Django's own async features.

To me that reads as a silent consensus, not developer inertia. When faced with a slow task, the pragmatic, battle-tested answer remains the same as it always has been: "put it in the background". That simple pattern is the true Django way, and async remains a solution for a problem most of us will never have. A six-year engineering marathon that 86% of Django developers have chosen not to run.

I wonder if Django is falling prey to the sunken cost fallacy. What other improvements could have been made to the framework with the thousands of hours poured into async? Instead of trying to be competitive on every front, maybe Django's strength lies in doubling down on what it has always done best: being a batteries-included framework for rapid, pragmatic development. Many developers who need async are leaving for FastAPI anyway, which makes the entire effort feel like it may have been wasted.
