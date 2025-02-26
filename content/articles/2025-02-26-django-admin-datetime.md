---
tags: django, python
summary: When you have admin users in multiple time zones, the way Django handles the input and display of dates and times is causing confusion. Here’s how you can improve things.
---

# Django Admin’s handling of dates and times is very confusing

Question: when you see this help text under a field in the Django Admin, do you know what it means?

![](/articles/images/django-admin-datetime.png)

“Note: You are 1 hour ahead of server time.” Uhm, ok? Does that mean I have to enter times with an offset of one hour? Do I add an hour or subtract an hour? Or do I enter times “as is”, and Django is smart enough to deal with the difference of my time zone and “server time”?

My Django project has admins in multiple time zones, and all of them have asked me what the hell they are supposed to fill in there. For example, say say that we want an item to be active from March 1, 2025 at 8:00, Pacific Time. The staff member in question is located in Berlin. Does this person enter 17:00, which is Pacific Time translated to CET? But you get this warning about being ahead of server time. So does the admin enter 16:00 instead? What even is the “server time”, and why should this person care? I happen to know it’s set to UTC, but my admins don’t know.

```python
USE_TZ = True
TIME_ZONE = "UTC"
```

Why doesn’t the Django Admin just say “date and time must be entered as UTC”? That would make it super clear how people should enter the values, which the current note does not. At the moment I am adding `help_text=f"Date and time must be entered as {settings.TIME_ZONE}."` to all my `DateTimeField` instances, and I’m hiding Django’s default note with the following css:

```css
.timezonewarning { 
  display: none; 
}
```

This is a substantial improvements for our admins, who now understand exactly what’s being asked of them. They know that dates and times have to be entered in a certain time zone, and that they should translate their “target time zone” to UTC.

![](/articles/images/django-admin-datetime-after.png)

You know what would make this much better? Add a dropdown with time zones next to the date and time fields, so that dates and times can be entered for a specific time zone without having to calculate anything. You can still store everything as UTC, and if you also store that time zone, you can show these values in that time zone as well. Or just store the `datetime` in the actual time zone, with the correct offset? Does everything really have to be stored as UTC?

Currently when dates and times are shown in the Admin interface, it shows them in the “server time” time zone, rather than translated to the browser’s time zone. I understand why: Django doesn’t know a user’s time zone (since this is not something that’s stored in the `User` model). But, it should be able to use the browser’s time zone to show these dates and times in the user’s local time zone, right? Or another option: add a time zone picker to the top menu, next to the theme switcher for example. Have users pick their time zone, and save this in a cookie. 

At the very least, it should simply say what time zones these dates and times are shown in - so instead of `March 1, 2025, 16:00`, show `March 1, 2025, 16:00 (UTC)`. No more room for confusion and it’s a very easy fix without the need to translate anything to other time zones.

The docs actually say this:

> When support for time zones is enabled, Django stores datetime information in UTC in the database, uses time-zone-aware datetime objects internally, and translates them to the end user’s time zone in templates and forms.

But.. it’s doesn’t translate datetime objects to the *end user’s time zone*, that’s just not true. It translates them to the *server time zone* (`settings.TIME_ZONE`), but when you’re dealing with admins in multiple time zones, this is not the same as the *end user’s time zone*. Django doesn’t use `settings.TIME_ZONE` when storing datetime objects by the way, that’s always done as UTC. So if `settings.TIME_ZONE` is purely used for display purposes, it should be rather easy to replace this with a time zone dropdown in the top menu, right?

I also think the Django’s time zones documentation should be updated, to remove the text about “end user’s time zone” and instead link to `settings.TIME_ZONE`. Django should also decide on one term: end user’s time zone or “server time”. This is not the same thing unless all your admins and your server(s) are in the same timezone.

I brought all of this up in a Discourse discussion in November of last year, where I was told to create a ticket. So I created a [ticket](https://code.djangoproject.com/ticket/35951), which promptly got closed because it needs discussion first. Fair enough (although annoying), so next I created a forum topic about this, where it then kinda died. So if you agree that Django’s handling of dates and times and time zones should be improved in the Admin, please [chime in on the forum](https://forum.djangoproject.com/t/djangos-handling-of-datetimes-in-the-admin-interface-can-be-greatly-improved/36823) and let’s get this ball rolling again. The Django Admin needs better handling of time zones!