---
tags: review, python, django
---

# Review roundup: the search for the perfect Python IDE (for Django)
When I first started working with Python in September 2009, I needed a good IDE. I quickly settled for Netbeans and I've been using it ever since, even though there are some things that really irritate me. But at least it works, and fits well in my workflow.

Last weekend I did a clean install of Snow Leopard, and while I was busy setting it up again I started to wonder if maybe I needed to look for a better replacement.

My list of must-have features isn't that long:

- It needs to run on Mac OS X
- Autocompletion for Django code (models/forms)
- Be able to set breakpoints and debug my Django project
- Virtualenv support
- Give warnings and notices for syntax errors, unused imports, unused variables, etc
- Besides working with projects, it should also be easy to edit other (separate) files

And some nice-to-haves:

- Subversion and Mercurial need to be supported
- Syntax highlighting for Django templates
- Build-in sqlite browser
- Open source and/or free, although I'd go for a commercial product if it's better than the rest

## Netbeans with Python plugin
As I said, I've been using [Netbeans](http://netbeans.org/) until now. And even though I'd like to find a replacement, there's a lot to like. It's free, runs on Mac, has superb version control support and helps me while developing by showing me syntax errors even before I run the script. It helps me keep my code clean by notifying me about unused imports, variables and functions. It mostly stays out of my way, and once started, is pretty snappy.

So, why find a replacement at all? Well, code completion is very limited, barely usable even.

```python
from django.db import models

class Person(models.Model):
    name = models. # it won't autocomplete this!
```

It can't deal with Django templates. To be honest, I don't really care that much, but the fact that it can't even recognize HTML5 syntax is getting very annoying. It's always telling me I have syntax errors even though it's all perfectly fine.

And last but not least, I've never been able to get any form of Django debugging or breakpoints to work. Python scripts, yes, but not a Django project.

## Komodo
The first replacement I tried was [Komodo IDE 6](http://www.activestate.com/komodo-ide), a commercial product from ActiveState. At $295 it's quite expensive, so it has to be a *lot* better than Netbeans.

Their feature list made me very hopeful: support for debugging, HTML5, Django and all major version control systems was all listed. Add to that a database browser and my whishlist is almost completely fulfilled.

Sadly though, autocompletion doesn't work properly. I've tried the same example as with Netbeans, and it could not figure out what methods were available. My guess is this is because of another big problem: no support for virtualenv, so how could it know what `django.db.models` is?

Lastly, their advertised Django support seems limited to syntax highlighting of the template language. Based on the lack of virtualenv support alone, I've not bothered to test Komodo for more than an hour or so.

## PyCharm
[PyCharm](http://www.jetbrains.com/pycharm/) is a relatively new IDE made by JetBrains. It's also a commercial product, but at 88 euros (about $125) a lot more affordable. Well, at least the personal license is, as the commercial one for companies is 176 euros, or about $250. However, they also have a free license for open-source projects.

JetBrains markets their IDE as a "Powerful Python and Django IDE": the specific mention of Django is promising. Listed features are Code Assistance, Code Analysis, complete Django support, version control, a graphical debugger and a lot more.

I've been testing PyCharm for about a week now, and I have to say I really like it, even though it's kind of buggy right now. Their Django support is very cool: syntax highlighting works, code completion finally works (even for Django's default template tags and filters), and it also helps you to write better code, faster. For example, it can recognize old function-based generic views and offer to replace them with Django 1.3's new class-based generic views. Or, when you mention a template that doesn't exist yet, will offer to create it: very helpful indeed! It also knows what context variables are available in your template, and can auto-complete them too: {{ person. }} will show the possible values.

Their Django support goes further than the features already mentioned: you can run all management command right from the IDE. You can run Django's runserver command for example. While this is nice and all (after all, doing it in a terminal is just as easy), the ability to set breakpoints and debug the running server is what really sets PyCharm apart for me.

All these features make the life of a Django developer a lot easier. It also works well with virtualenv, where each project has its own Python interpreter and Python path.

Is it all perfect? Sadly, no. It's a bit buggy - not in the sense that it crashes or locks up, but certain features don't work as advertised. For example, I mentioned that it can recognize missing templates and auto-complete context variables inside templates. However, this does not work for all render shortcuts inside your views, and does not work well with keyword arguments. So while this code works perfectly with PyCharm:

```python
return render_to_response('file.html', {'foo':bar})
```

This does not:

```python
return direct_to_template(request, 'file.html', {'foo':bar})
```

Luckily they quickly responded to the bug-report, and I am confident that it will be fixed soon.

Another annoying thing is that you can't have multiple projects in your workspace: they each need their own window, making it hard to work on multiple projects at the same time.

I can't wait for PyCharm to mature!

## Wing Python IDE
[Wing](http://www.wingware.com/) IDE is a very mature IDE, that focuses on Python since 1999. It promises a graphical debugger, version control, auto completion, and Django support (including breakpoints and debugging).

While it should work on Mac OS X, it needs a separately installed X server like XQuartz. Considering the features of Wing and how mature it is (as opposed to PyCharm), I felt this an acceptable extra step, willing to try it out. Sadly, I never got it working, Wing always crashed right back to the desktop.

I will try to get Wing to work, and if it ever does, will update this post with my findings.

## Eclipse with PyDev plugin
Since Aptana Studio 3 is basically the same Eclipse-based IDE but with PyDev already pre-installed, I am not going to test Eclipse with PyDev.

## Aptana Studio 3
Aptana offers an open source Eclipse based IDE, which they say supports CSS3, HTML5 and Python (among others). It also mentions debugging, but [their site](http://www.aptana.com/products/studio3) is very uninformative on features otherwise. I happened to know that [PyDev](http://pydev.org/) is included with Aptana Studio 3, and luckily their site is a lot more helpful.

PyDev specifically lists Django integration, code completion (also with auto import, something done by PyCharm as well), code analysis and a debugger. The features are promising, so even though I kind of hate Eclipse and its weird perspective-based interface, I did download Aptana to look at it with an open mind.

Getting started with a project wasn't really easy. I always use a specific way of organizing my code: a top folder with the name of the project, with subfolders for the virtualenv stuff (lib, bin, include) which are not committed to version control, and a subfolder called "project" which contains the actual Django project. So the IDE needs to understand which Python interpreter to use (no problem with Aptana) and which folder is the Django project folder (this was quite a puzzle).

Once I got my project properly set up though, I was pleasantly surprised with Aptana. Code completion does a very nice job, although not quite as nice as PyCharm in some places. For example, when I create a subclass of the ListView generic view, both IDE's offer to import the correct class, but only PyCharm knows which instance variables (like template_name or model) are available for autocompletion.

Debugging a Django project works very well: set a breakpoint, choose to debug your Django project and Aptana will start the server with the debugger attached. The only problem I could possibly have, is that you have to switch to the debug perspective.

I also like the Problems pane, which shows the output of the code analysis for all Python files inside your project. Most other IDE's only show the result of the analysis for the currently opened file. Aptana makes it really easy to spot all problems.

In the end, while Aptana feels less buggy than PyCharm, it's also much less user friendly. Everything is just a bit more complex to set up. Creating a project with existing sources was a bit more complex. And while most IDE's recognized the .svn folders in my project and let me work with Subversion without having to configure anything, this was not the case with Aptana. I first had to install a plugin to be able to work with Subversion, and sadly trying to search for plugins mostly gave me the dreaded OS X beach-ball. And even when it was finally set up, I didn't find it easy to work with. I guess command-line based version control is the way to go with Aptana.

## Conclusion
If PyCharm was less buggy, there would be no contest to me, even considering its price tag. It's user friendly, has the best Django support, does a good job debugging projects and makes my life a lot easier. On the other hand there's Aptana. It's free, powerful and does a good job with Django project too. It's complex, but once everything is set up (which needs to be done only once) it's pretty nice to work with.

Right now I just can't decide between the two. I'll keep testing and comparing them both. I have to say though: while I expect that PyCharm will get less buggy very soon, I don't think Eclipse based products like Aptana will ever get user friendly.

**Update August 2012**
I've neglected to update the conclusion of this blog post, sorry for that. In the end I decided to go with PyCharm and I couldn't be happier with it. It quickly got stable and even better, and I have been enjoying it daily since May 2011.
