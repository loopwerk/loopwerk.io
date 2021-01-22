# -*- coding: utf-8 -*-
#: settings for liquidluck

from datetime import date
import sys


site = {
    "name": "Loopwerk",
    "url": "https://www.loopwerk.io",
    "prefix": "articles",
    "feed": "/articles/feed.xml",
    "date": date.today(),
}

config = {
    "source": "content",
    "output": "deploy",
    "static": "deploy/static",
    "static_prefix": "/static/",
    "permalink": "{{date.year}}/{{slug}}/index.html",
    "relative_url": False,
    "perpage": 500,
    "feedcount": 20,
    "timezone": "+00:00",
}

author = {
    "default": "kevin",
    "vars": {
        "kevin": {
            "name": "Kevin Renskers",
            "email": "kevin@loopwerk.io",
        }
    }
}

reader = {
    "active": [
        "MarkdownReader.MarkdownReader",
    ],
}

writer = {
    "active": [
        "liquidluck.writers.core.PostWriter",
        "liquidluck.writers.core.PageWriter",
        "liquidluck.writers.core.ArchiveWriter",
        "liquidluck.writers.core.ArchiveFeedWriter",
        "liquidluck.writers.core.FileWriter",
        "liquidluck.writers.core.YearWriter",
        "liquidluck.writers.core.TagWriter",
        "SitemapWriter.SitemapWriter",
    ],
    "vars": {
        "archive_output": "articles/index.html",
        "archive_feed_output": "articles/feed.xml",
        "year_template": "year.html",
        "tag_template": "tag.html",
        "post_template": "article.html",
    }
}

if sys.argv[1] == "build":
    writer["active"].append("ImageWriter.ImageWriter")

theme = {
    "vars": {
        "navigation": [
            {'title': 'Home', 'link': '/'},
            {'title': 'Articles', 'link': '/articles/'},
            {'title': 'Apps', 'link': '/apps/'},
            {'title': 'Projects', 'link': '/projects/'},
            {'title': 'Mentorship Program', 'link': '/mentor/'},
            {'title': 'About', 'link': '/about/'},
        ]
    }
}
