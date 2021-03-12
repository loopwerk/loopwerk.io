---
tags: python, django
---

# Making Django suck less
Or, "How to make Django even better then it already is". Because it really isn't as bad as the title implies :)

In my previous post [Things I hate about Python and Django](/articles/2009/things-i-hate-about-python-and-django/), I said that one of the things I  "hate" about Django is its template language. While very easy to use and pretty extensible, it's missing some important (and basic, to be honest) features like in-template creation of variables, a good `if` syntax and the ability to use variable variables (variable interpolating).

I have been looking for a template replacement and looked into [Mako](http://www.makotemplates.org/), [Cheetah](http://www.cheetahtemplate.org/) and [Jinja2](http://jinja.pocoo.org/).

* Mako is easily plugged into a Django project thanks to the [django-mako](http://code.google.com/p/django-mako/) project. I don't really like its syntax though.
* Cheetah has a very nice syntax (but completely different from the normal Django templates). Getting it to play nice with Django is a lot harder though. Simple things like `direct_to_template` are easy enough, but once you start extending templates with each other, it gets nasty.
* Jinja2 uses almost exactly the same syntax as the normal Django template language, while adding extra features and (a lot of) extra power. It looks very easy to use as a drop-in replacement.

Based on this I chose Jinja2 as the winner, and started a small project to see how easy it is to plug into Django. The easiest way to use it, is by using the [Coffin](http://github.com/dcramer/coffin) library, which adds Jinja2 versions of things like `direct_to_template` and `render_to_response`, and even ports the most useful Django filters like `{% url %}`.

First, install Jinja2, and then install Coffin with the following commands:

```bash
$ cd /tmp
$ git clone git://github.com/dcramer/coffin.git
$ cd coffin/
$ sudo python setup.py install
```

In your views, you can now simply change `from django.views.generic.simple import direct_to_template` to `from coffin.views.generic.simple import direct_to_template`. Really, that's it, you are now using Jinja2.

If you want to render your 404 and 500 templates with Jinja2, change `from django.conf.urls.defaults import *` in your urls.py to `from coffin.conf.urls.defaults import *`.

Most existing Django templates should just work, however some things are a bit different. Read the [How Compatible is Jinja2 with Django?](http://jinja.pocoo.org/2/documentation/faq#how-compatible-is-jinja2-with-django) chapter in the official Jinja2 documentation, and [Convert Django Templates to Jinja2](http://splike.com/wiki/Convert_Django_Templates_to_Jinja2) for more information. Seeing as how similar the two systems are, it leaves me wondering why Django is developing and maintaining their own template language. It seems like a smart move to switch to Jinja2.

Are you using the default Django template language? Something else? If so, which one and why? Let me know in the comments.
