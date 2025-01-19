---
tags: python, uv
summary: So, like me you’ve decided to switch from Poetry to uv, and now you’re wondering how to actually migrate your pyproject.toml file? You’ve come to the right place!
---

# How to migrate your Poetry project to uv

So, like me you’ve decided to switch from Poetry to uv, and now you’re wondering how to actually migrate your `pyproject.toml` file? You’ve come to the right place!

While uv sadly doesn’t come with a migration command (yet), we *can* use PDM’s migration tool, which gets us 95% of the way there since PDM and uv both use mostly the same configuration format. Let’s use a basic project that uses Django, gunicorn and ruff (using two optional dependency groups), to illustrate the different steps. Our `pyproject.toml` file, as created by Poetry, will look something like this:

```
[tool.poetry]
name = "poetrytest"
version = "0.1.0"
description = ""
authors = ["Kevin Renskers <kevin@loopwerk.io>"]
readme = "README.md"

[tool.poetry.dependencies]
python = "^3.13"
Django = "^5.1.3"

[tool.poetry.group.dev]
optional = true

[tool.poetry.group.dev.dependencies]
ruff = "^0.7.4"

[tool.poetry.group.prod]
optional = true

[tool.poetry.group.prod.dependencies]
gunicorn = "^23.0.0"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

Don’t worry if you don’t use dependency groups in your project; the process is still exactly the same, you just get to ignore some steps.

## Step 1: use PDM’s import tool
We start by running `uvx pdm import pyproject.toml`. This will modify the `pyproject.toml` to be almost uv compatible. Our file now looks like this:

```
[tool.poetry]
name = "poetrytest"
version = "0.1.0"
description = ""
authors = ["Kevin Renskers <kevin@loopwerk.io>"]
readme = "README.md"

[tool.poetry.dependencies]
python = "^3.13"
Django = "^5.1.3"

[tool.poetry.group.dev]
optional = true

[tool.poetry.group.dev.dependencies]
ruff = "^0.7.4"

[tool.poetry.group.prod]
optional = true

[tool.poetry.group.prod.dependencies]
gunicorn = "^23.0.0"

[tool.pdm.dev-dependencies]
dev = [
    "ruff<1.0.0,>=0.7.4",
]
prod = [
    "gunicorn<24.0.0,>=23.0.0",
]

[tool.pdm.build]
includes = []

[build-system]
requires = ["pdm-backend"]
build-backend = "pdm.backend"

[project]
authors = [
    {name = "Kevin Renskers", email = "kevin@loopwerk.io"},
]
requires-python = "<4.0,>=3.13"
dependencies = [
    "Django<6.0.0,>=5.1.3",
]
name = "poetrytest"
version = "0.1.0"
description = ""
readme = "README.md"
```

## Step 2: remove old sections from `pyproject.toml`
Every section that starts with `tool.poetry` can be removed, as well as the `build-system` section. The newly added `tool.pdm.build` section can also be removed. Our file now looks like this:

```
[tool.pdm.dev-dependencies]
dev = [
    "ruff<1.0.0,>=0.7.4",
]
prod = [
    "gunicorn<24.0.0,>=23.0.0",
]

[project]
authors = [
    {name = "Kevin Renskers", email = "kevin@loopwerk.io"},
]
requires-python = "<4.0,>=3.13"
dependencies = [
    "Django<6.0.0,>=5.1.3",
]
name = "poetrytest"
version = "0.1.0"
description = ""
readme = "README.md"
```

## Step 3: clean up `pyproject.toml`
Now rename `[tool.pdm.dev-dependencies]` to `[dependency-groups]` and move it below `[project]`. If you don’t have a `[tool.pdm.dev-dependencies]` section because you didn’t use dependency groups, then don’t worry. You don’t have to do anything.

In my projects I’ve also added a new section `[tool.uv]` where I clear out the default dependency groups, so that production dependencies don’t get installed on my local machine, and development dependencies don’t get installed on my production server (see [this article](/articles/2024/python-uv-revisited/) for more info).

I’ve also reordered the items within `[project]` and I’ve switched the order of the version requirements so that instead of `Django<6.0.0,>=5.1.3` it now specifies `Django >=5.1.3, <6.0.0`. It’s more logical and readable that way.

The `pyproject.toml` file now looks like this and is done:

```
[project]
name = "poetrytest"
version = "0.1.0"
description = ""
readme = "README.md"
authors = [
    {name = "Kevin Renskers", email = "kevin@loopwerk.io"},
]
requires-python = ">=3.13,<4.0"
dependencies = [
    "Django >=5.1.3, <6.0.0",
]

[dependency-groups]
dev = [
    "ruff >=0.7.4, <1.0.0",
]
prod = [
    "gunicorn >=23.0.0, <24.0.0",
]

[tool.uv]
default-groups = []
```

## Step 4: recreate your virtual environment
It’s a good idea to remove your old `.venv` folder and then you can run `uv lock` or `uv sync` and your packages will get installed. Congrats, you’ve migrated your project from Poetry to uv!

So while it wasn’t quite as easy as executing a single command, it’s not very hard either. Mostly you just need to take care of removing and renaming the right sections from `pyproject.toml`, and it works.

> Credit for the idea to use PDM to migrate from Poetry to uv goes to [this tweet](https://x.com/tiangolo/status/1839686030007361803).