---
tags: firebase, javascript
---

# Connecting Stripe to Firestore via Cloud Functions and webhooks
After adding [subscriptions in iOS via Apple's Storekit](/articles/2020/storekit-webhooks-firestore/), I have now also added subscriptions to the web client of Critical Notes, using Stripe (even though they have [some serious drawbacks](/articles/2020/user-subscriptions/) at the moment).

Since it was a bit of a puzzle to get it working, I am sharing my backend and frontend code.

## Opening the Checkout page
It all starts with a button that the user can click to subscribe.

```
<button on:click={() => subscibe('price_A')}>$3.99/month</button>
```

That calls the `subscibe` function below:

``` javascript
function subscibe(priceId) {
  createStripeSession(priceId).then(result => {
    const sessionId = result.data;

    const stripe = Stripe("pk_live_XXX");
    stripe.redirectToCheckout({
      sessionId: sessionId,
    }).then(function (result) {
      console.log(result.error.message);
    });
  });
}

import "firebase/functions";

function createStripeSession(priceId) {
  return functions.httpsCallable("createStripeSession")({priceId: priceId})
    .catch(error => {
      showError(error.message);
    });
}
```

As you can see, `subscibe` calls `createStripeSession`, which in turn executes a callable Cloud Function called `createStripeSession` to fetch a Stripe session id. Once it has that session id, it can redirect to Stripe's hosted Checkout page.

The Cloud Function is a bit more complex.

``` javascript
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const db = admin.firestore();
const stripe = require("stripe")("sk_live_XXXXXX");

const runtimeOpts = {
  memory: "1GB",
};

exports.createStripeSession = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "The function must be called while authenticated.");
  }

  if (!data.priceId) {
    throw new functions.https.HttpsError("permission-denied", "priceId is required");
  }

  const userId = context.auth.uid;

  const userSnapshot = await db.collection("users").doc(userId).get();
  if (!userSnapshot.exists) {
    throw new functions.https.HttpsError("not-found", "No user document found.");
  }

  const user = userSnapshot.data();

  let customerId;

  if (user.webSubscription && user.webSubscription.customer) {
    customerId = user.webSubscription.customer;
  } else {
    const customer = await stripe.customers.create({
      description: userId,
      name: user.name,
      email: context.auth.token.email,
    });

    customerId = customer.id;
    await userSnapshot.ref.update({ webSubscription: { customer: customerId } });
  }

  const session = await stripe.checkout.sessions.create({
    payment_method_types: ["card"],
    line_items: [
      {
        price: data.priceId,
        quantity: 1,
      },
    ],
    mode: "subscription",
    success_url: "https://www.critical-notes.com/subscriptions/success",
    cancel_url: "https://www.critical-notes.com/subscriptions/cancelled",
    customer: customerId,
  });

  return session.id;
});
```

Let's go over it. First of all, we try to fetch the user document from Firestore, for the user that is calling this Cloud Function. We check if the user already has a stored Stripe subscription, if so, that means we can use the existing Stripe customer object. Otherwise we create a Stripe customer and store its id on our user object.

Finally we create a session object using that customer id and return the session id.

With all that code done, the user is able to view the Checkout page and pay to subscribe.

## Webhook
The other part of the puzzle is the webhook that enables Stripe to send server-to-server updates whenever a subscription is created, renewed, cancelled, etc. That's another Cloud Function.

``` javascript
exports.stripeWebhook = functions.runWith(runtimeOpts).https.onRequest(async (request, response) => {
  const endpointSecret = "whsec_XXXXX";
  const sig = request.get("stripe-signature");

  let event;

  try {
    event = stripe.webhooks.constructEvent(request.rawBody, sig, endpointSecret);
  } catch (err) {
    return response.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === "checkout.session.completed") {
    const subscription = await stripe.subscriptions.retrieve(event.data.object.subscription);
    await updateSubscription(subscription);
  }

  if (event.type === "customer.subscription.created") {
    updateSubscription(event.data.object);
  }

  if (event.type === "customer.subscription.updated") {
    updateSubscription(event.data.object);
  }

  if (event.type === "customer.subscription.deleted") {
    updateSubscription(event.data.object);
  }

  response.json({ received: true });
});

async function updateSubscription(subscription) {
  // Find the user with this stored customerId
  const userQuerySnapshot = await db.collection("users").where("webSubscription.customer", "==", subscription.customer).limit(1).get();

  if (userQuerySnapshot.empty) {
    throw new functions.https.HttpsError("not-found", "No user found");
  }

  const expireDate = subscription.ended_at ? 0 : subscription.current_period_end * 1000; // in ms
  const isSubscribed = expireDate > Date.now();

  const status = {
    isSubscribed: isSubscribed,
    expireDate: expireDate,
  };

  const webSubscription = subscription;

  return userQuerySnapshot.docs[0].ref.update({ status: status, webSubscription: webSubscription });
}
```

We get different kinds of events from Stripe, and we handle them in slightly different ways, but in the end we always store Stripe's subscription object on the user, together with a simple `isSubscribed` boolean in a `status` object.

## Enable the user to manage their subscription
Finally, we want the user to be able to manage their subscription: cancel it, renew it, update their payment method, and so on. Luckily Stripe offers a handy Customer Portal for this, so we don't have to build this ourselves.

It works in a similar way as opening the Checkout page. We again start with a button:

```
<button on:click={openPortal}>Manage subscription</button>
```

That calls this JavaScript function:

``` javascript
function getStripePortalUrl() {
  return functions.httpsCallable("getStripePortalUrl")()
    .catch(error => {
      showError(error.message);
    });
}
```

Which uses yet another Cloud Function:

``` javascript
exports.getStripePortalUrl = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "The function must be called while authenticated.");
  }

  const userId = context.auth.uid;

  const userSnapshot = await db.collection("users").doc(userId).get();
  if (!userSnapshot.exists) {
    throw new functions.https.HttpsError("not-found", "No user document found.");
  }

  const user = userSnapshot.data();

  const result = await stripe.billingPortal.sessions.create({
    customer: user.webSubscription.customer,
    return_url: "https://www.critical-notes.com",
  });

  return result.url;
});
```

And there you have it! A complete implementation of Stripe for handling user subscriptions.
