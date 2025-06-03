---
tags: django, python
summary: Introducing ActionSerializerViewSet, a ViewSet that allows you to choose a serializer for each action and method combination.
---

# An easy way to use different serializers for different actions and request methods in Django REST Framework

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

I find that this is often not what I want; for example I often want a simple version of the model to be returned in the list endpoint (`/posts/`), while the full model is returned in the retrieve endpoint (`/posts/{post_id}/`). And I also often want that the *input* serializer is different from the *output* serializer, when creating or updating something (especially when using DRF’s built-in Browsable API, because it includes all the read-only fields in the example input payload, causing confusion).

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
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)

        response_serializer = PostWriteSerializer(
            instance=serializer.instance,
            context=self.get_serializer_context(),
        )

        headers = self.get_success_headers(response_serializer.data)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)

        if getattr(instance, "_prefetched_objects_cache", None):
            # If 'prefetch_related' has been applied to a queryset, we need to
            # forcibly invalidate the prefetch cache on the instance.
            instance._prefetched_objects_cache = {}

        response_serializer = PostWriteSerializer(
            instance=serializer.instance,
            context=self.get_serializer_context(),
        )
        return Response(response_serializer.data)
```

This is starting to get pretty unwieldy for something that comes up all time time. Or what about different serializers for different [router actions within a viewset](https://www.django-rest-framework.org/api-guide/viewsets/#marking-extra-actions-for-routing)? You keep adding more and more code to handle all the different actions within the `get_serializer_class` method.

Today I want to present a better way, inspired by [rest-framework-actions](https://github.com/AlexisMunera98/rest-framework-actions) and [drf-rw-serializers](https://github.com/vintasoftware/drf-rw-serializers). 

The first project, rest-framework-actions, allows you to specify different serializers for different actions (so you can have a `list_serializer_class` which is different from the `serializer_class`), which is super useful, as well as different serializers for input versus output. It’s almost perfect, but not quite. For example you can’t specify different serializers for added actions, and since there’s no serializer fallback logic you end up being forced to six properties to your ViewSets.

The second project, drf-rw-serializers, allows you to specify different serializers for the write and read actions: `write_serializer_class` and `read_serializer_class`, and it handles serializer fallbacks a lot better. But it doesn’t allow you to specify different serializers for different actions, it’s a bit too simple.

So I took these ideas, evolved it, and now your view can look like this:

```python
class PostViewSet(ActionSerializerViewSet):
    serializer_class = PostDetailSerializer
    list_serializer_class = PostListSerializer
    write_serializer_class = PostWriteSerializer
```

Or you can get super specific, like this:

```python
class PostViewSet(ActionSerializerViewSet):
    list_read_serializer_class = PostListSerializer
    retrieve_read_serializer_class = PostDetailSerializer
    create_write_serializer_class = PostWriteSerializer
    create_read_serializer_class = PostListSerializer
    update_write_serializer_class = PostWriteSerializer
    update_read_serializer_class = PostDetailSerializer
```

And it also works for any extra actions you add onto the ViewSet. So you can have different serializers for each action, you can have different serializers for input and output, and a different serializer for every combination of action and method, with sensible fallback logic so you don’t have to specify a serializer for every possible combination (like you’re forced to do with rest-framework-actions).

Here’s the full code of `ActionSerializerViewSet`. Just drop it into your project (mine lives in a `lib.py` file) and use this instead of `ModelViewSet`.

```python
from rest_framework import permissions, status, viewsets
from rest_framework.response import Response


class ActionSerializerViewSet(viewsets.ModelViewSet):
    """
    A ModelViewSet that enables the use of different serializers for responses and
    requests for update/create, as well as different serializers for different actions.

    The create and update actions use a special write serializer, while the response of these
    actions use the read serializer.
    """

    def get_action_serializer(self, method):
        result = (
            getattr(self, f"{self.action}_{method}_serializer_class", None)
            or getattr(self, f"{self.action}_read_serializer_class", None)
            or getattr(self, f"{self.action}_serializer_class", None)
            or getattr(self, f"{method}_serializer_class", None)
            or getattr(self, "read_serializer_class", None)
            or getattr(self, "serializer_class", None)
        )

        assert result is not None, (
            f"{self.__class__.__name__} should either include one of `{self.action}_{method}_serializer_class`, `{self.action}_read_serializer_class`, `{self.action}_serializer_class`, `{method}_serializer_class`, `read_serializer_class`, and `serializer_class` attribute, or override the `get_serializer_class()` method"
        )

        return result

    def get_serializer_class(self):
        method = "read" if self.request.method in permissions.SAFE_METHODS else "write"
        return self.get_action_serializer(method)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)

        response_serializer = self.get_action_serializer("read")(
            instance=serializer.instance,
            context=self.get_serializer_context(),
        )

        headers = self.get_success_headers(response_serializer.data)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)

        if getattr(instance, "_prefetched_objects_cache", None):
            # If 'prefetch_related' has been applied to a queryset, we need to
            # forcibly invalidate the prefetch cache on the instance.
            instance._prefetched_objects_cache = {}

        response_serializer = self.get_action_serializer("read")(
            instance=serializer.instance,
            context=self.get_serializer_context(),
        )
        return Response(response_serializer.data)
```

Disclaimer: this code could (and probably should) be split up into multiple mixins, so you don’t always get the full set of actions that come with `ModelViewSet` when you use `ActionSerializerViewSet`. Once I have a need for that in my real-world project I’ll make the changes and update this post. For now I don’t want to post this code to GitHub, maybe later.