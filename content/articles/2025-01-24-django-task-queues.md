---
tags: django, python, review
summary: I use django-apscheduler to run a queue of scheduled tasks. Now I also need the ability to run one-off tasks and that turned out to not be so simple.
---

# Looking at Django task runners and queues

At [Sound Radix](https://www.soundradix.com/) we don’t use any async code in Django, but we do use a task queue for things we don’t want to run synchronously in the views (such as sending email), and for things that we need to run on a schedule. For example: every day we import sales reports from an external reseller, every month we generate and send a sales report to the managers, and every five seconds we send queued email.

For this we rely on two packages: [`django-mailer`](https://github.com/pinax/django-mailer/), and [`django-apscheduler`](https://github.com/jcass77/django-apscheduler). The former acts as an email backend in Django, and instead of directly sending emails it adds them to a queue in the database. The latter is for executing scheduled jobs - one of which is to send queued emails.

Our `django-apscheduler` script looks something like this:

#### <i class="fa-regular fa-file-code"></i> /soundradix/management/commands/runapscheduler.py
```python
from apscheduler.schedulers.blocking import BlockingScheduler
from apscheduler.triggers.cron import CronTrigger
from django.conf import settings
from django.core import management
from django.core.management.base import BaseCommand
from django_apscheduler.jobstores import DjangoJobStore
from django_apscheduler.models import DjangoJobExecution


def send_mail():
    # Send queued emails. Failures will be marked deferred.
    management.call_command("send_mail")


def retry_deferred():
    # Will move any deferred mail back into the normal queue.
    management.call_command("retry_deferred")


def purge_sessions():
    # Remove expired sessions from the database.
    management.call_command("clearsessions")


def import_xchange_daily():
    # Import Xchange sales data.
    management.call_command("import_xchange_daily")


def send_sales_report():
    # Send the monthly sales report to the managers.
    management.call_command("send_sales_report")


class Command(BaseCommand):
    help = "Runs APScheduler."

    def handle(self, *args, **options):
        scheduler = BlockingScheduler(timezone=settings.TIME_ZONE)
        scheduler.add_jobstore(DjangoJobStore(), "default")

        jobs = [
            (send_mail, CronTrigger(second="*/5")),
            (retry_deferred, CronTrigger(minute="*")),
            (purge_sessions, CronTrigger(day="*", hour="14", minute="27")),
        ]

        if settings.ENVIRONMENT == "PRODUCTION":
            jobs += [
                (import_xchange_daily, CronTrigger(day="*", hour="0", minute="2")),
                (send_sales_report, CronTrigger(month="*", day="1", hour="8", minute="13")),
            ]

        for method, trigger in jobs:
            scheduler.add_job(
                method,
                trigger=trigger,
                id=method.__name__,
                max_instances=1,
                replace_existing=True,
            )

        try:
            logger.info("Starting scheduler...")
            scheduler.start()
        except (KeyboardInterrupt, DjangoJobExecution.MultipleObjectsReturned):  # The job is already being executed
            logger.info("Stopping scheduler...")
            scheduler.shutdown()
            logger.info("Scheduler shut down successfully!")
```

We run this `manage.py runapscheduler` script via systemd with the following config file:

#### <i class="fa-regular fa-file-code"></i> /etc/systemd/system/scheduler.soundradix.com.service
```
[Unit]
Description=scheduler process for api.soundradix.com
After=api.soundradix.com.service
BindsTo=api.soundradix.com.service
PartOf=api.soundradix.com.service

[Service]
User=soundradix
Group=www-data
Restart=on-failure
WorkingDirectory=/home/soundradix/api.soundradix.com
ExecStart=/home/soundradix/.local/bin/uv run /home/soundradix/api.soundradix.com/manage.py runapscheduler

[Install]
WantedBy=multi-user.target
```

This is much better than just running `manage.py runapscheduler` on the production server, as this service now automatically starts when the server starts, it’ll restart if it crashes, and it restarts whenever the deploy script restarts the main `api.soundradix.com` service, to which this belongs.

So far so good, everything works perfectly fine without any problems. Hooray, article done! Well, not quite. The thing is that we now want to run one specific bit of code in the background, without it being a scheduled task. We have a long-running script that takes about a minute to complete, and this is started from a button in a Django view. But we can’t just start a function which takes a minute from a Django view, it blocks the process during this time and the user is waiting for the request to complete. Instead we want the button to add the work to a background queue. And sadly this is not possible with  `django-apscheduler`; it only handles periodically run (scheduled) tasks.

I see a few options for us.

## Option one: add django-tasks to the mix
Django will "soon" natively support background tasks (see [DEP 0014: Background workers](https://github.com/django/deps/blob/main/accepted/0014-background-workers.rst)), which will include a task-based email backend, so you can just use Django’s own email backend and it won’t block your view, it’ll be handled in a background task.

There is already a reference implementation available to use right now, called [`django-tasks`](https://github.com/RealOrangeOne/django-tasks). Sadly this only handles one-time tasks (not scheduled tasks), isn’t stable yet, and doesn’t add the task-based email backend for Django. So we’d have to stick with `django-mailer`, `django-apscheduler` for the scheduled tasks, and add `django-tasks` for the one-off tasks. We’d have two systemd processes running, which I am not terribly excited about.

## Option two: switch to django-q2
[Django Q2](https://django-q2.readthedocs.io/en/master/) got recommended to me, and at first glance it seems perfect: it handles both scheduled and one-off tasks, it can use the Django ORM so no need to install Redis or MongoDB, it’s under active development but stable. Sadly though scheduled tasks can at most run once a minute, because it follows cron, which has the same limitation. Sending emails with a delay of up to a minute isn’t really acceptable for us. When a new user registers a new account we want the confirmation link to be there instantaneously, not after a minute of waiting. We’re not going to run `django-q2` and `django-apscheduler` side by side, but there’s another solution: `django-mailer` has its own `runmailer` management command to poll the queue every 5 seconds, so we could run that as a systemd service. We’d still have two systemd processes running.

## Option three: just use the cron
All our scheduled tasks are run as management.py commands, so why not add all of them to the cron? We could have a text file in our repo that has the crontab config, something like this:

```
* * * * * ~/.local/bin/uv run ~/api.soundradix.com/manage.py send_mail
* * * * * ~/.local/bin/uv run ~/api.soundradix.com/manage.py retry_deferred
27 14 * * * ~/.local/bin/uv run ~/api.soundradix.com/manage.py purge_sessions
2 0 * * * ~/.local/bin/uv run ~/api.soundradix.com/manage.py import_xchange_daily
```

And the deploy script can then install the new cron by running `crontab < /path/to/file`. So we still have the config in our repo, we can’t forget to add a new task to the crontab on the server. The only problem is that cron can’t run more than once a minute, so we’re in the same situation with the `send_mail` command. To solve this we could have that run in a separate process, outside of cron -- with the `runmailer` command as a systemd service.

Then we still have to add `django-tasks` to the mix for the one-off background tasks, and its systemd service of course. The upside is that once this is part of Django itself that we can get rid of the `runmailer` service since it’ll be part of Django’s built-in version of `django-tasks`.

I like this option, as we’re prepared for the future where Django’s built-in task runner is the only systemd service we need to run, and for the scheduled tasks we just use the cron, which is intended exactly for this kind of work.

## Option four: Celery
[Celery](https://docs.celeryq.dev/en/latest/index.html) is the big player when it comes to task queues and periodic tasks. It even has native support for Django nowadays, so you don’t need to install other third party Django packages to make it work (it does require RabbitMQ or Redis though to store the tasks).

To me, reading through the documentation, it seems quite complex to set up. There are a lot of moving parts, and a big departure of the current setup. I think it’s too much just to add one-off tasks to our current system.

---

Honestly, none of these four options are exactly great. I think that simply adding `django-tasks` to the mix is the easiest option with the least amount of work. All the periodic tasks just keep working as they do, nothing changes there. It just doesn’t feel great that we’re using two different task runners.

I’m not sure if switching from `django-apscheduler` to `django-q2` is worth the effort when it can’t run tasks more than once a minute. For our mail job I can use Django-mailer’s `runmailer` management command, but what about other future jobs which we might want to run twice a minute for example? It just doesn’t seem a future-proof option. The exact same problem exists if we’d move to pure cron for the scheduled tasks, but at least we don’t add another dependency (`django-q2`) to the mix, so I’d prefer that over switching to `django-q2`.

Switching to Celery seems like way too much work just to add non-scheduled tasks.

It seems I have to choose between running `django-apscheduler` and `django-tasks` side-by-side, or running `django-tasks` in combination with cron for scheduled tasks (and `runmailer` for now). Since both options add `django-tasks`, I think it makes sense to just start there and keep `django-apscheduler` alone. I can always replace that with cron later on.