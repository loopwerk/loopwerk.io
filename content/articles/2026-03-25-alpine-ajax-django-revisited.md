---
tags: django, javascript, insights
summary: Nine months after adopting Alpine AJAX with Django, I've gone through template partials, Jinja2, and landed on an approach that's both fast and clean.
---

# Building modern Django apps with Alpine AJAX, revisited

About nine months ago I wrote [an article](/articles/2025/alpine-ajax-django/) about my quest to simplify my web development stack. How I went from SvelteKit on the frontend and Django on the backend, to an all-Django stack for a new project, using Alpine AJAX to enable partial page updates.

I've now been using this new stack for a while, and my approach -as well as my opinion- has changed significantly. Let's get into what works, what doesn't, and where I ended up.

## A quick recap

[Alpine AJAX](https://alpine-ajax.js.org/) is a lightweight alternative to [htmx](https://htmx.org), which you can use to enhance server-side rendered HTML with a few attributes, turning `<a>` and `<form>` tags into AJAX-powered versions. No more full page refreshes when you submit a form.

The key mechanic: when a form has `x-target="comments"`, Alpine AJAX submits the form via AJAX, finds the element with that ID in the response, and swaps it into the page. The server returns HTML, not JSON.

In [the original article](/articles/2025/alpine-ajax-django/) I used [django-template-partials](https://github.com/carltongibson/django-template-partials) (since merged into Django itself) to mark sections of a template as named partials using `{% partialdef %}`. Combined with a custom `AlpineTemplateResponse` the view could automatically return just the targeted partial when the request came from Alpine AJAX.

## Where I began: template partials

Let's say you have an article page with the article body parsed from Markdown, a like button, and a comment section. The template looks something like this:

```django title="article.html"
{% extends "base.html" %}

{% block body %}
  <article>
    <h1>{{ article.title }}</h1>
    {{ article_html|safe }}

    {% partialdef like_form inline %}
      <form method="post" id="like_form" x-target="like_form">
        {% csrf_token %}
        <button type="submit" name="toggle-like">
          {% if article.is_liked %}Unlike{% else %}Like{% endif %}
        </button>
      </form>
    {% endpartialdef %}

    {% partialdef comments inline %}
      <div id="comments">
        {% for comment in article.comments.all %}
          <div>{{ comment.user }}: {{ comment.text }}</div>
        {% endfor %}

        <form method="post" x-target="comments">
          {% csrf_token %}
          {{ comment_form }}
          <button type="submit" name="add-comment">Submit</button>
        </form>
      </div>
    {% endpartialdef %}
  </article>
{% endblock %}
```

Every form action POSTs to the same article view, which handles all the actions in one big `post` method:

```python title="views.py"
class ArticleView(View):
    def get_context(self, request, pk):
        article = get_object_or_404(
            Article.objects.prefetch_related("comments")
            .annotate_is_liked(request.user),
            pk=pk,
        )

        return {
            "article": article,
            "article_html": markdown(article.body),
            "comment_form": CommentForm(),
        }

    def post(self, request, pk):
        context = self.get_context(request, pk)
        article = context["article"]

        if "toggle-like" in request.POST:
            if article.is_liked:
                article.unlike(request.user)
                article.is_liked = False
            else:
                article.like(request.user)
                article.is_liked = True

            return AlpineTemplateResponse(request, "article.html", context)

        if "add-comment" in request.POST:
            form = CommentForm(request.POST)
            if form.is_valid():
                Comment.objects.create(article=article, user=request.user, ...)

            return AlpineTemplateResponse(request, "article.html", context)

        return redirect(article)

    def get(self, request, pk):
        context = self.get_context(request, pk)
        return AlpineTemplateResponse(request, "article.html", context)
```

The `AlpineTemplateResponse` from [the original article](/articles/2025/alpine-ajax-django/) takes care of returning just the targeted partial when the request comes from Alpine AJAX. It works. I thought I was being smart to prevent template duplication this way, but there are two problems:

1. **The view does too much work.** Every POST action calls `get_context`, which fetches everything: the article, the parsed Markdown body, the comments, the like state, the comment form. When the user clicks "Like", we do all this work we'll never use in the partial template. The template partial means the *response* is small, but the *server-side work* is exactly the same as rendering the full page.

2. **The template is a mess.** Those `{% partialdef %}` blocks scattered throughout the template make it noisy and hard to read. In a small example it's fine, but in a real template with 200+ lines, it gets ugly fast.

## When doubt set in: switching to Jinja2

To be honest though, the real killer of my motivation while working on this project has been the Django Template Language. I'm sorry, but I just hate it. I have since 2009, and I still do. The syntax is bad enough, but then you have to constantly fight its limitations. The fact I can't simply call a function is so incredibly annoying, and is causing way more boilerplate with tons of custom template tags and filters.

So, switch to Jinja2, right? Except that template partials aren't supported in combination with Jinja2. No more `{% partialdef %}`. Which means returning full page responses for AJAX requests, which isn't exactly ideal.

I did it anyway. I ripped out all the `{% partialdef %}` tags, migrated my templates to Jinja2, and my views just returned the full template for AJAX requests. Alpine AJAX is smart enough to extract the elements it needs by their IDs, and throws away the rest.

This was simpler and I was much happier writing Jinja2 templates. But the wastefulness got worse. Before, the server at least returned a small response. Now it rendered the entire page *and* sent all of it over the wire, just for the browser to use a tiny piece of it.

It was at this moment that I seriously thought about throwing the entire frontend away and rebuilding it in SvelteKit, with Django REST Framework returning JSON responses. But that seemed like a pretty big waste of effort, so instead I took a deep breath and thought about what I wanted:

1. Jinja2 templates. Non-negotiable.
2. Small, fast AJAX responses. No rendering the full page for a like toggle.
3. No template duplication between the full page and the AJAX response.
4. Simple views that only do the work they need to do.

Template partials gave me #2 and #3, but not #1 or #4. Switching to Jinja2 and returning the full template for AJAX requests gave me #1 and #3, but not #2 or #4. I needed a different approach.

## Where I ended up: separate views with template includes

The answer turned out to be straightforward, and the one I initially discarded as "too much boilerplate": instead of one monolithic view handling all POST actions, split each action into its own view with its own URL. And instead of `{% partialdef %}`, use plain `{% include %}` tags to extract reusable template fragments.

Let me show you. Here's the simplified article template:

```django title="article.html"
{% extends "base.html" %}

{% block body %}
  <article>
    <h1>{{ article.title }}</h1>
    {{ article.body }}

    {% include "articles/_like_form.html" %}
    {% include "articles/_comments.html" %}
  </article>
{% endblock %}
```

Clean and readable. Each include is a self-contained fragment. And here's the like form:

```django title="_like_form.html"
<form method="post"
      action="{{ url('toggle-like', args=[article.id]) }}"
      id="like_form"
      x-target="like_form">
  {{ csrf_input }}
  {% if article.is_liked %}
    <button type="submit">Unlike</button>
  {% else %}
    <button type="submit">Like</button>
  {% endif %}
</form>
```

And finally, the view:

```python title="views.py"
class ToggleLikeView(LoginRequiredMixin, View):
    def post(self, request, pk):
        article = get_object_or_404(
            Article.objects.annotate_is_liked(request.user),
            pk=pk,
        )

        if article.is_liked:
            article.unlike(request.user)
            article.is_liked = False
            article.like_count -= 1
        else:
            article.like(request.user)
            article.is_liked = True
            article.like_count += 1

        if is_alpine(request):
            return TemplateResponse(
                request, "articles/_like_form.html",
                {"article": article},
            )

        # For non-Alpine requests, we just redirect back
        return redirect(article)
```

No comment queries. No form building. No Markdown parsing. Just the like state.

The `is_alpine` check provides a redirect fallback for non-JavaScript POST requests, keeping things progressive. And the `ArticleView` itself becomes GET-only. No more branching on POST keys. No `get_context` method that fetches everything for every action. Each view does one thing.

## The trade-offs

More templates. For the article page, I went from one template to several: the include fragments (`_like_form.html`, `_comments.html`) that are shared between the full page and the AJAX responses. When an action needs to update multiple elements on the page, you also end up with small response templates that combine the right includes. For example, if submitting a comment should update both the comment list and a comment count elsewhere on the page:

```jinja title="_add_comment_response.html"
{% include "articles/_comments.html" %}
{% include "articles/_engagement_counts.html" %}
```

Trivial, but still a file you have to create and name.

More views and URL routes. Each action gets its own view class and its own `path()` entry. For a page with likes, comments, and subscriptions, that's three or four extra views.

But here's what I got in return:

**Actual performance improvement.** Not just smaller responses, but less work on the server. Each view only queries what it needs.

**Jinja2.** I'm using Jinja2 instead of the Django Template Language. I can call functions, I have proper expressions, and I don't need custom template tags for basic things. This alone was worth the switch.

**Readable templates.** The main `article.html` is short and shows the page structure at a glance. Each fragment is self-contained. No `{% partialdef %}` blocks scattered everywhere.

**Simple views.** Each view does exactly one thing. Easy to understand, easy to test, easy to optimize.

## Conclusion

I went through three stages: template partials with Django Template Language, full-page responses with Jinja2, and finally separated views with template includes. Each step solved a real problem with the previous approach.

The pattern I've landed requires more files and views than I'd like, but each is simple and does one thing.

My overall feelings on Django + Alpine AJAX have also changed. I still believe there are benefits to using a simplified tech stack and using hypermedia as the engine of state. Just return HTML instead of returning JSON to a JavaScript framework which then has to turn it into HTML. Conceptually it just makes sense to me.

But the dream was to build a plain old Django application using simple views and simple templates, using old-fashioned MPA server-rendered pages. Sprinkle in a few Alpine AJAX attributes and magically your site gets SPA-like usability. And it simply hasn't played out that way for me. Yes, you *could* do that, if you're fine with the wastefulness of returning full pages as a response to AJAX requests. But when you want to do it better than that, you end up with more boilerplate to make it possible to return small bits of HTML.

And this isn't really about Alpine AJAX specifically; htmx would lead to the exact same place. The fundamental tension is in the HTML-over-the-wire approach itself: the server has to know which fragments of HTML to return, and that means structuring your views and templates around it. You trade the complexity of a JavaScript frontend for a different kind of complexity on the server.

Progressive enhancement adds to that complexity. Every view needs an `is_alpine` check with a redirect fallback, every form needs to work both as a regular POST and as an AJAX submit. If I dropped progressive enhancement and just required JavaScript, those redirect fallbacks and the branching that comes with them would disappear. The views would be simpler. But I think progressive enhancement is important enough to keep in place.

Would I use Alpine AJAX (or htmx) again? Honestly: probably not. I have a lot more fun when building frontends with SvelteKit. Building composable and reusable UI components is so much more natural there, and the performance is simply better (once the initial JS bundle has been downloaded and parsed). But am I going to throw away my current project's code and redo it all? No, I am not. Django with Alpine AJAX is a nice change of scenery, it's a nice playground I don't usually get to play in. I think I ended up with a good compromise, and hey: I still don't have to build and maintain a separate API, API docs, and frontend.