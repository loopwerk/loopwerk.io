---
tags: python, django
---

# How to dynamically add fields to a Django model
For a project I needed to create a Django model from a list of fields that were defined somewhere else. It took me hours to get this to work, so to save you the time, here is the solution:

```python
fields = ['field_a', 'field_b', 'field_c']

# the base model with some basic fields
class MyModel(models.Model):
    date = models.DateField()

# add the extra fields after the model has been created
for field in fields:
    MyModel.add_to_class(field, models.DecimalField(decimal_places=4, max_digits=10))
 ```

My first instinct was to create an `__init__` function inside the model class and use that to create the extra fields, but since the `__init__` function is never called for models, this didn't work. Creating the extra fields after you created the model class itself however works just fine.
