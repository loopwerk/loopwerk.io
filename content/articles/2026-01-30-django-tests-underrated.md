---
tags: django, python, insights
summary: I never made the switch from unittest to pytest for my Django projects. And after years of building and maintaining Django applications, I still don't feel like I'm missing out.
---

# Django's test runner is underrated

Every podcast, blog post, Reddit thread, and every conference talk seems to agree: "just use pytest". [Real Python](https://realpython.com/tutorials/testing/) says most developers prefer it. Brian Okken's [popular book](https://pragprog.com/titles/bopytest2/python-testing-with-pytest-second-edition/) calls it "undeniably the best choice". It's treated like a rite of passage for Python developers: at some point you're supposed to graduate from the standard library to the "real" testing framework.

I never made that switch for my Django projects. And after years of building and maintaining Django applications, I still don't feel like I'm missing out.

## What I actually want from tests

Before we get into frameworks, let me be clear about what I need from a test suite:

1. Readable failures. When something breaks, I want to understand why in seconds, not minutes.

2. Predictable setup. I want to know exactly what state my tests are running against.

3. Minimal magic. The less indirection between my test code and what's actually happening, the better.

4. Easy onboarding. New team members should be able to write tests on day one without learning a new paradigm.

Django's built-in test framework delivers all of this. And honestly? That's enough for most projects.

## Django tests are just Python's unittest

Here's something that surprises a lot of developers: Django's test framework isn't some exotic Django-specific system. Under the hood, it's Python's standard `unittest` module with a thin integration layer on top.

`TestCase` extends `unittest.TestCase`. The `assertEqual`, `assertRaises`, and other assertion methods? Straight from the standard library. Test discovery, setup and teardown, skip decorators? All standard `unittest` behavior.

What Django adds is integration: Database setup and teardown, the HTTP client, mail outbox, settings overrides.

This means when you choose Django's test framework, you're choosing Python's defaults plus Django glue. When you choose pytest with [pytest-django](https://pypi.org/project/pytest-django/), you're replacing the assertion style, the runner, and the mental model, then re-adding Django integration on top.

Neither approach is wrong. But it's objectively more layers.

## The self.assert* complaint

A common argument I hear against unittest-style tests is: "I can't remember all those assertion methods". But let's be honest. We're not writing tests in Notepad in 2026. Every editor has autocomplete. Type `self.assert` and pick from the list.

And in practice, how many assertion methods do you actually use? In my tests, it's mostly `assertEqual` and `assertRaises`. Maybe `assertTrue`, `assertFalse`, and `assertIn` once in a while. That's not a cognitive burden.

Here's the same test in both styles:

```python
# Django / unittest
self.assertEqual(total, 42)
with self.assertRaises(ValidationError):
    obj.full_clean()
```

```python
# pytest
assert total == 42
with pytest.raises(ValidationError):
    obj.full_clean()
```

Yes, pytest's `assert` is shorter. It's a bit easier on the eyes. And I'll be honest: pytest's failure messages are better too. When an assertion fails, pytest shows you exactly what values differed with nice diffs. That's genuinely useful.

But here's what makes that work: pytest rewrites your code. It hooks into Python's AST and transforms your test files before they run so it can produce those detailed failure messages from plain `assert` statements. That's not necessarily bad - it's been battle-tested for over a decade. But it is a layer of transformation between what you write and what executes, and I prefer to avoid magic when I can.

For me, unittest's failure messages are good enough. When `assertEqual` fails, it tells me what it expected and what it got. That's usually all I need. Better failure messages are nice, but they're not worth adding dependencies and an abstraction layer for.

## The missing piece: parametrized tests

If there's one pytest feature people genuinely miss when using Django's test framework, it's parametrization. Writing the same test multiple times with different inputs feels wasteful.

But you really don't need to switch to pytest just for that. The [parameterized](https://pypi.org/project/parameterized/) package solves this cleanly:

```python
from django.test import SimpleTestCase
from parameterized import parameterized

class SlugifyTests(SimpleTestCase):
    @parameterized.expand([
        ("Hello world", "hello-world"),
        ("Django's test runner", "djangos-test-runner"),
        ("  trim  ", "trim"),
    ])
    def test_slugify(self, input_text, expected):
        self.assertEqual(slugify(input_text), expected)
```

Compare that to pytest:

```python
import pytest

@pytest.mark.parametrize("input_text,expected", [
    ("Hello world", "hello-world"),
    ("Django's test runner", "djangos-test-runner"),
    ("  trim  ", "trim"),
])
def test_slugify(input_text, expected):
    assert slugify(input_text) == expected
```

Both are readable. Both work well. The difference is that parameterized is a tiny, focused library that does one thing. It doesn't replace your test runner, introduce a new fixture system, or bring an ecosystem of plugins. It's a decorator, not a paradigm shift.

Once I added parameterized, I realized pytest no longer solved a problem I actually had.

## Side by side: common test patterns

Let's look at how typical Django tests compare to pytest's approach.

### Database tests

```python
# Django
from django.test import TestCase
from myapp.models import Article

class ArticleTests(TestCase):
    def test_article_str(self):
        article = Article.objects.create(title="Hello")
        self.assertEqual(str(article), "Hello")
```

```python
# pytest + pytest-django
import pytest
from myapp.models import Article

@pytest.mark.django_db
def test_article_str():
    article = Article.objects.create(title="Hello")
    assert str(article) == "Hello"
```

With Django, database access simply works. `TestCase` wraps every test in a transaction and rolls it back afterward, giving you a clean slate without extra decorators. pytest-django takes the opposite approach: database access is opt-in. Different philosophies, but I find theirs annoying since most of my tests touch the database anyway, so I'd end up with `@pytest.mark.django_db` on almost every test.

### View tests

```python
# Django
from django.test import TestCase
from django.urls import reverse

class ViewTests(TestCase):
    def test_home_page(self):
        response = self.client.get(reverse("home"))
        self.assertEqual(response.status_code, 200)
```

```python
# pytest + pytest-django
from django.urls import reverse

def test_home_page(client):
    response = client.get(reverse("home"))
    assert response.status_code == 200
```

In Django, `self.client` is right there on the test class. If you want to know where it comes from, follow the inheritance tree to `TestCase`. In pytest, `client` appears because you named your parameter `client`. That's how fixtures work: injection happens by naming convention. If you didn't know that, the code would be puzzling. And if you want to find where a fixture is defined, you might be hunting through `conftest.py` files across multiple directory levels.

## What about fixtures?

Pytest's fixture system is the other big feature people bring up. Fixtures compose, they handle setup and teardown automatically, and they can be scoped to function, class, module, or session.

But the mechanism is implicit. You've already seen the implicit injection in the view test example: name a parameter `client` and it appears, add `db` to your function signature and you get database access. Powerful, but also magic you need to learn.

For most Django tests, you need some objects in the database before your test runs. Django gives you two ways to do this:

- `setUp()` runs before each test method
- `setUpTestData()` runs once per test class, which is faster for read-only data

```python
class ArticleTests(TestCase):
    @classmethod
    def setUpTestData(cls):
        cls.author = User.objects.create(username="kevin")
    
    def test_article_creation(self):
        article = Article.objects.create(title="Hello", author=self.author)
        self.assertEqual(article.author.username, "kevin")
```

If you need more sophisticated object creation, [factory-boy](https://pypi.org/project/factory-boy/) works great with either framework.

The fixture system solves a real problem - complex cross-cutting setup that needs to be shared and composed. My projects just haven't needed that level of sophistication. And I'd rather not add the indirection until I do.

## The hidden cost of flexibility

Pytest's flexibility is a feature. It's also a liability.

In small projects, pytest feels lightweight. But as projects grow, that flexibility can accumulate into complexity. Your `conftest.py` starts small, then grows into its own mini-framework. You add pytest-xdist for parallel tests (Django has `--parallel` built-in). You write custom fixtures for DRF's `APIClient` (Django's `APITestCase` just works). You add a plugin for coverage, another for benchmarking. Each one makes sense in isolation.

Then a test fails in CI but not locally, and you're debugging the interaction between three plugins and a fixture that depends on two other fixtures. 

Django's test framework doesn't have this problem because it doesn't have this flexibility. There's one way to set up test data. There's one test client. There's one way to run tests in parallel. Boring, but predictable.

When I'm debugging a test failure, I want to debug my code, not my test infrastructure.

## When I would recommend pytest

I'm not anti-pytest. If your team already has deep pytest expertise and established patterns, switching to Django's runner would be a net negative. Switching costs are real. If I join a project that uses pytest? I use pytest. This is a preference for new projects, not a religion.

It's also worth noting that pytest can run unittest-style tests without modification. You don't have to rewrite everything if you want to try it. That's a genuinely nice feature.

But if you're starting fresh, or you're the one making the decision? Make it a conscious choice. "Everyone uses pytest" can be a valid consideration, but it shouldn't be the whole argument.

## My rule of thumb

Start with Django's test runner. It's boring, it's stable, and it works.

Add parameterized when you need parametrized tests.

Switch to pytest only when you can name the specific problem Django's framework can't solve. Not because a podcast told you to, but because you've hit an actual wall.

I've been building Django applications for a long time. I've tried both approaches. And I keep choosing boring.

Boring is a feature in test infrastructure.