---
tags: javascript, sveltekit
summary: Solving problems by putting writable reactive stores in Svelte’s context.
---

# Putting Svelte stores inside context for fun and profit

In [Critical Notes](https://www.critical-notes.com) I use modals with forms inside of them. The basic (simplified) layout is like this, inside a detail page:

```
{#if editModalOpen}
  <Modal title="Edit Character" close={() => editModalOpen = false}>
    <CharacterForm {character} />
  </Modal>
{/if}
```

A modal looks like this:

![Modal 1](/articles/images/cn-modal-1.jpg)

Modals can be nested infinitely. Inside of this character form are multiple buttons that will open open another modal with another form, for example to create a new lore item:

![Modal 2](/articles/images/cn-modal-2.jpg)

Every modal has code that detects when the escape key is pressed, and then it will close the top-most modal. The core of the code looks like this:

#### <i class="fa-regular fa-file-code"></i> Modal.svelte
``` typescript
<script lang="ts">
  export let title: string;
  export let close = () => {};

  let modal: HTMLElement;

  function isTopModal() {
    const nodes = modal.querySelectorAll(".modal");
    return nodes.length === 0;
  }

  function handleKeydown(e: KeyboardEvent) {
    if (e.key === "Escape" && isTopModal()) {
      e.preventDefault();
      close();
    }
  }
</script>

<svelte:window on:keydown={handleKeydown} />

<div role="dialog" aria-modal="true" bind:this={modal}>
  <h1>{title}</h1>
  <slot />
</div>
```

Every modal listens for key presses, and if the escape key is pressed and the modal has no child modals, then the modal closes itself. When multiple modals are opened, you can press the escape key multiple times to close them all. This works perfectly fine, but there is one problem: it’s way too easy to accidentally close a modal with a bunch of unsaved changes, just by pressing the wrong key. I wanted to make it impossible to close the modal with the escape key when there are unsaved changed in the form.

At its core, the `Modal` component needs to know if its form has changes, and then just ignore the escape key:

``` typescript
let hasChanges = false;

function handleKeydown(e: KeyboardEvent) {
  if (e.key === "Escape" && isTopModal() /*HLS*/&& !hasChanges/*HLE*/) {
    e.preventDefault();
    close();
  }
}
```

But how can the modal know that its form has changes? It doesn’t even know which form is shown, it just has a `<slot />` tag and that’s it. My first instinct was to use an event dispatcher to communicate from the child to the parent:

#### <i class="fa-regular fa-file-code"></i> Form.svelte
``` typescript
<script>
    import { createEventDispatcher } from 'svelte';

    const dispatch = createEventDispatcher();
    
    function handleFormChanges() {
        dispatch('change', { hasChanges: true });
    }
</script>
```

#### <i class="fa-regular fa-file-code"></i> Modal.svelte
``` typescript
<script>
    let hasChanges = false;

    function handleFormChange(event) {
        hasChanges = event.detail.hasChanges;
    }
</script>

<div class="modal">
    <slot on:change={handleFormChange}></slot>
</div>
```

Sadly though this doesn’t work: Svelte will give the error `slot cannot have directives`.

One possible solution was to move the event listener to the character page, where the modal is created, and to pass `hasChanges` from the character page to the modal. But there are many many pages with modals throughout the site, and I really didn’t want to have to update all of them. I wanted a self-contained solution that didn’t involve changing every page, every modal or every form.

My first thought was to just use a global store to store the `hasChanges` value. Write to it from the forms, listen to it from the modals, done. But the nested modals make that problematic: changes made to a child modal would now also affect the parent modal, since they use the same store. And then I remembered that you can [set context variables](https://v4.svelte.dev/docs/svelte#setcontext), which are stored per component. And you can store a writable store inside the context just fine.

#### <i class="fa-regular fa-file-code"></i> Modal.svelte
``` typescript
<script lang="ts">
  import { setContext } from "svelte";
  import { writable } from "svelte/store";
  import type { Writable } from "svelte/store";
  
  export const hasChanges: Writable<boolean> = writable(false);
  setContext("hasChanges", hasChanges);
</script>
```

#### <i class="fa-regular fa-file-code"></i> Form.svelte
``` typescript
<script lang="ts">
  import { getContext } from "svelte";
  import type { Writable } from "svelte/store";

  const hasChangesStore: Writable<boolean> | undefined = getContext("hasChanges");
  
  // My form logic ends up calling this function when something changes
  function formChanged(hasChanges) {
    if (hasChangesStore) {
      hasChangesStore(hasChanges);
    }
  }
</script>
```

And just like that every modal has its own store, and every modal will only listen to the escape key when its form has no changes.