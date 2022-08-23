---
tags: javascript, sveltekit
summary: When HttpOnly cookies didn't work as expected in my SvelteKit project I had to find a workaround.
---

# Working around HttpOnly cookie problems in SvelteKit

When I completely rewrote my [Critical Notes](https://www.critical-notes.com) side-project from Svelte + Firestore to SvelteKit + Django, I wanted to use HttpOnly cookies for authentication. So the web client would call a Django API endpoint to login, the server would return a response with a `set-cookie` header which would set a HttpOnly cookie containing a token, and from then on every request that the web client makes to the API would automatically send that cookie back. It sounded pretty simple to implement and great for security (HttpOnly cookies can't be read by JavaScript). Locally everything was working perfectly fine, so when the time came to deploy everything to my staging server, I was really surprised that nothing was working: cookies were not getting send back to the API so none of the requests were authenticated. I wrote up my problems in a [GitHub ticket](https://github.com/sveltejs/kit/issues/1198#issuecomment-932447869) and hoped for a fix.

Sadly the problem wasn't getting fixed in SvelteKit in time for me to release the new version of Critical Notes, so I had to come up with a workaround, and it's this workaround that I want to talk about in this post, since I've been getting multiple questions about it via email, Twitter and that GitHub ticket.

My workaround in a few bullet-points:

- The client calls the external login endpoint via a SvelteKit endpoint
- The external endpoint no longer returns a `set-cookie` header but simply returns the token in the body of the response
- The SvelteKit endpoint reads the response and sets its own HttpOnly cookie
- SvelteKit hooks reads the cookie and makes the token available in the session
- Every other API endpoint request gets an `Authorization` header with that token

So in other words, the Django API doesn't do anything with cookies anymore; it doesn't send them, and it doesn't expect to receive them. It has become a mobile-style API that just deals with headers.

The biggest cog in this wheel is the login "proxy", the SvelteKit endpoint that is called by the web client:

``` javascript
// /routes/auth/login.js
import { postApi } from "$lib/api";

export async function post({ request }) {
  let body;

  try {
    body = /*HLS This calls the external API*/await postApi(fetch, “auth/login", await request.json())/*HLE*/;
  } catch (error) {
    return {
      status: error.status,
      body: { error: error.error },
   };
  }

  return {
    headers: {
      "set-cookie": `token=${body.token}; path=/; HttpOnly; max-age=31536000`,
    },
    body,
  };
}
```

Then to get access to the token in the web client I use the following hooks:

``` javascript
// /hooks.js
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

This token can then be accessed from any Svelte component from the `load` method (the `session` gets passed in) or by directly importing the session store: `import { session } from "$app/stores"`.

Logging out is done using a SvelteKit endpoint that clears the cookie:

``` javascript
// /routes/auth/logout.js
export function post() {
  return {
    headers: {
      "set-cookie": 'token=""; path=/; HttpOnly; expires=Thu, 01 Jan 1970 00:00:00 GMT',
    },
    body: {
      ok: true,
    },
  };
}
```

Of course you could call an external logout endpoint here as well, if that's something your API requires.

Some questions I've been asked:

## Is this safe?
We're reading the HttpOnly cookie and storing it in memory (in the `$session` store via the `handle` and `getSession` hooks), so in theory we've undone all the nice security benefits of HttpOnly cookies. That is indeed a bit of a bummer! Make sure to properly sanitize user generated content so they can't run their JavaScript code on your website, but if they're able to do that you have huge problems already anyway.

## What about proxying all requests?
One way to increase the security is to proxy *all* requests via a local SvelteKit endpoint: that way the endpoint code can read the HttpOnly cookie and set the `Authorization` header with the token. The token would never have to be passed to the client, it should never have a need for it. In my case I am also using the existence of the token in `$session` to know if the user is logged in or not, but of course you could simply check for the existence of the token cookie and store a simple `isLoggedIn` boolean in the `$session`.

While this would be better for security, it also doubles the requests made, every single request has to go to two servers, and this will cause some latency. I decided not to go this route for my project.

## Why do you even need the HttpOnly cookie?
When the user logs in and the external API returns a token, you need to store this token somewhere. Just keeping it in memory means that the user is logged out when they refresh the browser or close the website. You could store it in a normal (non-HttpOnly) cookie or in `localStorage`; you wouldn't need to proxy the login request via a SvelteKit endpoint anymore, but both are easily readable by JavaScript code and are not considered secure. On top of that, non-HttpOnly cookies have a maximum lifetime of only one week (at least in Safari) so your users will be logged out after a week.

## What's the ideal solution?
Ideally SvelteKit would properly handle HttpOnly cookies: receiving them from an external API, and from then on automatically sending them back, but sadly that's exactly the thing that doesn't work. So storing a HttpOnly cookie ourselves by proxying the login endpoint is the best workaround I could come up with. I do think proxying *all* endpoints is the more secure way to go to prevent the token from ever being stored in memory client-side, but you'll need to decide if those extra requests are acceptable for you.