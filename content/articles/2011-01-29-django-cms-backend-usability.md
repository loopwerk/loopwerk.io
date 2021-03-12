---
tags: review, python, django
---

# Django-CMS backend usability
Yesterday I wrote [an article](/articles/2011/django-cms-vs-feincms-vs-mezzanine/) comparing Django-CMS, FeinCMS and Mezzanine. One of the conclusions was that while Django-CMS is the best CMS on paper, I don't like its backend interface that much. I thought it would be a good idea to properly explain what I don't like about it, and try to come up with a better interface.

## The problem
When you edit a page in the CMS, there is no way to immediately see the content that's on the page. Have a look at the first screenshot: I can see that there is a "content" placeholder that contains a text plugin and a picture, and an "aside" placeholder that contains a text plugin. But what text? Which picture? This is not "what you see is what you get" levels of easy.

The second problem I have is when you edit a plugin. Have a look at the second screenshot: the current text content is shown both as preview and wysiwyg editor. I don't see how this is helpful, both (should) show the same content with the same markup and layout. The only place where I found this way of showing the preview together with the form is when editing a picture plugin.

## A possible solution
The frontend editing of Django-CMS is very nice. You see the content of the entire page, click on one of the plugins and an editor pops up. Why not replicate this in the admin interface? Show those preview blocks under each other with a link to add a new block to the page. Editing content could be done in a popup just as in the frontend.

With this solution it's possible to see the layout of the entire page. It also solves the usability problem of multiple save buttons on screen at the same time: currently when you begin to edit a plugin that form gets its own save button, which needs to be clicked before you can then save the page itself.  When you present the form in a modal popup, it is immediately clear that you need to close that popup by saving or canceling.

This is a very basic mockup, of course you'd need to be able to see and edit multiple placeholders. I don't know what would work best: tabs for each placeholder, placeholders underneath each other (kinda like the current interface does), or maybe even next to each other. I think that last option could work very well, at least as long as you don't have more than two placeholders.

I am very interested in your opinions about the current Django-CMS backend, its usability problems and your solution.
