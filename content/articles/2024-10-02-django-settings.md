---
tags: django, python
summary: There are many ways to configure Django, like multiple settings files or .env files. Here's how I do it.
---

# How I configure my Django projects

When you create a brand new Django project using the `django-admin startproject` command it'll have a `settings.py` file with all settings configured inside of it. This is nice and easy to get started and if you'd never deploy your website, it would work just fine. But of course things get more complicated: you're going to need separate settings for your live production site, your staging site, your continuous integration server, etc.

For example when you're going to deploy your site, you're going to want to configure at least these settings:

```python
# Some of the settings in settings.py
SECRET_KEY = "super-secret"
DEBUG = True
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    }
}
```

When I just got started with Django, the way I dealt with having different settings for different environments was to have multiple settings files:

- A base `settings.py` file with all the common settings
- And a `settings_[environent].py` file per environment which imports the base settings, and then adds its own settings.

For example I'd have a `settings_production.py` file that looked like this:

```python
from settings import *

DEBUG = False

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "mydatabase",
        "USER": "username",
        "PASSWORD": "password",
    }
}
```

You'd then run your Django site using this `settings_production.py` file - by passing that as a parameter to whatever you use to run your Django instance (like gunicorn).

While this multiple-settings-files solution works, I find it pretty hard to work with, since you now always have to deal with multiple files. You don't have a single overview of all settings for an environment. There's also the problem that database passwords and the `SECRET_KEY` are committed to git, which is of course a huge no-no.

So at some point, many years ago, I switched to [django-environ](https://github.com/joke2k/django-environ), a popular package that allows you to read an `.env` file and use those values in your `settings.py` file. And this `.env` file is **not committed to git**, instead you create this locally and on your server.

Your `.env` file has the config values:

```text
DEBUG=True
SECRET_KEY=secret-key
DATABASE_URL=postgres://username:password@localhost:5432/mydatabase
```

And the `settings.py` file uses these values:

```python
import environ

env = environ.Env(
    # set casting, default value
    DEBUG=(bool, False)
)

environ.Env.read_env()

SECRET_KEY = env("SECRET_KEY")
DEBUG = env("DEBUG")
DATABASES = {
    "default": env.db(),
}
```

This solution gives two big benefits compared to the multiple settings files:

- There is just one `settings.py` file to manage, giving you a much better overview of all settings.
- Secret values are no longer stored in git.

There is one downside: when you introduce new values to the `.env` file you have to remember to edit this file not just locally, but also on staging, production, CI, etc. Totally worth it though.

However! Before you switch to `django-environ`, I should mention that a recent update completely broke the parsing of values when they contain a `#` character, which is pretty common in the `SECRET_KEY`. See [this issue](https://github.com/joke2k/django-environ/issues/519) for more details. So instead I am now using two other packages in tandem: [python-dotenv](https://github.com/theskumar/python-dotenv) and [dj-database-url](https://github.com/jazzband/dj-database-url).

The `.env` file looks the same, the difference is in the `settings.py` file:

```python
import os
import dj_database_url
from dotenv import load_dotenv

load_dotenv(str(BASE_DIR / "myproject" / ".env"))

DEBUG = os.getenv("DEBUG") == "True"
SECRET_KEY = os.getenv("SECRET_KEY")
DATABASES = {
    "default": dj_database_url.parse(os.getenv("DATABASE_URL")),
}
```

The difference with `django-environ` is that this solution doesn't try to parse the values in the `.env` file at all, it doesn't try to turn them into the right type (like a boolean for `DEBUG`), it's just a "dumb" solution to read environment variables - no magic and thus less stuff to break. I'm a big fan of these two small packages that both do one small thing, and do it well. All that `python-dotenv` does is read the `.env` file, and makes those values available to Python's built-in `os` module, so that you can read them using `os.getenv`. And `dj-database-url` simply parses a database URL like `postgres://mydatabase:password@localhost:5432/mydatabase` into the config format that Django expects.

I really feel that `django-environ` was trying to do too much magic and it was breaking stuff as a result. That issue that I linked to above has been open since February without any official replies. And while a fix has been committed, no release has been made. It doesn't make me trust `django-environ` anymore.
