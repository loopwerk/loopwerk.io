---
tags: python
summary: After comparing uv to Poetry, I am trying out PDM. On paper it combines all the best things of Poetry and uv, without their downsides. How does it hold up?
---

# Trying out PDM (and comparing it with Poetry and uv)

Two weeks ago I wrote [an article pitting uv against Poetry](/articles/2024/python-poetry-vs-uv/). My conclusion was that although I loved uv’s speed and the way it replaces pyenv, I was going to stick with Poetry because of two major uv downsides: its CLI in general but specifically the inability to see outdated packages. Then I saw the news that [PDM](https://pdm-project.org/), yet another Python package and dependency manager, now supports uv as its resolver and installer. When I looked at the PDM docs I saw that it also supports automatically installing Python versions, as well as multiple dependency groups (like Poetry).

It really seems that this combines all the best things of Poetry and uv, without their downsides. Let’s take a look!

## Getting started
There are multiple installation methods: via a script, via pipx (or `uv tool`), or via Homebrew. I used pipx myself, and it was quick and painless. Compared to Poetry and uv, it’s just as easy.

Most of the commands to install packages are very similar to Poetry:

```
pdm config use_uv true
pdm init
pdm add django
pdm add ruff --group dev
pdm add gunicorn --group prod
pdm install --group dev
```

One weird thing that I noticed: when you add a dependency it’s automatically and immediately getting installed. I prefer Poetry’s way where adding a new dependency to a group doesn’t immediately install it - you have to run `poetry install --with [group]` as a separate command. Why this is better will become more obvious in the next section.

## Dependency groups
While PDM supports multiple optional dependency groups, in practice every single dependency from every group gets installed, because running `pdm add` immediately installs the dependency, even when it’s for an optional group. After initializing an empty PDM project I ran the following commands:

```
pdm add django
pdm add ruff --group dev
pdm add gunicorn --group prod
```

They all got installed to my machine. Even running `pdm install --group dev` doesn’t remove the production packages. Well, PDM *claims* it’s removing gunicorn, but it’s still in the virtual environment:

```
~/Workspace/temp/pdm-test $ pdm install --group dev
⠋ Resolving packages from lockfile...⠋ Resolving dependencies...                                                                                                                       Resolved 6 packages in 3ms
Removed gunicorn v23.0.0
Removed packaging v24.1
Audited 4 packages in 0.04ms
```

Probably a bug where it says it’s removing a package, but in reality it’s not. The effect is that I have to delete the entire `.venv` folder and then run `pdm install --group dev` for it to only install the base and development dependencies, without the production dependencies. But if I then add one more production package, for example `pdm add cowsay --group prod` it not only immediately installs cowsay but also gunicorn again. Sheesh! Poetry does this a hundred times better by its `add` command not immediately installing packages (when specifying a group).

This strange behavior happens whether or not you use uv. Adding a new package always installs it, running `pdm install --group dev` doesn’t get rid of production packages, and you need to recreate the virtual environment for that to happen. In practice this will only happen on your local machine where you add packages to your project; on your production server you’ll never run `pdm add`, only `pdm install --group prod`. But it *is* an issue because I have run into problems where a production dependency, not needed on my local machine, simply can not be installed on my local machine. Using PDM would not be possible which a project that has such dependencies.

## Updating dependencies
Just like Poetry, PDM can show a list of outdated packages using `pdm outdated`. However, it can’t do this for specific dependency groups (like Poetry can), and it can’t only show top-level dependencies either. With Poetry you can run something like `poetry show --outdated --top-level`, but with PDM you’ll always get all deeply nested dependencies which you probably don’t care about.

This is another bummer, but a smaller one.

## PDM replaces pyenv
My biggest disappointment with Poetry, by far, is that it doesn’t manage the Python installation for you. You can’t just update a version number, push it to production, and that Python version will get installed and the virtual environment recreated. uv does this brilliantly.

PDM can also do this, albeit with some weirdness. The general workflow looks like this: when you run `pdm init` you need to select which Python interpreter to use:

```
~/Workspace/temp/pdm-test $ pdm init
Creating a pyproject.toml for PDM...
Please enter the Python interpreter to use
 0. cpython@3.12 (/Users/kevin/.pyenv/shims/python3)
 1. cpython@3.12 (/Users/kevin/.pyenv/shims/python)
 2. cpython@3.12 (/Users/kevin/Library/Application Support/pdm/python/cpython@3.12.6/bin/python3)
 3. cpython@3.12 (/Users/kevin/.pyenv/versions/3.12.6/bin/python3.12)
 4. cpython@3.12 (/Users/kevin/.pyenv/shims/python3.12)
 5. cpython@3.12 (/opt/homebrew/bin/python3.12)
 6. cpython@3.9 (/usr/bin/python3)
 7. cpython@3.12 (/opt/homebrew/Cellar/python@3.12/3.12.6/Frameworks/Python.framework/Versions/3.12/bin/python3.12)
```
 
I would **much** rather prefer if I could simply say that this project uses Python 3.12, and it installs it locally. Let’s say I want to use a Python version that’s not on my system yet, like 3.8. I then first have to run `pdm python install 3.8` and then when I run `pdm init`, can I choose that interpreter as one of the options. PDM then stores the required Python version in the `pyproject.toml` file, but it also creates a `.pdm-python` file which contains the full path to the interpreter (`/Users/kevin/Workspace/temp/pdm-test/.venv/bin/python` in my case). This file should not be committed to git and to be honest I don’t really understand the point of this file.

Okay, so I initialized my project using Python 3.8, I added Django as a dependency, everything is running as expected. Now I want to update my project to Python 3.10, which is also not installed on my system yet. I can run `pdm use 3.10` which then installs Python 3.10, but it doesn’t change the `requires-python` config in the `pyproject.toml` file and you get this error:
 
```
~/Workspace/temp/pdm-test $ pdm use 3.10
Successfully installed cpython@3.10.15
Version: 3.10.15
Executable: /Users/kevin/Library/Application Support/pdm/python/cpython@3.10.15/bin/python3
[NoPythonVersion]: No Python interpreter matching requires-python="==3.8.*" is found.
```

To fix this discrepancy we can manually edit the `pyproject.toml` file, changing the value of `requires-python` from `==3.8.*` to `==3.10.*`. Now there’s yet another error:

```
~/Workspace/temp/pdm-test $ pdm install
WARNING: Lockfile hash doesn't match pyproject.toml, packages may be outdated
Updating the lock file...
INFO: The saved Python interpreter doesn't match the project's requirement. Trying to find another one.
WARNING: Project requires a python version of ==3.10.*, The virtualenv is being created for you as it cannot be matched to the right version.
INFO: python.use_venv is on, creating a virtualenv for this project...
Virtualenv is created successfully at /Users/kevin/Workspace/temp/pdm-test/.venv
[PdmUsageError]: The target requires Python ==3.8.* which is not compatible with the project's requires-python ==3.10.*
```

Turns out that the lockfile has its own `requires_python = "==3.8.*"` line, and this is not getting updated, so now the lockfile and the `.pyproject.toml` file disagree about the Python version to use. To fix this we need to run `pdm lock --update-reuse --python "==3.10.*"` and then finally we can run `pdm install` again without errors. Our project now uses Python 3.10, and when this is pushed to production PDM *should* automatically install the new Python version and recreate the virtualenv (I say should, because I didn’t actually try this in production).

When you compare this with uv or pnpm (a JavaScript dependency manager) this is pretty bad UX. There are too many cryptic errors and steps needed. Compare this to uv where you just set a version number inside of `.python-version` and uv takes care of the rest. PDM just falls short.
 
## Conclusion
I had really high hopes for PDM because on paper it looked like the perfect blend of Poetry and uv. Sadly it’s not quite good enough in my opinion. The biggest problem for me is the way it handles optional dependency groups. And while it can install Python versions for you, it’s nowhere near as user-friendly as that should be.

So let’s compare Poetry, uv and PDM. When it comes to installing Python versions:

- Poetry doesn’t this at all
- PDM does, but not particularly user-friendly
- uv does it brilliantly

And when it comes to handling optional dependency groups:

- Poetry does this exactly as I’d expect
- PDM fails by always installing everything
- uv doesn’t have the concept of multiple dependency groups at all

Finding and updating outdated packages:

- Poetry does this the best
- PDM is “good enough”
- uv fails by not making it possible to see outdated packages

With all of that said, which package manager would I use? Stick with Poetry or switch to PDM? It actually depends on the project: for some projects PDM would simply not work because I’m dealing with production dependencies which cannot be installed on my MacBook. For other projects I *could* use PDM. I’d get the Python version handling (which is “meh” but certainly better than what Poetry offers) by giving up the outstanding handling of outdated packages.

In reality I don’t want to use different package managers for different projects so I’m sticking with Poetry for now. I’m really hoping that Poetry will add Python management, or that uv will improve its CLI, or that PDM will improve all the things mentioned in this article, as well as their cryptic errors in general. My money is that uv will make the biggest improvements in the shortest time.