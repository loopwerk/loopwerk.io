---
tags: workflow, howto, browsers
summary: iCloud's Hide My Email only works in Safari, DuckDuckGo's extension doesn't work in Safari and forces their search engine... are there no better solutions?
---

# The search for a cross-browser private email address service

Yesterday I [reviewed a bunch of web browsers](/articles/2026/still-no-perfect-browser/), and I mentioned that the ability to create private email addresses is important to me. It's a great way to combat spam; no matter how much you trust a website not to spam you, eventually they'll be hacked, your email address will be public, and you'll receive spam and phishing emails. Better to create a private email address that forwards to your real email address, a unique one for every website. Then you can simply deactivate that forwarding address when it gets leaked, or you no longer need it.

Within Safari I always use iCloud's Hide My Email feature (which does require iCloud+). It will suggest to create a private email address for any email field:

![](/articles/images/private-email/hide-my-email.webp)

It's super convenient, but it only works in Safari. If you use another browser and want to generate one of these addresses, you have to click through several screens in system settings. There's no way to create a shortcut that generates an address, which is strange. Not sure why Apple makes it so hard to use this feature outside of Safari?

In other browsers there's the DuckDuckGo extension, which enables their private email address feature (they don't have an extension for Safari for some reason). And honestly, this one is even better than Apple's version. It blocks all trackers, and it makes it super easy to deactivate and reactivate an address:

![](/articles/images/private-email/duckduckgo.webp)

I really do love this service. But here's the catch: the DuckDuckGo extension also forces your search engine to DuckDuckGo. Fair enough of course, but I prefer (and pay for) [Kagi](https://kagi.com) myself. You can't even visit DuckDuckGo's [email dashboard](https://duckduckgo.com/email/) to generate a new private email if you don't have the extension installed.

Firefox has their own Relay feature, but this only works in Firefox, and is only free for up to 50 addresses (also fair enough). It's not a solution for me since I use Helium as my second browser.

So the easy choice is to use the DuckDuckGo extension in Helium, iCloud's Hide My Email in Safari, and live with the fact that I'm using two different private email services, plus the fact I'm now forced to use DuckDuckGo as my search engine in Helium. But that didn't sit right with me.

A second easy choice is to use something like [Addy](https://addy.io), which has an extension for every browser. This would give one consistent service to use no matter which browser, without forcing you to a specific search engine. I really like DuckDuckGo's service though...

I went with a slightly more complex route: I created my own shortcut which uses DuckDuckGo's (undocumented) API to create a new address and puts it in my clipboard. This shortcut is available in the services menu in every macOS app, and also in the macOS menu bar. It's pretty great! I can now create a unique `@duck.com` email address in any browser or other app with just a single click.

Here's how I got it to work.

## 1. Get your DuckDuckGo auth token
First, install DuckDuckGo's extension in your non-Safari browser of choice.

Then go to DuckDuckGo's [email dashboard](https://duckduckgo.com/email/), open the network inspector, and generate a new email address. There should be one request to `https://quack.duckduckgo.com/api/email/addresses` in the inspector - get its Authorization header.

Now you can remove the extension again.

## 2. Create the shortcut
Create a new shortcut with the following steps:

1. Get Contents of URL
	- URL: `https://quack.duckduckgo.com/api/email/addresses`
	- Method: `POST`
	- Headers: `Authorization = Bearer {YOUR_AUTH_TOKEN}`
2. Get Dictionary Value: key `address` from `Contents of URL`
3. Text: `[Dictionary Value]@duck.com` (tip: right click in the text field to insert a variable)
4. Copy to Clipboard: `Text`

![](/articles/images/private-email/shortcut.webp)

Give your shortcut a name and icon. Then open the details sidebar on the right, and check the `Services Menu` box. Your shortcut is now available in any macOS app:

![](/articles/images/private-email/service.webp)

> [!IMPORTANT]
> Do not share your shortcut with anyone else, as it includes your personal authorization token!

## 3. Add it to the menu bar
We can make it even better, by adding the shortcut directly to the menu bar, with its own icon. It was the most confusing step, so it might take a bit of trial and error to make it work. This should work in macOS Golden Gate at the time of writing:

1. Open `System Settings` -> `Menu Bar`
2. Click on `Add Controls...`
3. Find the `Run Shortcut` control, and drag that into your menu bar
4. You'll be asked to choose which shortcut to run; pick your newly created shortcut

It'll take on the icon you've assigned to the shortcut itself, which in my case is an envelope (the one on the left):

![](/articles/images/private-email/menubar.webp)

The vertical centering looks a bit off (yet another example of Apple's eye for detail being a bit lazy), but it works absolutely wonderfully nonetheless. Enjoy!