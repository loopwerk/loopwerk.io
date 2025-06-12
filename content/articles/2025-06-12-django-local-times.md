---
tags: django, python
summary: A robust, two-part solution for showing dates and times in your visitor’s local timezone, handling the tricky first-visit problem.
---

# Make Django show dates and times in the visitor’s local timezone

When building a web app, handling timezones correctly is crucial for a good user experience. Django's timezone support is powerful but requires understanding two key settings:

* `USE_TZ = True`: When enabled, Django stores all datetimes in your database in UTC. This is a fundamental best practice that ensures your data is consistent and unambiguous, regardless of where your servers or users are located.
* `TIME_ZONE`: This setting (e.g., `"America/New_York"` or `"Europe/London"`) defines the default timezone for your project. Django uses it to display datetimes in your templates.

The problem arises because your application serves users across the globe, yet your `TIME_ZONE` setting is a single, fixed value. A user in Tokyo doesn't want to see timestamps in your server's New York time. They expect to see times converted to their own local timezone.

Let’s start with a typical scenario. You have a `Comment` model that stores when a comment was added:

#### <i class="fa-regular fa-file-code"></i> models.py
```python
class Comment(models.Model):
    post = models.ForeignKey(Post, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    comment = models.TextField()
    added = models.DateTimeField(auto_now_add=True)
```

When you render these comments in a template, you’ll find the problem right away:

#### <i class="fa-regular fa-file-code"></i> post.html
```html
{% for comment in post.comment_set.all %}
  <div>
    <h3>From {{ comment.user.name }} on {{ comment.added }}</h3>
    <p>{{ comment.comment }}</p>
  </div>
{% endfor %}
```

By default, Django will render `{{ comment.added }}` using the `TIME_ZONE` from your settings. If your project's `TIME_ZONE` is set to `"America/New_York"`, a user in California will see the East Coast time, not their local Pacific time. Let's fix that.

## The Server-Side Fix: A Timezone Middleware

The most robust way to solve this is on the server. If Django knows the user's timezone, it can automatically convert all datetime objects during rendering. The plan is simple:

1.  Use JavaScript to get the visitor's timezone from their browser.
2.  Store it in a cookie.
3.  Create a Django middleware to read this cookie on every request and activate the timezone.

First, let's create the middleware. This small piece of code will check for a `timezone` cookie and, if it exists, activate it for the current request.

#### <i class="fa-regular fa-file-code"></i> myapp/middleware.py
```python
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

Don't forget to add the middleware to your `settings.py`:

#### <i class="fa-regular fa-file-code"></i> settings.py
```python
# settings.py
MIDDLEWARE = [
    # ...
    "myapp.middleware.TimezoneMiddleware",
]
```

Next, we need to set that cookie. A tiny snippet of JavaScript in your base template is all it takes. The `Intl` object in modern browsers makes this incredibly easy.

#### <i class="fa-regular fa-file-code"></i> base.html
```html
<script>
  document.cookie = "timezone=" + Intl.DateTimeFormat().resolvedOptions().timeZone + "; path=/";
</script>
```

With this in place, every rendered `datetime` object will now be in the user's local timezone. Hooray!

Except for one small catch: it only works *after* the first page load. On the very first visit, the browser hasn't sent the cookie yet. Django renders the page in UTC, *then* the JavaScript runs and sets the cookie for the *next* request. This means new visitors get UTC times on their first impression. We can do better.

## Fixing the First-Visit Problem with a Template Tag and JavaScript

To create a seamless experience, we need to handle that first visit gracefully. The solution is to combine our server-side middleware with a little client-side enhancement. We'll render the time in a way that JavaScript can easily find and format it, ensuring the correct time is shown even on the first load.

First, we create a custom template tag that wraps our timestamp in a semantically-correct `<time>` element. This element includes a machine-readable `datetime` attribute, which is perfect for our JavaScript to hook into.

#### <i class="fa-regular fa-file-code"></i> myapp/templatetags/local_time.py
```python
from django import template
from django.template.defaultfilters import date
from django.utils.html import format_html
from django.utils.timezone import localtime

register = template.Library()


@register.filter
def local_time(value):
    """
    Renders a <time> element with an ISO 8601 datetime and a fallback display value.
    Example:
      {{ comment.added|local_time }}
    Outputs:
      <time datetime="2024-05-19T10:34:00+02:00" class="local-time">May 19, 2024 at 10:34 AM</time>
    """
    if not value:
        return ""

    localized = localtime(value)
    iso_format = date(localized, "c")

    # This format is specific to a US-style locale.
    display_format = date(localized, "F j, Y \\a\\t h:i A")

    return format_html('<time datetime="{}" class="local-time">{}</time>', iso_format, display_format)
```

Now, update your template to use this new filter. Remember to load your custom tags first.

#### <i class="fa-regular fa-file-code"></i> post.html
```html
/*HLS*/{% load local_time %}/*HLE*/

{% for comment in post.comment_set.all %}
  <div>
    <h3>From {{ comment.user.name }} on /*HLS*/{{ comment.added|local_time }}/*HLE*/</h3>
    <p>{{ comment.comment }}</p>
  </div>
{% endfor %}
```

Finally, add a bit of JavaScript to your base template. This script will find all our `<time>` elements and re-format their content using the browser's knowledge of the local timezone.

#### <i class="fa-regular fa-file-code"></i> base.html
```html
<script>
  // Define the formatting options to precisely match our Django filter.
  const options = {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  };

  document.querySelectorAll('.local-time').forEach((el) => {
    const utcDate = new Date(el.getAttribute('datetime'));
    
    // Explicitly use the 'en-US' locale to ensure the format is consistent 
    // with the server-rendered template tag.
    el.textContent = utcDate.toLocaleString('en-US', options);
  });
</script>
```

Just make sure that the way Python formats the dates and times matches the way the JavaScript code does it, or you’ll get flickering content updates. My code uses the `en-us` locale for all users (`LANGUAGE_CODE = "en-us"` in settings.py).

## The Best of Both Worlds

So why use both the middleware *and* the JavaScript? Because together, they cover all bases and provide the best user experience.

*   **On the first visit:** The user has no `timezone` cookie and the middleware does nothing. The `local_time` template tag renders the time in your server's default timezone (`setting.TIME_ZONE`). Immediately after the page loads, the JavaScript runs, finds the `.local-time` element, and instantly rewrites its content to the user's actual local time. There might be a barely-perceptible flicker, but only on this very first page view.

*   **On all subsequent visits:** The user has the cookie. The `TimezoneMiddleware` activates their timezone. The `local_time` template tag now renders the time correctly, right from the server. The JavaScript still runs, but it essentially replaces the already-correct time with the same correct time, resulting in no visible change.

This two-part approach gives you the best of server-side rendering (no content-shifting for returning visitors) while using client-side JavaScript as a progressive enhancement to fix the one edge case where the server can't know better.