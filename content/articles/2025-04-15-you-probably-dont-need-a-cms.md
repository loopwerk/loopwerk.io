---
tags: django, python
summary: Many people quickly reach for a big CMS package for Django, when often this is overkill. Here’s how to use a simple Django model with a CKEditor 5 WYSIWYG field, including embedded media like YouTube.
---

# You probably don’t need a CMS

When I took over development and maintenance of the Sound Radix site and backend in January of 2023, it had a full blown CMS system ([puput](https://github.com/APSL/puput)) for the artist interviews. The administrators used the regular ol’ Django Admin site to manage everything except for the interviews which were handled in a completely separate CMS environment, reached on its own URL. Similarly I see plenty of people recommending Wagtail or Django CMS or Mezzanine when somebody asks how to get started building a simple blog.

I’m always very surprised by this. These are big dependencies that do a lot of stuff, and usually you only need a very small portion of their functionality - especially when getting started. I think it makes a lot more sense to build something yourself, which is also a great learning exercise when getting started.

For example the artist interviews on Sound Radix basically consist of a title, excerpt, a body, and a few other metadata fields such as a published date and slug. The body field should be a nice WYSIWYG editor because that’s what our marketing guys are comfortable with. But in no way does this require a complete CMS when a simple WYSIWYG text field does the job. So in this article I want to share our setup, how we get a nice editor experience, and how I made it possible to embed any kind of content (YouTube, Spotify, Apple Music, Instagram) without needing any special editor plugins.

It all starts with our model, which in our case looks like this, but really it’s the `body` field that’s the important bit:

#### <i class="fa-regular fa-file-code"></i> models.py
```python
import datetime
from django.db import models
from bs4 import BeautifulSoup, Tag
from django_ckeditor_5.fields import CKEditor5Field


class Article(models.Model):
    image = models.ImageField(upload_to="cms", blank=True, null=True)
    title = models.CharField(max_length=255)
    /*HLS The important bit*/body = CKEditor5Field()/*HLE*/
    excerpt = models.TextField(blank=True)
    date = models.DateField(db_index=True, default=datetime.date.today)
    slug = models.SlugField(max_length=255, unique=True)

    class Meta(OrderableModel.Meta):
        ordering = ["-date"]

    def save(self, *args, **kwargs):
        # Automatically add target="_blank" to all external links
        soup = BeautifulSoup(self.body, "html.parser")
        for link in soup.find_all("a"):
            link = cast(Tag, link)
            href = str(link.get("href") or "")

            if (
                href is not None
                and link.get("target") is None
                and href.startswith("http")
                and not href.startswith("http://www.soundradix.")
            ):
                link["target"] = "_blank"

        self.body = str(soup)

        super().save(*args, **kwargs)
```

The `CKEditor5Field` field comes from the [django-ckeditor-5](https://github.com/hvlads/django-ckeditor-5) project, for which we use the following config:

#### <i class="fa-regular fa-file-code"></i> settings.py
```python
CKEDITOR_5_CUSTOM_CSS = "css/ckeditor5/admin_dark_mode_fix.css"
CKEDITOR_5_CONFIGS = {
    "default": {
        "toolbar": [
            "undo", "redo", "|",
            "heading", "|",
            "bold", "italic", "underline", "|",
            "bulletedList", "numberedList", "blockQuote", "|",
            "link", "imageUpload", "|", "sourceEditing",
        ],
        "link": {
            "decorators": {
                "openInNewTab": {
                    "mode": "manual",
                    "label": "Open in a new tab",
                    "defaultValue": True,
                    "attributes": {"target": "_blank"},
                }
            }
        },
        "image": {
            "toolbar": [
                "imageTextAlternative", "|", "imageStyle:alignLeft", "imageStyle:alignRight", "imageStyle:alignCenter", "imageStyle:side", "|",
            ],
            "styles": [
                "full", "side", "alignLeft", "alignRight", "alignCenter",
            ],
        },
        "heading": {
            "options": [
                {"model": "paragraph", "title": "Paragraph", "class": "ck-heading_paragraph"},
                {"model": "heading2", "view": "h2", "title": "Heading 2", "class": "ck-heading_heading2"},
                {"model": "heading3", "view": "h3", "title": "Heading 3", "class": "ck-heading_heading3"},
                {"model": "heading4", "view": "h4", "title": "Heading 4", "class": "ck-heading_heading4"},
            ]
        },
        "removePlugins": ["WordCount", "MediaEmbed"],
        "height": 300,
        "width": 800,
    },
}
```

By default this editor doesn’t work so well when the Django Admin is in dark mode, which is why this extra css is needed:

#### <i class="fa-regular fa-file-code"></i> admin_dark_mode_fix.css
```css
.ck.ck-editor {
    color: black;
}
```

So instead of a complete CMS we now have a Django model with a `CKEditor5Field` instance. Our model becomes the CMS, and our admins manage everything within the normal Django Admin interface that they’re already familiar with. They don’t have to use multiple URLs, like `/admin/` and `/cms/` to manage different kinds of things on the site.

We embed a bunch of things in our articles, such as Instagram photos, YouTube videos, Spotify, Tidal and Apple Music songs, and more. While CKEditor 5 has built-in support for some embeds (when you paste in a link to a YouTube video it turns into embed code by default), it doesn’t support everything we need. Instead of building complicated plugins, we decided to completely remove remove this responsibly from the text editor, and instead we parse the body text for special tags like this:

```
Lorem ipsum dolor sit amet, consectetur adipiscing elit
sed do eiusmod tempor incididunt ut labore et dolore magna
aliqua. Ut enim ad minim veniam. 

[[https://www.youtube.com/watch?v=dQw4w9WgXcQ]]

Excepteur sint occaecat cupidatat non proident, 
sunt in culpa qui officia deserunt mollit anim id est laborum.
```

Basically any link placed between two square brackets get transformed into a piece of embedded content. We do this when we save the model, with the following code:

#### <i class="fa-regular fa-file-code"></i> models.py
```python
import datetime
from django.db import models
from bs4 import BeautifulSoup, Tag
from django_ckeditor_5.fields import CKEditor5Field

/*HLS*/from .utils import render_embeds/*HLE*/


class Article(models.Model):
    # Previous fields...
    /*HLS*/rendered_body = models.TextField(blank=True)/*HLE*/
    
    def save(self, *args, **kwargs):
        # Previous logic...
        self.body = str(soup)
        /*HLS*/self.rendered_body = render_embeds(self.body)/*HLE*/

        super().save(*args, **kwargs)
````

#### <i class="fa-regular fa-file-code"></i> utils.py
```python
import re


def render_embeds(body: str) -> str:
    # YouTube replacer
    body = re.sub(
        r"(?:<p>)?\[\[(?:https:\/\/www\.youtube\.com\/watch\?v=|https:\/\/youtu\.be\/)(.*?)\]\](?:<\/p>)?",
        lambda match: f'<iframe class="aspect-video" src="https://www.youtube.com/embed/{match.group(1)}" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>',
        body,
        flags=re.IGNORECASE,
    )

    # Tidal replacer
    body = re.sub(
        r"(?:<p>)?\[\[https:\/\/tidal\.com\/browse\/track\/(.*?)\]\](?:<\/p>)?",
        lambda match: f'<iframe src="https://embed.tidal.com/tracks/{match.group(1)}" height="96" title="Spotify embedded player" frameborder="0" allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" allowfullscreen></iframe>',
        body,
        flags=re.IGNORECASE,
    )

    # Spotify replacer
    body = re.sub(
        r"(?:<p>)?\[\[https:\/\/open\.spotify\.com\/(.*?)\]\](?:<\/p>)?",
        lambda match: f'<iframe src="https://open.spotify.com/embed/{match.group(1)}" height="352" title="Spotify embedded player" frameborder="0" allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" allowfullscreen></iframe>',
        body,
        flags=re.IGNORECASE,
    )

    # Apple Music replacer
    body = re.sub(
        r"(?:<p>)?\[\[https:\/\/music\.apple\.com\/(.*?)\]\](?:<\/p>)?",
        lambda match: f'<iframe src="https://embed.music.apple.com/{match.group(1)}" height={"175" if "?i=" in match.group(1) else "450"} title="Apple embedded player" frameborder="0" allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" allowfullscreen></iframe>',
        body,
        flags=re.IGNORECASE,
    )

    return body
```

This `render_embeds` function can easily be extended with more replacement logic, all without having to deal with CKEditor plugins. It makes it really easy for us to switch to another editor if we’d want to, since the source of truth is simple text containing template tags.

Finally, we hide the `rendered_body` in the Django Admin:

#### <i class="fa-regular fa-file-code"></i> admin.py
``` python
class ArticleAdminForm(forms.ModelForm):
    class Meta:
        model = Article
        exclude = ["rendered_body"]


class ArticleAdmin(admin.ModelAdmin):
    form = ArticleAdminForm
```

And with that we have a simple and user friendly text editor  without having to include a big dependency like Django CMS or Wagtail. Our admins can upload images into their articles, and we can easily embed anything we want. We have a single Django Admin interface where all content is managed, including the articles.

So next time you’re reaching for a CMS when you’re building a blog, I would suggest to first start with a simple model and a WYSIWYG field.