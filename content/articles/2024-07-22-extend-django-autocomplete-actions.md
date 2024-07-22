---
tags: django
summary: Extending Django’s autocomplete widget with a new action which copies the linked user’s email address to the clipboard.
---

# Extend Django’s autocomplete widget actions

When you use Django’s admin interface it’s often a good idea to use an autocomplete form field for a `ForeignKey` model field, especially once the related table has a lot of entries. For example an `Order` model has a relationship to a `User` model:

```python
class Order(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="orders",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
    )
```

Once you have thousands of users in your database, the admin interface when you want to add or edit an order becomes unusably slow, sometimes it just crashes. To solve this problem you can instruct the admin form to render the field as an autocomplete field:

```python
class OrderAdmin(admin.ModelAdmin):
    autocomplete_fields = ["user"]
```

This gets rendered like so, when editing an `Order` with a `User`:

![screenshot](/articles/images/django-icons-before.png)

This works great, but what if you want to add more actions at the end of that list? I am working on a project where the team’s support person asked me to make it easier to copy a user’s email address when looking at an `Order`. Or any other model with a relationship to a `User`: it gets tedious to have to click the little eye icon, copy the email address from the popup window, and then close the popup window again. If I could add another icon next to the eye icon which would immediately copy the email address to the clipboard, that would make their life a lot easier.

Turns out this is pretty easy. I created a subclass of Django’s built-in `RelatedFieldWidgetWrapper`:

```python
from django.contrib.admin.widgets import RelatedFieldWidgetWrapper

class CustomRelatedFieldWidgetWrapper(RelatedFieldWidgetWrapper):
    template_name = "admin/related_widget_wrapper.html"

    def get_context(self, name, value, attrs):
        context = super().get_context(name, value, attrs)
        if value and hasattr(self.rel.model, "email"):
            instance = self.rel.model.objects.get(pk=value)
            context["email"] = instance.email
        return context
```

The contents of the `admin/related_widget_wrapper.html` file:

```html
{% extends "admin/widgets/related_widget_wrapper.html" %}
{% load i18n static %}
<div class="related-widget-wrapper" {% if not model_has_limit_choices_to %}data-model-ref="{{ model_name }}"{% endif %}>
  {{ rendered_widget }}
  {% block links %}
    {{ block.super }}

    {% if not is_hidden %}
    {% if can_view_related %}
    {% if email %}
      <button 
        type="button" 
        style="padding: 0; margin: 0; border: 0; background: transparent; cursor: pointer;" 
        title="copy {{ email }}" 
        onclick="navigator.clipboard.writeText('{{ email }}')">
        <svg style="width: 16px; height: 18px; fill: #2c70bf;" xmlns="http://www.w3.org/2000/svg">...</svg>
      </button>
    {% endif %}
    {% endif %}
    {% endif %}
  {% endblock %}
</div>
```

I just used an inline SVG file, but you can of course also use an image tag with a locally hosted image.

Then to make Django use this custom version instead of the built-in one, I added the following lines to my root `urls.py`:

```python
from django.contrib.admin import widgets
from lib import CustomRelatedFieldWidgetWrapper

widgets.RelatedFieldWidgetWrapper = CustomRelatedFieldWidgetWrapper
```

And just like that we’ve added a new clickable icon which copies the email address to the clipboard:

![screenshot](/articles/images/django-icons-after.png)