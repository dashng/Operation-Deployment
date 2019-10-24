# remove celery due task:
```
$ python manage.py shell
>>> from djcelery.models import PeriodicTask
>>> pt = PeriodicTask.objects.get(name='the_task_name')
>>> pt.delete()
```
