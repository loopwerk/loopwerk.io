---
tags: review, python, django
---

# Django-CMS vs. FeinCMS vs. Mezzanine
When you need a content management system for Django, there is enough choice. Maybe even too much: the very helpful site [djangopackages.com][1] lists 13. Some are mature and very feature-complete, while others are barely more than a basic model and a template. The biggest three systems (in terms of downloads, repo forks and -watchers) are [Django-CMS][3], [FeinCMS][4] and [Mezzanine][2]. I've built sites with both Django-CMS and Mezzanine, looked at FeinCMS and decided to write down a comparison.

## Django-CMS
With a very nice and professional looking website, you immediately get the feeling that this is a very mature CMS. The latest version, 2.1, has been in the making for a long time and adds very cool features such as frontend editing and easy integration of third party apps. Version 2.1 final has been released yesterday, so if you never looked at Django-CMS before, now is the perfect time.

Is has some very compelling arguments:

- Stable and mature, with multiple core developers
- Very good documentation for developers
- Many extensions available
- Extensions are very easy to create
- Frontend editing
- Very easy to integrate your own apps into the CMS
- Extremely easy for developers to work with
- Multiple templates, each template can define its own placeholders
- Good support for multilingual sites
- Moderation workflow and advanced permissions
- Revert changes / undelete pages

But not all is golden:

- The plugin system, while nicely extendible, makes the admin interface [pretty sucky][7]
- Doesn't work with [Grappelli][5]
- Doesn't use the TinyMCE editor by default

It's a very good CMS that's very easy to work with as a developer. However, I feel that for normal users the CMS could be improved a lot by dropping the current plugin based interface. The idea of multiple plugins per block of content is nice, but the admin interface is not usable enough. Tip for Django-CMS developers reading this: have a look at the TYPO3 backend.

The thing I absolutely like the most about Django-CMS is the way you define one or more placeholders directly in your HTML templates. Then, when you create a new page, you select one of your templates and it scans the source to find the placeholders you've defined. No config, no code, very very easy.

_**Update** - just to clarify: I'm not suggesting to drop the plugin system, just its current (backend) admin interface. Maybe when the frontend editing gets even better, it could completely replace it and thus solving the biggest problems I am having with Django-CMS. See also one of my other posts [here][7]._

## FeinCMS

I've never worked with this CMS before, but I did install it for a quick tryout. According to djangopackages.com it's the second biggest CMS for Django.

Pros:

- Probably the most flexible CMS
- Good documentation
- Easy to create you own custom content types
- Multilingual

Cons:

- There is no content type that does both rich text and images (and I like TinyMCE and django-filebrowser so much!)
- Harder to setup and get started with
- Admin interface looks and feels old-fashioned
- No reversion
- No moderation

It's the most flexible CMS by far, but that does come with a price: it's also the most complicated CMS of the three (mostly for developers but also for users). It's a real developers' CMS. As I've never actually built a site with FeinCMS I can't really say much more about it, but I can't say I am very motivated to try it out with two other excellent content management systems as its competitors.


## Mezzanine

For my latest project I used the Mezzanine CMS, because Django-CMS [didn't quite fit right][6]. I've worked with Mezzanine for two weeks now.

Pros:

- Includes Grappelli, TinyMCE and django-filebrowser
- Admin interface looks sexy and clean
- Frontend editing (although not quite as nicely done as Django-CMS)
- Completely integrated blogging engine
- Shopping cart module (not used this yet)
- Build-in form editor that is actually very usable (as compared to the third party forms extension for Django-CMS)
- Admin users can edit some site settings like posts per page, Google Analytics id, etc
- Developer docs are basic but good

Cons:

- It's a young project (not mature, few core developers)
- The default templates are pretty bad
- Some of the features should not be in the CMS: 960.gs integration and multi-device detection
- No reversion
- No moderation
- Absolutely no support for multilingual sites
- The homepage is not part of the CMS
- Harder to integrate with third party apps
- The url of your blog is hardcoded in settings.py

Especially the last three points really bug me. Mezzanine really should look at Django-CMS and steal their apps- and menus integration. The multi-device detection is a nice idea, but I'll do this with CSS 3 media selectors, thank you very much. I also don't want to use 960.gs, as I'm using em-based layouts more and more. Things like this should not be in the CMS but in your own app/templates/javascript code. My suggestion is to remove the device detection from the CMS, move it to its own app and release that on Github. Then you could also use it without the rest of Mezzanine.

In the end I did like working with Mezzanine a lot, and after customizing each and every template and removing all of their CSS code, the end-result is very nice too. The biggest plus points when compared to Django-CMS are the integrated blog posts, the very nice admin interface and the consistent use of TinyMCE. I predict that Mezzanine will overtake FeinCMS as the second biggest CMS within a year.

## Conclusion

FeinCMS is very flexible and extendible and I can imagine a lot of situations where this is needed. If you don't need the flexibility though, I would not use FeinCMS because of its admin interface and complexity.

So, which one do I prefer? Django-CMS or Mezzanine? If you need to build a multilingual site or need moderation, the decision is easy, as Mezzanine doesn't support neither. Otherwise though, it's difficult. Django-CMS offers the worst admin interface of the two, but has many features and is the easiest of the two to build a site in. On the other hand, Mezzanine feels fresh and has an admin interface which I can show to a client full of confidence.

Maybe that's why I built my own site with Django-CMS, but for my latest project (which will have multiple writers with probably questionable computer experience) I chose Mezzanine. It's a head versus heart thing: in my head I know Django-CMS is the better CMS, but Mezzanine just feels better.


  [1]: http://djangopackages.com/grids/g/cms/
  [2]: http://mezzanine.jupo.org/
  [3]: http://www.django-cms.org/
  [4]: http://www.feinheit.ch/labs/feincms-django-cms/
  [5]: http://code.google.com/p/django-grappelli/
  [6]: /articles/2011/looking-for-django-cms/
  [7]: /articles/2011/django-cms-backend-usability/
