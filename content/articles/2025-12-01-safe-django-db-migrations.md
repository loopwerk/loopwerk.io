---
tags: coolify, django, python, deployment, insights, howto
summary: How to run schema-changing Django migrations safely, avoiding schema/code mismatches and server errors during rolling deploys.
---

# Safe Django migrations without server errors

One of the best features of modern container-based deployment platforms (Coolify included) is that they give you zero downtime rolling updates out of the box. When you push code, a new image is built, migrations run, and traffic only shifts to the new container when it’s healthy.

However, this convenience creates a hidden trap for Django developers. Because Coolify performs a rolling update, there is a window of time (usually 1–2 minutes) where both the old and new versions of your application are running simultaneously against the same database.

This works fine if you are just adding a new table. But if you run a destructive migration, like removing a field or renaming a column, your deployment becomes a race condition. The new container runs the migration, the database schema changes, and your *old* container (which is still serving live traffic) immediately starts throwing 500 errors because it's trying to query a column that no longer exists.

This isn't a limitation of Coolify; it is a fundamental constraint of rolling deployments. Heroku, Render, Fly.io, ECS, Kubernetes — anything that swaps containers while the old version is still serving traffic has the same constraint. You cannot fix this by changing where the migration runs in your Dockerfile. You have to fix it by changing how you write migrations.

## Why you can't just fix the infrastructure

Your first instinct might be to tweak the deployment settings to avoid the overlap. Let's look at why the common infrastructure workarounds don't actually solve the problem.

### Strategy A: the post-deploy hook
You could remove `migrate` from the build step and run it in a "Post-Deploy" hook. This means migrations run *after* the new container is live and the old one is dead.

This fixes the “removing a field” problem, because the schema change happens after the old container is no longer serving traffic. But it breaks the “adding a field” problem: if you add a new required column, the new code in the new container might start up and try to query that column *before* the migration finishes. Result: the new app crashes on startup, and the deployment fails.

Another issue: if migrations fail, your *deployment still succeeds*, leaving your app running with mismatched code and schema.

Verdict: worse than before.

### Strategy B: separate migration job
You could create a second service in the same project that runs migrations as a one-shot job.

The problem is that you still have to choose: run it before the deploy, or after? 

You’ve essentially re-implemented either Strategy A or the original “migrate during build” approach, just in a second container. The core compatibility problem remains.

Verdict: more complex and still unsafe.

### Strategy C: blue/green databases
This is the most elaborate workaround: copy production to a new database, run migrations there, and then point the new code to the new DB.

This is incredibly complex to manage for data consistency, and it would be catastrophic for any e-commerce site:

10:00:00 - Start cloning production DB
10:00:30 - User places $500 order (written to old DB)
10:01:00 - Clone complete, run migrations on clone
10:01:30 - User registers account (written to old DB)
10:02:00 - Switch to new DB
10:02:01 - Previous order and user... GONE 💀

You’re solving the wrong problem with a rocket launcher. This is enterprise-grade DevOps machinery for a basic schema compatibility issue.

Verdict: massive complexity, no real benefit.

## The real solution: the two-phase deploy

The hard truth is that destructive migrations can’t be made safe unless the schema stays compatible with both old and new code during the rollout.

The solution is not infrastructure; it's application patterns. The key idea: decouple the code change from the schema change. This is known as the Two-Phase Deploy Pattern, also called expand-and-contract, non-breaking migrations, or safe migrations.  

## Example 1: removing a field safely

Let's say we want to remove the `phone_number` field from our `User` model. The simplest way is sadly the wrong way: delete the field from `models.py`, run `makemigrations`, and deploy. This causes the server errors described above.

Instead, split it into two deploys.

### Phase 1: expand (make schema compatible with both versions)
We stop using the field in code, but we keep the column in the database and make sure it doesn’t break either version.

First we make the field nullable so the new code can ignore it:

```python
# models.py
class User(models.Model):
    ...
    # We want to delete this, but first we make it nullable
    phone_number = models.TextField(null=True, blank=True) 
```

Then remove all references to `user.phone_number` in templates, views, and serializers. Now it’s safe to create a migration and deploy this version.

**Result:**

- Migration runs safely during build.
- Old code still reads `phone_number`, which still exists.
- New code ignores `phone_number` and doesn’t break if it's missing.
- During the rollout window, both versions remain fully compatible.

Even if some old code hits that field for a moment, it still exists, so nothing crashes.

### Phase 2: contract (remove old schema elements)
Now that the production code no longer uses `phone_number`, we can safely drop it. Delete the field from `models.py`:

```python
# models.py
class User(models.Model):
    ...
    # phone_number is gone
```

Create a migration and deploy this version.

**Result:**

- The column is dropped during build.
- Running code from phase 1 ignores the column anyway.
- New code from phase 2 also ignores it.

No server errors.

## Example 2: renaming a field safely

Renaming a field is just “remove old field + add new field,” so the same pattern applies. 

### Phase 1: add new field + dual-write + data migration

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

Update your app to use `new_name` everywhere, but keep writing both fields for now.

Then add a data migration to your migration file:

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

After deploying this version and letting it run for a while, all users should now have `new_name` populated, and dual-writes have ensured the values stayed in sync.

### Phase 2: remove old field

Now remove `old_name` and the dual-write logic:

```python
class User(models.Model):
    new_name = models.CharField(max_length=100)
```

Generate the migration, deploy, and you’re done.

## Summary

Running migrations during your Coolify build is good practice — it catches failures early and keeps your deploys atomic. But schema-destructive migrations will always conflict with rolling updates if they break compatibility between old code and the new schema.

Instead of bending Coolify into a complicated orchestration engine, embrace the proven approach: deploy schema changes in two phases, keeping them backwards-compatible.

You should use this pattern for all kinds of destructive changes:

- **Removing fields** (old code tries to access them)
- **Removing models** (old code queries them)
- **Renaming fields** (old code uses old name)
- **Renaming models** (old code queries old table)
- **Making fields NOT NULL** (old code may write NULLs)
- **Decreasing field size** (old code may write longer values)
- **Changing field types** (old code expects different type)

It’s simple, safe, predictable, and works with every hosting platform, including Coolify.