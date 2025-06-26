---
tags: django, python, deployment
summary: I'm a big fan of the django-tailwind-cli package, but I ran into problems deploying it to production. Here’s to make sure you cache-bust tailwind.css.
---

# Production-ready cache-busting for Django and Tailwind CSS

I'm a big fan of the [django-tailwind-cli](https://github.com/django-commons/django-tailwind-cli) package. It makes integrating Tailwind CSS into a Django project incredibly simple. By managing the Tailwind watcher process for you, it streamlines development, especially when paired with [django-browser-reload](https://github.com/adamchainz/django-browser-reload) for live updates. It's a fantastic developer experience.

However, when I first deployed a project using this setup, I ran into a classic problem: caching. You see, `django-tailwind-cli` creates a single `tailwind.css` file that you load in your base template. In production, browsers and CDNs will aggressively cache this file to improve performance. This is normally a good thing! But when you deploy an update, like adding a new Tailwind class to a template, your users might not see the changes. Their browser will continue to serve the old, cached `tailwind.css file`, leading to broken or outdated styling.

Luckily, Django has a built-in cache-busting mechanism in the form of `ManifestStaticFilesStorage`. But, there’s one important caveat: you can’t use this class directly. The Tailwind build process relies on a source file (typically `css/source.css`) that contains this line:

```css
@import "tailwindcss";
```

When `collectstatic` runs, `ManifestStaticFilesStorage` tries to be helpful and process this file, too. It attempts to find and hash `source.css`, and it also attempts to hash the imported `tailwindcss`, which won’t work.

The solution is to create a custom storage class that tells Django to leave `source.css` alone.

#### <i class="fa-regular fa-file-code"></i> storage.py
```python
from django.contrib.staticfiles.storage import ManifestStaticFilesStorage

class CustomManifestStaticFilesStorage(ManifestStaticFilesStorage):
    def hashed_name(self, name, content=None, filename=None):
        # Skip hashing for source.css — it's only used during Tailwind compilation
        if name == 'css/source.css':
            return name
        return super().hashed_name(name, content, filename)

    def post_process(self, paths, **options):
        # Exclude source.css from post-processing
        paths = {k: v for k, v in paths.items() if k != 'css/source.css'}
        return super().post_process(paths, **options)
```

Then configure it in `settings.py`:

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
        if DEBUG else "storage.CustomManifestStaticFilesStorage",
    },
}
```

The last thing to do is update your base template. Replace the `{% tailwind_css %}` tag with:

#### <i class="fa-regular fa-file-code"></i> base.html
```html
<link rel="preload" href="{% static 'css/tailwind.css' %}" as="style">
<link href="{% static 'css/tailwind.css' %}" rel="stylesheet" />
```

With everything configured, your deployment process for static files will now be a two-step command:

```sh
./manage.py tailwind build
./manage.py collectstatic --noinput
```

First, `tailwind build` creates the final `tailwind.css` file. Then, `collectstatic` picks it up, hashes it with a unique name like `tailwind.4e3e58f1a4a4.css`, and places it in your `STATIC_ROOT` directory, ready to be served.

That’s it! Your Tailwind styles are now production-ready and properly cache-busted.