---
tags: python, uv, review
summary: After comparing uv to Poetry, I am trying out PDM. On paper it combines all the best things of Poetry and uv, without their downsides. How does it hold up?
---

# Trying out PDM (and comparing it with Poetry and uv)

Two weeks ago I wrote [an article pitting uv against Poetry](/articles/2024/python-poetry-vs-uv/). My conclusion was that although I loved uv's speed and the way it replaces pyenv, I was going to stick with Poetry because of two major uv downsides: its CLI in general but specifically the inability to see outdated packages. Then I saw the news that [PDM](https://pdm-project.org/), yet another Python package and dependency manager, now supports uv as its resolver and installer. When I looked at the PDM docs I saw that it also supports automatically installing Python versions (like uv), as well as multiple dependency groups (like Poetry).

It really seems that this combines all the best things of Poetry and uv, without their downsides. Let's take a look!

> **Update October 12, 2024:** a previous version of this article made some comments about PDM not being able to add dependencies to an optional dependency group, without them also immediately getting installed. This turns out to not be correct, when using the `--no-sync` option. The article and its conclusion have been updated.

## Getting started

There are multiple installation methods: via a script, via pipx (or `uv tool`), or via Homebrew. I used pipx myself, and it was quick and painless. Compared to Poetry and uv, it's just as easy.

Most of the commands to install packages are very similar to Poetry:

```
$ pdm config use_uv true
$ pdm init
$ pdm add django
$ pdm add ruff --group dev
$ pdm add gunicorn --group prod
$ pdm install --group dev
```

## Dependency groups

PDM supports multiple optional dependency groups, just like Poetry does. One big difference with Poetry is that by default every single dependency from every group gets installed, because running `pdm add` immediately installs the dependency, even when it's for an optional group. After initializing an empty PDM project I ran the following commands:

```
$ pdm add django
$ pdm add ruff --group dev
$ pdm add gunicorn --group prod
```

They all got installed to my machine. When you then run `pdm install --group dev` PDM _claims_ that it's removing gunicorn, but it's still in the virtual environment:

```
$ pdm install --group dev
⠋ Resolving packages from lockfile...⠋ Resolving dependencies...                                                                                                                       Resolved 6 packages in 3ms
Removed gunicorn v23.0.0
Removed packaging v24.1
Audited 4 packages in 0.04ms
```

Probably a bug where it says it's removing a package, but in reality it's not (see also the next section). The effect is that I had to delete the entire `.venv` folder and then run `pdm install --group dev` for it to only install the base and development dependencies, without the production dependencies.

Luckily this has a simple solution: the `--no-sync` option when adding a package.

```
$ pdm add gunicorn --group prod --no-sync
```

This adds the package to the dependency group without installing it. This is the default behavior for Poetry (for optional dependency groups) and needs an explicit option for PDM, which is fine. Let's call it a tie.

The reason why I don't want production packages to get installed on my local machine is because some production packages are a huge hassle to install on macOS. Until I knew about the `--no-sync` option PDM seemed like a no-go for me.

## Output weirdness when using uv

One thing that does bother me about PDM is the weirdness of its output when you add a new dependency. For example when I run `pdm add django` in a completely new project, the output is what I expect (albeit quite verbose):

```
$ pdm add django
Adding packages to default dependencies: django
Resolved 5 packages in 98ms
Added asgiref v3.8.1
Added django v5.1.2
Added sqlparse v0.5.1
Added tzdata v2024.2
  0:00:00 🔒 Lock successful.
Changes are written to pyproject.toml.
⠋ Resolving packages from lockfile...⠋ Resolving dependencies...                                                                                                                       Resolved 5 packages in 2ms
Prepared 3 packages in 0.56ms
Installed 3 packages in 79ms
 + asgiref==3.8.1
 + django==5.1.2
 + sqlparse==0.5.1
```

When I then add a second package, the output becomes weird:

```
$ pdm add ruff --group dev
Adding packages to dev dependencies: ruff
Resolved 6 packages in 41ms
Added ruff v0.6.9
  0:00:00 🔒 Lock successful.
Changes are written to pyproject.toml.
⠋ Resolving packages from lockfile...⠋ Resolving dependencies...                                                                                                                       Resolved 2 packages in 3ms
Removed asgiref v3.8.1
Removed django v5.1.2
Removed sqlparse v0.5.1
Removed tzdata v2024.2
Prepared 1 package in 0.46ms
Installed 1 package in 2ms
 + ruff==0.6.9
```

Why does it say that it's removing Django and its dependencies? Which is also absolutely not true by the way, they are still in my virtual environment just fine.

When you don't use uv as the resolver and installer, the output becomes a lot better:

```
$ pdm add django
Adding packages to default dependencies: django
  0:00:00 🔒 Lock successful.
Changes are written to pyproject.toml.
Synchronizing working set with resolved packages: 3 to add, 0 to update, 0 to remove

  ✔ Install asgiref 3.8.1 successful
  ✔ Install sqlparse 0.5.1 successful
  ✔ Install django 5.1.2 successful

  0:00:01 🎉 All complete! 3/3

$ pdm add ruff --group dev
Adding packages to dev dependencies: ruff
  0:00:01 🔒 Lock successful.
Changes are written to pyproject.toml.
Synchronizing working set with resolved packages: 1 to add, 0 to update, 0 to remove

  ✔ Install ruff 0.6.9 successful

  0:00:00 🎉 All complete! 1/1
```

No more super verbose output and no more mention of packages that are getting removed even though that's not true. To be fair PDM gives plenty of warnings that using uv as the installer is experimental, and personally I wouldn't use it yet.

## Updating dependencies

Just like Poetry, PDM can show a list of outdated packages using `pdm outdated`. However, it can't do this for specific dependency groups (like Poetry can), and it can't only show top-level dependencies either. With Poetry you can run something like `poetry show --outdated --top-level`, but with PDM you'll always get all deeply nested dependencies which you probably don't care about.

This is a bummer but not a deal-breaker.

## PDM replaces pyenv

My biggest disappointment with Poetry, by far, is that it doesn't manage the Python installation for you. You can't just update a version number, push it to production, and that Python version will get installed and the virtual environment recreated. uv does this brilliantly.

PDM can also do this, albeit with some weirdness. The general workflow looks like this: when you run `pdm init` you need to select which Python interpreter to use:

```
$ pdm init
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
Please select (0):
```

I would **much** rather prefer if I could simply say that this project uses Python 3.12, and it installs it locally. Let's say I want to use a Python version that's not on my system yet, like 3.8. I then first have to run `pdm python install 3.8` and then when I run `pdm init`, can I choose that interpreter as one of the options. PDM then stores the required Python version in the `pyproject.toml` file, but it also creates a `.pdm-python` file which contains the full path to the interpreter (`/Users/kevin/Workspace/temp/pdm-test/.venv/bin/python` in my case). This file should not be committed to git and to be honest I don't really understand the point of this file.

Okay, so I initialized my project using Python 3.8, I added Django as a dependency, everything is running as expected. Now I want to update my project to Python 3.10, which is also not installed on my system yet. I can run `pdm use 3.10` which then installs Python 3.10, but it doesn't change the `requires-python` config in the `pyproject.toml` file and you get this error:

```
$ pdm use 3.10
Successfully installed cpython@3.10.15
Version: 3.10.15
Executable: /Users/kevin/Library/Application Support/pdm/python/cpython@3.10.15/bin/python3
[NoPythonVersion]: No Python interpreter matching requires-python="==3.8.*" is found.
```

To fix this discrepancy we can manually edit the `pyproject.toml` file, changing the value of `requires-python` from `==3.8.*` to `==3.10.*`. Now there's yet another error:

```
$ pdm install
WARNING: Lockfile hash doesn't match pyproject.toml, packages may be outdated
Updating the lock file...
INFO: The saved Python interpreter doesn't match the project's requirement. Trying to find another one.
WARNING: Project requires a python version of ==3.10.*, The virtualenv is being created for you as it cannot be matched to the right version.
INFO: python.use_venv is on, creating a virtualenv for this project...
Virtualenv is created successfully at /Users/kevin/Workspace/temp/pdm-test/.venv
[PdmUsageError]: The target requires Python ==3.8.* which is not compatible with the project's requires-python ==3.10.*
```

Turns out that the lockfile has its own `requires_python = "==3.8.*"` line, and this is not getting updated, so now the lockfile and the `.pyproject.toml` file disagree about the Python version to use. To fix this we need to run `pdm lock --update-reuse --python "==3.10.*"` and then finally we can run `pdm install` again without errors. Our project now uses Python 3.10, and when this is pushed to production PDM _should_ automatically install the new Python version and recreate the virtualenv (I say should, because I didn't actually try this in production).

When you compare this with uv or pnpm (a JavaScript dependency manager) this is pretty bad UX. There are too many cryptic errors and steps needed. Compare this to uv where you just set a version number inside of `.python-version` and uv takes care of the rest. PDM just falls short.

## More uv weirdness

As I said above, you need to choose a Python interpreter when you initialize a new PDM project.

```
$ pdm init
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
Please select (0):
```

The weird thing is that this doesn't properly work when you use uv. When I chose option 3 for example, this is what I got:

```
Please select (0): 3
INFO: Using uv is experimental and might break due to uv updates.
Using Python 3.11.10
Creating virtualenv at: .venv
Activate with: source .venv/bin/activate.fish
Virtualenv is created successfully at /Users/kevin/Workspace/temp/pdm-test/.venv
Project name (pdm-test):
```

So I selected Python 3.12 but it's using Python 3.11 for some reason. In fact it did this for every option I chose. When I stopped using uv (`pdm config use_uv false`) and created a new project, the right interpreter got used. Very strange.

Another reason to not use uv with PDM just yet, but also it doesn't give me the most confident feeling about PDM as a whole.

## Conclusion

I had really high hopes for PDM because on paper it looked like the perfect blend of Poetry's UX and uv's speed, with the ability to manage the Python version as well, ala uv. Sadly I don't think uv is usable with PDM yet, for the reasons outlined above. And while PDM can install Python versions for you, it's nowhere near as user-friendly as that should be.

So let's compare Poetry, uv and PDM. When it comes to installing Python versions:

- Poetry doesn't do this at all
- PDM does, but not particularly user-friendly
- uv does it brilliantly

And when it comes to handling optional dependency groups:

- Poetry does this exactly as I'd expect
- PDM handles this too, as long as you remember the `--no-sync` option to prevent production dependencies from getting installed locally
- uv doesn't have the concept of multiple dependency groups at all

Finding and updating outdated packages:

- Poetry does this the best
- PDM is "good enough"
- uv fails by not making it possible to see outdated packages

With all of that said, which package manager would I use? Stick with Poetry or switch to PDM? By switching I'd get the Python version handling (which is "meh" but certainly better than what Poetry offers), but I'd be giving up the outstanding handling of outdated packages.

I'm sticking with Poetry for now, mainly because PDM feels too rough around the edges -- especially when using uv as the resolver and installer. I'm really hoping that Poetry will add Python management, or that uv will improve its CLI, or that PDM will improve all the things mentioned in this article, as well as their cryptic errors in general. My money is that uv will make the biggest improvements in the shortest time.

> **Update Nov 11, 2024**: uv has released multiple updates solving my biggest gripes, and I am now in the process of switching my projects over from Poetry to uv. Check my [new article about those updates](/articles/2024/python-uv-revisited/)!
