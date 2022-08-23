---
tags: javascript, sveltekit
summary: SvelteKit version 1.0.0-next.415 removed the session object and store. Refactoring my project wasn't very straightforward, let's go over the changes.
---

# SvelteKit session refactor

If you've been following SvelteKit's [changelog](https://github.com/sveltejs/kit/blob/master/packages/kit/CHANGELOG.md) you've noticed a bunch of big breaking changes lately. The two biggest ones are the overhaul of the router plus the load API, and the removal of the session object and store. The router plus load change comes with a migration guide and even a migration script, but the session changes were a lot more manual work for me, and a lot more things to figure out.

## Old situation

My web app [Critical Notes](https://www.critical-notes.com) uses an external API, built in Django. Users can login to the API which returns an auth token, which we need to store and from then on all requests to the API need to send along this auth token. Pretty standard stuff. The code to make all of this work looked like this:

### /hooks.js
``` javascript
import cookie from "cookie";

export async function handle({ event, resolve }) {
  const cookies = cookie.parse(event.request.headers.get("cookie") || "");
  event.locals.token = cookies.token;
  return await resolve(event);
}

export function getSession({ locals }) {
  return {
    token: locals.token,
  };
}
```

In `hooks.js` I read the cookie, copy the token to `event.locals`, and then the `getSession` function copies the `locals` to the actual session object. From then on every load function can access it:

### /routes/+layout.js
``` javascript
export async function load({ fetch, session }) {
  const fetchedUser = await getApi(fetch, "/auth/me", session.token);
  
  return {
    fetchedUser
  };
}
```

> (Please note that code like this will fetch the user on each and every page change which is most probably not what you want. I kept the code in this post small to focus on the token logic. See [this](https://github.com/sveltejs/kit/discussions/5883#discussioncomment-3460345) for an example that caches the user and only fetches it once.)

And every page and component has easy access to it as well:

### /routes/some-route/+page.svelte
``` javascript
<script>
  import { session } from "$app/stores";
  // access token as `$session.token` 
</script>
```

## New situation

With the removal of the session object and store, the existing code no longer worked. In fact SvelteKit generates fatal errors whenever you access the session object in a load function, or the session store anywhere else. Here's how the code looks now:

### /hooks.js
``` javascript
import cookie from "cookie";

export async function handle({ event, resolve }) {
  const cookies = cookie.parse(event.request.headers.get("cookie") || "");
  event.locals.token = cookies.token;
  return await resolve(event);
}
```

The `hooks.js` mostly still works the same, except that the `getSession` function has been removed. So how do we access the event locals? Well, we need to create a root level `+layout.server.js` file like this:

### /routes/+layout.server.js
``` javascript
export async function load({ locals }) {
  return {
    ...locals,
  };
}
```

All this does is make the data available to the root `+layout.js` file, which we need to change like so:

### /routes/+layout.js
``` javascript
export async function load({ fetch, /*HLS*/data/*HLE*/ }) {
  // you now have access to `data.token`
  const fetchedUser = await getApi(fetch, "/auth/me", /*HLS*/data.token/*HLE*/);

  return {
    /*HLS*/...data/*HLE*/,
    fetchedUser
  };
}
```

By returning the destructured data object we will be able to access the token in every single load function of every single route:

### /routes/some-route/+page.js
``` javascript
export async function load({ fetch, parent }) {
  const data = await parent();
  // you now have access to `data.token`
}
```

And in the same way we can also access the token in every single `+page.svelte` file:

### /routes/some-route/+page.svelte
```javascript
<script>
  export let data;
  const { token } = data;
</script>
```

Accessing the token inside of components is also a small change:

### /lib/components/MyComponent.svelte
``` javascript
<script>
  import { page } from "$app/stores";
  // you now have access to `$page.data.token`
</script>
```

And with that all functionality is restored. In the end this SvelteKit change required me to make changes to `hooks.js`, `+layout.js`, a new `+layout.server.js` file, and changes to every layout, page and component to read the token in a different way. For me I had to change about 200 lines across 60 files.

Good luck!