---
tags: javascript, sveltekit
summary: I was working to architect a SvelteKit app so that it does as few requests as possible, from a central place, so that all subpages have access to the content. Sadly dealing with SSR makes it very hard to achieve my goals.
---

# Architecting a SvelteKit app - and failing

I was working to architect a SvelteKit app so that it does as few requests as possible, from a central place (`__layout.svelte`), so that all subpages have access to the content. For example you could fetch a list of books on the `/books` page and then when you open `/books/123` or `/books/123/another-page`, it shouldn't fetch that book - after all, you already got the whole list of books.

Also, I need to be able to update the content when WebSocket updates come in. I don't want every single page to have its own WebSocket handling to update the content; this all needs to be done in a central place.

Obviously my first thought immediately went to Svelte's writable stores: when I fetch the content in `__layout.svelte` I can save it in a store, and every page or component can simply read from the store. I can place the WebSocket handler in `__layout.svelte` as well, and it can update the Svelte store and all pages will automatically update. Sounds great!

This is the basic idea that I came up with. Just a really basic example of two pages that should share the content, with a simple REST endpoint that logs to the console whenever someone fetches data.

### lib/store.js

``` javascript
import { writable } from "svelte/store";
export const content = writable();
```

### routes/index.json.js

``` javascript
export const get = async (request) => {
  console.log("RECEIVED REQUEST");
  return { body: new Date().toISOString() };
}; 
```

### routes/__layout.svelte

``` javascript
<script context="module">
  import { get } from "svelte/store";
  import { content } from "$lib/store";

  export async function load({ fetch }) {
    const storedContent = get(content);

    if (storedContent) {
      return {
        props: {
          fetchedContent: storedContent
        }
      };
    }

    const res = await fetch("/index.json");

    return {
      props: {
        fetchedContent: await res.text()
      }
    };
  }
</script>

<script>
  export let fetchedContent;

  if (fetchedContent) {
    $content = fetchedContent;
  }
</script>

<slot />
```

### routes/index.svelte

``` javascript
<script>
  import { content } from "$lib/store";
</script>

<h1>Welcome to SvelteKit</h1>
<p>{$content}</p>

<p>
  <a href="/subpage">subpage</a>
</p>
```

### routes/subpage.svelte

``` javascript
<script>
  import { content } from "$lib/store";
</script>

<h1>Subpage</h1>
<p>{$content}</p>

<p>
  <a href="/">back</a>
</p>
```

The good thing is that the content is only fetched once, so when you go from the homepage to the subpage, it doesn't fetch anything from the server (keep an eye on the terminal for the `RECEIVED REQUEST` messages). I can add a single WebSocket listener that would update the `content` store, and both pages would immediately update their content. So far so good!

However, when you refresh the page, you briefly see old content show up, and then it suddenly refreshes itself. See also [this issue](https://github.com/sveltejs/kit/issues/2213) I created. Even worse: this old content is visible on ALL webbrowsers. Turns out using Svelte stores from SSR is a *really* bad idea, as the state is shared between all clients, not just the current one. As the docs say: 

> Mutating any shared state on the server will affect all clients, not just the current one.

I thought that the fix would be rather simple. Just check if we're running in the browser, and if not, just always do the fetch:

### routes/__layout.svelte

``` javascript
<script context="module">
  import { get } from "svelte/store";
  /*HLS*/import { browser } from "$app/env";/*HLE*/
  import { content } from "$lib/store";

  export async function load({ fetch }) {
    const storedContent = get(content);

    if (/*HLS*/browser &&/*HLE*/ storedContent) {
      return {
        props: {
          fetchedContent: storedContent
        }
      };
    }

    const res = await fetch("/index.json");

    return {
      props: {
        fetchedContent: await res.text()
      }
    };
  }
</script>

<script>
  export let fetchedContent;

  if (/*HLS*/browser &&/*HLE*/ fetchedContent) {
    $content = fetchedContent;
  }
</script>

<slot />
```

Sadly this doesn't work because the SSR version of the page now has no content, and then when the browser hydrates the page the content suddenly pops in. Instead of briefly flashing old content, it now briefly flashes "undefined". One small positive: at least content is not shared between different browsers anymore, but it's a long way from a full solution.

I've created a GitHub repo with a minimal, reproducible example of a bunch of problems I've come across with this architecture: [https://github.com/kevinrenskers/sveltekit-reproduce](https://github.com/kevinrenskers/sveltekit-reproduce). I would love it if people could play around with it and send a PR with a better architecture that does manage to tick my boxes: don't fetch content from the server more than absolutely necessary, make it possible to update content from a single place (for WebSocket updates), and don't leak data from one client to another.

**Update August 16, 2021**: I've created [a pull request](https://github.com/kevinrenskers/sveltekit-reproduce/pull/2) with a solution to my problem. Sadly it does come with considerable boilerplate.

**Update April 22, 2022**: I've written a [follow up article with a proper solution](/articles/2022/sveltekit-architecture/). Almost no boilerplate anymore!