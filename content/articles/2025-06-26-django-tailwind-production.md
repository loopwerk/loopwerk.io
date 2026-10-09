---
tags: django, deployment, howto
summary: I'm a big fan of the django-tailwind-cli package, but I ran into problems deploying it to production. Here's how to make sure you cache-bust tailwind.css.
---

# Production-ready cache-busting for Django and Tailwind CSS

I'm a big fan of the [django-tailwind-cli](https://github.com/django-commons/django-tailwind-cli) package, because it makes using Tailwind CSS with a Django project very simple. It manages the Tailwind watcher process for you, and becomes even better when paired with [django-browser-reload](https://github.com/adamchainz/django-browser-reload) for live updates.

This package outputs a `tailwind.css` file that you load in your base template. And because my projects use aggressive caching rules for static files, it meant that changes to this file weren't always visible to users, which would lead to broken styling on the site.

I didn't want to stop caching my static files, so instead I looked into generating cache-busting filenames, such as `tailwind.4e3e58f1a4a4.css`. Luckily, Django has a built-in feature that does exactly this: `ManifestStaticFilesStorage`. But you need to make sure that `css/source.css` is not processed by `ManifestStaticFilesStorage` or things will break.

## Step 1: configure the storage

Update `settings.py`:

```python title="settings.py"
STATIC_ROOT = BASE_DIR / "static_root"
STATIC_URL = "/static/"

STORAGES = {
    "default": {
        "BACKEND": "django.core.files.storage.FileSystemStorage",
    },
    "staticfiles": {
        "BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage"
        if DEBUG else "django.contrib.staticfiles.storage.ManifestStaticFilesStorage",
    },
}
```

This will use `StaticFilesStorage` in development mode, `ManifestStaticFilesStorage` otherwise.

## Step 2: update your deploy process

With the settings configured, your deployment process for static files will now be two commands:

```shell-session
$ ./manage.py tailwind build
$ ./manage.py collectstatic --noinput --ignore css/source.css
```

First, `tailwind build` creates the final `tailwind.css` file. Then, `collectstatic` picks it up, hashes it with a unique name like `tailwind.4e3e58f1a4a4.css`, and places it in your `STATIC_ROOT` directory. Problem solved!