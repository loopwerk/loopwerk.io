---
tags: python, django
---

# Using the Google Visualization API in Django
In a project I am working on, I need to show a lot of graphs and charts. Together with the client we chose to use the [Visualization API by Google](http://code.google.com/apis/visualization/), which provides a Python library, offers [many different kinds](http://code.google.com/apis/visualization/documentation/gallery.html) of charts and very important: the data is not sent to Google, but is loaded by the browser from your own datastore.

Getting this to work took some time and here, in a nutshell, is how to do it in Django.

First of all, download and install the Python library from [http://code.google.com/p/google-visualization-python/](http://code.google.com/p/google-visualization-python/) (or, just include it in your Django project if you don't want to install it).

Add the following line to your html template:

```html
<script type="text/javascript" src="http://www.google.com/jsapi"></script>
```

Javascript code:

```javascript
google.load('visualization', '1', {'packages':['annotatedtimeline']});
datasource = new google.visualization.Query('http://127.0.0.1:8000/datasource/');
var id = document.getElementById('your graph id here');
var graph = new google.visualization.AnnotatedTimeLine(id);

datasource.setQuery('column_a+column_b+column_c');
datasource.send(function(response) {
    graph.draw(response.getDataTable(), {wmode: 'opaque'});
});
```

_don't forget the trailing slash after your datasource url_

Your Django view on /datasource:

```python
def datasource(request):
    import gviz_api
    from myapp.models import Books
    from django.http import HttpResponse

    # These are the columns that you provided in the datasource.setQuery() function
    # Make it a set to filter out duplicates
    columns = set(request.GET.get('tq', '').split('+'))

    queryset = Books.objects.all().values()
    all_fields = Books._meta.get_all_field_names()

    # Always add the date column
    description = {}
    description['date'] = ('date', 'Date')

    for column in columns:
        if column in all_fields:
            title = unicode(Books._meta.get_field(column).verbose_name)
            description[column] = ('number', title)

    data_table = gviz_api.DataTable(description)

    for query in queryset:
        data_table.AppendData([query])

    return HttpResponse(data_table.ToResponse(tqx=request.GET.get('tqx', '')))
```

So what does it do? Well, in your javascript code you can set which columns you want to show in your graph (in this example column_a, column_b and column_c). These are the names of the variables in your Django DB model. The view then creates a gviz_api.DataTable object containing these columns (plus a "date" column) and adds the real data from your database to it. Now, in this example all the columns are expected to be a number, but you could change your code to allow for columns of different types as well.

The nice thing is that you can dynamically change which columns you want to show by calling `datasource.setQuery()` again with different values, and the new graph is shown without the need of a page reload. Only the graph itself is redrawn with the new datatable.
