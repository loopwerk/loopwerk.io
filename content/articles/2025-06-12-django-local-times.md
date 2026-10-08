---
tags: django, howto
summary: A solution for showing dates and times in your visitor's local timezone, all while handling the tricky first-visit problem.
---

# Make Django show dates and times in the visitor's local timezone

Proper timezone handling is very important for a good user experience. When your site shows me emails or comments, I want to see the dates and times in my own local timezone, not whatever your server's timezone is set to.

```html title="post.html"
{% for comment in post.comment_set.all %}
<div>
  <h3>From {{ comment.user.name }} on <mark>{{ comment.added }}</mark></h3>
  <p>{{ comment.comment }}</p>
</div>
{% endfor %}
```

The template above won't show the timestamp in my own local timezone, and sadly Django doesn't really make this easy to do either. The problem is that it has a single `TIME_ZONE` setting, while your users are located all over the world. So how can we make sure that `{{ comment.added }}` shows in the visitor's local timezone?

## The solution

To render dates and times in the visitor's own timezone, we first need to know their timezone. We could use JavaScript to read the timezone from their browser, and store that in a cookie. We then read that cookie in a Django middleware, which will "activate" that timezone. With an active timezone, Django automatically converts all dates and times, exactly what we want.

Let's start with the middleware:

```python title="myapp/middleware.py"
from zoneinfo import ZoneInfo
from django.utils import timezone

class TimezoneMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        tzname = request.COOKIES.get("timezone")
        if tzname:
            try:
                # Activate the timezone for this request
                timezone.activate(ZoneInfo(tzname))
            except Exception:
                # Fallback to the project's default timezone if the name is invalid
                timezone.deactivate()
        else:
            # No cookie, so use the project's default timezone
            timezone.deactivate()

        return self.get_response(request)
```

And add the middleware to your `settings.py`:

```python title="settings.py"
# settings.py
MIDDLEWARE = [
    # ...
    "myapp.middleware.TimezoneMiddleware",
]
```

Next up, we still need to set that cookie. One line of JavaScript in your base template does the trick:

```html title="base.html"
<script>
  document.cookie = "timezone=" + Intl.DateTimeFormat().resolvedOptions().timeZone + "; path=/";
</script>
```

With this and the middleware in place, every rendered `datetime` object will now be in the user's local timezone. Rejoice!

We're not quite done yet, though. Sadly this solution only works after the first page load, because on the very first visit, the browser hasn't sent the cookie yet. That means the first page renders using the server's timezone. We can do better.

## Make it better

So how are we going to render dates and times in the visitor's timezone on that first page, when the server hasn't received that cookie yet? Basically we're going to render dates and times in a special HTML tag using the following custom `localtime` filter, which we're then going to re-render using JavaScript.

```python title="myapp/templatetags/localtime.py"
from django import template
from django.template.defaultfilters import date
from django.utils.html import format_html
from django.utils.timezone import localtime as _localtime

register = template.Library()


@register.filter
def localtime(value):
    """
    Renders a <time> element with an ISO 8601 datetime and a fallback display value.
    Example:
      {{ comment.added|localtime }}
    Outputs:
      <time datetime="2024-05-19T10:34:00+02:00" class="local-time">May 19, 2024 at 10:34 AM</time>
    """
    if not value:
        return ""

    localized = _localtime(value)
    iso_format = date(localized, "c")

    # This format is specific to a US-style locale.
    display_format = date(localized, "F j, Y \\a\\t g:i A")

    return format_html('<time datetime="{}" class="local-time">{}</time>', iso_format, display_format)
```

Everywhere we're rendering a timestamp, we're now going to use this new filter:

```html title="post.html"
<mark>{% load localtime %}</mark>

{% for comment in post.comment_set.all %}
<div>
  <h3>From {{ comment.user.name }} on <mark>{{ comment.added|localtime }}</mark></h3>
  <p>{{ comment.comment }}</p>
</div>
{% endfor %}
```

Last but not least, some more JavaScript needs to be added to your base template. This script will find all `<time>` elements and re-format their content using the browser's local timezone.

```html title="base.html"
<script>
  // Define the formatting options to precisely match our Django filter.
  const options = {
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  };

  document.querySelectorAll(".local-time").forEach(el => {
    const utcDate = new Date(el.getAttribute("datetime"));

    // Explicitly use the 'en-US' locale to ensure the format is consistent
    // with the server-rendered template tag.
    el.textContent = utcDate.toLocaleString("en-US", options);
  });
</script>
```

Just make sure that the way Python formats the dates and times matches the way the JavaScript code does it, or you'll get flickering content updates. My code uses the `en-us` locale for all users (`LANGUAGE_CODE = "en-us"` in settings.py).

## The best of both worlds

So why use both the middleware and the JavaScript? Couldn't we drop the middleware and only use the `localtime` filter? Technically yes, but by using them both together, we get the best of both worlds.

On the first visit, the user has no `timezone` cookie and the middleware does nothing. The `localtime` template tag renders the time in your server's default timezone. Immediately after the page loads, the JavaScript runs, finds the `<time>` element, and instantly rewrites its content to the user's actual local time. There will be a (barely) perceptible flicker, but only on this very first page view.

But on all following page views the user does have the cookie set. The middleware activates their timezone and so the `localtime` filter now renders the time correctly, right from the server. The JavaScript code that reformats the `<time>` element still runs, but nothing needs to be changed, and no flicker will occur at all.

If we got rid of the middleware, the user would have this slight flicker of changing content on every page load, instead of only on the first one.

> [!UPDATE] 
> **July 30, 2025**: all the code necessary to make this work on your website (so the template tag, middleware and JavaScript code) is now available as part of [django-vrot](https://github.com/loopwerk/django-vrot).
