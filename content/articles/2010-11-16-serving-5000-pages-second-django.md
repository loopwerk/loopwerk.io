---
tags: python, django
---

# Serving 5000 pages per second with Django
Okay, this website wasn't slow and will never need to serve 5000 pages per second, but hey, it's possible now! Oh right, and it was fun to play around with a nice caching system.

Almost everything on mixedCase.nl needs to come from the database: the list of categories, the menu on top of the site, the articles, the count of the number of comments, how many entries there are per month and category, and so on. So, caching makes a big difference in making the site very quick. When I wanted to play around with caching, I already knew about these options Django provides out of the box:

* Cache individual views with a decorator
* Cache pieces of the rendered templates with the cache templatetag
* Use Django's cache middleware to cache the output of entire pages to memcached

Option 1 was not an option, since all views are provided by third-party applications ([Django-CMS](https://github.com/divio/django-cms) and one of my all-time favorite apps: [Zinnia](https://github.com/Fantomas42/django-blog-zinnia)). Option 2 is better, because all templates are written by myself, so I can do whatever I want. While this is indeed a very nice option if you want to cache "expensive" bits of your pages, Django still has to do some work. The third option is pretty cool: insert two pieces of middleware in your `settings.py` and your entire site is cached. However, the webserver still needs to call your Django instance (in my case [Gunicorn](http://gunicorn.org/)).

Today I was looking at the documentation of [Nginx](http://wiki.nginx.org/Main), the webserver I use. Listed in the available modules: [HttpMemcachedModule](http://wiki.nginx.org/HttpMemcachedModule). Wow, the webserver can use your memcached cache, so it doesn't even have to hit the Django server! After looking into this, I quickly saw a problem: Nginx can use the current url as a cache-key, but not much else. And Django's cache middleware uses a key composed of cookies, sessions, url and md5 hashes. So, the cache as written by Django cannot be read from Nginx. Bummer.

As the saying goes: Google is your friend, and it wasn't long before I found some posts about this very problem. Some people wrote their own cache middleware, so it's readable from Nginx. However, invalidating the cache looked difficult in all their solutions: whenever a new comment is made for example, you need to remove the cache for the article, the list of articles on /articles/, all category lists that article is on, and the homepage. Why? Because they all show a count of the comments made on articles. And since all those pages are saved in memcached with an URL as their key, you need to find all those URL's to remove them from the cache. Ouch.

I then found a very interesting project on Github: [StaticGenerator for Django](https://github.com/luckythetourist/staticgenerator). In short, it's a piece of middleware that saves the output of the requested page as an HTML file, which can be served from Nginx. And since it's just a bunch of files on disk, it's very easy to just remove all of them whenever something on the website has changed (a new page or article has been added, a comment has been made, and so on). I made some modifications on the StaticGenerator, because I only want to cache pages for anonymous users, and want to be able to set a list of excluded URL's. The [source code is available](https://github.com/kevinrenskers/mixedcase-python/tree/master/project/staticgenerator) on my GitHub account.

To use the StaticGenerator, add these settings to `settings.py`:

```python
WEB_ROOT = os.path.join(os.path.dirname(__file__), 'generated')

STATIC_GENERATOR_ANONYMOUS_ONLY = True

STATIC_GENERATOR_URLS = (
    r'^/$',
    r'^/(articles|projects|about)',
)

STATIC_GENERATOR_EXCLUDE_URLS = (
    r'\.xml$',
    r'^/articles/search',
    r'^/articles/feed',
    r'^/articles/comments/posted',
)
```

You also need to add `'staticgenerator.middleware.StaticGeneratorMiddleware'` to the end of your `MIDDLEWARE_CLASSES` list.

Of course, you want to remove the generated pages as soon as something has changed. You can simply add something like this to one of your `models.py` files:

```python
from django.db.models.signals import post_save
from staticgenerator import recursive_delete

def delete_cache(sender, **kwargs):
    recursive_delete('/')

post_save.connect(delete_cache)
```

Please note that this is a very simple implementation: every time any of your models is saved, all generated pages are removed. This includes someone simply logging in on the admin site as well, which is of course not something you would want. I'll update this post with a better way of doing this.

Finally, my (shortened) Ngix config:

```nginx
server {
    server_name .mixedcase.nl;
    root /path/to/project/generated/;

    access_log /var/log/nginx/mixedcase.nl.access.log;

    location /media/  {
        alias /path/to/project/media/;
        access_log off;
        expires max;
    }

    location /adminmedia/  {
        alias /path/to/project/lib/python2.6/site-packages/django/contrib/admin/media/;
        access_log off;
        expires max;
    }

    location / {
        if (-f $request_filename/index.html) {
            rewrite (.*) $1/index.html break;
        }

        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_redirect off;

        if (!-f $request_filename) {
            proxy_pass http://unix:/tmp/gunicorn_mixedcase.sock;
            break;
        }
    }
}
```

As I said in the first sentence: mixedCase.nl can now do 5000 pages per second. I'm impressed!
