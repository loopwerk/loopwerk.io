---
tags: django, python
summary: Comparing two Python package managers: Poetry and new kid on the block uv.
---

# Poetry versus uv

In January of 2023 I switched all my Python projects to [Poetry](https://python-poetry.org), a pretty great dependency manager. Before that I used Python’s own built-in virtual environment feature, and `requirement.txt` files that I’d install with pip, with different requirement files for local development, testing on CI, and the production deployment. 

Poetry made installing, removing, and updating third party packages a lot simpler and a lot faster, there’s now a proper lock file, and publishing packages to PyPI no longer means having to own a doctorate’s degree. All of that is to say: I’m a fan.

Recently Astral (known for their very fast Python formatter  [ruff](https://astral.sh/ruff)) announced [uv](https://docs.astral.sh/uv/), an extremely fast Python package and project manager. There’s been a lot of talk about it being written in Rust and thus locking out Python developers from maintaining this tool, it being owned and developed by a VC-backed company with no business plan and seemingly no way to monetize any of their work, but I want to focus on actually using uv. How does it compare to Poetry?

## Installation

The easiest way to install Poetry is with [pipx](https://pipx.pypa.io), which is a great tool to use for globally installing Python applications:

`$ pipx install poetry`

You can also use their install script (`curl -sSL https://install.python-poetry.org | python3 -`) but I wouldn’t recommend it. Poetry then tends to break whenever you upgrade Python, requiring you to reinstall Poetry again. That’s what so great about pipx: every application gets its own isolated environment.

Installing uv is even easier. You don’t even need pipx installed - which makes sense since uv replaces pipx among other tools:

`$ brew install uv`

I think this is a small win for uv since you don’t need to first install pipx. uv really is meant to replace a whole bunch of Python tools.

## Getting started
I think both tools are about equally easy to get started with. Creating a new project with their `init` commands, adding dependencies, it’s all very similar:

```
$ poetry init
$ poetry add django
$ poetry add ruff --group dev
$ poetry install --with dev
$ poetry run ./manage.py
```

```
$ uv init
$ uv add django
$ uv add ruff --dev
$ uv run ./manage.py
```

Uv does have a `uv sync` command to install the dependencies, but in practice you won’t need to run that, as `uv run` already makes sure that the dependencies are in sync, which is pretty nice.

Installing dependencies is also a lot faster than with Poetry. Definitely a win for uv!

Dig a little bit deeper though and there are some notable differences.

## Dependency groups
Poetry supports multiple groups of dependencies within a project. For example you can add a dependency group `dev`, and `prod` and `test`, and each group can have dependencies added that won’t be installed by default. The `prod` group can contain `gunicorn`, `dev` can have `ruff` and `test` can contain `pytest` for example. You can specify which group to install with `poetry install --with dev`, and you can also install multiple groups.

This is not possible with uv, as far as I can see. There are dev dependencies, but they are always getting installed. It seems this is only useful for when you publish your code to PyPI, not for when you’re writing an app, like a Django site. This is too bad, since now all dependencies for development, production and testing are always getting installed in every environment. Yes, that installation is very fast but it would still be good to be able to have separate dependencies for production which you might not want to (or can not) install on your MacBook.

## Updating dependencies
Updating dependencies is quite easy in Poetry:

```
$ poetry show --outdated --top-level --with dev --with prod
$ poetry update
$ poetry update --with dev
$ poetry update django
$ poetry update ruff --with dev
```

The only downside here is that you always have to deal with those dependency groups (if you have them), but other than that, it works very well.

This is not quite as easy with uv. For starters, there is no command to see outdated packages, which is already pretty much a dealbreaker. And then to update dependencies you don’t run something like `uv update django` but instead you need to run `uv lock --upgrade-package django`. Upgrading all packages can be done with `uv lock --upgrade`.

I think this doesn’t make much sense. The way that the uv CLI is structured is complex with a lot of commands and subcommands. I really do prefer Poetry’s CLI. For example why is there a `uv pip` interface with a bunch of different subcommands to manage package dependencies on a low level?

## uv replaces pipx
One of the goals of uv is to replace a bunch of different Python tools, amongst which is pipx. pipx is used to “install and run Python applications in isolated environments”. For example:

```
$ pipx install cowsay
$ cowsay mooo
```

This installs the Python application cowsay into its own isolated environment, and makes the binary available on the PATH.

uv replaces pipx with familiar commands:

```
$ uv tool install cowsay
$ cowsay mooo
```

With both pipx and uv you don’t even have to explicitly install the application, you can also run `pipx run cowsay mooo` or `uvx  cowsay mooo` to run it immediately.

It’s nice that uv can replace pipx, especially since it’s way faster in installing the applications, but it doesn’t really solve any complexity, it doesn’t make my life easier.

## uv replaces pyenv
And here we get to the very best feature of uv: it completely replaces [pyenv](https://github.com/pyenv/pyenv), mimicking the way [pnpm](https://pnpm.io) (a package manager for JavaScript projects that I absolutely love) works. You just configure your project to require a certain Python version (by setting the version number in the `.python-version` file), and then whenever you use `uv run` within the project the right Python version is installed, the virtual environment gets created, and the dependencies get installed. And it does that super fast too; installing Python 3.12.6 took about a second or two. When you want to upgrade the Python version you just edit `.python-version`, and that’s it: when you run any command using `uv run` the new Python version is automatically dowloaded and used.

The best part is that the Python version is stored in the git repo, so when you deploy the changes to production uv will automatically install and use the same Python version there as well. This is an amazing feature and something I really wish Poetry did as well. But instead you’ll need to combine Poetry with pyenv like so:

```
$ poetry config virtualenvs.prefer-active-python true
$ pyenv install 3.12.6
$ pyenv local 3.12.6
$ poetry install
```

The magic bit here is the `pyenv local 3.12.6` command, which you run in your Python project. This also stores the Python version in `.python-version`, which pyenv uses to make that the active Python version within this folder. And because of the `virtualenvs.prefer-active-python` Poetry config change, Poetry now uses that Python version as well.

The big downside with Poetry’s approach is that merely changing the value of `.python-version` doesn’t do anything. It doesn’t automatically install a new Python version. So pushing such a change to production doesn’t do anything either. You need to make sure that you install the right Python version using `pyenv install`, which is also much much slower than installing Python using uv. I’m talking multiple minutes versus a few seconds.

## Conclusion
I appreciate that uv is an all-in-one tool replacing both pipx and pyenv. While replacing pipx is a “nice to have”, it’s the way it replaces pyenv that I really love. The ability to change the version number in `.python-version`, push this to production, and it installs the new Python version, it’s amazing. I really love that.

But I don’t see myself switching to uv yet, and that’s because of its command line interface. Just look at the list of commands over at https://docs.astral.sh/uv/reference/cli/, and you’ll see what I mean. The `uv pip` and `uv lock` interfaces don’t make sense to me at all.

Adding and removing dependencies works just fine, until you want to support multiple dependency groups. And updating dependencies doesn’t work well at all - you can’t even see a list of outdated ones.

So for now I am sticking with pipx, pyenv, and Poetry. All tools written in Python, and maintained by Pythonistas. I am looking forward to seeing what uv might become and I’ll surely be tempted to try it again in the future. But I do think their corporate backing and lack of business plan is a huge downside, but [other](https://mastodon.social/@glyph/113093806840686501) [people](https://cloudisland.nz/@freakboy3742/113093889194737339) [said](https://mastodon.social/@glyph/113094489990995018) it better.

**Update Oct 4, 2024**: I wrote [another article where I looked at PDM](/articles/2024/trying-pdm/), comparing that with Poetry and uv. Check it out!

**Update Nov 11, 2024**: uv has released multiple updates solving my biggest gripes, and I am now in the process of switching my projects over from Poetry to uv. Check my [new article about those updates](/articles/2024/python-uv-revisited/)!