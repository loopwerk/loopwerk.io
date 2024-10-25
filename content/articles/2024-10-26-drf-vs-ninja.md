---
tags: review, backend, django, python
summary: Let’s compare Django REST Framework with new kid on the block, Ninja.
---

# Django REST Framework versus Django Ninja

I’m a big fan of Django REST Framework (DRF), which I’ve been using since 2017 or so. I’ve also dabbled with Vapor (a web framework for Swift) and have written two articles comparing it to DRF: [Vapor 3 versus Django REST Framework](/articles/2019/vapor-vs-drf/) in 2019 and [Vapor 4 versus Django REST Framework](/articles/2021/vapor4-vs-drf/) in 2021. Since that 2021 article I’ve exclusively used DRF for all my API projects.

Recently I became aware of [Django Ninja](https://django-ninja.dev), another API framework for Django, and decided to try it out. For this I am going to compare it with DRF using the following models, inspired by my real Dungeons & Dragons note-taking tool [critical-notes.com](https://www.critical-notes.com):

#### <i class="fa-regular fa-file-code"></i> **models.py**
``` python
from django.conf import settings
from django.db import models

class Campaign(models.Model):
    name = models.CharField(max_length=50)
    is_private = models.BooleanField(default=True, db_index=True)
    members = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name="campaigns",
        through="Membership",
    )

class Membership(models.Model):
    campaign = models.ForeignKey(Campaign, on_delete=models.CASCADE)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    is_dm = models.BooleanField(default=False)

class Character(models.Model):
    campaign = models.ForeignKey(Campaign, on_delete=models.CASCADE)
    name = models.CharField(max_length=255, blank=True)
    description = models.TextField(blank=True)
    is_hidden = models.BooleanField(default=False)

    def __str__(self):
        return self.name
```

As you can see, a D&D campaign has multiple members, and each member has a role: player or dungeon master (this is stored in the `is_dm` boolean field). Campaigns be public or private (`is_private`). Then there’s a `Character` model, because of course we want to store the characters we play in our D&D campaigns.

## Django REST Framework
I’m going to start by building the characters endpoints in DRF. I’m going to assume that people reading this article already have at least a basic knowledge of DRF so I am not going to explain every line of code in detail, but most things should be pretty clear.

There are two important rules for the character API: 

1. You can fetch a list of characters in a campaign as long as you’re a member of that campaign, or if it’s a public campaign - but only members can add characters or make other changes.
2. A character can be marked as hidden (`is_hidden`), in which case only the DM should be able to fetch or modify it. Normal players should never know about the hidden characters.

But let’s start simple and not worry about these rules just yet.

#### <i class="fa-regular fa-file-code"></i> **views.py**
``` python
from rest_framework import viewsets
from .models import Character
from .serializers import CharacterSerializer

class CharacterViewSet(viewsets.ModelViewSet):
    serializer_class = CharacterSerializer

    def get_queryset(self):
        return Character.objects.filter(campaign_id=self.kwargs["campaign_id"])
```

#### <i class="fa-regular fa-file-code"></i> **serializers.py**
``` python
from .models import Character

class CharacterSerializer(serializers.ModelSerializer):
    class Meta:
        model = Character
        fields = "__all__"
```

#### <i class="fa-regular fa-file-code"></i> **urls.py**
``` python
from django.contrib import admin
from django.urls import include, path
from rest_framework.routers import SimpleRouter
from .views import CharacterViewSet

router = SimpleRouter(use_regex_path=False)
router.register(
    "api/campaigns/<int:campaign_id>/characters",
    CharacterViewSet, 
    basename="character",
)

urlpatterns = [
    path("admin/", admin.site.urls),
    path("", include(router.urls)),
]
```

With that little bit of code in place we can access the URL `/api/campaigns/1/characters/` to fetch all characters that belong to campaign 1. We can POST to `/api/campaigns/1/characters/` to create a new character, we can PUT to `/api/campaigns/1/characters/1/` to edit a character and DELETE to `/api/campaigns/1/characters/1/` to, you guessed it, delete a character. All this functionality which such a super simple `ModelViewSet` subclass: this is absolutely one of the best features of DRF.

However, there are some problems to fix:

1. We need to make sure that you’re allowed to access the characters (i.e. you need to be a logged-in member of the campaign, or it needs to be a public campaign).
2. You should only be allowed to create characters or make other changes when you’re a member of the campaign.
3. Only DMs should be able to see hidden characters.
4. When you create a new character by POSTing to `/api/campaigns/1/characters/`, you shouldn’t be able to give a different `campaign_id` in the POST payload: it needs to be “locked” to the campaign that’s in the URL. In the same way you shouldn’t be able to edit the `campaign_id` when you update a character.

Let’s tackle the first three points all at the same time, by creating a custom permissions class:

#### <i class="fa-regular fa-file-code"></i> **permissions.py**
``` python
from rest_framework.permissions import SAFE_METHODS, BasePermission
from .models import Campaign, Membership

class CampaignMemberOrPublicReadOnlyPermission(BasePermission):
    def has_permission(self, request, view, *args, **kwargs):
        try:
            request.campaign = Campaign.objects.get(pk=view.kwargs.get("campaign_id"))
        except Campaign.DoesNotExist:
            return False

        if request.user.is_anonymous:
            # User is not logged in, so check if it's a public campaign, in which case
            # we can do GET requests only.
            if not request.campaign.is_private:
                return request.method in SAFE_METHODS

            # Private campaign: no access at all
            return False

        try:
            request.membership = Membership.objects.get(
                user=request.user, campaign_id=view.kwargs.get("campaign_id")
            )
            return True
        except Membership.DoesNotExist:
            # Not a member, so check if it's a public campaign, in which case we can do
            # GET requests only.
            request.membership = Membership()
            if not request.campaign.is_private:
                return request.method in SAFE_METHODS
            
            # Private campaign: no access at all
            return False
```

And we change our view to make use of it:

#### <i class="fa-regular fa-file-code"></i> **views.py**
``` python
from rest_framework import viewsets
from .models import Character
from .serializers import CharacterSerializer
/*HLS*/from .permissions import CampaignMemberOrPublicReadOnlyPermission/*HLE*/

class CharacterViewSet(viewsets.ModelViewSet):
    /*HLS*/permission_classes = (CampaignMemberOrPublicReadOnlyPermission,)/*HLE*/
    serializer_class = CharacterSerializer

    def get_queryset(self):
        qs = Character.objects.filter(campaign_id=self.kwargs["campaign_id"])
        if not /*HLS The membership gets added to the request in the CampaignMemberOrPublicReadOnlyPermission class*/self.request.membership.is_dm/*HLE*/:
            /*HLS Filter out hidden characters*/qs = qs.filter(is_hidden=False)/*HLE*/
        
        return qs
```

With this change users can only fetch characters for campaigns they’re a member of, and of public campaigns. Furthermore, only members can make non-GET requests, meaning that only members can create new characters, edit characters, or delete characters. And only DMs can fetch hidden characters.

All that’s left to do is to make sure the `campaign_id` can’t be changed when creating or updating a character. That’s very easy with a small addition to our `CharacterViewSet` as well:

#### <i class="fa-regular fa-file-code"></i> **views.py**
``` python
class CharacterViewSet(viewsets.ModelViewSet):
    # ...

    def perform_create(self, serializer):
        serializer.save(campaign_id=self.kwargs["campaign_id"])

    def perform_update(self, serializer):
        serializer.save(campaign_id=self.kwargs["campaign_id"])
```

That’s our characters API done, in DRF. Now let’s recreate this with Ninja.

## Django Ninja
To create the basic CRUD functionality for characters, a lot more code is needed.

#### <i class="fa-regular fa-file-code"></i> **views.py**
``` python
from typing import List
from django.shortcuts import get_object_or_404
from ninja import NinjaAPI
from .models import Character
from .schemas import CharacterIn, CharacterOut

api = NinjaAPI()

@api.get("/campaigns/{int:campaign_id}/characters/", response=List[CharacterOut])
def character_list(request, campaign_id: int):
    qs = Character.objects.filter(campaign_id=campaign_id)
    return list(qs)

@api.post("/campaigns/{int:campaign_id}/characters/", response=CharacterOut)
def character_create(request, campaign_id: int, data: CharacterIn):
    character = Character.objects.create(**data.dict(), campaign_id=campaign_id)
    return character

@api.get("/campaigns/{int:campaign_id}/characters/{int:id}/", response=CharacterOut)
def character_detail(request, campaign_id: int, id: int):
    return get_object_or_404(Character, campaign_id=campaign_id, id=id)

@api.put("/campaigns/{int:campaign_id}/characters/{int:id}/", response=CharacterOut)
def character_update(request, campaign_id: int, id: int, data: CharacterIn):
    character = get_object_or_404(Character, campaign_id=campaign_id, id=id)

    for attr, value in data.dict(exclude_unset=True).items():
        setattr(character, attr, value)

    character.save()

    return character

@api.patch("/campaigns/{int:campaign_id}/characters/{int:id}/", response=CharacterOut)
def character_patch(request, campaign_id: int, id: int, data: CharacterIn):
    character = get_object_or_404(Character, campaign_id=campaign_id, id=id)

    for attr, value in data.dict().items():
        setattr(character, attr, value)

    character.save()

    return character

@api.delete("/campaigns/{int:campaign_id}/characters/{int:id}/")
def character_delete(request, campaign_id: int, id: int):
    character = get_object_or_404(Character, campaign_id=campaign_id, id=id)
    character.delete()
    return {"success": True}
```

#### <i class="fa-regular fa-file-code"></i> **schemas.py**
``` python
from ninja import ModelSchema
from .models import Character

class CharacterOut(ModelSchema):
    class Meta:
        model = Character
        fields = "__all__"

class CharacterIn(ModelSchema):
    class Meta:
        model = Character
        exclude = ["id", "campaign"]
```

#### <i class="fa-regular fa-file-code"></i> **urls.py**
``` python
from django.contrib import admin
from django.urls import include, path
from .views import api

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", api.urls),
]
```

Our basic `CharacterViewSet` for DRF was literally four lines of code, and it did the same as what Ninja needs thirty lines for (excluding newlines, so in reality it’s even more). The problem is that Ninja doesn’t have something like a `ViewSet` which bundles the CRUD operations; you need to write an endpoint for every operation. I also don’t really like how we need to use `get_object_or_404` all over the place, because Ninja doesn’t handle exceptions itself, unlike DRF.

And we haven’t even started on permissions, making sure people only view characters of campaigns they have access to, making sure only the DM has access to the hidden characters, all the stuff we did before with DRF with very few lines of code. Then I came across a third party package called `django-ninja-crud`, which aims to solve this boilerplate code. Let’s refactor our views.

## Django Ninja CRUD
After reading Django Ninja CRUD’s documentation I changed my views and URL config as such:

#### <i class="fa-regular fa-file-code"></i> **views.py**
``` python
from ninja import Router
from ninja_crud import views, viewsets
from .models import Character
from .schemas import CharacterIn, CharacterOut

router = Router()

class CharacterViewSet(viewsets.APIViewSet):
    router = router
    model = Character
    default_request_body = CharacterIn
    default_response_body = CharacterOut

    list_characters = views.ListView()
    create_character = views.CreateView()
    read_character = views.ReadView()
    update_character = views.UpdateView()
    delete_character = views.DeleteView()
```

#### <i class="fa-regular fa-file-code"></i> **urls.py**
``` python
from django.contrib import admin
from django.urls import path
from ninja import NinjaAPI
from .views import router as character_router

api = NinjaAPI()
api.add_router("/campaigns/{campaign_id}/characters/", character_router)

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", api.urls),
]
```

It’s definitely shorter than the code we had before, but it’s still a far cry from DRF (also, it’s missing a PATCH endpoint since there’s no view for that). And then my half-optimism got replaced by sadness because it’s not possible to access the `campaign_id` path parameter from within the `CharacterViewSet`. So that means that it’s impossible to filter characters, or to do any sort of campaign permission checks.

Instead the code has to be changed like so:

#### <i class="fa-regular fa-file-code"></i> **views.py**
```python
from ninja import Router
from ninja_crud import views, viewsets
from .models import Character
from .permissions import campaignMemberOrPublicReadOnlyPermission
from .schemas import CharacterIn, CharacterOut

router = Router()

class CharactersViewSet(viewsets.APIViewSet):
    router = router
    model = Character
    default_request_body = CharacterIn
    default_response_body = CharacterOut

    def get_queryset(request, path_parameters):
        return Character.objects.filter(campaign_id=path_parameters.campaign_id)

    def init_model(request, path_parameters):
        return Character(campaign_id=path_parameters.campaign_id)

    list_characters = views.ListView(
        path="/campaigns/{campaign_id}/characters/",
        get_queryset=get_queryset,
        decorators=[campaignMemberOrPublicReadOnlyPermission],
    )
    create_character = views.CreateView(
        path="/campaigns/{campaign_id}/characters/",
        init_model=init_model,
        decorators=[campaignMemberOrPublicReadOnlyPermission],
    )
    read_character = views.ReadView(
        path="/campaigns/{campaign_id}/characters/{id}",
        decorators=[campaignMemberOrPublicReadOnlyPermission],
    )
    update_character = views.UpdateView(
        path="/campaigns/{campaign_id}/characters/{id}",
        decorators=[campaignMemberOrPublicReadOnlyPermission],
    )
    delete_character = views.DeleteView(
        path="/campaigns/{campaign_id}/characters/{id}",
        decorators=[campaignMemberOrPublicReadOnlyPermission],
    )
```

#### <i class="fa-regular fa-file-code"></i> **permissions.py**
```python
from functools import wraps
from django.core.exceptions import PermissionDenied
from .models import Campaign, Membership

SAFE_METHODS = ("GET", "HEAD", "OPTIONS")

def campaignMemberOrPublicReadOnlyPermission(func):
    @wraps(func)
    def wrapper(request, *args, **kwargs):
        campaign_id = kwargs.get("path_parameters").campaign_id

        try:
            request.campaign = Campaign.objects.get(pk=campaign_id)
        except Campaign.DoesNotExist:
            raise PermissionDenied()

        if request.user.is_anonymous:
            # User is not logged in, so check if it's a public campaign, in which case
            # we can do GET requests only.
            if not request.campaign.is_private:
                if request.method in SAFE_METHODS:
                    return func(request, *args, **kwargs)

            # Private campaign: no access at all
            raise PermissionDenied()

        try:
            request.membership = Membership.objects.get(
                user=request.user, campaign_id=campaign_id
            )
            return func(request, *args, **kwargs)
        except Membership.DoesNotExist:
            # Not a member, so check if it's a public campaign, in which case we can do
            # GET requests only.
            request.membership = Membership()
            if not request.campaign.is_private:
                if request.method in SAFE_METHODS:
                    return func(request, *args, **kwargs)

        raise PermissionDenied()

    return wrapper
```

#### <i class="fa-regular fa-file-code"></i> **urls.py**
```python
from django.contrib import admin
from django.urls import path
from ninja import NinjaAPI
from .views import router as character_router

api = NinjaAPI()
api.add_router("", character_router)

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", api.urls),
]
```

This is a huge bummer. Not only do we have to repeat the full path in every single CRUD operation for every single model, we also have to override a lot more code to make filtering and permissions work. There is no single method or thing to override which would check permissions, so we have to include the `decorators` parameter into every CRUD operation as well.

And I haven’t even added things like only returning hidden characters to DMs. The problem with that is that `request.membership` does not exist within the `get_queryset` method, even though it’s been set inside of the `campaignMemberOrPublicReadOnlyPermission` decorator. So we’d have to fetch the membership object yet again inside of `get_queryset`, making yet another query, just because we can’t read the one we’ve already set.

## Conclusion
It was at this moment that I made my conclusion: Django Ninja is not for me. While DRF certainly has its problems (there are just way too many `View` and `ViewSet` subclasses and mixins and multiple inheritance), it is super flexible, you can make any kind of API you want, and it’s very easy to centralize things like permission checks, filtering on querysets, etc. Creating nested endpoints such as `/campaigns/{campaign_id}/characters/*` is absolutely no problem without having to repeat this prefix into every endpoint.

Django Ninja and the CRUD project have quite bad documentation and almost no examples. It’s just so much easier to get stuff done with DRF. Things like error handling, which “just works” with DRF, needs a bunch of custom code in Ninja.

For this article I was originally planning to also build the API endpoints for fetching and creating campaigns, which has its own list of rules and complexities to deal with, but I already know that this is fairly straightforward with DRF and a big problem with Ninja. Sure: anything is possible with Ninja as long as you don’t use its CRUD package and write every single endpoint by hand, but there is way too much boilerplate involved. There’s a `django-ninja-extra` package which does have a class-based way of encapsulating multiple endpoints with shared behavior, for example for permissions, but then you still need to write every endpoint for every CRUD operation.

I think that if you have a very straightforward API with a few endpoints that don’t do too must custom logic, then Django Ninja could be very well suited for that. I really had some “oh, wow!” moments while playing around with it. But for anything more complex... I’m sticking with DRF.