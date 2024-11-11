---
tags: django, python
summary: Almost two months ago I compared Poetry with uv, and for me uv had some pretty significant drawbacks that kept me from switching over. The situation has changed quite a bit since then!
---

# Revisiting uv

Almost two months ago [I compared Poetry with uv](/articles/2024/python-poetry-vs-uv/), and for me uv had some pretty significant drawbacks that kept me from switching over -- the two big ones being the lack of dependency groups, and the inability see outdated packages.

I’m very happy to say that both these issues have been solved in recent updates of uv, and I am definitely going to switch my Python projects from Poetry to uv. Yes, the smaller drawbacks are unchanged: uv is not written in Python, locking out most of the Python community from contributing; Astral, the company behind uv doesn’t seem to have a way to monetize their work; and I think the command interface for uv still doesn’t make much sense. But I can forget about all of that when uv has such clear benefits -- especially its ability to manage the installed Python version.

## Dependency groups
Since version 0.4.7 dependency groups are properly supported in uv, and now you can add dependencies to any custom group you want:

```
$ uv add django
$ uv add --group dev --no-sync ruff
$ uv add --group prod --no-sync gunicorn
```

Only Django gets installed, the other two packages get added to the dependency list but won’t be installed (the `--no-sync` parameter skips the installing). 

However, as soon as you run any command that in turn runs `uv sync` (like `uv run`) you will notice that all of the optional dependencies get installed, which is not what I personally want to happen. Luckily this is easily solved by adding these two lines to your `pyproject.toml` file:

```
[tool.uv]
default-groups = []
```

And now only Django will be installed, even when you run `uv sync`. The way to get the other groups also installed is similar to Poetry:

```
$ uv sync --group dev
$ uv sync --group prod
$ uv sync --group dev --group prod
```

I’d use `uv sync --group dev` on my local machine, and I’d use `uv sync --group prod` on the production server, and the right packages get installed as expected.

And just like that, the biggest problem I had with uv is now completely gone.

## Showing outdated packages
Previously it wasn’t possible to see a list of outdated packages, but I’m happy to say that this has been added in uv 0.5.0:

```
$ uv tree --outdated
$ uv tree --outdated --depth=1
```

This will show a tree of all dependencies, with their latest version noted, if an update is available. The second command is my favorite: it only shows top-level dependencies, the ones I am actually interested in.

Now, this will only show the update information for installed dependencies. Meaning that if you added production dependencies to a `prod` group (like I’ve done with gunicorn in the example above), you won’t know if there’s an update available. Luckily uv makes it easy to see outdated packages in all groups, even when those groups are not installed:

```
$ uv tree --group prod --group dev --outdated --depth=1
```

The output for my simple test project looks like this, when I installed an older version of Django:

```
$ uv tree --group prod --group dev --outdated --depth=1
Resolved 11 packages in 0.64ms
uvtestproject v0.1.0
├── django v5.1.2 (latest: v5.1.3)
├── mypy v1.13.0 (group: dev)
├── ruff v0.7.3 (group: dev)
└── gunicorn v23.0.0 (group: prod)
```

You can see that the latest update for Django is listed in that tree. My only wish is that this would *only* show actually outdated packages rather than all packages, but I’ll take this and hope for more uv updates.

In case you don’t use dependency groups then you might want to use `uv pip list --outdated` rather than `uv tree --outdated`, since it only shows actually outdated packages. But sadly `uv pip list` doesn’t take the `--group` parameter so you can’t view updates for non-installed dependencies, like you can with `uv tree`. It also doesn’t support `--depth=1` which is a bummer.