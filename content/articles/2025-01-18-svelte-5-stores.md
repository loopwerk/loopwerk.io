---
tags: javascript, sveltekit
summary: One pattern that I love to use in my SvelteKit projects is returning writable stores from the layout's load function. Can we migrate this to the new $state rune?
---

# Refactoring Svelte stores to $state runes

I've finished migrating my first big SvelteKit project from Svelte 4 to Svelte 5 and its [new runes](https://svelte.dev/docs/svelte/what-are-runes), and while my first impression when working on this migration [wasn't all that great](/articles/2025/svelte-5-runes/), in the end I do think that most of the code got more explicit and easier to reason about. (With a few exceptions and some things got much more complex, which I'll address in a future article.)

One pattern that I love to use in my SvelteKit projects is returning writable stores from the layout's `load` function. This makes it possible to fetch data from the server (for example the user object for the logged in user), and then you make this object available as a writable reactive store throughout the whole application. So when the user updates their username or avatar, you do the PUT request to the server and you get the updated user object back from the server as the response, you can simply update the `$user` writable store value and every place in your app where you show the user object gets updated immediately. I've [written about this pattern previously](/articles/2024/sveltekit-writable-store-from-load/) if you want to know more. The alternative of calling `invalidateAll()` is pretty bad, as it'll rerun all `load` functions. I don't need to refetch all my server data just to refetch the user object, especially when it's already right there in the response of my PUT request!

The basic code to make this lovely pattern work looks like this:

```ts title="+layout.ts"
import type { LayoutLoad } from "./$types";
import { writable } from "svelte/store";

export const load: LayoutLoad = async () => {
  return {
    user: writable({ name: "Kevin Renskers" }),
  };
};
```

Obviously the user object would normally be something you'd `fetch` from a server, but this example serves our purpose. Now we have a writable store that we can access from any page, and we can thus change the user object:

```svelte title="+page.svelte"
<script lang="ts">
  let { data } = $props();
  let { user } = data;

  function change() {
    $user.name = "Piet Paulusma";
  }
</script>

<button onclick={change}>Change user name</button>
```

When we press the button the user name as shown on a completely different page or layout automatically changes. For example maybe we're showing the user's name in the navigation bar when the user is logged in:

```svelte title="+layout.svelte"
<script lang="ts">
  let { children, data } = $props();
  let { user } = data;
</script>

<nav>
  <a href="/">Home</a>
  {#if $user}
    <a href="/account/">{$user.name}</a>
  {/if}
</nav>

{@render children()}
```

This pattern still works beautifully, but I wanted to see if I could replace the store with Svelte 5's new `$state` rune, so that the code fits better with the rest of the code, all migrated to the new runes.

Sadly, you can't just return a `$state` rune from `+layout.ts` like so:

```ts title="+layout.ts"
import type { LayoutLoad } from "./$types";

export const load: LayoutLoad = async () => {
  return {
    user: $state({ name: "Kevin Renskers" }),
  };
};
```

This results in the Svelte error `rune_outside_svelte`: "The `$state` rune is only available inside `.svelte` and `.svelte.js/ts` files". I also can't rename `+layout.ts` to `+layout.svelte.ts`, because then I get the error message "Files prefixed with + are reserved". Bummer.

One thing we can try is to store the state in an external file:

```ts title="/lib/state.svelte.ts"
type State = {
  user: undefined | { name: string };
};

export const state: State = $state({ user: undefined });
```

We write to `state` from our `load` function:

```ts title="+layout.ts"
import type { LayoutLoad } from "./$types";
import { state } from "$lib/state.svelte";

export const load: LayoutLoad = async () => {
  state.user = { name: "Kevin Renskers" };
};
```

We can access it from our layout:

```svelte title="+layout.svelte"
<script lang="ts">
  let { children } = $props();
  import { state } from "$lib/state.svelte";
</script>

<nav>
  <a href="/">Home</a>
  {#if state.user}
    <a href="/account/">{state.user.name}</a>
  {/if}
</nav>

{@render children()}
```

And we can still write to it from our page:

```svelte title="+page.svelte"
<script lang="ts">
  import { state } from "$lib/state.svelte";

  function change() {
    state.user = { name: "Piet Paulusma" };
  }
</script>

<button onclick={change}>Change user name</button>
```

But sadly this introduces shared state on the server (when we use SSR), and this is a big problem since we're now leaking data between different users. See [SvelteKit's own documentation on this](https://svelte.dev/docs/kit/state-management#No-side-effects-in-load) for more info. You can quite easily see this data leakage in action with the following code:

```ts title="/lib/state.svelte.ts"
export const state = $state({ count: 0 });
```

```ts title="+layout.ts"
import type { LayoutLoad } from "./$types";
import { state } from "$lib/state.svelte";

export const load: LayoutLoad = async () => {
  state.count += 1;
};
```

```svelte title="+layout.svelte"
<script lang="ts">
  let { children } = $props();
  import { state } from "$lib/state.svelte";
</script>

<h1>{state.count}</h1>

{@render children()}
```

When you open this in two browsers and refresh a few times, one browser after the other, you'll see the count go up and up (when looking at the page source), proving that the state is shared between both browsers (well, not really, it's shared on the server, and used by both users). This will have serious consequences if you go this route: if user A is logged in and you'd write the user object to the shared state, and user B is not logged in, they'd still see a flash of user A's username appear in the navigation bar, until the shared state is overwritten by the `undefined` user object. This is exactly the problem that I ran into when building [Critical Notes](https://www.critical-notes.com), and I [wrote about it back in 2021](http://localhost:3001/articles/2021/architecting-sveltekit/) and [again in 2022](/articles/2022/sveltekit-architecture/) with the solution to my architecture problem.

So where does this leave us? It seems that if you want to use the pattern of returning a writable store from your load function, that this _cannot be migrated to the new `$state` rune_, as returning such a rune is impossible and writing to a shared `$state` is a bad bad very bad idea. It would be nice if Svelte would make it possible to return writable and reactive `$state` from the load function so all our code uses the same patterns, but until then, let's hope that Svelte isn't going to deprecate their stores.
