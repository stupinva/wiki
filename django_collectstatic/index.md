Проблема со сбором статики в Django
===================================

Имеется такой вот 6-летний глюк: [#21080 (collectstatic post-processing fails for references inside comments) – Django](https://code.djangoproject.com/ticket/21080)

Чтобы исправить, нужно в файле /usr/lib/python2.7/dist-packages/django/contrib/staticfiles/storage.py поменять начало функции hashed_name следующим образом:

    def hashed_name(self, name, content=None):
        name = name.replace('"', '')
        parsed_name = urlsplit(unquote(name))
        clean_name = parsed_name.path.strip()
        clean_name = os.path.normpath(clean_name)
        opened = False
