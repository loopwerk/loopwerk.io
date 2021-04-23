---
tags: javascript, open source
---

# Automating your changelog and GitHub releases
In a short time I've created 25 releases for my static site generator [Saga](https://github.com/loopwerk/Saga). For each release I've manually updated the `CHANGELOG.md` file, which is a bit tedious and easy to forget. I really wanted to automate this using GitHub Actions, which I was already using to automatically run unit tests on every commit to the main branch, and for every pull request. I searched the [GitHub Marketplace](https://github.com/marketplace) for Actions that would suit my needs, but sadly couldn't find any.

- I create releases by pushing tags, so my workflow needs to be triggered by, and be based on, tags.
- Most of the Actions I found on the Marketplace are Pull Request and Issue based: they create a changelog based on closed Pull Requests and Issues between two points in time. This is not how the majority of my work is done: since it's just me, at least for now, most code is simply committed to the main branch without going through a pull request. And if there's a Pull Request, that'll end up in a squashed commit anyway, so it's no problem to only use commits to generate the changelog.
- I have specific wishes for how the changelog should look like. I want to use the [Conventional Commits](https://www.conventionalcommits.org/) format, but also turn pull request references in commit messages into clickable links: [#8] should become [[#8](https://github.com/loopwerk/Saga/pull/8)].

Maybe there's an existing Action that would be the perfect fit for me, but I also thought it would be interesting to create my own. It took a bit longer than I thought it would, mostly due to the difficulty to set up a development environment where I can run GitHub Actions locally, but the Action is done! It's called [tag-changelog](https://github.com/loopwerk/tag-changelog) can be used in your GitHub Actions workflows too.

My Action simply takes the commits between the last two tags, and turns that into a changelog string which is then made available for other Actions. 

```yml
- name: Create changelog text
  id: changelog
  uses: loopwerk/tag-changelog@v1
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    exclude_types: other,perf
```

So if you want to write the generated changelog to a file, or if you want to automatically create GitHub Releases using that same changelog text, that's all very easy. You combine small steps into a larger workflow:

```yml
name: Create Release

on:
  push:
    tags:
      - '*'

jobs:
  create-release:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v2

      - name: Create changelog text
        id: changelog
        uses: loopwerk/tag-changelog@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          exclude_types: other,perf

      - name: Create release
        uses: actions/create-release@latest
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          body: ${{ steps.changelog.outputs.changes }}

      - name: Read CHANGELOG.md
        id: package
        uses: juliangruber/read-file-action@v1
        with:
          path: ./CHANGELOG.md

      - name: Write to CHANGELOG.md
        uses: DamianReeves/write-file-action@master
        with:
          path: ./CHANGELOG.md
          contents: ${{ steps.changelog.outputs.changelog }}${{ steps.package.outputs.content }}
          write-mode: overwrite

      - name: Commit and push CHANGELOG.md
        uses: EndBug/add-and-commit@v7
        with:
          add: CHANGELOG.md
          message: "chore: Update CHANGELOG.md"
          branch: main
```

I wasn't creating GitHub Releases yet for Saga, I simply didn't feel like doing that extra work since I was already using git tags and keeping a `CHANGELOG` file, but now that it's all automated; not a problem anymore.

To be fair, `tag-changelog` is rather opinionated at the moment, it's not configurable and I'm not sure how many other people will find it useful - but give it a look if it sounds interesting. I am planning to make the Action much more configurable and would gladly accept contributions.

Which brings me to the actual development process that I'm using. Normally you'd have to commit and push every single change to GitHub to test your Action, but before I even started writing a single line of code, I already knew I didn't want to work like that. It took a bit of effort, but I now have a workflow where I can run my Action locally on my own machine using [act](https://github.com/nektos/act). I had to figure the following things out, that I am documenting mostly for myself, but if you're planning to write GitHub Actions, this will be very helpful too I think.

1. Installing act is super simple using Homebrew: `brew install act`. However, you will also need to install Docker. I used [Docker Desktop](https://www.docker.com/products/docker-desktop).

2. You'll need to create a `.github/workflow/[workflow].yml` file within your Action repo, that will be executed by act. There are subtle differences in how act behaves different from the real GitHub workflow runner though, and this was the first big hurdle.

```yml
name: My Workflow

on:
  push

jobs:
  my-workflow:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Locally
        uses: actions/checkout@v2
        if: ${{ env.ACT }}
        with:
          path: "[my_folder_name]"
      - name: Checkout GitHub
        uses: actions/checkout@v2
        if: ${{ !env.ACT }}

      - name: My Action
        uses: ./
```

The big gotcha is how `actions/checkout` needs to be setup differently for the local vs. remote runner. For act, it needs that `path` parameter, which should be set to the name of the folder containing your Action. My `tag-changelog` Action for example is located in `/Users/loopwerk/workspace/tag-changelog`, so I would use `path: "tag-changelog"`.

The second gotcha is that `uses: ./` parameter for the Action you're working on. This also works when the workflow runs on GitHub itself.

3. `node_modules` is a problem when that's in your `.gitignore` file, which is very likely. The problem is that everything in your `.gitignore` is not copied to the Docker image running the workflow, and so any dependencies you're trying to `import`, no longer work. The solution is to package up all the JavaScript into a single compiled file containing all the dependencies. I used [ncc](https://github.com/vercel/ncc) for that.

4. If your Action depend on `${{ secrets.GITHUB_TOKEN }}`, you have some extra work to do which wasn't clear to me: you'll need to manually create a personal access token and store it in a `.secrets` file like this:

```
GITHUB_TOKEN=ABC123ABC123ABC123ABC123ABC123
```

If you don't do this step, your Action will not be given a `GITHUB_TOKEN`, since act can't create one for the runner like GitHub does. Just make really sure to add this file to `.gitignore`!

5. If you're using `getOctokit` from `@actions/github`, your Action does need to be in a git repo that's actually pushed to GitHub. This was a puzzle that I couldn't solve for a long time: I was trying to get a first version of my Action to work locally before even committing anything, let alone pushing it to GitHub, but that simply doesn't work. At least push a basic `README` file for example, and then work on your JavaScript code locally, and it'll work just fine.

You can look at the [repo for tag-changelog](https://github.com/loopwerk/tag-changelog), in particular check out `.github/workflows/run.yml`, `package.json` and `action.yml`. If you're trying to build a JavaScript-based GitHub Action, that should give you all the information necessary to also use act to locally develop and test your code, while it also works when GitHub runs it online.
