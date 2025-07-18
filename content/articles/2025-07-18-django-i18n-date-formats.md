---
tags: django, python
summary: A dive into why Django's DATETIME_FORMAT setting seems to do nothing, and how to actually force the 24-hour clock in the admin, even when your locale says otherwise.
---

# Why Django's DATETIME_FORMAT ignores you (and how to fix it)

When you start a new Django project, you get a handful of default settings for localization and timezones:

#### <i class="fa-regular fa-file-code"></i> settings.py
```python
USE_I18N = True
LANGUAGE_CODE = "en-us"
USE_TZ = True
TIME_ZONE = "UTC"
```

I’ve written before about the default timezone being a silly choice for sites with a global user base, both on [the backend](/articles/2025/django-admin-datetime/) and [the frontend](/articles/2025/django-local-times/). 

But today, I want to talk about internationalization (`I18N`) and language settings. For my sites, `LANGUAGE_CODE = "en-us"` is perfectly fine; all my admin users speak English, and we prefer American spelling over the British variant. But there are some weird things going on in Django that I want to address.

## The `USE_I18N` puzzle

Here's the first weird thing. The default settings have `USE_I18N = True`, which enables Django’s internationalization features. The default `LANGUAGES` setting also includes a massive list of every language under the sun.

You'd think this means the Django Admin would automatically switch languages. If I set my browser's preferred language to Dutch, shouldn't the Admin follow suit? Nope. It remains stubbornly English.

It turns out you need to add this to your middleware for the translation to actually happen:

#### <i class="fa-regular fa-file-code"></i> settings.py
```python
MIDDLEWARE = [
    # ...
    "django.middleware.locale.LocaleMiddleware",
]
```

Only after adding `LocaleMiddleware` will the Admin honor your browser's language preference. This feels weird to me. Why enable `USE_I18N` by default, which has a small performance cost, if it doesn't do anything without manual intervention?

It’s also very strange to me that there isn’t a language drop-down in the Admin, where users can choose from the available languages (as defined by the `LANGUAGES` setting). That seems like such an obvious improvement to the Admin, in the same way that there really should be a timezone dropdown as well, to render dates and times in your local timezone.

But since I never add translations for my own code (models and templates), I only ever want my Admin in English anyway, so I just turn the whole translation system off. My settings become:

#### <i class="fa-regular fa-file-code"></i> settings.py
```python
USE_I18N = False
LANGUAGE_CODE = "en-us"
LANGUAGES = [("en-us", "English")]
USE_TZ = True
TIME_ZONE = "UTC"
```

## Formatting settings are ignored

With `LANGUAGE_CODE = "en-us"`, Django formats all dates and times according to US conventions. This means using the 12-hour clock with "a.m." and “p.m.”. As a European, this format is just hard to read, especially when you have to mentally parse "12 a.m." and "12 p.m." We want a simple 24-hour clock.

Let's test this with a basic model:

#### <i class="fa-regular fa-file-code"></i> models.py
```python
from django.db import models

class Appointment(models.Model):
    scheduled_at = models.DateTimeField()
```

And a simple admin:

#### <i class="fa-regular fa-file-code"></i> admin.py
```python
from django.contrib import admin
from .models import Appointment

@admin.register(Appointment)
class AppointmentAdmin(admin.ModelAdmin):
    list_display = ["scheduled_at"]
```

As expected, the admin form widget and the list display both render the time in the 12-hour format. No problem, I thought. Django has settings for this! I'll just force the 24-hour format everywhere.

#### <i class="fa-regular fa-file-code"></i> settings.py
```python
DATETIME_FORMAT = "N j, Y, H:i"
TIME_FORMAT = "H:i"
```

And now for the second weird thing: this does absolutely nothing. The times in the admin are still shown with a.m./p.m. A quick trip to the documentation reveals the culprit:

> The default formatting to use for displaying datetime fields in any part of the system. **Note that the locale-dictated format has higher precedence and will be applied instead.**

Wait.. what? So even though I set `USE_I18N = False`, Django still uses the `LANGUAGE_CODE` to determine formatting rules, and **overrides my custom settings**. Setting `USE_I18N = False` only stops the translation framework; it doesn't stop the localization formatting. The `en-us` locale's formatting rules are hardcoded to use the 12-hour clock, and they will always win against the `DATETIME_FORMAT` setting.

So, what is the point of `DATETIME_FORMAT` and `TIME_FORMAT`? They seem only to work if you use a locale that doesn't have its own predefined formats? It feels completely backward; a specific custom setting should always override a general locale-based one.

## The fix: overriding locale formats

So how do we get our 24-hour clock? If the locale format is the problem, we need to change the locale format.

Django provides a clean, if somewhat hidden, way to do this with the `FORMAT_MODULE_PATH` setting. This tells Django to look in a specific Python module for custom format definitions.

### 1. Create a `formats` package

In your project directory (the one with `manage.py`), create a new package for our custom formats. I'll call mine `formats`.

```
myproject/
├── formats/
│   ├── __init__.py
│   └── en/
│       ├── __init__.py
│       └── formats.py
└── manage.py
```

### 2. Create a custom `formats.py`

Inside `formats.py` we can define our own formats for the `en` language code. We'll specify the 24-hour clock using `H` for the hour.

#### <i class="fa-regular fa-file-code"></i> myproject/formats/en/formats.py
```python
DATETIME_FORMAT = "N j, Y, H:i"
TIME_FORMAT = "H:i"
SHORT_DATETIME_FORMAT = "m/d/Y H:i"
```

You can add a few other locate-related formats you want to override here, see [the documentation for `FORMAT_MODULE_PATH`](https://docs.djangoproject.com/en/5.2/ref/settings/#format-module-path) for the available settings.

### 3. Point Django to your custom formats

Finally, in your `settings.py`, tell Django where to find this new module:

#### <i class="fa-regular fa-file-code"></i> settings.py
```python
FORMAT_MODULE_PATH = 'formats'
```

And voilà! The Django admin now displays all times in the glorious, unambiguous 24-hour format, even while `LANGUAGE_CODE` is still `en-us`.

It’s definitely more work than you'd expect for such a simple change. I really do think they should change the precedence order, but now you know how to change formatting settings for an existing locale.

## Override the time picker options

There is one remaining place where “a.m.” and “p.m.” are still being used, and that’s in the time picker, which shows quick options for “now”, “midnight”, "6 a.m.”, “noon” and "6 p.m.”. I’d rather see 24-hour times here, which means we have to override Django’s default strings.

We need to make three changes to our settings:

#### <i class="fa-regular fa-file-code"></i> settings.py
```python
LANGUAGE_CODE = "en"
LANGUAGES = [("en", "English")]
LOCALE_PATHS = [BASE_DIR / "locale"]
```

This is because `en-us` is Django’s default language which doesn’t use translation files. As such we need to switch to a custom language where we can make changes. Any strings that don’t exist in our custom language translation file automatically fall back to the default, which is `en-us`.

Now create the following file in the root (same level as `manage.py`):

#### <i class="fa-regular fa-file-code"></i> locale/en/LC_MESSAGES/djangojs.po
```
msgid ""
msgstr ""
"Project-Id-Version: django\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
"Language: en\n"

msgid "Midnight"
msgstr "00:00"

msgid "6 a.m."
msgstr "06:00"

msgid "Noon"
msgstr "12:00"

msgid "6 p.m."
msgstr "18:00"
```

Then run `./manage.py compilemessages` and restart the development server. And with that the Django Admin should show sensible times in the time picker dropdown as well.