---
tags: python, django, review
---

# Things I hate about Python and Django
I have been a PHP programmer for the last 9 years, and only in September of 2009 I switched to Python and the Django framework. While I really love the Python language and the Django framework (especially compared to something like the Zend PHP framework), there are a couple of things that are really bugging me.

## Python
* The lack of public, private and protected functions. Yes, there is a convention to use an underscore for private methods, but it seems very old-fashioned to me.
* Static functions are overly complicated to use in my opinion.
* Why do all methods need to be given a "self" as their first parameter. I mean really..? Why can't this be automagically done?
* `', '.join(list)`. No matter how you this explain this to me, it's still backwards.
* No `switch` statement. You can replicate its functionality using a dictionary, but it is harder to read, and a lot harder to write.
* Dictionaries are unordered. Argh! Very, very annoying.
* The official Python documentation. I guess I am spoiled having used the very impressive official PHP documentation for so long, but really Python could use more work on this.
* Not everything is consistently done in a object oriented fashion: why is it `len(['list'])` and `len("string")`, and not `['list'].len()` and `"string".len()`?
* All the underscores and `__init__.py` files.
* Tuples must die. They are ugly, especially when you only have one item in it and it needs that dangling comma: `('item',)`

## Django
* The template language has some very strong points, but simple things like variable variables are impossible without writing your own template tags. For example, within a loop I'd like to be able to do something like `{{ my_dict.{{ variable }} }}`.
* The code style, in particular all the function_names_with_underscores. I always use mixedCaseNames, and now everything looks like crap.
* It gets annoying having to restart your webserver after you change code. Thank God for the awesome development server that comes with Django at least.
* Why can I use a `{% block %}` only once in my template? Maybe I want to show a block (like a title) twice on the same page. I know the technical reason for this limitation, but with Jinja2 templates for example you can at least show a previously defined block again.
* Because much of your Python code is only executed once (after which only the compiled result is executed), sometimes it is overly complicated to write a function that is executed on every hit.

## It's not all bad
I'd like to end on a positive note though with the things I love about Python and Django.

* Significant whitespace. It makes other peoples Python code much easier to read, even though I still miss the closing brackets some times. They just make it easier to see where your block ends.
* Keyword arguments. All languages should have them!
* The community is great, both Python and Django (and Plone!)
* Url configs, and how easy it is to create a beautiful url that links to a view.
* Extending templates makes it easy to organize your html code
* The Django documentation is very good. In fact, I think I have never seen an open source project with better documentation!
* The thing I love most about Django has to be its buildin generic views like direct_to_template, object_list, object_detail, etc. It's so easy to create a view that shows a paginated list of items, or a view that uses a date in your url like /blog/2009/03.
* And last but certainly not least: the buildin admin site. It just saves you so much time!
