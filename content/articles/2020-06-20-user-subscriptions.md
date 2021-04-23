---
tags: review
summary: As I am reaching feature-completeness of my side project Critical Notes, I need to add paid subscriptions to it. Users can already subscribe in the iOS app, but of course not everyone uses iOS, so I need to build something for the web client too.
---

# User subscriptions on the web
As I am reaching feature-completeness of my side project Critical Notes, I need to add paid subscriptions to it. Users can [already subscribe in the iOS app](/articles/2020/storekit-webhooks-firestore/), but of course not everyone uses iOS, so I need to build something for the web client too.

What I need and want from a payment platform is rather simple: 

- I want a pre-built hosted checkout page: I don't want to have the payment form on my actual website.
- A hosted page where users can manage their subscription (cancel or update their payment method). Again, I don't want to have to build the pages and forms to do all that.
- It needs to handle sending invoices to the user.
- It needs to keep my server up-to-date via webhook messages.
- And finally, it needs to handle VAT rates around the world. It is required by law that I collect VAT from users in the EU.

Basically, I just want my server to receive an `isSubscribed` boolean for a user, and everything else is handled off-site.

These are the payment platforms/providers I've looked into.

## Stripe
My initial impression wasn't very positive, as their docs are an absolute maze. They have about a million pages on their documentation portal, and they all assume a fair bit of knowledge of Stripe and payment providers in general. It's all rather low-level. But, I dug in, got some help from their support staff (via email and Twitter), and built a working implementation.

### Positives
* Reasonable prices. They charge 1.4% to 2.9%, plus a flat fee of €0.25 per transaction.
* A hosted checkout page. You redirect to their checkout page and when the payment is completed, it redirects back to a success page on your own website.
* A hosted "customer portal" where the user can manage their subscription.
* Emails are sent with the invoice, reminders about upcoming invoices, reminders about their payment method expiring, and more.
* A solid API and webhooks (once you get it implemented, no thanks to the docs).
* A really good test mode, where you flip a switch on your Stripe Dashboard, and all payments and API calls are going to a test environment. Great to test the whole checkout flow on your own website.
* Very friendly and patient support staff.

### Negatives
* You are required to give them your phone number, which is then displayed in all emails sent to your users. I don't want my personal cellphone number to be public like that! But apparently it's a legal requirement, or so that say at least.
* They don't handle VAT at all. If you charge $4 a month for a subscription, the user will be charged $4 a month and that's it. 

Of course I'm required to actually collect (and then pay to the tax office!) the value added taxes, so that last point is actually a major problem and a dealbreaker. Stripe is working on adding VAT support but the first version of it, coming in July 2020, will require you to input all countries / U.S. states and their tax levels by hand. That's just not going to work. Plus they won't do automatic user location detection, so the user has to pick their country to see the correct VAT percentage. 

The second version of their VAT system, possibly coming in September, will instead handle VAT automatically without you needing to input this all by hand, or the user having to choose anything. I really don't know who would use the first version.

Since I don't want to wait until September (at the earliest), Stripe is not really an option, which is too bad as I have it all working.

## Gumroad
Gumroad is mostly targeted towards "digital creators" selling ebooks, webinars, video courses and merchandise. However they also support selling memberships and are much more "developer friendly" than Stripe. It's not as low-level, there are way fewer things you need to do. They only support hosted checkout pages for example, which can be shown as a modal overlay on your webpage, or embedded into your page.

### Positives
* You basically add a `<button>` to your website, and it opens the checkout page in a good looking overlay. Super easy.
* They have a page where users can manage all their subscriptions, including yours. It's clearly linked in all emails too.
* They handle VAT automatically. So if you set a $4 a month price and the user is in France, they will be charged $4 + 20% VAT. Super easy for the user and for me.
* My own personal phone number is not in the emails (since technically Gumroad is the seller on record, not me).

### Negatives
* More expensive than lower-level Stripe: 5%, plus a charge fee of 3.5% + 30¢.
* They don't have an easy way to test the checkout flow. You can only initiate a test payment from their dashboard, but there is no "test mode" switch you can flip and test the flow from within your website. The only way to do it is to create a voucher code for 100% discount, but you end up polluting the live data with test customers. They really need a better test mode.
* The docs are way too simplistic.
* The payload you receive in the webhook is rather basic, and even using the API you don't get an end date for a subscription for example.
* No redirect url support after a payment is complete.

The lack of support for redirecting to a thank you page is actually a pretty big problem. Imagine this scenario: you have a "Subscribe now" button somewhere on your website, and when the user clicks on it, the Gumroad checkout page is shown as an overlay. The user completes their payment, and they are still left on the same page on your website with that overlay still open. So the user closes the overlay... and sees the same "Subscribe now" button. This happens because the webhook wasn't called yet (that takes about 10 seconds), so our server doesn't know yet that the user is now a subscriber. This is extremely confusing to the user - it takes a good 10 seconds or so for the UI to update, finally replacing the "Subscribe now" button with a "Thank you for subscribing" text.
	
> Gumroad actually offers `redirect_url` support for selling digital goods, but not for memberships. They told me it's on their roadmap but they don't have an ETA yet.

## Patreon
It didn't occur to me for a long time, but Patreon can actually be used for handling user subscriptions pretty easily via a "Authenticate with Patreon" button on your website. That will allow you to link your own user model to the Patreon user, call the Patreon API and get server-to-server updates via a webhook.

### Positives
* All the subscription stuff is simply handled on Patreon.
* They automatically handle all VAT stuff as expected, same as Gumroad.

### Negatives
* More expensive than Stripe: 5% plus payment processing fees.
* The API is dead. Their developer docs have a big red banner on top saying "As of June 22nd, 2020, we are no longer actively supporting the API due to resource constraints", even though as recently as November 2019 [they pledged something very different](https://www.patreoncommunity.com/t/the-api-has-been-abandoned/5894/4) on their community forum.

Patreon seemed like a really good option, but I am not going to jump on board of an abandoned train. I really don't understand why they would let their API die. If it was a solid API that just keeps on working I might consider using them anyway (even if it's not supported), but just read the forums for all the problems that people are having with the API being down or broken and having to beg for weeks for help. Nope nope nope.

## Memberstack
Someone from Memberstack told me to check out their offerings. They offer "user accounts, members-only content and Stripe payments for any website" with hosted checkout pages and all that. But, it really is an all-or-nothing package deal where you have to use their user system. That's not an option for me.

## Conclusion
So, what am I going to do now? That's hard to say. I think Gumroad right now has the most potential: it doesn't add my phone number to the emails, and (much more importantly) they automatically handle VAT. Sure, it's more expensive than Stripe, but still much less than what Apple charges for In App Purchases - the famous 30%. It's the UX that really suffers though, those 10 seconds or so where the user is looking at my webpage and not seeing that subscription being active. 

Stripe meanwhile has the lowest rates and because you're actually the seller on record, your own business name will be shown on credit card statements (rather than Gumroad or Patreon). Not important, but pretty cool. Too bad that comes with the requirement of adding your phone number to all emails. Getting a Google Voice number could work, but that's not free and I don't really want to take on costs until I have some subscribers. But that's besides the point really, the real issue is the total lack of VAT support on their hosted checkout page. They really do focus on the low level stuff where YOU build a checkout page and handle VAT. It's what Gumroad, Patreon and Memberstack are all built on.

If you have suggestions for Saas as in "subscriptions as a service", please [let me know](mailto:kevin@loopwerk.io)!
