---
tags: javascript, sveltekit
summary: Last August I wrote about trying to come up with the architecture for a SvelteKit app I was working on, and failing.  I'm happy to say that I have found a solution for all my problems!
---

# SvelteKit Architecture - the solution

In August last year [I wrote](/articles/2021/architecting-sveltekit/) about trying to come up with the architecture for a SvelteKit app I was working on, namely my side-project [Critical Notes](https://www.critical-notes.com/). I wanted to make sure that I was doing as few REST requests as possible, allowing for centralized WebSocket updates, and minimizing boilerplate. At that time I failed to come up with a good solution, and the article ended on a sad note.

I'm happy to say that I have found a solution for all my problems and the new version of Critical Notes -fully rewritten in SvelteKit- launched in October of 2021, although it took some steps to get there.

The first version of my solution used either `context` (since renamed to `stuff`) or a store, depending on if we're running in SSR or in the browser. I first came up with this solution just a day after writing my previous SvelteKit article, and created a [Pull Request](https://github.com/kevinrenskers/sveltekit-reproduce/pull/2) to my example/repro repository on GitHub. Many people have found this PR and found it useful, but that code is rather boilerplate-y. In the months since, I've greatly simplified the code. Instead of either using `stuff` or a store, we're now always using a store from `stuff`, in a safe way.

Let's dig in!

### /routes/__layout.svelte
```javascript
<script context="module">
  import { fetchBooksStore } from "$lib/utils";
  export async function load({ fetch, stuff }) {
    try {
      const updatedStuff = {
        ...stuff,
        fetchedBooksStore: await fetchBooksStore(fetch),
      };
      return {
        stuff: updatedStuff,
      };
    } catch (error) {
      return error;
    }
  }
</script>

<slot />
```

### /routes/index.svelte
```javascript
<script context="module">
  // Pass the `stuff` from __layout into the props of this page
  export async function load({ stuff }) {
    return { props: stuff };
  }
</script>

<script>
  export let fetchedBooksStore;
  $: books = Object.values($fetchedBooksStore);
</script>

<h1>List of books</h1>
<ul>
  {#each books as book (book.id)}
    <li><a href="/{book.id}">{book.title}</a></li>
  {/each}
</ul>
```

### /routes/[id].svelte
```javascript
<script context="module">
  import { get } from "svelte/store";

  export async function load({ params, stuff }) {
    // Bail out if we don't have the book in the store
    const book = get(stuff.fetchedBooksStore)[params.id];
    if (!book) {
      return {
        status: 404,
        error: "Book not found",
      };
    }
    return { props: stuff };
  }
</script>

<script>
  import { page } from "$app/stores";
  export let fetchedBooksStore;
  $: book = $fetchedBooksStore[$page.params.id];
</script>

<a href="/">&lt; back to list</a>

<h1>{book.title}</h1>
<p>Author: {book.author}</p>
```

That was all the layout code, and now for the utility code:

### /lib/store.js
```javascript
import { writable } from "svelte/store";
export const books = writable({});
```

### /lib/utils.js
```javascript
import { get, readable } from "svelte/store";
import { browser } from "$app/env";
import { books as booksStore } from "$lib/store";

function arrayToDict(arr) {
  const dict = {};
  arr.forEach(value => {
    dict[value.id] = value;
  });
  return dict;
}

export async function fetchBooksStore(fetch) {
  const books = browser && get(booksStore);
  if (books && Object.values(books).length > 0) {
    return booksStore;
  }

  const response = await fetch("/books.json");
  const fetchedBooks = await response.json();

  if (browser) {
    booksStore.set(arrayToDict(fetchedBooks));
    return booksStore;
  } else {
    return readable(arrayToDict(fetchedBooks));
  }
}
```

The meat of the solution is contained within this `fetchBooksStore` function: it always returns a Svelte store, no matter if we're running in the browser or in SSR. It's just that in SSR we create a readable store on the fly, we're not using any global store that would be shared by all clients (which is the problem [I initially wrote about](/articles/2021/architecting-sveltekit/)). That makes our layout code a lot easier, as we now always have a consistent interface to work with - compared to my first solution where you'd sometimes have a store and sometimes a normal object, and there were a bunch of `if browser` checks all over the layout code. This is now all hidden away.

Of course `fetchBooksStore` can be made much more generic to fetch and store any kind of content. For example the version I use in Critical Notes looks like this:

```javascript
export async function fetchContent(fetch, store, endpoint, token) {
  const hasFetchedContent = browser && get(campaignsLoadedLists)[campaignId][endpoint];
  if (hasFetchedContent) {
    return store;
  }

  const fetchedValues = await getApi(fetch, `campaigns/${endpoint}`, token);

  if (browser) {
    store.set(fetchedValues);
    return store;
  } else {
    return readable(arrayToDict(fetchedValues));
  }
}
```

By passing in the actual store and the endpoint to fetch, I can fetch any kind of content with just one function.

So, that's my solution, and the way I've architected Critical Notes. All content is stored in a Svelte store, and these stores are used to render all pages. And my WebSocket code can easily write updates to these stores, which is then automatically reflected on the pages. And very importantly: this is doing as few REST requests as possible, by using the stores as a cache. I'm very happy!

I have created a minimal example repo: https://github.com/loopwerk/sveltekit-architecture. I'd love to hear if this has helped you.