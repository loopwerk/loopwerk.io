---
tags: javascript, sveltekit
summary: Quite recently I upgraded a Svelte 4 project to Svelte 5, and soon afterwards I found some problems inside of Safari 12 that needed a tricky workaround.
---

# Svelte 5 sites don’t work as expected in Safari 12 and 13

Quite recently I upgraded a Svelte 4 project to Svelte 5, and at first everything seemed to work perfectly fine. I tested the site in multiple browsers in multiple versions, found no bugs, and deployed to production. Pretty soon after that I started to get complaints that the site’s dropdown menus no longer worked in Safari 12 or Safari 13, so I got an account at [BrowserStack.com](https://www.browserstack.com) - a pretty great way to test your site in almost any browser and OS you can think of - and was able to reproduce the issue. Sure enough: when you hovered your mouse over the main menu items, the submenu items no longer became visible.

To figure out what was actually causing the problem I decided to copy my `Menu.svelte` component to the [Svelte Playground](https://svelte.dev/playground/hello-world), so that I could easily play around with the CSS and the JavaScript in Safari 12 (using BrowserStack), to see what was causing it, and how to fix it. Sadly Svelte’s Playground only works in Safari 17.6 and up [due to missing polyfills](https://github.com/sveltejs/svelte.dev/issues/911), but even with the polyfills in place only Safari 14 and up would be supported. So then I tried [JSFiddle](https://jsfiddle.net): I copied my component’s HTML and CSS into a new fiddle (leaving out all the Svelte specific logic), opened it up in Safari 12... and JSFiddle also didn’t work. Sigh. Then I found [CodePen.io](https://codepen.io) and luckily this did work in Safari 12. But so did my menu. Hovering the mouse over the main menu items revealed the submenu items just fine, no bugs at all. Weird!

Turns out that when you copy the CSS code from your Svelte component, that this isn’t actually the CSS code as your Svelte site gets it. It gets transformed by Svelte, notably it adds those unique identifiers to almost every CSS selector: your `li.main-menu` selector gets turned into `li.main-menu.svelte-13eihuy` for example. When I inspected the differences between the “pure” CSS code as written in my component and copied into the CodePen (and working fine in Safari 12), and the transformed CSS code as found in my production site, I noticed a very big difference, something that didn’t happen with Svelte 4: Svelte 5 transforms nested CSS selectors by wrapping them in `:where()`, which is not supported in Safari 12.

So this:

``` css
li.main-menu ul {
  display: none;
}

li.main-menu:hover ul {
  display: block;
}
```

gets turned into this by Svelte 5:

``` css
li.main-menu.svelte-13eihuy ul:where(.svelte-13eihuy) {
  display: none;
}

li.main-menu.svelte-13eihuy:hover ul:where(.svelte-13eihuy) {
  display: block;
}
```

Well... shit. One possible solution is to instead write the CSS like this:

``` css
li.main-menu :global(ul) {
  display: none;
}

li.main-menu:hover :global(ul) {
  display: block;
}
```

And while that worked fine for my `Menu` component, I actually found a lot more problems in the site caused by this newly added `:where`, and I didn’t want to go through every component in the site to fix them for Safari 12. I wanted to fix this breaking change for all my components in one go.

To be fair, the Svelte 5 migration docs [do make a note of this breaking change](https://svelte.dev/docs/svelte/v5-migration-guide#Other-breaking-changes-Scoped-CSS-uses-:where()). They even mention a workaround:

“In the event that you need to support ancient browsers that don’t implement `:where`, you can manually alter the emitted CSS, at the cost of unpredictable specificity changes:”

``` javascript
css = css.replace(/:where\((.+?)\)/, '$1');`
```

Great! My site has always worked fine without that `:where` everywhere, so let me just remove it using this oneliner. But where do you put this? It’s absolutely not clear where you should modify the generated CSS.

(Also, “ancient browsers”? What is ancient? What is the cut off where a browser becomes ancient according to Svelte? It would be extremely helpful if they would specifically mention which browsers are supported by them.)

Anyway, after a lot of trial and error and reading through docs of multiple projects, I finally got a working workaround. Inside of `vite.config.js`, inside of `plugins`, after `sveltekit()`, you need to add the following custom plugin:

``` javascript
{
  name: "strip-where-selectors",
  enforce: "post",
  transform(code, id) {
    if (id.endsWith(".css")) {
      return code.replace(/:where\((.+?)\)/g, "$1");
    }
    return code;
  },
  async generateBundle(_, bundle) {
    for (const [key, asset] of Object.entries(bundle)) {
      if (asset.type === "asset" && key.endsWith(".css")) {
        asset.source = asset.source.toString().replace(/:where\((.+?)\)/g, "$1");
      }
    }
  },
},
```

This transforms the CSS both in the dev server and in created builds, and gets rid of the `:where` selector. And now the site works perfectly fine again in “ancient” Safari 12 and 13. Which yes, we still support!