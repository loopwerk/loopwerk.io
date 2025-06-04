---
tags: django, python
summary: Introducing ActionSerializerModelViewSet, a ViewSet that allows you to choose a serializer for each action and method combination.
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
class PostViewSet(ActionSerializerModelViewSet):
    serializer_class = PostDetailSerializer
    list_serializer_class = PostListSerializer
    write_serializer_class = PostWriteSerializer
```

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

And it also works for any extra actions you add onto the ViewSet. So you can have different serializers for each action, you can have different serializers for input and output, and a different serializer for every combination of action and method, with sensible fallback logic so you don’t have to specify a serializer for every possible combination (like you’re forced to do with rest-framework-actions).

Here’s the full code of `ActionSerializerModelViewSet`. Just drop it into your project (mine lives in a `lib.py` file) and use this instead of `ModelViewSet`.

```python
# mypy: ignore-errors

from rest_framework import mixins, permissions, status, viewsets
from rest_framework.generics import GenericAPIView
from rest_framework.response import Response


# Generic views

class ActionSerializerGenericAPIView(GenericAPIView):
    def get_action_serializer(self, method):
        assert hasattr(self, "action"), "View must have an `action` attribute"

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


# Mixins

class ActionSerializerCreateModelMixin(mixins.CreateModelMixin):
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


class ActionSerializerUpdateModelMixin(mixins.UpdateModelMixin):
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


# ViewSets

class ActionSerializerGenericViewSet(viewsets.ViewSetMixin, ActionSerializerGenericAPIView):
    pass


class ActionSerializerReadOnlyModelViewSet(
    mixins.RetrieveModelMixin, mixins.ListModelMixin, ActionSerializerGenericViewSet
):
    pass


class ActionSerializerModelViewSet(
    ActionSerializerCreateModelMixin,
    mixins.RetrieveModelMixin,
    ActionSerializerUpdateModelMixin,
    mixins.DestroyModelMixin,
    mixins.ListModelMixin,
    ActionSerializerGenericViewSet,
):
    pass
```

If you’re using [drf-spectacular](https://drf-spectacular.readthedocs.io/) to document your API (and if you’re not - you should), then the following code will make sure that the correct serializers are used for the request and response.

```python
from drf_spectacular.openapi import AutoSchema


class ActionSerializerAutoSchema(AutoSchema):
    def get_request_serializer(self):
        if self.method.lower() in {"post", "put", "patch"}:
            if hasattr(self.view, "get_action_serializer"):
                return self.view.get_action_serializer("write")
        return super().get_request_serializer()

    def get_response_serializers(self):
        if not hasattr(self.view, "get_action_serializer"):
            return super().get_response_serializers()

        method = self.method.lower()

        if method == "post":
            return {
                "201": self.view.get_action_serializer("read"),
            }
        elif method in {"put", "patch"}:
            return {
                "200": self.view.get_action_serializer("read"),
            }

        return super().get_response_serializers()
```

Simply add the following to settings.py and it’s automatically used:

```python
REST_FRAMEWORK = {
    "DEFAULT_SCHEMA_CLASS": "path.to.ActionSerializerAutoSchema",
}
```