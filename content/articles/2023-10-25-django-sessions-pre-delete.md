---
tags: python, django
summary: How do you delete baskets belonging to anonymous users when their sessions expires? It wasn't quite as simple as I thought.
---

# Deleting anonymous users' baskets when their sessions expire

I'm in the process of migrating [a webshop](https://www.soundradix.com) from Django-Oscar to a custom shop, built from scratch. We want anonymous (not logged in) users to be able to add products to their basket, but we also want baskets to be cleaned up when that anonymous user's session expires. Plus, when an anonymous user logs in, their anonymous basket should then be assigned to that user, possibly by merging it with an existing open basket for the user.

The biggest problem I had was the cleaning up of baskets when sessions expire. With Oscar we have literally over 31 million open baskets for anonymous users in our database, 99.9% of which are of course unable to ever be checked out because those sessions are long expired - and deleted, by running the `clearsessions` management command. This is something that I really wanted to do better with our new shop.

My first instinct was to model the basket like this:

``` python
class Basket(Model):
    owner = ForeignKey(User, blank=True, null=True, on_delete=CASCADE)
    session = ForeignKey(Session, blank=True, null=True, on_delete=CASCADE)
```

The basket would either belong to a user, or be assigned a session. When the session is removed from the database, the basket would automatically be deleted with it. And when the user logs in I'd simply assign the basket to the user and remove the session value. That was the idea at least.

Sadly it wasn't quite this easy. The problem is that when a user logs in, that this user gets a new session (which is documented [right here](https://docs.djangoproject.com/en/4.2/topics/http/sessions/#django.contrib.sessions.backends.base.SessionBase.cycle_key)). And the old session is deleted, so the basket is also deleted, before you ever get a chance to assign the basket to the newly logged-in user, for example in a `user_logged_in` signal handler.

I could override the built-in `cycle_key` method to simply not do its thing. When a user logs in they keep their old session and in the `user_logged_in` signal handler I can update the basket. It's a simple solution, but one that leaves our users vulnerable to [session fixation attacks](https://en.wikipedia.org/wiki/Session_fixation), so really it's not a solution at all. What other options do we have?

In the end I removed the `session` field from my `Basket` model, and I am storing the basket ID inside of the session. Then I have a `pre_delete` signal handler reacting when sessions are deleted, and in this handler I then clean up the basket.

Let's look at the code. The code to get the basket for the current request is rather simple:

``` python
def get_basket(request):
    if request.user and request.user.is_authenticated:
        return Basket.objects.get_or_create(owner=request.user, status=Basket.Status.OPEN)[0]
    else:
        basket_id = request.session.get("basket_id", None)
        if basket_id:
            try:
                return Basket.objects.get(id=basket_id, owner__isnull=True, status=Basket.Status.OPEN)
            except Basket.DoesNotExist:
                pass

        basket = Basket.objects.create(owner=None, status=Basket.Status.OPEN)
        request.session["basket_id"] = basket.id
        return basket
```

If the user is logged in we get (or create) a basket for the user. Otherwise we see if there's a `basket_id` value in the session and get that basket - or create a new basket for the anonymous user and store its ID in the session.

Of course I want baskets to be removed when sessions expires, which is what the following signal handler does:

``` python
@receiver(pre_delete, sender=Session)
def session_deleted(instance, **kwargs):
    if instance.expire_date < timezone.now():
        # Session is getting deleted because it expired.
        # Delete the anonymous basket belonging to this session (if any).
        basket_id = instance.get_decoded().get("basket_id", None)
        if basket_id:
            Basket.objects.filter(id=basket_id, owner__isnull=True).delete()
```

And finally, the `user_logged_in` signal handler that assigns the anonymous basket to the now logged-in user:

```python
@receiver(user_logged_in)
def logged_in(request, user, **kwargs):
    basket_id = request.session.get("basket_id", None)
    if basket_id:
        assign_or_merge_basket(basket_id=basket_id, user=user)
        del request.session["basket_id"]

def assign_or_merge_basket(basket_id, user):
    try:
        from_basket = Basket.objects.get(id=basket_id, owner__isnull=True, status=Basket.Status.OPEN)
    except Basket.DoesNotExist:
        # If we can't find the basket, then there's nothing to do, nothing to migrate or merge.
        return

    # Does this user already have an open basket? If so, then merge the contents of this basket
    # with that basket. Otherwise just assign the owner to the basket.
    try:
        into_basket = Basket.objects.get(owner=user, status=Basket.Status.OPEN)
        merge_baskets(from_basket, into_basket)
    except Basket.DoesNotExist:
        Basket.objects.filter(id=basket_id, owner__isnull=True).update(owner=user)
```

And with all these pieces in place we have baskets for anonymous users that are getting cleaned up when sessions expire.

One thing to note is that this only works with the database backend for sessions. If you use the cache backend then there's no `pre_delete` signal for when a session is removed. This is unfortunate and something I wish Django would improve, to make it possible to clean up database records tied to sessions.