---
tags: django, insights
summary: I never made the switch from unittest to pytest for my Django projects. And after years of building and maintaining Django applications, I still don't feel like I'm missing out.
---

# Django's test runner is underrated

Is it just me, or does every podcast, blog post, and conference talk agree that pytest is the bee's knees? [Real Python](https://realpython.com/tutorials/testing/) says that most developers prefer it, and Brian Okken's book [Python Testing with pytest](https://pragprog.com/titles/bopytest2/python-testing-with-pytest-second-edition/) literally calls it "undeniably the best choice". It's almost like a rite of passage: at some point you're supposed to graduate to pytest, the "real" testing framework for grown-ups.

Call me a radical, but I never made that switch. And after all these years of building and maintaining Django apps, I still don't feel like I'm missing out.

## What I need

I have a few simple requirements for a testing framework: I need my tests to run quickly, I want to see exactly which tests failed and why, and new team members should be able to write tests on day one, without learning a whole new system.

Django's built-in test framework delivers all of this, so I've honestly never seen any reason to switch to something else. That's not to say that pytest doesn't have some things which are genuinely better! It's just that to me, the downsides are bigger.

## Fewer dependencies

Django's test framework is just Python's standard `unittest` module with a thin integration layer on top: things like database setup and teardown, the HTTP client, mail outbox, and settings overrides. 

In other words, when you use Django's test framework, you're using Python's defaults (plus a bit of Django glue). No other dependencies needed and nothing else to learn. But when you choose pytest, you're replacing everything, from the assertion style to the test runner. And then you re-add Django integration on top with [pytest-django](https://pypi.org/project/pytest-django/).

I'm not a big fan of adding dependencies when it's not necessary.

## Less magic

One common argument I hear against unittest is that there are too many assert methods. And yes, there are a bunch of them, and they have kind of long names. But every editor has autocomplete, so type `self.assert` and pick from the list.

And in practice, how many assertion methods do you actually use? In my tests, it's mostly `assertEqual` and `assertRaises`. Maybe `assertTrue` and `assertFalse` once in a while. It's not really a problem in my opinion.

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

I'll admit that pytest's `assert` is shorter, and easier to read. And to be fair, pytest's failure messages are better too: when a test fails, it shows you a nice diff.

But to make that possible, pytest has to rewrite your code. It hooks into Python's AST and transforms your test files before they run so that it can produce those detailed failure messages from simple `assert` statements. Sure, this has been battle-tested for over a decade, but you can't deny that it's a layer of transformation between what you write and what actually runs. Or in other words: magic.

Personally I find unittest's failure messages good enough. When `assertEqual` fails, it tells me what it expected and what it got. That's all I need, really.

## Parametrize

If there's one pytest feature that people can't stop talking about, it's parametrization. Writing the same test multiple times but with different inputs is indeed a waste of time and effort.

But you really don't need to switch to pytest just for that. The [parameterized](https://pypi.org/project/parameterized/) package solves this cleanly:

```python
from django.test import SimpleTestCase
from parameterized import parameterized

class SlugifyTests(SimpleTestCase):
    @parameterized.expand([
        ("Hello world", "hello-world"),
        ("Django's test runner", "djangos-test-runner"),
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
])
def test_slugify(input_text, expected):
    assert slugify(input_text) == expected
```

Both are readable and both work well, but parameterized is a small library that does one thing well, whereas pytest is a big framework.

If you don't want to install even this small dependency, then the standard library also has you covered: [`subTest`](https://docs.python.org/3/library/unittest.html#distinguishing-test-iterations-using-subtests) lets you loop over your cases inside a single test method while still reporting each failing input separately.

```python
from django.test import SimpleTestCase

class SlugifyTests(SimpleTestCase):
    def test_slugify(self):
        cases = [
            ("Hello world", "hello-world"),
            ("Django's test runner", "djangos-test-runner"),
        ]
        for input_text, expected in cases:
            with self.subTest(input_text=input_text):
                self.assertEqual(slugify(input_text), expected)
```

I like parameterized much better though, and to me it's absolutely worth the install.

## Simpler database access

```python
# Django
from django.test import TestCase
from myapp.models import Article

class ArticleTests(TestCase):
    def test_article_str(self):
        article = Article.objects.create(title="Hello")
        self.assertEqual(str(article), "Hello")
```

With Django, you never have to think about database access. `TestCase` wraps every test in a transaction and rolls it back afterward, giving you a clean slate without extra decorators. It just works as expected.

```python
# pytest + pytest-django
import pytest
from myapp.models import Article

@pytest.mark.django_db
def test_article_str():
    article = Article.objects.create(title="Hello")
    assert str(article) == "Hello"
```

With pytest-django database access is opt-in, and you need to use the `@pytest.mark.django_db` decorator. I find this pretty annoying, since most of my tests touch the database. I don't really see the point of having to opt-in, to be honest.

## Fixtures

For most Django tests, you need some objects in the database before your test runs. Django gives you two ways to do this: `setUp()` runs before each test method, and `setUpTestData()` runs once per test class.

```python
class ArticleTests(TestCase):
    @classmethod
    def setUpTestData(cls):
        cls.author = User.objects.create(username="kevin")
    
    def test_article_creation(self):
        article = Article.objects.create(title="Hello", author=self.author)
        self.assertEqual(article.author.username, "kevin")
```

Pytest handles this with its own bespoke fixture system. You first define a fixture, and then make use of it by way of dependency injection:

```python
import pytest

@pytest.fixture
def author(db):
    return User.objects.create(username="kevin")

def test_article_creation(author):
    article = Article.objects.create(title="Hello", author=author)
    assert article.author.username == "kevin"
```

Fixtures are the other big pytest feature people bring up constantly. Fixtures compose, they handle setup and teardown automatically, and they can be scoped to function, class, module, or session. It's very powerful, but the mechanism is implicit. I'm not a big fan of dependency injection systems, and pytest is no different.

And it's not just your own fixtures that work like this; the built-in helpers arrive the same way. Here's a view test in both frameworks:

```python
# Django
from django.test import TestCase
from django.urls import reverse

class ViewTests(TestCase):
    def test_home_page(self):
        response = self.client.get(reverse("home"))
        self.assertEqual(response.status_code, 200)
```

In Django, `self.client` exists on the test class. If you want to know where it comes from, follow the inheritance tree to `TestCase`. Simple.

```python
# pytest + pytest-django
from django.urls import reverse

def test_home_page(client):
    response = client.get(reverse("home"))
    assert response.status_code == 200
```

In pytest, `client` gets injected purely based on the name of the parameter. To find out which parameters can be injected, you end up hunting through `conftest.py` files.

As you might've guessed, I like the explicit version better.

I think that the fixture system is probably better suited for very large projects with lots of test data, but my projects just haven't needed this kind of power. And until I do, I'd rather stick with the explicit version.

## Predictable

When you start using pytest, it feels lightweight. But as your project grows, your `conftest.py` balloons into its own mini-framework. You add pytest-xdist for parallel tests (Django has `--parallel` built-in). You write a custom fixture for DRF's `APIClient`. Then you add a plugin for coverage, and another for benchmarking. Each addition made perfect sense.

Then a test fails in CI but it's impossible to reproduce locally, and now you're debugging the interaction between three plugins and a fixture that depends on two other fixtures. That's the stuff that makes my head hurt.

Django's test framework doesn't have this problem because it doesn't have this flexibility. It's boring, but predictable.

## My rule of thumb

Let me be clear that I'm not anti-pytest. If I join a project that uses pytest? I use pytest. This is simply my personal preference for new projects.

For new projects, here's my rule of thumb: start with Django's test runner. It's predictable, it's explicit, and it works just fine. Add parameterized when you need parametrized tests. For me this is good enough.

Switch to pytest only when you can name the specific problem Django's framework can't solve. When you hit that wall, you'll know the time is right to switch.