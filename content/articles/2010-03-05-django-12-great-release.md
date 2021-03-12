---
tags: review, python, django
---

# Django 1.2, a great release
I've been playing with the Beta release of Django 1.2 ([get it here](http://www.djangoproject.com/download/)) and I love many of the new improvements. I'd like to list the best and biggest new features, and also some problems I encountered while using it.

## Smarter if tag

I was already using [this snippet](http://www.djangosnippets.org/snippets/1350/) a lot, and that is no longer necessary. This is now in Django's core, making it so much easier to use if statements in html templates.

## Multiple database support

Personally I don't expect I will use this a lot, but it's great to see that it's possible with a standard Django configuration. Read more about it [on the official documentation](http://docs.djangoproject.com/en/dev/topics/db/multi-db/).

## Cached template loaders

Before Django 1.2, all templates needed to be parsed from disc for every request. This can be a (small) problem if you have lots of nested templates. I am very happy with this change, but have yet to see its impact. As a side-effect of the new template loaders, it is now much much easier to use different template languages like Jinja2, which I blogged about in a [previous post](/articles/2009/making-django-suck-less/).

## Custom email backends

While I am generally happy to use the basic smtp backend for email, it is good to see that this change will allow Google App Engine users to use Django's email functions again. Now only proper database support is missing, but then it will be very easy to switch to Google App Engine indeed.

## New message system

The old message system was flawed. It didn't support different message levels (notice, warning, succes, error, etc), was only available for logged in users, and required an extra database hit on every request. The new generic message system solves all of these problems and I couldn't be happier.

## I18N/L10N improvements

Django 1.2 can show dates and numbers in the right way. For example, in The Netherlands, we show dates as 13-02-1982, while in England they use 02/13/1982. Also big numbers with separators for groups of thousands are now locale aware. Since I am currently working on an application with support for English, Dutch and German, this is a very very welcome improvement to Django.

The only problems I had with getting this to work was finding out which setting to change, because this wasn't documented yet, or at the very least hard to find. If you are interested in the new L10N improvements, add this to your settings.py:

```python
USE_I18N = True
USE_L10N = True
USE_THOUSAND_SEPARATOR = True
```

Of course there are many more improvements like better tab completion in bash, object permissions, object validation, better CSRF protection and a better test framework. But those are features not yet used by me, although I am very interested in object validation.
