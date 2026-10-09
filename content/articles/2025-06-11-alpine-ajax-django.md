---
tags: django, javascript, insights, howto
summary: Ditch the complex SPA. Learn how to build modern, server-rendered Django apps using Alpine AJAX and the power of hypermedia.
---

# Beyond htmx: building modern Django apps with Alpine AJAX

I've recently been rethinking how I build web applications. For the past few years my default has been a Django backend serving a JSON API to a frontend built with SvelteKit. And I am not alone; many (if not most) sites now use a complex JavaScript frontend and a JSON API. This pattern, the Single-Page Application (SPA), brought us amazing user experiences, but it also brought a mountain of complexity: state management, API versioning, client-side routing, duplicate form validation, build tools, and the endless churn of the JavaScript ecosystem.

And then I came across [htmx](https://htmx.org), which promises to enhance HTML to the point where your old-fashioned Multi-Page Application (MPA) feels modern, without having to write a single line of JavaScript. We can have the smooth, modern UX of a SPA but with the simplicity and robustness of traditional, server-rendered Django applications.

## The promise of htmx

htmx is a brilliant library that "completes" HTML as a hypertext. It lets you trigger AJAX requests from any element, not just links and forms, and swap the response HTML into any part of the page.

For example, here's a classic "click-to-edit" pattern. Initially, the page shows user details with an "Edit" button:

```html
<!-- Initial state -->
<html>
  <body>
    <div hx-target="this" hx-swap="outerHTML">
      <div><label>First Name</label>: Joe</div>
      <div><label>Last Name</label>: Blow</div>
      <div><label>Email</label>: joe@blow.com</div>
      <button hx-get="/contact/1/edit" class="btn primary">
        Click To Edit
      </button>
    </div>
  </body>
</html>
```

When you click the button, htmx sends a `GET` request to `/contact/1/edit`. The server responds not with JSON, but with a snippet of HTML for an edit form:

```html
<!-- HTML returned from the server -->
<form hx-put="/contact/1" hx-target="this" hx-swap="outerHTML">
  <div>
    <label>First Name</label>
    <input type="text" name="firstName" value="Joe" />
  </div>
  <div>
    <label>Last Name</label>
    <input type="text" name="lastName" value="Blow" />
  </div>
  <div>
    <label>Email Address</label>
    <input type="email" name="email" value="joe@blow.com" />
  </div>
  <button class="btn">Submit</button>
  <button class="btn" hx-get="/contact/1">Cancel</button>
</form>
```

htmx then swaps this form into the DOM, replacing the original `div`. No JSON, no client-side templating, no virtual DOM. It's simple and fast.

![DB to JSON to JS to HTML vs DB to HTML meme](/articles/images/dbtohtml.png)

You can build features like [infinite scroll](https://htmx.org/examples/infinite-scroll/) and [active search](https://htmx.org/examples/active-search/) with just a few HTML attributes, but there is one big downside: it encourages you to add behavior to elements that have no native function.

```html
<button hx-get="/contact/1/edit" class="btn primary">
  Click To Edit
</button>
```

If JavaScript is disabled or fails to load, this button does nothing, and the application is broken. This violates the principle of progressive enhancement, where a site should be functional at a baseline level (plain HTML) and enhanced with JavaScript.

To be fair, you _can_ write progressively enhanced code with htmx, but it often requires attribute repetition and constant vigilance from you, the developer.

## My preferred alternative: Alpine.js + Alpine AJAX

[Alpine.js](https://alpinejs.dev) is a minimal JavaScript framework for composing behavior directly in your HTML. If you've used Vue, it will feel very familiar. It's very often used alongside htmx to handle things htmx doesn't, like toggling modals or managing simple client-side state.

```html
<!-- Simple Alpine.js counter -->
<div x-data="{ count: 0 }">
  <button x-on:click="count++">Increment</button>
  <span x-text="count"></span>
</div>

<!-- Alpine.js dropdown -->
<div x-data="{ open: false }">
  <button @click="open = ! open">Toggle</button>
  <div x-show="open" @click.outside="open = false">Contents ..</div>
</div>
```

I was already including Alpine for this kind of light interactivity, and then I discovered its [Alpine AJAX](https://alpine-ajax.js.org) plugin. It does most of what htmx does, but with two key differences:

1.  It's smaller (3kB vs 14kB for htmx).
2.  It only enhances `<a>` and `<form>` tags.

That second point might seem like a downside at first, but it prevents you from making the progressive enhancement mistake. Your application _must_ work with plain HTML first, and any AJAX functionality is purely an enhancement. It forces you to do things the right way, unlike htmx.

## Let's rebuild it with Alpine AJAX

Here is the same "click-to-edit" feature, now built with Alpine AJAX.

First, the initial state. The `<button>` is now an `<a>` tag, which has a meaningful `href`:

```html
<!-- Initial state with Alpine AJAX -->
<html>
  <body>
    <div id="user_details">
      <div><label>First Name</label>: Joe</div>
      <div><label>Last Name</label>: Blow</div>
      <div><label>Email</label>: joe@blow.com</div>
      <a href="/contact/1/edit" x-target="user_details" class="btn primary">
        Click To Edit
      </a>
    </div>
  </body>
</html>
```

Without JavaScript, this is a standard link that takes you to the edit page (a full page refresh). With JavaScript, the `x-target="user_details"` attribute tells Alpine AJAX to fetch the content from the link's `href` and use the response to replace the element with the ID `user_details`.

The server returns the edit form. This is a standard HTML `<form>` that works perfectly without JavaScript:

```html
<!-- HTML returned from server -->
<form
  method="post"
  action="/contacts/1"
  id="user_details"
  x-target="user_details"
>
  <div>
    <label>First Name</label>
    <input type="text" name="firstName" value="Joe" />
  </div>
  <!-- ... other fields ... -->
  <button type="submit">Submit</button>
  <a class="btn" href="/contact/1" x-target="user_details">Cancel</a>
</form>
```

When JavaScript is enabled, the `x-target` on the form intercepts the submission, sends it via AJAX, and replaces the target with the result. The "Cancel" link works the same way. It's progressively enhanced by default.

## Making it sing with Django

This is all great, but how do we handle this on the Django side? An AJAX request for a partial update needs just a snippet of HTML, while a full-page refresh (JS disabled) needs the full base template.

### The simple approach

Alpine AJAX (and htmx) sends a special header with its requests. We can check for this header in our view to decide what to render.

```python title="views.py"
from django.shortcuts import render
from django.template.response import TemplateResponse

def contact_view(request, pk: int):
    contact = Contact.objects.get(pk=pk)
    context = {"contact": contact}

    if "X-Alpine-Request" in request.headers:
        # It's an AJAX request, return just the partial
        return TemplateResponse(request, "partial.html", context)

    # It's a normal request, return the full page
    return TemplateResponse(request, "full.html", context)
```

This works, but maintaining two separate templates (`full.html` and `partial.html`) is a pain. Yes we can use Django's `include` tag to include the partial template into the full template, but we can do better.

### A better way: django-template-partials

A fantastic third-party package called [`django-template-partials`](https://github.com/carltongibson/django-template-partials) lets us define reusable blocks within a single template. We can then render just a specific block.

First, we define our partial block in the main template:

```django title="full.html"
<html>
<body>
  <mark>{% partialdef details inline %}</mark>
    <div id="user_details">
      ... contact details and edit link ...
    </div>
  <mark>{% endpartialdef %}</mark>
</body>
</html>
```

Now, our view can choose to render the whole template or just the `details` partial from it:

```python title="views.py"
def contact_view(request, pk: int):
    contact = Contact.objects.get(pk=pk)
    context = {"contact": contact}

    if "X-Alpine-Request" in request.headers:
        return TemplateResponse(request, <mark>"full.html#details"</mark>, context)

    return TemplateResponse(request, "full.html", context)
```

Much cleaner! We only have one template to maintain.

### The best way: an abstracted `TemplateResponse`

We can abstract this logic away into a custom `TemplateResponse` class to make our views even cleaner. Alpine AJAX sends another header, `X-Alpine-Target`, which tells us which partial it's expecting. We can use this to automatically determine the partial name.

```python title="lib.py"
from django.template.response import TemplateResponse as BaseTemplateResponse
from django.http import HttpRequest

def is_alpine(request: HttpRequest) -> bool:
    return "X-Alpine-Request" in request.headers

class AlpineTemplateResponse(BaseTemplateResponse):
    def get_ajax_template(self, request: HttpRequest, template: str) -> str:
        if is_alpine(request):
            # Use the target ID from the request as the partial name.
            # This allows one view to serve multiple, distinct partials.
            # We fall back to "alpine" as a sensible default.
            partial = request.headers.get("X-Alpine-Target") or "alpine"
            return f"{template}#{partial}"
        return template

    def __init__(self, request: HttpRequest, template: str, *args, **kwargs):
        template_name = self.get_ajax_template(request, template)
        super().__init__(request, template_name, *args, **kwargs)

```

Now our view is blissfully unaware of the implementation details:

```python title="views.py"
from .lib import AlpineTemplateResponse

def contact_view(request, pk: int):
    contact = Contact.objects.get(pk=pk)
    return AlpineTemplateResponse(request, "full.html", {"contact": contact})
```

## Final example: search-as-you-type

Here's how a "search-as-you-type" feature looks with our Alpine stack. Alpine handles the user input events (like debouncing), and Alpine AJAX handles the form submission.

```html
<h3>Search Contacts</h3>

<form x-target="search-results" action="/contacts" autocomplete="off">
  <input
    class="form-control"
    type="search"
    name="search"
    placeholder="Begin Typing To Search Users..."
    @input.debounce="$el.form.requestSubmit()"
    @search="$el.form.requestSubmit()"
  />
  <button x-show="false">Search</button>
</form>

<table class="table">
  <thead>
    <tr>
      <th>First Name</th>
      <th>Last Name</th>
      <th>Email</th>
    </tr>
  </thead>
  <tbody id="search-results">
    {# Initial results rendered by Django #}
  </tbody>
</table>
```

This degrades perfectly: without JS, it's a standard search form with a submit button. 

Compare this with the htmx version:

```html
<h3>Search Contacts</h3>

<input
  class="form-control"
  type="search"
  name="search"
  placeholder="Begin Typing To Search Users..."
  hx-post="/search"
  hx-trigger="input changed delay:500ms, keyup[key=='Enter'], load"
  hx-target="#search-results"
/>

<table class="table">
  <thead>
    <tr>
      <th>First Name</th>
      <th>Last Name</th>
      <th>Email</th>
    </tr>
  </thead>
  <tbody id="search-results">
    {# Initial results rendered by Django #}
  </tbody>
</table>
```

Instead of leaning on Alpine for the trigger logic, htmx has its own DSL for triggers. And like I said before: most people who use htmx, also use Alpine, so it's a bit strange to use two different syntaxes side by side. But more importantly this version doesn't work without JavaScript, it's not a progressive enhancement.

Yes, you _can_ make this htmx example work without JavaScript, but it's not enforced, none of the official examples do so, and it results in a lot of added HTML attributes. It's not as ergonomic as Alpine AJAX in my experience.

## Make Django messages work with Alpine AJAX

It's incredibly easy to make Django's messages framework work with Alpine AJAX. Let's say we have a view that sets a success message:

```python
messages.success(request, "Success!")
```

How do you make this message appear when you're only returning a partial HTML template as a response to an AJAX request?

The trick is to use Alpine AJAX's `x-sync` attribute. Change your `base.html` to include the following snippet:

```html title="base.html"
{% partialdef messages inline %}
<div id="messages" x-sync x-merge="append" class="toast toast-top toast-end">
  {% for message in messages %}
  <div
    class="alert alert-{{ message.tags }} flex"
    x-data="{ open: false }"
    x-show="open"
    x-init="$nextTick(() => open = true); setTimeout(() => open = false, 3000)"
    x-transition.duration.500ms
  >
    <div>{{ message.message }}</div>
    <button class="btn btn-circle btn-ghost" @click="open = false">x</button>
  </div>
  {% endfor %}
</div>
{% endpartialdef %}
```

And then include the following middleware into your project (and add it to `MIDDLEWARE` in `settings.py`):

```python title="middleware.py"
class AlpineMessageMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)

        if (
            "X-Alpine-Request" in request.headers
            and not 300 <= response.status_code < 400
            and (messages := get_messages(request))
            and not response.text.endswith("</html>")
        ):
            response.write(
                render_to_string(
                    "base.html#messages",
                    {"messages": messages},
                )
            )

        return response
```

This includes the `messages` partial from `base.html` into any partial template response, as a result of an Alpine AJAX request. Alpine AJAX sees the `x-sync` attribute, finds the same element in the webpage, and merges the content.

The result is that you can use Django's messages framework and those messages are shown as expected, even when you return a partial template that doesn't include those messages. The middleware takes care of all of that.

## Closing thoughts

I've been building with this stack for a few weeks, and it feels pretty good. I get to stay in Django, writing Python and standard HTML templates. All my validation and business logic live on the server where they belong. There's no API layer to maintain, no over-fetching, no build steps, no JS frameworks.

This approach also champions locality of behavior. When you look at a template, the behavior is right there in the HTML attributes (`x-target`, `@input`), not hidden away in a separate JavaScript file. It's the same reason I love Tailwind CSS.

I think that for highly interactive, application-like experiences (think Figma), a framework like SvelteKit or Vue is still the right tool. But for the vast majority of simple content-driven websites this hypermedia approach feels like a return to sanity. It's a return to the stability and simplicity of Web 1.0 without the full page reloads.

If you're a Django developer feeling the fatigue of the modern frontend, maybe give Alpine AJAX (or htmx) a try. You might be surprised how productive and fun it is.

> [!UPDATE]
> **March 25, 2026**: after multiple months of working with Django and Alpine AJAX I've revisited this topic in a [new article](/articles/2026/alpine-ajax-django-revisited/).