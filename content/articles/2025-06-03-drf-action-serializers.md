---
tags: django, python, news
summary: An easy way to use different serializers for different actions and request methods in Django REST Framework.
---

# Announcing drf-action-serializers

Imagine a simple Django REST Framework serializer and view like this:

```python
from rest_framework import serializers
from rest_framework import viewsets
from .models import Post

class PostSerializer(serializers.ModelSerializer):
    class Meta:
        model = Post
        fields = "__all__"

class PostViewSet(viewsets.ModelViewSet):
    serializer_class = PostSerializer

    def get_queryset(self):
        return Post.objects.all()
```

The `PostSerializer` class is used for everything: the list of posts, retrieving a single post, the payload when creating or updating a post, and the response when creating or updating a post. 

I find that this is often not what I want; for example I often want a simple version of the model to be returned in the list endpoint (`/posts/`), while the full model is returned in the retrieve endpoint (`/posts/{post_id}/`). And I also often want that the *input* serializer is different from the *output* serializer, when creating or updating something.

Using different serializers in the list and retrieve endpoints isn’t too hard:

```python
class PostViewSet(viewsets.ModelViewSet):
    def get_serializer_class(self):
        if self.action == "list":
            return PostListSerializer
        return PostDetailSerializer
```

But when you also want to use different input and output serializers when creating and updating models, then you need to override a lot more code:

```python
class PostViewSet(viewsets.ModelViewSet):
    def get_serializer_class(self):
        if self.action == "list":
            return PostListSerializer
        return PostDetailSerializer

    def create(self, request, *args, **kwargs):
        serializer = PostWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)

        response_serializer = PostDetailSerializer(
            instance=serializer.instance,
            context=self.get_serializer_context(),
        )

        headers = self.get_success_headers(response_serializer.data)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()
        serializer = PostWriteSerializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)

        if getattr(instance, "_prefetched_objects_cache", None):
            # If 'prefetch_related' has been applied to a queryset, we need to
            # forcibly invalidate the prefetch cache on the instance.
            instance._prefetched_objects_cache = {}

        response_serializer = PostDetailSerializer(
            instance=serializer.instance,
            context=self.get_serializer_context(),
        )
        return Response(response_serializer.data)
```

This is starting to get pretty unwieldy for something that comes up all time time. Or what about different serializers for different [router actions within a viewset](https://www.django-rest-framework.org/api-guide/viewsets/#marking-extra-actions-for-routing)? You keep adding more and more code to handle all the different actions within the `get_serializer_class` method.

Today I want to present a better way, inspired by [rest-framework-actions](https://github.com/AlexisMunera98/rest-framework-actions) and [drf-rw-serializers](https://github.com/vintasoftware/drf-rw-serializers). 

The first project, rest-framework-actions, allows you to specify different serializers for different actions (so you can have a `list_serializer_class` which is different from the `serializer_class`), which is super useful, as well as different serializers for input versus output. It’s almost perfect, but not quite. For example you can’t specify different serializers for extra router actions, and since there’s no serializer fallback logic you end up being forced to add six properties to your ViewSets.

The second project, drf-rw-serializers, allows you to specify different serializers for the write and read actions: `write_serializer_class` and `read_serializer_class`, and it handles serializer fallbacks a lot better. But it doesn’t allow you to specify different serializers for different actions, it’s a bit too simple.

So I took these ideas, evolved it, and now your view can look like this:

```python
class PostViewSet(ActionSerializerModelViewSet):
    serializer_class = PostDetailSerializer
    list_serializer_class = PostListSerializer
    write_serializer_class = PostWriteSerializer
```

And just like that you’re using a different serializer for the list action, and for the create and update actions.

Or you can get super specific, like this:

```python
class PostViewSet(ActionSerializerModelViewSet):
    list_read_serializer_class = PostListSerializer
    retrieve_read_serializer_class = PostDetailSerializer
    create_write_serializer_class = PostWriteSerializer
    create_read_serializer_class = PostListSerializer
    update_write_serializer_class = PostWriteSerializer
    update_read_serializer_class = PostDetailSerializer
```

Now you’re using different input and output serializers as well!

And it also works for any extra actions you add onto the ViewSet. So you can have different serializers for each action, you can have different serializers for input and output, and a different serializer for every combination of action and method, with sensible fallback logic so you don’t have to specify a serializer for every possible combination (like you’re forced to do with rest-framework-actions).

The code is [published on PyPI](https://pypi.org/project/drf-action-serializers/) and can be installed with one command:

```bash
$ uv add drf-action-serializers
```

There’s nothing to configure, there is no step 2. Now you can use the ViewSets from `drf_action_serializers.viewsets` instead of from `rest_framework.viewsets`.

If you’re using [drf-spectacular](https://drf-spectacular.readthedocs.io/) to document your API (and if you’re not - you should), then there’s a cool optional package to install:

```bash
$ uv add drf-action-serializers[spectacular]
```

Simply add the following to settings.py and it’s automatically used:

```python
REST_FRAMEWORK = {
    "DEFAULT_SCHEMA_CLASS": "drf_action_serializer.spectacular.ActionSerializerAutoSchema",
}
```

Your API docs will now show the correct schemas for the request and the response.