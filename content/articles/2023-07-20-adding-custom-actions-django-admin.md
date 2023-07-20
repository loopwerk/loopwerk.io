---
tags: python, django
summary: Let's add custom actions to Django's admin site - but to the change form, not the list view.
---

# Adding custom actions to the Django Admin

For [a project I am working on](https://www.soundradix.com) I had to build a form where people can apply to get educational discounts on all the products in the shop. This form is sent to the Django backend, where it's stored in the database, but these applications have to be reviewed by someone from the support team.

Here's the list of requirements going in:

- We're going to use Django's built-in admin interface, as the support team is already using this for all other things.
- The model should be read-only in the admin UI: the applications can be denied or approved, but it doesn't make sense to edit them.
- Instead of the usual delete and save buttons, there should be two other buttons: deny and approve.
- When pressing either of these buttons, another page will be shown with a textarea pre-filled with some text which will be sent to the user who filled in the apply form.

When looking at the Django docs I came across something called [Admin actions](https://docs.djangoproject.com/en/4.2/ref/contrib/admin/actions/) which sounded perfect, but sadly that's purely for adding actions to the list-view, to execute some kind of action on one or multiple objects at the same time. That's not what I need. I'm pretty sure I'm not the only one who ran into the same wish to add a new action (page) to the admin interface and looked at the Admin actions docs in disappointed, so here's how I managed to fulfill my requirements in three easy steps.

## 1. Making the form read-only

This was really easy: just override the `has_change_permission` and `has_delete_permission` methods of your `ModelAdmin` subclass.

``` python
class EducationalDiscountApplicationAdmin(admin.ModelAdmin):
    list_display = ["user", "type", "institute", "program", "created"]
    list_filter = ["type", "created"]

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


admin.site.register(EducationalDiscountApplication, EducationalDiscountApplicationAdmin)
```

Now when opening an `EducationalDiscountApplication` object in the admin, the delete and save buttons are gone, replaced with a close button. The list view now even says "Select educational discount application to view" instead of "to change". Neat!

## 2. Adding the deny and approve buttons to the change form

I created a new template called `submit_line.html`, in the `templates/admin/[app_name]/[model_name]/` folder, with the following code:

```
{% extends "admin/submit_line.html" %}
{% load i18n admin_urls %}
{% block submit-row %}
    <a href="../deny/" class="closelink" style="background:red;">DENY</a>
    <a href="../approve/" class="closelink" style="background:green;">APPROVE</a>
{% endblock %}
```

And already when I open the change form of an `EducationalDiscountApplication` object, I can see the new buttons! 

![screenshot](/articles/images/django-admin-actions-1.png)

Clicking on them doesn't do anything yet, as these URLs are not recognized by the admin site yet. That's the third and final part of the puzzle.

# 3. Adding the new views to the admin site

Add the `get_urls` method to the `ModelAdmin` subclass:

``` python
class EducationalDiscountApplicationAdmin(admin.ModelAdmin):
    list_display = ["user", "type", "institute", "program", "created"]
    list_filter = ["type", "created"]

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

    def get_urls(self):
        urls = super().get_urls()
        my_urls = [
            path("<int:pk>/deny/", self.admin_site.admin_view(self.deny_view)),
            path("<int:pk>/approve/", self.admin_site.admin_view(self.approve_view)),
        ]
        return my_urls + urls

    def deny_view(self, request, pk):
        application = EducationalDiscountApplication.objects.get(pk=pk)

        if request.method == "POST":
            # Do something here:
            # Send email, delete the application form, etc

            return redirect("admin:sr_app_educationaldiscountapplication_changelist")

        context = dict(
            self.admin_site.each_context(request),
            object=application,
            opts=EducationalDiscountApplication._meta,
            title="Deny Application?",
        )
        return TemplateResponse(request, "admin/sr_app/educationaldiscountapplication/deny_application.html", context)
        
    def approve_view(self, request, pk):
        # ...
````

And the template:

```
{% extends "admin/base_site.html" %}
{% load i18n admin_urls static %}

{% block breadcrumbs %}
<div class="breadcrumbs">
<a href="{% url 'admin:index' %}">{% translate 'Home' %}</a>
&rsaquo; <a href="{% url 'admin:app_list' app_label=opts.app_label %}">{{ opts.app_config.verbose_name }}</a>
&rsaquo; <a href="{% url opts|admin_urlname:'changelist' %}">{{ opts.verbose_name_plural|capfirst }}</a>
&rsaquo; <a href="{% url opts|admin_urlname:'change' object.pk|admin_urlquote %}">{{ object|truncatewords:"18" }}</a>
&rsaquo; {% translate 'Deny' %}
</div>
{% endblock %}

{% block content %}
<form method="post">{% csrf_token %}
    <div>
        <input type="hidden" name="post" value="yes">
        <textarea style="width: 100%; height: 400px; margin-bottom: 20px;" name="text"></textarea>
        <input type="submit" value="{% translate 'Deny the application and send the email' %}">
    </div>
</form>
{% endblock %}
```

And with this in place the new page is shown when the DENY button is pressed, and form submits can easily be handled in the view code. Best of all, the page doesn't look out of place at all, as it's rendered in the same way as the delete confirmation page for example, with the same sidebar, header, breadcrumbs, the whole shebang.

![screenshot](/articles/images/django-admin-actions-2.png)