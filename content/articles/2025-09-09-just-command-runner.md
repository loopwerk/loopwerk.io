---
tags: review
summary: How I use the just command runner to create a simple, unified interface for running, testing, linting, and formatting all my projects, regardless of the tech stack.
---

# One command to run them all

As a developer who jumps between projects in Python, JavaScript, and Swift, I live with a constant, low-level friction: remembering the right command to get things done. For example to run the development server it might be `uv run ./manage.py runserver`, `pnpm dev`, or `swift run watch content Sources deploy`, depending on the project. 

For a long time, I just dealt with it. I'd seen people praise the [just](https://github.com/casey/just) command runner, but I never really got the point. It seemed like a solution in search of a problem.

That changed when I started two Django projects that use [django-tailwind-cli](https://github.com/django-commons/django-tailwind-cli). To run the dev server *and* the Tailwind watcher, I had to use a specific, combined command: `uv run ./manage.py tailwind runserver`. The number of times I defaulted to the standard `runserver` command out of muscle memory, then spent ten minutes pulling my hair out when my style changes didn't appear, was embarrassing. That was my tipping point.

I finally understood the value of `just`. It’s not just (heh) about running complex commands; it's about creating a simple, unified interface for all your projects. Now, every project of mine has a `justfile` that defines a core set of recipes.

For example, for a Django project:

```makefile
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

```makefile
run:
    pnpm vite dev --port 3000

test:
    pnpm vitest --run

format:
    pnpm prettier --write .

check:
    pnpm svelte-kit sync && pnpm svelte-check --tsconfig ./tsconfig.json
```

The magic is that the *invocation* is always the same. I no longer need to remember the specifics. I just `cd` into a directory and run:

-   `just run` to start the development server.
-   `just test` to run the test suite.
-   `just format` to auto-format the code.
-   `just check` to run linters and type-checkers.

Each project implements these recipes differently, but the interface for me, the developer, is stable. The cognitive load is gone.

Look, I know I'm late to the party on this one, but if you've been on the fence about command runners, I highly recommend giving `just` a try. It’s a wonderfully simple tool that solves a real, everyday annoyance. Better late than never.