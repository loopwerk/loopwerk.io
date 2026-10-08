---
tags: django, insights
summary: Async Django is a huge technical achievement, but it solves a problem most sites simply don't have, while adding a lot of complexity.
---

# Was async Django worth it?

A client recently asked me a seemingly simple question:

> If we switch our Django backend to run on an ASGI server, will it get faster?

I had to disappoint the client and tell him that switching from WSGI to ASGI does nothing on its own. To see any change, we'd have to start rewriting all views to be async, and even then, the benefits would be tiny because they don't have the kinds of problems that async is meant to solve.

This got me thinking. I have never used async views, and neither has anybody that I know. Am I missing something? Why did the Django team pour countless hours into this multi-year effort to add async support? Surely they had a good reason, right?

## What does async solve

Let me start by explaining why async views wouldn't make my client's site faster, and what kind of problems it is supposed to solve.

In a nutshell, async Django is better at handling requests where your code ends up waiting for something, like a database query to return, an external API to respond, or a file to be read from disk.

When a synchronous (WSGI) request is waiting, it blocks the worker process. So if you have four workers, and four requests are waiting on slow API calls, your entire server is effectively blocked. New visitors have to wait in line, looking at a blank page trying to load. Not great.

Async (ASGI) is more like a timeshare. When an async view is waiting for something, like an API call, it can tell the event loop to go on with other tasks, until the API call is finished, and then it'll continue with the view. This allows a single process to handle hundreds of concurrent connections, without needing hundreds of workers.

So async is not really about making your code run faster, and it wouldn't have made a difference for my client. It's about not blocking your server while it's busy with slow tasks. Most websites don't really run into these kinds of problems though.

## But at what cost

It's a noble goal, to make Django better at handling more requests without needing more workers. It's been a big success in the Node world, where a simple Express server can handle thousands of requests with a single worker.

But Express didn't start out as a synchronous framework where async then had to be bolted onto, like with Django. And I think there are two major downsides to doing it this way, the first of which is the added complexity.

Django is now basically a dual-mode framework, with two ways of doing many things: `save()` and `asave()`, a sync cache and an async cache, and so on. It makes the documentation harder to navigate, especially for new developers. Async and non-async code don't work well together, which causes warts like wrapping your code in `sync_to_async` calls. Because there are these two modes, code becomes more complex to reason about.

The second downside is the sheer amount of work that went into this - and it's nowhere near done. It started in 2019 with Andrew Godwin's proposal ([DEP 0009](https://github.com/django/deps/blob/main/accepted/0009-async.rst)) and has been a part of every major release since. This adds up to a colossal amount of work by many core contributors. Will it ever be finished? And at what cost? Will it have been worth it?

Even Andrew has [said](https://forum.djangoproject.com/t/is-dep009-async-capable-django-still-relevant/30132/2) the following:

> [W]e’ll never be able to make it fully async-only in the ORM core, as the slowdown in sync mode will just be too much. Given that, I’m very realistic about the fact that we may just not be able to write and maintain what are two parallel ORM cores

So they can't make the ORM async-only, and maintaining two ORM cores is madness. Does that mean the ORM stays sync-only? Doesn't that remove a huge argument in favor of Async Django?

There's also the question of performance. Hackeryarn wrote a really interesting [article with benchmarks](https://hackeryarn.com/post/async-python-benchmarks/) showing that in most real-world scenarios, like when a database is involved, sync Django actually outperforms FastAPI, which is fully asynchronous from the ground up. His conclusion: 

> If your service talks to a database directly, it is unlikely that your service is the bottleneck. To get the best performance you should stick with a sync webserver and ensure that you pool your database connections. As the ecosystem stands, async introduces too much overhead to make sense.

"Async introduces too much overhead to make sense". Ouch. And yeah, from what I've seen, I agree.

## My verdict

I want to start by acknowledging the impressive work by the core team, who managed to add an async programming model onto a mature and fundamentally synchronous framework, without breaking it for its millions of users.

But, was that effort worth it? I would say "probably not".

For the most common performance bottlenecks in a web application (sending emails, processing images, generating reports) the best solution is still to offload the work to a background task runner like Celery. That pattern is much simpler to reason about, and it scales better for heavy loads. We never needed async to deal with these problems!

The proof is the fact that hardly anybody is using it. Just look at the official [Django Developer Survey from 2024](https://blog.jetbrains.com/pycharm/2024/06/the-state-of-django/), conducted by JetBrains and the Django Software Foundation. Out of ~4,000 respondents, only 14% of Django developers actually use async views. And that's despite this feature being available since 2020. Worse: when Django developers do need async capabilities, they're more likely to reach for FastAPI than Django's own async features.

I wonder if Django is falling prey to the sunken cost fallacy. What other improvements could have been made to the framework with the thousands of hours poured into async? Instead of trying to be everything for everyone, maybe Django should be doubling down on what it has always done best: being a batteries-included framework for rapid, pragmatic development. If that means it's less suitable for high-concurrency APIs that need to handle loads of slow requests, I think that's a fair trade to make.

A feature's success is measured by how useful it is, not by how impressive the effort was. And to justify the complexity it adds, it needs to solve a common problem better than existing solutions do. Async Django simply doesn't.