---
tags: django, python, review
summary: Background tasks have always been essential in Django projects. Django 6.0 finally acknowledges that fact, but its new Tasks framework stops short of what real apps need.
---

# Django 6.0 Tasks: a framework without a worker

Background tasks have always existed in Django projects. They just never existed in Django itself.

For a long time, Django focused almost exclusively on the request/response cycle. Anything that happened outside that flow, such as sending emails, running cleanups, or processing uploads, was treated as an external concern. The community filled that gap with tools like Celery, RQ, and cron-based setups.

That approach worked but it was never ideal. Background tasks are not an edge case. They are a fundamental part of almost every non-trivial web application. Leaving this unavoidable slice entirely to third-party tooling meant that every serious Django project had to make its own choices, each with its own trade-offs, infrastructure requirements, and failure modes. It's one more thing that makes Django complex to deploy.

Django 6.0 is the first release that acknowledges this problem at the framework level by introducing a built-in tasks framework. That alone makes it a significant release. But my question is whether it actually went far enough.

## What Django 6.0 adds

Django 6.0 introduces a brand new tasks framework. It’s not a queue, not a worker system, and not a scheduler. It only defines background work in a first-party, Django-native way, and provides hooks for someone else to execute that work.

As an abstraction, this is clean and sensible. It gives Django a shared language for background execution and removes a long-standing blind spot in the framework. But it also stops there.

Django's task system only supports one-off execution. There is no notion of scheduling, recurrence, retries, persistence, or guarantees. There is no worker process and no production-ready backend. That limitation would be easier to accept if one-off tasks were the primary use case for background work, but they are not. In real applications, background work is usually time-based, repeatable, and failure-prone. Tasks need to run later, run again, or keep retrying until they succeed.

## A missed opportunity

What makes this particularly frustrating is that Django had a clear opportunity to do more.

[DEP 14](https://github.com/django/deps/blob/main/accepted/0014-background-workers.rst) explicitly talks about a database backend, deferring tasks to run at a specific time in the future, and a new email backend that offloads work to the background. None of that has made it into Django itself yet. Why wasn't the database worker from [django-tasks](https://github.com/RealOrangeOne/django-tasks) at least added to Django, or something equivalent? This would have covered a large percentage of real-world use cases with minimal operational complexity.

Instead, we got an abstraction without an implementation.

I understand that building features takes time. What I struggle to understand is why shipping such a limited framework was preferred over waiting longer and delivering a more complete story. You only get to introduce a feature once, and in its current form the tasks framework feels more confusing than helpful for newcomers. The [official documentation](https://docs.djangoproject.com/en/6.0/topics/tasks/) even acknowledges this incompleteness, yet offers little guidance beyond a link to the [Community Ecosystem](https://www.djangoproject.com/community/ecosystem/) page. Developers are left guessing whether they are missing an intended setup or whether the feature is simply unfinished.

## What Django should focus on next

Currently, with Django 6.0, serious background processing still requires third-party tools for scheduling, retries, delayed execution, monitoring, and scaling workers. That was true before, and it remains true now. Even if one-off fire-and-forget tasks are all you need, you still need to install a third party package to get a database backend and worker.

DEP 14 also explicitly states that the intention is *not* to build a replacement for Celery or RQ, because "that is a complex and nuanced undertaking". I think this is a mistake. The vast majority of Django applications need a robust task framework. A database-backed worker that handles delays, retries, and basic scheduling would cover most real-world needs without any of Celery's operational complexity. Django positions itself as a batteries-included framework, and background tasks are not an advanced feature. They are basic application infrastructure.

Otherwise, what is the point of Django's Task framework? Let's assume that it'll get a production-ready backend and worker soon. What then? It can still only run one-off tasks. As soon as you need to schedule tasks, you still need to reach for a third-party solution. I think it should have a first-party answer for the most common cases, even if it's complex.

## Conclusion

Django 6.0's task system is an important acknowledgement of a long-standing gap in the framework. It introduces a clean abstraction and finally gives background work a place in Django itself. This is good! But by limiting that abstraction to one-off tasks and leaving execution entirely undefined, Django delivers the least interesting part of the solution.

If I sound disappointed, it's because I am. I just don't understand the point of adding such a bare-bones Task framework when the reality is that most real-world projects still need to use third-party packages. But the foundation is there now. I hope that Django builds something on top that can replace [django-apscheduler](https://github.com/jcass77/django-apscheduler), [django-rq](https://github.com/rq/django-rq), and [django-celery](https://github.com/celery/django-celery). I believe that it can, and that it should.
