# -*- coding: utf-8 -*-
#: settings for liquidluck

from datetime import date


site = {
    "name": "Loopwerk",
    "url": "https://loopwerk.io",
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
        "markdown.MarkdownReader",
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
        "sitemap.SitemapWriter",
    ],
    "vars": {
        "archive_output": "articles/index.html",
        "archive_feed_output": "articles/feed.xml",
        "year_template": "year.html",
        "tag_template": "tag.html",
    }
}

theme = {
    "vars": {
        "navigation": [
            {'title': 'Home', 'link': '/'},
            {'title': 'Articles', 'link': '/articles/'},
            {'title': 'Projects', 'link': '/projects/'},
            {'title': 'Apps', 'link': '/apps/'},
            {'title': 'About', 'link': '/about/'},
        ]
    }
}
