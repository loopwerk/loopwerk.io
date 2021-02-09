---
tags: iOS, swift, firebase
summary: I've recently added subscriptions to my Critical Notes iOS app, using Apple's StoreKit. Here is how I hooked it all up to Firestore including server-side receipt validation.
---

# Connecting Storekit to Firestore via Cloud Functions and webhooks
I've recently added subscriptions to my [Critical Notes](https://www.critical-notes.com) iOS app, using Apple's StoreKit. Initially I wanted to use [RevenueCat](https://www.revenuecat.com) but sadly they don't offer webhook support unless you're on the $119 a month paid plan - which is way too much for my app. And without webhooks it's impossible to keep the server informed about the subscription status of your users without resorting to periodically polling for updates.

It wasn't very easy to figure out all the moving parts of dealing with payments, receipts, receipt validation etc etc, especially in combination with Firestore. So here's my code, I hope it helps someone going through the same thing.

First, the Swift code. I have an `AppState` class that holds the state for my SwiftUI - shown here are just the StoreKit related bits.

``` swift
import StoreKit
import Combine

final class AppState: NSObject, ObservableObject {
  @Published var products = [SKProduct]()
  @Published var paymentInProgress = false

  func loadProducts() {
    let subcriptionIds = Set(["pro.monthly", "pro.yearly"])
    let request = SKProductsRequest(productIdentifiers: subcriptionIds)
    request.delegate = self
    request.start()
  }
  
  func buyProduct(_ product: SKProduct) {
    paymentInProgress = true
    let payment = SKPayment(product: product)
    SKPaymentQueue.default().add(payment)
  }
}

extension AppState: SKProductsRequestDelegate {
  func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    DispatchQueue.main.async { [weak self] in
      self?.products = response.products
    }
  }

  func request(_ request: SKRequest, didFailWithError error: Error) {
    print("Error getting products \(error)")
  }
}

extension AppState: SKPaymentTransactionObserver {
  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
      switch transaction.transactionState {
      case .purchased:
        print("purchased")
        queue.finishTransaction(transaction)

        storeReceipt {
          self.paymentInProgress = false
        }

      case .failed:
        print(transaction.error as Any)
        queue.finishTransaction(transaction)
        paymentInProgress = false

      case .purchasing:
        print("purchasing")
        paymentInProgress = true

      default:
        print("something else")
        paymentInProgress = false
      }
    }
  }

  func storeReceipt(done: @escaping () -> Void) {
    if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL, FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
      do {
        let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
        let receiptString = receiptData.base64EncodedString(options: [])

        let functions = CloudFunction()
        functions.validateReceipt(receipt: receiptString) {
          done()
        }
      } catch {
        print("Couldn't read receipt data with error: " + error.localizedDescription)
      }
    }
  }
}
```

Actually building the UI for showing the products is left as an exercise to the reader, but it's simple enough: just use the `products` array, show a button for each product, and on tap call the `buyProduct` function. Done.

I have a separate `CloudFunction` class with the `validateReceipt` function that was used in the `storeReceipt` function above:

``` swift
import Firebase
import FirebaseFunctions
import Foundation

final class CloudFunction {
  private lazy var functions = Functions.functions()

  func validateReceipt(receipt: String, completionHandler: @escaping () -> Void) {
    let parameters = ["receipt": receipt]

    functions.httpsCallable("validateReceipt").call(parameters) { _, error in
      if let error = error {
        print(error)
      }

      completionHandler()
    }
  }
}
```

The `validateReceipt` function above is calling a Cloud Function with the same name. It's responsible for validating the payment receipt, and storing it on the user. It first does this using Apple's production API, and on failure retries using the sandbox one.

``` javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const fetch = require('node-fetch');
const db = admin.firestore();

const runtimeOpts = {
  memory: '1GB',
};

function validateAndStoreReceipt(url, options, userSnapshot) {
  return fetch(url, options).then(result => {
    return result.json();
  }).then(data => {
    if (data.status === 21007) {
      // Retry with sandbox URL
      return validateAndStoreReceipt('https://sandbox.itunes.apple.com/verifyReceipt', options, userSnapshot);
    }

    // Process the result
    if (data.status !== 0) {
      return false;
    }

    const latestReceiptInfo = data.latest_receipt_info[0];
    const expireDate = +latestReceiptInfo.expires_date_ms;
    const isSubscribed = expireDate > Date.now();

    const status = {
      isSubscribed: isSubscribed, 
      expireDate: expireDate, 
    };

    const appleSubscription = {
      receipt: data.latest_receipt,
      productId: latestReceiptInfo.product_id,
      originalTransactionId: latestReceiptInfo.original_transaction_id
    };

    // Update the user document!
    return userSnapshot.ref.update({status: status, appleSubscription: appleSubscription});
  });
}

exports.validateReceipt = functions.runWith(runtimeOpts).https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('permission-denied', 'The function must be called while authenticated.');
  }

  if (!data.receipt) {
    throw new functions.https.HttpsError('permission-denied', 'receipt is required');
  }

  // First we fetch the user
  const userSnapshot = await db.collection('users').doc(context.auth.uid).get();
  if (!userSnapshot.exists) {
    throw new functions.https.HttpsError('not-found', 'No user document found.');
  }
  
  // Now we fetch the receipt from Apple
  let body = {
    'receipt-data': data.receipt,
    'password': 'MY_SECRET_PASSWORD',
    'exclude-old-transactions': true
  };
  
  const options = {
    method: 'post',
    body: JSON.stringify(body),
    headers: {'Content-Type': 'application/json'},
  };
  
  return validateAndStoreReceipt('https://buy.itunes.apple.com/verifyReceipt', options, userSnapshot);
});
```

Okay, that's a whole lot of code so far! But all it handles is the initial payment - any recurring payment or the subscription getting cancelled is not handled at all yet. For that we have yet another Cloud Function, one that is callable via HTTP and is the webhook that Apple posts to.

``` javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const db = admin.firestore();

const runtimeOpts = {
  memory: '1GB',
};

exports.appleWebhook = functions.runWith(runtimeOpts).https.onRequest(async (req, res) => {
  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(403).send('Forbidden');
  }

  // Check for correct password
  if (req.body.password !== 'MY_SECRET_PASSWORD') {
    return res.status(403).send('Forbidden');
  }

  const receipt = req.body.unified_receipt.latest_receipt_info[0];

  // Find the user with this stored transaction id
  const userQuerySnapshot = await db.collection('users')
    .where('appleSubscription.originalTransactionId', '==', receipt.original_transaction_id)
    .limit(1)
    .get();
    
  if (userQuerySnapshot.empty) {
    throw new functions.https.HttpsError('not-found', 'No user found');
  }

  const expireDate = +receipt.expires_date_ms;
  const isSubscribed = expireDate > Date.now();

  const status = {
    isSubscribed: isSubscribed, 
    expireDate: expireDate, 
  };

  const appleSubscription = {
    receipt: req.body.unified_receipt.latest_receipt,
    productId: receipt.product_id,
    originalTransactionId: receipt.original_transaction_id,
  };

  // Update the user
  return userQuerySnapshot.docs[0].ref.update({ status: status, appleSubscription: appleSubscription }).then(function() {
    return res.sendStatus(200);
  });
});
```

And with that function in place, Apple can now inform us whenever anything in the subscription changes. Please let me know if this was helpful at all!
