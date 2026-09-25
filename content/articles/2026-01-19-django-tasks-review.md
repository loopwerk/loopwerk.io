---
tags: django, review
summary: Background tasks have always been essential in Django projects. Django 6.0 finally acknowledges that fact, but its new tasks framework stops short of what real apps need.
---

# Django 6.0 Tasks: a framework without a worker

I've been using Django for 17 years now, and in all that time, Django has never had a first-party answer for how to deal with background tasks. Things like sending emails, processing uploads, or generating reports should not happen in the normal request/response cycle. While the view is busy processing, it blocks the response, and with it one of your workers. Let's say you have 8 workers and they're all resizing an image into a thumbnail: your website is now no longer accepting new requests.

And for all this time the standard solution has always been to move this work into a background task with third-party tools like Celery or RQ. Or management commands executed on a schedule with cron (my favorite solution).

That worked, but it was never ideal. Every non-trivial web application needs background tasks, and leaving this up to third-party tools meant that they all had to make their own choices. Each with its own trade-offs and infrastructure requirements. It's yet one more thing that makes Django complex to deploy.

## What Django 6.0 adds

Django 6.0 is the first release that acknowledges this problem at the framework level by introducing a built-in tasks framework. It defines the concept of background work in a Django-native way.

Sadly, that's where it stops. What's notable is what this framework is missing.

Django's task system only deals with one-off execution, and it doesn't do anything about scheduling or retries. That wouldn't be so bad if one-off tasks were the only use case for background work, but that's simply not true. In the real world tasks need to run later, keep repeating on a schedule, or keep retrying until they succeed. Django still offers none of this.

What's worse: since Django ships without a worker process and without a production-ready backend, even those one-off tasks don't actually run in the background unless you install third-party tools.

What makes this especially frustrating is that Django had an opportunity to do more. [DEP 14](https://github.com/django/deps/blob/main/accepted/0014-background-workers.rst) explicitly talks about a database backend, deferring tasks to run at a specific time in the future, and even mentions a new email backend that offloads work to the background. None of that has made it into Django itself. Instead, we only got the abstraction, without an implementation. Why wasn't the database worker from [django-tasks](https://github.com/RealOrangeOne/django-tasks) at least added to Django? This would have covered a large percentage of real-world use cases. 

Look, I understand that building features takes time. But you only get to introduce a feature once, and I don't get why shipping such a limited framework was better than waiting a few more releases for a complete story. Right now, in its current form, the tasks framework mostly confuses newcomers. The [official documentation](https://docs.djangoproject.com/en/6.0/topics/tasks/) even admits that it's incomplete, but offers very little information beyond a link to the [Community Ecosystem](https://www.djangoproject.com/community/ecosystem/) page.

## What Django should focus on next

With Django 6.0 background processing still requires third-party tools for scheduling, retries, delayed execution, monitoring, and scaling workers - just like before.

DEP 14 also explicitly states that the intention is *not* to build a replacement for Celery or RQ, because "that is a complex and nuanced undertaking". I think this is a mistake! Django positions itself as a batteries-included framework, and what I just described are basic requirements for any mildly serious project.

Otherwise, what is even the point of Django's tasks framework? Let's assume that it'll get a production-ready backend and worker at some point. Great, but it can still only run one-off tasks. As soon as you need to schedule (recurring) tasks, you still need to reach for a third-party solution. I think Django should have a first-party answer for the most common cases, even if it's complex to build. Because otherwise we could've just done nothing and stayed with the existing third-party solutions.

## Conclusion

Django 6.0 is an important step for background tasks by finally giving them a place in Django itself. But by limiting it to an abstraction of one-off tasks, and also leaving execution entirely undefined, I don't think we developers are much better off yet. 

If I sound disappointed, it's because I am. I just don't understand the point of adding such a bare-bones tasks framework when the reality is that most real-world projects still need to use third-party packages. There is still much to do, but at least the foundation is there now. I hope that Django builds something on top that can replace [django-apscheduler](https://github.com/jcass77/django-apscheduler), [django-rq](https://github.com/rq/django-rq), and [django-celery](https://github.com/celery/django-celery). I believe that it can, and that it should.
