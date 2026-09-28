---
tags: coolify, django, insights, howto
summary: How to run schema-changing Django migrations safely, avoiding schema/code mismatches and server errors during rolling deploys.
---

# Safe Django migrations without server errors

I'm a big fan of Coolify for deploying my projects - I've written about it [multiple times before](/articles/tag/coolify/). One of its best features is zero-downtime deploys, right out of the box. You push your code, a new image gets built, the Django migrations run, and traffic shifts over to the new container when it's ready. Your site never goes offline during deployment, your visitors don't notice anything.

There is something worth keeping in mind though: during this rolling deployment there's a window (usually about 1 to 2 minutes) where both the old and new versions of your web app are running at the same time, both using the same database.

This works fine when you've added a new table or field to your database. But in the case of a destructive database change, such as removing or renaming a field, there are problems ahead. Your deployment has become a race condition: the new container runs the migration, the database schema changes, and now your *old* container (still serving live traffic!) starts to throw server errors because it's trying to access a field that no longer exists. Until the new container takes over in a minute or so, all your users will see these errors. That's not great.

I ran into exactly this issue with a few of my recent deployments, and I wanted to find the best way to prevent these errors going forward.

Please note that this problem is not unique to Coolify, it happens in all modern container-based deployment platforms which swap containers to facilitate zero-downtime deploys.

## You can't just change the Dockerfile

My first instinct was to remove `manage.py migrate` from the build step, move it to its own "post deploy" hook. That would mean the migration runs after the new container is live and the old is gone. Surely that would solve the server errors, right?

It does indeed fix the "removing a field" problem, because the field is removed after the old container is gone, and the new container is already not referencing this old field in the code. Yay!

However, it will now break when you're adding a new field to the database. The new code is referencing a database field which hasn't been created yet, because the migration step hasn't run yet. Migrations can take quite a while to complete, and during this your site will still show errors to your users.

And what if the migrations fail? Your deployment still succeeded, so your app is running new code with an old database schema.

Verdict: worse than before.

## What about two databases?

Then I thought: what if I had two databases? Basically, when a new version of the app is deployed, create a copy of the database and assign it to the new container. The migrations run on this new database, leaving the old database alone. All the errors would be solved.

Sure, but what about database writes during this deployment? They are still made to the old database, so when the site switches to the new container, with the new database, those writes would be gone. This would be catastrophic for any e-commerce website.

I'm sure you could store those writes to the old database, somewhere, and replay them on the new database but damn, now we're talking enterprise-level DevOps for what feels like a pretty basic schema compatibility issue.

Verdict: this is madness.

## The two-phase deploy

To fix the server errors, we need to make sure that the database schema stays compatible with both the old code and the new code, at the same time. So really the fix lives in the code, not in the infrastructure.

The idea is to decouple the code change from the schema change. Turns out that I stumbled my way onto something known as the two-phase deploy pattern.

Let's look at how this solves all the problems.


## Example 1: removing a field

Let's say we have a `User` model, and we want to remove the `phone_number` field. We can't just remove the field, run `makemigrations` and deploy the change, because it will result in those server errors.

Instead, we have to make this change in two steps, two deploys.

### Phase 1

We need to make the schema compatible with both versions of the code. The old code still making use of this field, and the new code that doesn't.

First, we make the field nullable so the new code can ignore it:

```python title="models.py"
class User(models.Model):
    phone_number = models.TextField(null=True, blank=True)
```

Then we stop making use of this field in our code. Remove all references to `user.phone_number`, never write to it, never read from it. Now it's safe to create a migration and do a deploy.

During the deploy the old code will still use this field, and that's totally fine: it still exists in the database.

### Phase 2

After the first deploy is done, we can remove the field from the model for real, create another migration, and deploy again.

Since no code is referencing this field, no server errors will be triggered during the deploy.

## Example 2: renaming a field

If you'd simply rename a field in a Django model and push that change, we have the same problem as removing a field: the old code still references the old field name, which no longer exists.

But once you understand that renaming a field is really just removing an old field and adding a new one, you'll see that the same two-phase pattern applies: in phase 1 we add the new field, and set up dual field writing plus a data migration. Then in phase 2 we remove the old field.

### Phase 1

Let's say we want to rename field `old_name` to `new_name`. We do this by adding a new field first:

```python
class User(models.Model):
    old_name = models.CharField(max_length=100)
    new_name = models.CharField(max_length=100, null=True)

    def save(self, *args, **kwargs):
        # Dual-write during transition
        if self.old_name and not self.new_name:
            self.new_name = self.old_name
        super().save(*args, **kwargs)
```

Update your code to use `new_name` everywhere. Then add a data migration to the migration file, which copies the data from `old_name` to `new_name`:

```python
from django.db.models import F

def copy_old_to_new(apps, schema_editor):
    User = apps.get_model('accounts', 'User')
    User.objects.filter(new_name__isnull=True).update(new_name=F('old_name'))

class Migration(migrations.Migration):
    operations = [
        migrations.AddField(...),
        migrations.RunPython(copy_old_to_new, migrations.RunPython.noop),
    ]
```

Once this is deployed, all users have both `old_name` and `new_name` populated with the same data, and the overridden `save` method will keep them in sync. 

### Phase 2

This is basically the same as removing a field. Remove `old_name` from the model, remove the overridden `save` method, create a migration, and deploy.

No errors will happen since no code is referencing the old model field.

## Summary

I think that running the database migrations during the build process is a good idea, since failures are caught early and stop a deployment. To prevent server errors during the deployment, make sure that your schema stays compatible with both the old and the new code. Deploy the changes in two separate phases, keeping them backwards-compatible.

This goes for all kinds of destructive changes, some of which you might not have thought of: making fields NOT NULL, decreasing field size, or changing field types. Think about the old code running with the new database, and how that would break things, and it's pretty easy to figure out the two phases.
