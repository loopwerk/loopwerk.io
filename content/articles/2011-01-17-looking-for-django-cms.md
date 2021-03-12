---
tags: review, python, django
---

# Looking for a Django CMS which suits my needs
I need to build a content-based website for a client, in Django. Well, that's easy right? Pick one of the content management systems available, build some templates and css, and ta-da, done. Since I have used [Django-CMS][1] in previous projects, that would make my choice pretty easy too. It's easy to work with, flexible and pretty user-friendly.

Sadly though, after a day of wrestling with Django-CMS, I am not so sure about this choice. Let me explain why.

The client needs a site with some basic pages (about me, contact information), an articles section, and a home page which shows a mix of latest articles and content that needs to be editable. My first thought was to use Django-CMS in combination with [Zinnia][2] for the articles, just as I did for this site and which I still like a lot. However, for this project it just isn't suitable:

- There are going to be multiple writers who can all add new articles, but should only be able to edit their own, and;
- all new articles need to be approved by an editor before they can be published on the site.

Zinnia doesn't offer this level of moderation, and while I could possibly, eventually, get this to work, there is something nagging me about the combination of Django-CMS and Zinnia: the plugin-based system and the wysiwyg editor. I just don't like the plugin system used by Django-CMS, where you can add multiple blocks of content to a page. This content can for example be text or a picture. I'd much rather have just one big TinyMCE area with a filebrowser plugin for including pictures right there.

With Zinnia it is possible to use TinyMCE and the filebrowser plugin, great! Since 90% of the site will consist of articles, at least this part is easy to edit for the writers. However... this functionality depends on the [Grappelli][3] skin for the Django admin interface, which is not compatible with Django-CMS. So I can't use it.

Not all is lost: Zinnia can also use the plugin system offered by Django-CMS, so at least it's possible to enter content and pictures. There is a big usability problem with this though: you first need to create a blank article, save it and only then you can add plugins to it. How I am going to sell this to the client?

Right now I am thinking about writing my own articles-app, which does simple moderation and uses TinyMCE and filebrowser. This means I need Grappelli, so I need a stable CMS that plays nice with it and offers at least the following two features:

- TinyMCE and filebrowser, so the editing is consistent
- App integration, for including the articles section in the menu

[FeinCMS][4] could be nice, but as far as I can see from the docs, this too doesn't offer a TinyMCE widget with media/filebrowser integration. [Mezzanine][5] is pretty cool too, but I can't use their integrated blog manager, as it doesn't do moderation.

Any ideas? I know that it would be way easier to just use Plone or TYPO3 or even Wordpress, but the client specifically asked for Django.

  [1]: http://www.django-cms.org/
  [2]: https://github.com/Fantomas42/django-blog-zinnia
  [3]: http://code.google.com/p/django-grappelli/
  [4]: http://www.feinheit.ch/labs/feincms-django-cms/
  [5]: https://github.com/stephenmcd/mezzanine
