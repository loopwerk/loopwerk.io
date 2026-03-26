---
tags: saga, news
summary: Saga 3 brings much faster builds and a more flexible pipeline, while Parsley 1.2 adds powerful Markdown attribute support.
---

# Announcing Saga 3 and Parsley 1.2

I'm proud to announce big updates to two of my open source projects.

## Saga 3

[Saga](https://getsaga.dev) is designed to make static site generation simple and predictable. With version 3, the focus is on performance and extensibility.

The biggest change is dramatically faster rebuilds. Saga now caches the read phase between builds, which means only changed files are re-parsed. In practice, this makes iterative development noticeably quicker, especially on larger sites.

There are also a few new capabilities that make Saga more adaptable:

* **Build hooks** let you run custom code before or after each build (`beforeRead` and `afterWrite`), making it easier to integrate Saga into more complex workflows.
* **Dev server configuration** now lives directly in your pipeline, removing the need for separate setup.
* **Internationalization support** adds localized URLs, automatic translation linking, and locale-aware sitemaps, features that previously required custom solutions.

Saga 3 requires [saga-cli](https://github.com/loopwerk/saga-cli) version 2 to enable the incremental builds. There are a few breaking changes, so if you’re upgrading, check the [migration guide](https://getsaga.dev/docs/migrate/).

## Parsley 1.2

[Parsley](https://github.com/loopwerk/Parsley) continues to evolve as a Markdown processor. Version 1.2 introduces support for adding attributes to Markdown elements using curly braces `{...}`.

This makes it much easier to add classes, IDs, or custom attributes without dropping down to raw HTML.

| Notation | HTML result |
|----------|------------|
| `.myclass` | `class="myclass"` |
| `#myid` | `id="myid"` |
| `key="value"` | `key="value"` |

~~~text
## My heading {.special #intro}

This is a paragraph.
{.note}

> A blockquote.
{.warning}

* First
* Second
{.checklist}

---
{.divider}

```python {.highlight data-title="views.py"}
def hello():
    print("Hello, World!")
```
~~~

No backwards incompatible changes, so upgrading is very straightforward.