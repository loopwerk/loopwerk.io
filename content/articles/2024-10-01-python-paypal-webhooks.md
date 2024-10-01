---
tags: django, python
summary: Paypal’s documentation only shows a JavaScript example. How do you validate the webhooks in Python though?
---

# Validate PayPal webhooks using Python

One of my clients uses PayPal to accept payments for their webshop, and we wanted to implement PayPal’s webhooks to automatically deal with reversed payments, among other things.

Paypal’s documentation is pretty good: there’s the [Overview](https://developer.paypal.com/api/rest/webhooks/) of how to subscribe to webhooks, and the [Integration guide](https://developer.paypal.com/api/rest/webhooks/rest/) explains how to validate that the request really comes from PayPal. Sadly the only example they’ve given uses JavaScript, and of course we’re interested in a Python version.

Below you can find a basic webhook view which handles the validation using the self-verification method rather than the postback method (which needs to make an extra request on every received webhook event, no thanks). This example is written for Django, but the validation logic is of course completely independent from Django and can be used anywhere.

``` python
import base64
import zlib

import requests
from cryptography import x509
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding
from django.conf import settings
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import KeyValueCache


class PayPalWebhookView(APIView):
    def get_certificate(self, url):
        try:
            cache = KeyValueCache.objects.get(key=url)
            return cache.value
        except KeyValueCache.DoesNotExist:
            r = requests.get(url)
            KeyValueCache.objects.create(key=url, value=r.text)
            return r.text

    def post(self, request, *args, **kwargs):
        body = request.body

        # Create the validation message
        transmission_id = request.headers.get("paypal-transmission-id")
        timestamp = request.headers.get("paypal-transmission-time")
        crc = zlib.crc32(body)
        webhook_id = settings.PAYPAL_WEBHOOK_ID
        message = f"{transmission_id}|{timestamp}|{webhook_id}|{crc}"

        # Decode the base64-encoded signature from the header
        signature = base64.b64decode(request.headers.get("paypal-transmission-sig"))

        # Load the certificate and extract the public key
        certificate = self.get_certificate(request.headers.get("paypal-cert-url"))
        cert = x509.load_pem_x509_certificate(certificate.encode("utf-8"), default_backend())
        public_key = cert.public_key()

        # Validate the message using the signature
        try:
            public_key.verify(signature, message.encode("utf-8"), padding.PKCS1v15(), hashes.SHA256())
        except Exception:
            # Validation failed, exit
            return Response(status=status.HTTP_400_BAD_REQUEST)

        # Validation succeeded! 
        # Now you can inspect the webhook payload (request.data)
        # and handle each event (request.data.get("event_type"))

        return Response(status=status.HTTP_200_OK)
```

The webhook ID (`settings.PAYPAL_WEBHOOK_ID`) you get when you edit your PayPal app and add the webhook URL. It’s not part of the webhook payload. I store mine in an `.env` file which I read in my `settings.py` file.

I also use an extremely simple cache model to store the certificate:

``` python
class KeyValueCache(models.Model):
    key = models.CharField(max_length=255, unique=True)
    value = models.TextField()
```

It just makes sure that we don’t download the certificate file with every webhook event. You could use Redis or write it to disk or whatever else you want, but I chose a simple Django model.