---
tags: django, howto
summary: It's way too difficult to make Django use a 24-hour clock while using American English. Luckily it's not impossible.
---

# Django's internationalization settings are weird

When you start a new Django project, you get a handful of default settings for localization and timezones:

```python title="settings.py"
USE_I18N = True
LANGUAGE_CODE = "en-us"
USE_TZ = True
TIME_ZONE = "UTC"
```

I've written before about the default timezone being a silly choice for sites with a global user base, both on [the backend](/articles/2025/django-admin-datetime/) and [the frontend](/articles/2025/django-local-times/). But the other localization settings are just as strange.

## Weird defaults

The default settings have `USE_I18N = True`, which turns on Django's internationalization features. The default `LANGUAGES` setting also includes a massive list of every language under the sun. You'd think this means that the Django Admin would automatically use the browser's preferred language, right? But nope, no matter what I change my preference to, the Admin stays English.

It turns out you need to add this to your middleware for the translation to actually happen:

```python title="settings.py"
MIDDLEWARE = [
    # ...
    "django.middleware.locale.LocaleMiddleware",
]
```

I find this strange. Why enable `USE_I18N` by default (which has a small performance cost), but not this middleware? This combination of settings seems nonsensical to me, and yet it's what ships with Django as the default.

On a related note, here's a feature request for the Admin. Please add a language dropdown, so that I can choose my preferred language. It seems like a really simple and obvious UX improvement, just like a timezone dropdown.

Anyway, since I never add translations for my models, and all our admins speak English, I usually just turn the whole translation system off:

```python title="settings.py"
USE_I18N = False
LANGUAGE_CODE = "en-us"
LANGUAGES = [("en-us", "English")]
USE_TZ = True
TIME_ZONE = "UTC"
```

## Date formatting is way too difficult

While I, and the other admins on my projects, prefer the Admin to be in American English, we absolutely do not like the 12-hour clock with the "a.m." and "p.m." madness. Sadly, using `LANGUAGE_CODE = "en-us"` means you get both.

No problem, I thought, because Django has dedicated settings for this:

```python title="settings.py"
DATETIME_FORMAT = "N j, Y, H:i"
TIME_FORMAT = "H:i"
```

To my surprise, this does absolutely nothing. All the date/time fields in the Admin are still rendering with the annoying 12-hour clock. But why?

The answer lies in the documentation:

> The default formatting to use for displaying datetime fields in any part of the system. **Note that the locale-dictated format has higher precedence and will be applied instead.**

Wait... what? So even though I set `USE_I18N = False`, Django still uses `LANGUAGE_CODE` to determine the formatting rules, and even *overrides my custom settings*. What is the point of `DATETIME_FORMAT` and `TIME_FORMAT` then? It seems quite obvious that my custom setting should always override a default locale-based one. This is madness!

## The fix

I still want my 24-hour clock, Django's logic be damned. And if the locale format is the problem, we need to change the locale format itself.

Let's get started.

### 1. Create a `formats` package

In your project directory (the one with `manage.py`), create a new package for your custom formats. I'll call mine `formats`.

```text
myproject/
├── formats/
│   ├── __init__.py
│   └── en/
│       ├── __init__.py
│       └── formats.py
└── manage.py
```

### 2. Create a custom `formats.py`

Inside `formats.py` you can define your own formats for the `en` language code. Use `H` for the hour, which uses the 24-hour clock.

```python title="myproject/formats/en/formats.py"
DATETIME_FORMAT = "N j, Y, H:i"
TIME_FORMAT = "H:i"
SHORT_DATETIME_FORMAT = "m/d/Y H:i"
```

You can override other locale-related settings if you want to, see [the documentation for `FORMAT_MODULE_PATH`](https://docs.djangoproject.com/en/5.2/ref/settings/#format-module-path) for the available ones.

### 3. Point Django to your custom formats

Finally, tell Django where to find this new module:

```python title="settings.py"
FORMAT_MODULE_PATH = "formats"
```

And voilà! The Django Admin now displays all times in the glorious 24-hour format, even while `LANGUAGE_CODE` is still `en-us`.

It's definitely more work than you'd expect for such a simple change. I really do think they should change the precedence order, but now you know how to change formatting settings for an existing locale.

## Override the time picker shortcuts

Our `FORMAT_MODULE_PATH` solution fixed most of the clocks in the Admin, but not the time picker widget in the Admin. It still shows shortcuts like "6 a.m." and "6 p.m.". To change these, you have to dive into Django's translation system.

### 1. Update your settings

You need to make three changes, the rest can stay as-is:

```python title="settings.py"
LANGUAGE_CODE = "en"
LANGUAGES = [("en", "English")]
LOCALE_PATHS = [BASE_DIR / "locale"]
```

Django treats language `en-us` as its special, hardcoded default and doesn't look for a translation file for it, so you need to switch `LANGUAGE_CODE` to the more generic `en`. Any strings you don't override in your translation file will automatically fall back to the built-in `en-us` defaults.

### 2. Create the override file

Next, create the following file:

```po title="locale/en/LC_MESSAGES/djangojs.po"
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

### 3. Compile the messages

Finally, run the following management command to compile the translations:

```shell-session
$ ./manage.py compilemessages
```

Restart your development server, and the time picker will now show the newly translated shortcuts. Finally, the entire Django Admin is using a sensible clock!