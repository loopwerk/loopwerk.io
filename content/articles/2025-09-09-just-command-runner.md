---
tags: workflow, howto
summary: How I use the just command runner to create a simple, unified interface for running, testing, linting, and formatting all my projects, regardless of the tech stack.
---

# One command to run them all

I jump between projects in Python, TypeScript, and Swift, and there's this constant minor annoyance: remembering the right command to get things done. For example to run the development server it might be `uv run ./manage.py runserver`, `pnpm dev`, or `swift run watch`, depending on the project.

For a long time, I just dealt with it. I'd seen people on social media praise the [just](https://github.com/casey/just) command runner, but I never really understood the point.

That changed when I started a Django project that uses [django-tailwind-cli](https://github.com/django-commons/django-tailwind-cli). To run the dev server _and_ the Tailwind watcher, I have to use a specific, combined command: `uv run ./manage.py tailwind runserver`. You won't believe the number of times I instead ran the normal `runserver` command out of muscle memory, to then wonder out loud why my style changes didn't appear. It was embarrassing.

This made me understand the true value of `just`. It's not just (heh) about running complex commands, although it certainly can do that. For me it's all about creating a simple, unified interface for all my projects.

For example, for a Django project:

```makefile title="justfile"
run:
    uv run ./manage.py tailwind runserver

test:
    uv run ./manage.py test

format:
    uv run ruff format .

check:
    uv run ruff check .
    uv run djlint --check .
    uv run mypy . --check-untyped-defs
```

And for a SvelteKit project it might look like this:

```makefile title="justfile"
run:
    pnpm vite dev --port 3000

test:
    pnpm vitest --run

format:
    pnpm prettier --write .

check:
    pnpm svelte-kit sync && pnpm svelte-check --tsconfig ./tsconfig.json
```

The magic is that the _invocation_ is always the same: I just `cd` into a directory and run one of `just run`, `just test`, `just format` or `just check` to get things done. I never have to think about it anymore.

Look, I know I'm late to the party on this one, but if you've been on the fence about command runners, I highly recommend giving `just` a try. Better late than never.
