---
tags: django, python, deployment
summary: I'm a big fan of the django-tailwind-cli package, but I ran into problems deploying it to production. Here’s how to make sure you cache-bust tailwind.css.
---

# Production-ready cache-busting for Django and Tailwind CSS

I'm a big fan of the [django-tailwind-cli](https://github.com/django-commons/django-tailwind-cli) package. It makes integrating Tailwind CSS into a Django project incredibly simple. By managing the Tailwind watcher process for you, it streamlines development, especially when paired with [django-browser-reload](https://github.com/adamchainz/django-browser-reload) for live updates. It's a fantastic developer experience.

However, when I first deployed a project using this setup, I ran into a classic problem: caching. You see, `django-tailwind-cli` creates a single `tailwind.css` file that you load in your base template. In production, browsers and CDNs will aggressively cache this file to improve performance. This is normally a good thing! But when you deploy an update, like adding a new Tailwind class to a template, your users might not see the changes. Their browser will continue to serve the old, cached `tailwind.css` file, leading to broken or outdated styling.

Luckily, Django has a built-in cache-busting mechanism in the form of `ManifestStaticFilesStorage`. But, there’s one important caveat: you need to make sure that `css/source.css` is not processed by `ManifestStaticFilesStorage` or things will break.

Step 1: configure the storage in `settings.py`:

#### <i class="fa-regular fa-file-code"></i> settings.py
```python
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

Step 2: update your base template. Replace the `{% tailwind_css %}` tag with:

#### <i class="fa-regular fa-file-code"></i> base.html
```html
<link rel="preload" href="{% static 'css/tailwind.css' %}" as="style">
<link href="{% static 'css/tailwind.css' %}" rel="stylesheet" />
```

With those two things configured, your deployment process for static files will now be a two-step command:

```sh
./manage.py tailwind build
./manage.py collectstatic --noinput --ignore css/source.css
```

First, `tailwind build` creates the final `tailwind.css` file. Then, `collectstatic` picks it up, hashes it with a unique name like `tailwind.4e3e58f1a4a4.css`, and places it in your `STATIC_ROOT` directory, ready to be served.

That’s it! Your Tailwind styles are now production-ready and properly cache-busted.

> **Update August 2, 2025**: the initial version of this article used a custom subclass of `ManifestStaticFilesStorage` to ignore `css/source.css`, but then James was kind enough to tell me about `collectstatic`’s `--ignore` option. Thanks!