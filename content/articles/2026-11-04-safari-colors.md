---
tags: browsers
summary: Safari's "Show color in tab bar" setting doesn't always respect a website's color, depending on whether macOS is in light mode or dark mode.
---

# Safari’s tab bar has a dark mode bias

There's a setting in Safari, called "Show color in tab bar". When enabled, Safari will extend the website's background color into the window chrome, including the address bar, tab bar, and other toolbars.

I normally don't have this setting enabled, as I don't want my browser to blink in different colors like a deranged clown when I switch between tabs, but I decided to try it with my own website, and I found some weird behavior.

When macOS is in light mode, Safari will always use the website's background color, no matter if it's dark or light:

![](/articles/images/safari-colors/light_mode_dark_site.webp)
{.shadow}

![](/articles/images/safari-colors/light_mode_light_site.webp)
{.shadow}

But when macOS is in dark mode, then Safari will only respect dark websites. Light-colored websites will not get a light tab bar:

![](/articles/images/safari-colors/dark_mode_dark_site.webp)
{.shadow}

![](/articles/images/safari-colors/dark_mode_light_site.webp)
{.shadow}

One of these is not like the others... Weird, huh?