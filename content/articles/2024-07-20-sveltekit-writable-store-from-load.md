---
tags: javascript, sveltekit, insights
summary: How do you update content in real time when that content was fetched from the layout's load function?
---

# SvelteKit architecture tip: return a writable store from your load function

In my SvelteKit app I fetch some "core” data which is needed everywhere, such as the currently logged-in user, in the root `LayoutLoad` function. Something like this (simplified) example:

```typescript
export const load: LayoutLoad = async ({ fetch, data }) => {
  const response = await fetch(...);
  const user = await response.json();

  return {
    ...data,
    user: user,
  };
};
```

This works fine, the user is now available in every layout and page, via the page data:

```typescript
export let data;
const { user } = data;
```

But what if you want to update this `user` instance? For example on your website you have a form where the user can change their name, username, or avatar. When the form is submitted this gets stored on the server, but the site still shows the old user information, for example it still shows the old avatar of the user in the top menu. The `user` variable isn't writable, so how do you overwrite this?

Simple: make it writable by wrapping it in a writable store:

```typescript
import { writable } from "svelte/store";

export const load: LayoutLoad = async ({ fetch, data }) => {
  const response = await fetch(...);
  const user = await response.json();

  return {
    ...data,
    user: writable(user),
  };
```

Now `user` is a store and should be used as `$user` within your layouts and pages. And the benefit is that you can now overwrite its value:

```typescript
function storeUser(data) {
  const response = await fetch(..., {
    method: "POST",
    body: JSON.stringify(data),
  });
  $user = await response.json();
}
```

Of course you need to add proper error handling, but everything updates in real time now.

This is actually a much simpler solution of what [I wrote about back in 2022](/articles/2022/sveltekit-architecture/), where I conditionally returned either a readable store (from SSR) or a global writable store (from CSR) to make things like real time updates via WebSockets possible - although that solution does have one big advantage: the global store is always there. For example, let's say you fetch a list of books on the `/books` page and a list of albums on `/albums` page, so both those pages have a `LayoutLoad` method where the fetches are made. With SvelteKit this will cause the fetch to happen every time the user switches between these two pages, and the writable store will also be recreated every time. If your goal is to prevent refetching content you've already fetched before, then the global store is still your best bet. You just got to be careful to never touch the global store from SSR!
