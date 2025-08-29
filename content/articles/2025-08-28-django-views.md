---
tags: python, django
summary: Why I only use Django's base View class instead of generic class-based views or function-based views.
---

# How I write Django views

When learning Django, one of the first major forks in the road is how to write your views. Django gives you two main options: simple functions or powerful classes. The official tutorial starts you off gently with function-based views.

It begins with the basics:

```python
def index(request):
    return HttpResponse("Hello, world. You're at the polls index.")
```

It then gets a bit more complicated, but still using function-based views:

```python
def index(request):
    latest_question_list = Question.objects.order_by("-pub_date")[:5]
    context = {"latest_question_list": latest_question_list}
    return render(request, "polls/index.html", context)
```

But quickly after that, it dives into generic class-based views (CBV):

```python
class IndexView(generic.ListView):
    template_name = "polls/index.html"
    context_object_name = "latest_question_list"

    def get_queryset(self):
        """Return the last five published questions."""
        return Question.objects.order_by("-pub_date")[:5]
```

I think this is a mistake. There are a lot of generic views in Django: View, TemplateView, DetailView, ListView, FormView, CreateView, DeleteView, UpdateView, RedirectView, plus a whole bunch of date-based views: ArchiveIndexView, YearArchiveView, MonthArchiveView, WeekArchiveView, DayArchiveView, TodayArchiveView, DateDetailView.

By far the biggest issue I have with these views is their hidden complexity. Just look at the [documentation of DetailView](https://docs.djangoproject.com/en/5.2/ref/class-based-views/generic-display/#detailview). To understand this one class, you need to be aware of its inheritance tree:

- `django.views.generic.detail.SingleObjectTemplateResponseMixin`
- `django.views.generic.base.TemplateResponseMixin`
- `django.views.generic.detail.BaseDetailView`
- `django.views.generic.detail.SingleObjectMixin`
- `django.views.generic.base.View`

And then you need to know its method resolution order, or what it calls internally. The "method flowchart" includes:

- `setup()`
- `dispatch()`
- `http_method_not_allowed()`
- `get_template_names()`
- `get_slug_field()`
- `get_queryset()`
- `get_object()`
- `get_context_object_name()`
- `get_context_data()`
- `get()`
- `render_to_response()`

That’s 11 methods spread across 5 classes and mixins. Debugging a view or figuring out exactly which method to override to make the view behave in a certain way quickly becomes a case of opening way too many files and jumping back and worth between different method declarations. It’s just too much.

The supposed benefit is to make your views simpler with less code, but honestly for simple views it doesn’t really save any lines, and for complex views you’re often fighting against the default behavior of the generic views.

There is [so](https://docs.djangoproject.com/en/5.2/topics/class-based-views/generic-display/) [much](https://docs.djangoproject.com/en/5.2/topics/class-based-views/generic-editing/) [documentation](https://docs.djangoproject.com/en/5.2/topics/class-based-views/mixins/) [about](https://docs.djangoproject.com/en/5.2/ref/class-based-views/flattened-index/) all these view classes and mixins, it really doesn’t make things any simpler.

This complexity is why I'm a big fan of the argument made in [Django Views — The Right Way](https://spookylukey.github.io/django-views-the-right-way/) by Luke Plant. He advocates for using function-based views for everything. In his own words:

> One of the reasons for the pattern I’m recommending is that it makes a great starting point for doing anything. The body of the view — the function that takes a request and returns a response — is right there in front of you... If a developer understands what a view is... they will likely have a good idea of what code they need to write. The code structure in front of them will not be an obstacle. The same is not true of using CBVs as a starting point. As soon as you need any logic... you’ve got to know which methods or attributes to define, which involves knowing a massive API.

It’s a great guide that shows how common CBV patterns can be implemented more explicitly and often more concisely with functions. I highly recommend reading it.

However, I take a slightly different approach in my own projects: I only use the base `View` class. I avoid both function-based views *and* the complex generic class-based views. This gives me what I consider the perfect middle ground. It provides a clean way to organize code by request method (get, post, put, etc.) and automatically handles `405 Method Not Allowed` responses for you.

So, instead of a function-based view with a big `if` block:

```python
def comment_form_view(request, post_id):
    post = get_object_or_404(Post, pk=post_id)

    if request.method == "POST":
        form = CommentForm(data=request.POST)
        if form.is_valid():
            comment = form.save(commit=False)
            comment.post = post
            comment.save()
            return redirect(post)  # assumes Post has get_absolute_url()
    else:
        form = CommentForm()

    return TemplateResponse(request, "form.html", {"form": form, "post": post})
```

I write this:

```python
class CommentFormView(View):
    def get(self, request, post_id, *args, **kwargs):
        post = get_object_or_404(Post, pk=post_id)
        form = CommentForm()
        return TemplateResponse(request, "form.html", {"form": form, "post": post})

    def post(self, request, post_id, *args, **kwargs):
        post = get_object_or_404(Post, pk=post_id)
        form = CommentForm(data=request.POST)
        if form.is_valid():
            comment = form.save(commit=False)
            comment.post = post
            comment.save()
            return redirect(post)
        
        return TemplateResponse(request, "form.html", {"form": form, "post": post})
```

While this class-based version is a few lines longer, I find the separation of `get` and `post` logic far cleaner than nesting the core POST handling inside an `if request.method == "POST"` block.

You might notice a small duplication here: `get_object_or_404` is called in both `get` and `post`. The "textbook" way to solve this using the base `View` class is to use the `dispatch` method. It runs before `get` or `post` are called, making it a natural place for setup logic:

```python
class CommentFormView(View):
    def dispatch(self, request, post_id, *args, **kwargs):
        self.post_obj = get_object_or_404(Post, pk=post_id)
        return super().dispatch(request, *args, **kwargs)

    def get(self, request, *args, **kwargs):
        form = CommentForm()
        return TemplateResponse(request, "form.html", {"form": form, "post": self.post_obj})

    def post(self, request, *args, **kwargs):
        form = CommentForm(data=request.POST)
        if form.is_valid():
            comment = form.save(commit=False)
            comment.post = self.post_obj
            comment.save()
            return redirect(self.post_obj)
        
        return TemplateResponse(request, "form.html", {"form": form, "post": self.post_obj})
```

However, I don't really use this pattern in my own code, as it feels a bit too magical. Instead of a method that we explicitly call ourselves, it’s one more thing to have to know about Django’s `View` implementation.

For a simple case like this, I often find the small duplication is actually the clearest option. It's explicit and requires zero cognitive overhead to understand what's happening in `get` and `post`. If the setup logic becomes more complex, or when there is a bigger shared context with more variables in play, then instead of using `dispatch` I'll extract it into a simple helper method that I can call from both places. This keeps the control flow explicit:

```python
class CommentFormView(View):
    def get_shared_context(self, request, post_id):
        # Imagine that this would return more than just the one post variable 😅
        post = get_object_or_404(Post, pk=post_id)
        return {"post": post}

    def get(self, request, post_id, *args, **kwargs):
        form = CommentForm()
        context = self.get_shared_context(request, post_id) | {"form": form}
        return TemplateResponse(request, "form.html", context)

    def post(self, request, post_id, *args, **kwargs):
        form = CommentForm(data=request.POST)
        context = self.get_shared_context(request, post_id) | {"form": form}
        post = context["post"]

        if form.is_valid():
            comment = form.save(commit=False)
            comment.post = post
            comment.save()
            return redirect(post)
        
        return TemplateResponse(request, "form.html", context)
```

This, for me, is the sweet spot. We've eliminated the code duplication, but in a way that remains completely explicit. The `get` and `post` methods are in full control. There's no "magic" state being set behind the scenes. We get the simplicity and explicitness of a function, but with better organization, automatic HTTP method handling, and the ability to share logic on our own terms.

And yes, Django’s `FormView` is smaller in its most basic form:

```python
class CommentFormView(FormView):
    template_name = "form.html"
    form_class = CommentForm

    def form_valid(self, form):
        post = get_object_or_404(Post, pk=self.kwargs["post_id"])
        comment = form.save(commit=False)
        comment.post = post
        comment.save()
        return redirect(post)
```

But as soon as you want to add custom logic to the GET request (like adding extra context), handle different POST outcomes, or customize error handling, you quickly end up overriding multiple methods. At that point, you're back to deciphering the framework's internals, and the initial benefit of brevity is lost to complexity. My approach keeps all the logic right in front of you, every time.