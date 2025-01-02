---
tags: sveltekit
summary: I'm very busy migrating a big SvelteKit project to Svelte 5's new runes syntax and I have to be honest... not a big fan of the increased number of lines, especially when it comes to the props.
---

# First thoughts on Svelte 5’s runes

I'm very busy migrating a big SvelteKit project to Svelte 5's new runes syntax and I have to be honest... not a big fan of the increased number of lines, especially when it comes to the props.

For example, what used to be a single line:

```
export let user: User | undefined = undefined;
```

Now takes 5 lines because of the added effort to properly type everything:

```
interface Props {
   user?: User;
 }

let { user }: Props = $props();
```

And yeah of course in this simple case I could do the type inline:

```
let { user }: { user?: User } = $props();
```

But that doesn't scale when you have multiple props. And either way it’s still way more code than what it used to be, with the property name repeated.

It's also very annoying that the Svelte 5 migration script decides to use `let` for these props instead of `const`, which results in hundreds of ESLint warnings like "'user' is never reassigned. Use 'const' instead". Luckily ESLint can automatically fix most of them, but not all. For example I have a NumberPicker component that used to have three props:

```
export let min = 0;
export let value = 0;
export let max = 99;
```

The page using the component would bind to the `value`. With Svelte 5 the component now looks like this:

```
interface Props {
  min?: number;
  value?: number;
  max?: number;
}

let { min = 0, value = $bindable(0), max = 99 }: Props = $props();
```

Which results in two ESLint warnings because `min` and `max` should be const. But I can't change the `let` to a `const` because then `value` can't be reassigned anymore.

So far I am really not enjoying this migration. I’ll write another article with a more in-depth review, but I just wanted to share my first impressions.