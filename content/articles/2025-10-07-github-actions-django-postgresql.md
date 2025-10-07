---
tags: python, django, howto, workflow
summary: Did you know that you can run unit tests for your Django app, in GitHub Actions, using PostgreSQL?
---

# Run Django tests using PostgreSQL in GitHub Actions

Did you know that you can run unit tests for your Django app, in GitHub Actions, using PostgreSQL? I’m a little bit ashamed to admit that I had absolutely no idea until today. I really thought that I was forced to run my unit tests using Sqlite. And while most of the time that works perfectly fine, there are times when your Django app is using PostgreSQL-exclusive features and having to work around that in CI becomes a real pain. It’s also just a good idea to stay as close to the production setup as possible when running your tests.

Turns out that it’s actually really simple to use a real PostgreSQL database in GitHub Actions! Here’s a minimal example workflow that installs your dependencies, starts a PostgreSQL 15 service, and runs your Django tests, all inside CI:

#### <i class="fa-regular fa-file-code"></i> .github/workflows/tests.yml
```
name: Unit tests

on:
  push:
    branches: ["develop"]
  pull_request:
    branches: ["develop"]

env:
  DEBUG: "True"
  DATABASE_URL: "postgres://postgres:postgres@postgres:5432/test_soundradix"
  SECRET_KEY: "unit-tests"

jobs:
  build:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_soundradix
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    strategy:
      max-parallel: 4

    steps:
      - uses: actions/checkout@v3
      - uses: astral-sh/setup-uv@v3
      - run: uv python install
      - run: uv sync --group dev
      - run: uv run ./manage.py test --noinput
```

Until today I didn’t have the `services` section where the database is configured, and my `DATABASE_URL` was set to `sqlite://:memory:`. Everything else in this file is unchanged.

My Django project is configured to read environment variables using [python-dotenv](https://github.com/theskumar/python-dotenv), and to parse a database URL from those environment variables using [dj-database-url](https://github.com/jazzband/dj-database-url), as I described in my article [How I configure my Django projects](/articles/2024/django-settings/). My `settings.py` looks like this:

#### <i class="fa-regular fa-file-code"></i> settings.py
```
import os
import dj_database_url
from dotenv import load_dotenv

load_dotenv(str(BASE_DIR / "myproject" / ".env"))

DEBUG = os.getenv("DEBUG") == "True"
SECRET_KEY = os.getenv("SECRET_KEY")
DATABASES = {
    "default": dj_database_url.parse(os.getenv("DATABASE_URL")),
}
```

With this setup, your Django tests now run against a real PostgreSQL database in CI. No more surprises when deploying to production!