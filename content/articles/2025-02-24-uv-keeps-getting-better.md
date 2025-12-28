---
tags: python, uv
summary: It's been three months since I migrated all my Python projects over to uv. And it's only gotten better! Let's look at two recent major improvements.
---

# uv just keeps on getting better

It's been three months since I [migrated](/articles/2024/migrate-poetry-to-uv/) all my Python projects over to uv. As a reminder, uv is a Python package and project manager, which replaces poetry, pip, pipx, pyenv, virtualenv, and more. I love it, especially for the way it handles the installing of the correct Python version for each project. I wrote a [series of articles](/articles/tag/uv/) about uv, check it out if you haven't.

In this article I want to take a closer look at two major improvement that were added to uv over the last three months.

## Scrips with embedded metadata

In the olden days if I wanted to create a one-off script to quickly fetch some data from the internet, I'd have to create a virtual environment by hand, activate it, pip install the dependencies I'd need, and run the script. Something like this:

```shell
$ mkdir cd ~/Workspace/playground
$ cd ~/Workspace/playground
$ python3 -m venv .venv
$ source .venv/bin/activate
$ pip install requests
$ nano script.py
$ python3 script.py
```

That's a lot of steps! But the biggest problem with this is that Python already needs to be installed on your system, and it's a hassle to use a different Python version than the globally installed version. You'd need to use pyenv or something like that to manage Python versions, which is slow and cumbersome. You also need to remember to activate the virtual environment before running the script.

But as we know from my [first article on uv](/articles/2024/python-poetry-vs-uv/), uv dramatically improves the project workflow, so that the steps look more like this:

```shell
$ mkdir cd ~/Workspace/playground
$ cd ~/Workspace/playground
$ uv init
$ uv add requests
$ nano script.py
$ uv run script.py
```

Uv makes things easier by handling the virtual environment for you. You never have to create one by hand, you don't have to activate it yourself, uv does all this automatically. More importantly though, uv handles the installation of Python versions, and it's super fast to download a new Python version. Still, it's kinda annoying to have to create an entire uv project just to run a simple one-off script.

This is where embedded metadata comes in. Using embedded metadata you can now simply create a Python file, declare the dependencies inline, and run it. That's it. Uv will create a temporary virtual environment, install the right Python version, install the dependencies, activate it the virtual environment, and run the script.

```shell
$ nano script.py
$ uv run script.py
```

```python title="script.py"
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "requests",
# ]
# ///

import requests
resp = requests.get("https://peps.python.org/api/peps.json")
print(resp)
```

The syntax for the embedded metadata can be a bit hard to remember though, so uv added some useful commands to help with this:

```shell
$ uv init --script script.py --python 3.12
$ uv add requests --script script.py
```

Alternatively, if you don't want to use the embedded metadata, you can also run a script by specifying its dependencies on the command line, like so:

```shell
$ uv run --with requests script.py
```

Personally I like the embedded metadata though, especially when the number of dependencies grows, since you can simply use `uv add` with the `--script` parameter to keep adding dependencies as your script grows.

For more information, check out the [official docs](https://docs.astral.sh/uv/guides/scripts/).

## Loading .env files

If your project needs to read environment variables from a `.env` file, you'd have to use a package like [python-dotenv](https://github.com/theskumar/python-dotenv) and its `load_dotenv` function to load the `.env` file so that its values are available to Python's own `os.getenv` function.

uv now makes this dependency obsolete by allowing you to load an `.env` file directly from the `uv run` command:

```shell
$ uv run --env-file .env ./manage.py runserver
```

The contents of your `.env` file are made available to Python as environment variables and can be accessed using `os.getenv`.

Of course you don't want to use this full command every single time you run your script (or Django, in this case), but luckily it's very easy to have your script use uv by default. In your script (for example `manage.py`!) change the first line from this:

```
#!/usr/bin/env python
```

To this:

```
#!/usr/bin/env -S uv run --env-file .env
```

And now you can just run `./manage.py runserver` without having to prefix it with `uv run` -- and the `.env` file is loaded without any other dependencies.

For more information check the [uv docs](https://docs.astral.sh/uv/configuration/files/#env).
