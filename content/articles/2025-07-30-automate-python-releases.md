---
tags: python
summary: I maintain a handful of Python packages. Here’s how I automate creating new releases, both on PyPI and GitHub.
---

# Automate Python package releases
I maintain a handful of Python packages, such as [django-generic-notifications](https://github.com/loopwerk/django-generic-notifications), [drf-action-serializers](https://github.com/loopwerk/drf-action-serializers), [django-rss-filter](https://github.com/loopwerk/django-rss-filter) and [django-vrot](https://github.com/loopwerk/django-vrot). Whenever I finish a new feature or fix a bug in one of these packages, I of course need to release a new version.

Until today I did this by hand:

1. Update the version in `pyproject.toml`
2. Run `uv build`
3. Run `uv publish`
4. Login using a special token
5. Push a tag with the version number to Git
6. Manually create a new release on Github, filling in the changes in the new release.

It’s kind of time-consuming, especially the last step where I have to go to GitHub, create a new release based on a tag, and come up with a changelog. But now I’ve finally automated all this, and the steps are now much simpler:

1. Update the version in `pyproject.toml`
2. Push a tag with the version number to Git

A Github Action then takes care of everything else: linting and type-checking the code, running unit tests on multiple Python versions, and if everything is okay: creating a new release, publishing it to PyPI, creating the changelog text based on commits (using my own [tag-changelog](https://github.com/loopwerk/tag-changelog) action), and then using that to create a new release on GitHub.

And those two steps can be simplified even further by using tbump:

1. Just run `tbump {new_version_number}`.

It’ll update the version number in `pyproject.toml`, commit the changes, and create a push a new tag to Git. Check the [tbump website](https://github.com/your-tools/tbump) for instructions on how to set it up.

The workflow that does all the automated work should be added to the `.github/workflows/` folder in your repo. Here’s mine:

#### <i class="fa-regular fa-file-code"></i> .github/workflows/release.yml
```toml
name: Release

# This workflow runs on any tag push
on:
  push:
    tags:
      - "*"

# These permissions are necessary for trusted publishing to PyPI,
# and creating a GitHub Release
permissions:
  contents: write
  id-token: write

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v3
        with:
          version: "latest"
          enable-cache: true

      - name: Install dependencies
        run: uv sync --dev

      - name: Run type checking
        run: uv run mypy .

      - name: Run linting
        run: uv run ruff check .

  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.10", "3.11", "3.12", "3.13"]

    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v3
        with:
          version: "latest"
          enable-cache: true

      - name: Install dependencies
        run: uv sync --dev --python ${{ matrix.python-version }}

      - name: Run tests
        run: uv run pytest

  build-and-publish:
    # This job only runs if the lint and test jobs pass
    needs: [lint, test]
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v3
        with:
          version: "latest"
          enable-cache: true

      - name: Build package
        run: uv build

      - name: Publish to PyPI
        uses: pypa/gh-action-pypi-publish@release/v1

      - name: Create changelog text
        id: changelog
        uses: loopwerk/tag-changelog@v1
        with:
          # The GITHUB_TOKEN is automatically provided by GitHub Actions
          token: ${{ secrets.GITHUB_TOKEN }}
          # Exclude common, uninteresting commit types from the changelog
          exclude_types: other,doc,chore,build

      - name: Create release
        uses: softprops/action-gh-release@v2
        with:
          # Use the changelog text generated in the previous step as the release body
          body: ${{ steps.changelog.outputs.changes }}
          token: ${{ secrets.GITHUB_TOKEN }}
```

The only remaining step is to set up a trusted publisher on PyPI, so that GitHub is allowed to push a new release to PyPI without any kind of API key or token.

1. Go to https://pypi.org/manage/projects/
2. Hit the Manage button for your project
3. In the Publishing menu fill in the form to add a new trusted publisher. The `Environment name` field can be left empty.

Two important notes about my setup:

One: I use [uv](https://docs.astral.sh/uv/) as my Python package and project manager. Two: this workflow file assumes that pytest, mypy and ruff are added as dev dependencies. In `pyproject.toml` it looks like this:

```toml
[dependency-groups]
dev = [
    "mypy>=1.15.0",
    "ruff>=0.11.8",
    "pytest>=8.3.5",
]
```

With the workflow file in place and the trusted publisher set up, the next time you push a new tag to Git, a new release will be published to PyPI and to GitHub. And that's it! Your entire release process is now automated, triggered by a single command. This saves time, reduces the chance of manual error, and ensures every release is consistent and well-documented.