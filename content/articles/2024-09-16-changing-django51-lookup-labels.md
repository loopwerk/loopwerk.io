---
tags: django, python, howto
summary: Django 5.1 adds related field lookup to the model admin’s list_display, but with an annoying quirk. Let’s fix that!
---

# Changing the way Django 5.1 generates admin list labels

I love Django’s admin feature. It’s so easy to quickly build out a complete CRUD admin for all your models, it’s truly one of Django’s strongest points. One thing that was always a bit annoying though was adding related fields to a `ModelAdmin`’s `list_display`.

For example let’s say your `User` model has a one to one relationship with an `AccountSettings` model, and in the admin’s list of users you want to show the users' names as well as the value of `AccountSettings.pace_account_id`. Until Django 5.1 you’d have to create a getter function like this:

```python
class UserAdmin(BaseUserAdmin):
    list_display = [
        "name",
        "pace_account_id",
    ]

    @admin.display(ordering="account_settings__pace_account_id")
    def pace_account_id(self, obj):
        return obj.account_settings.pace_account_id
```

This works fine: the header in the table is “PACE ACCOUNT ID”, and it’s sortable:

![screenshot](/articles/images/lookup_after.png)

But it’s also quite a lot of annoying boilerplate code to have to write with lots of repetition. Why can `list_filter` and `search_fields` work with related fields using the double underscore lookup method (`account_settings__pace_account_id`), yet `list_display` can not?

Good news: this has been fixed in Django 5.1! I was super excited about this feature, since it would allow me to remove a bunch of boilerplate code. Now I can just add `account_settings__pace_account_id` to `list_display` and it just works, sortable and all. However, I immediately noticed something quite annoying: the header in the table isn’t just “PACE ACCOUNT ID” as I would expect, but rather the full “ACCOUNT SETTINGS PACE ACCOUNT ID”. This is way too long and takes up way too much space:

![screenshot](/articles/images/lookup_before.png)

After some puzzling, I found a solution. Django uses `django.forms.utils.pretty_name` to generate the table headers, so we’re going to replace this with our own version.

```python
import inspect
from django.db.models.constants import LOOKUP_SEP
from django.forms import utils

def custom_pretty_name(name):
    if LOOKUP_SEP in name and inspect.stack()[1][3] == "label_for_field":
        name = name.split(LOOKUP_SEP)[-1]
    return pretty_name(name)


pretty_name = utils.pretty_name
utils.pretty_name = custom_pretty_name
```

This code needs to be placed inside of `settings.py`, all the way at the top. Placing it anywhere else means that Django still uses the original version before it’s replaced with the custom one. Once you add this code to the top of `settings.py`, the table headers are now nicely succinct, and by using Python’s `inspect` module we only change the behavior when the function is called by Django’s own `label_for_field` method. 

We also defer to the original method to return the pretty name, rather than copying Django’s code into our custom function. So in the case that Django would modify their `pretty_name` implementation, we automatically make use of it as well.

And with that, the table header looks great once again, without all the boilerplate code:

![screenshot](/articles/images/lookup_after.png)