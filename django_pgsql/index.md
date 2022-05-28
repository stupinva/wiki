Django + PostgreSQL за 8 шагов
==============================

Автор: urslan

Дата: 17 мая 2016
 
Источник: [Django + PostgreSQL за 8 шагов](https://djbook.ru/examples/77/)

На ночь глядя решился написать гайд по установке СУБД PostgreSQL для использования вместе с Django.

Хотя в мануалах Django и рекомендуется использовать PostgreSQL, но среди разработчиков бытует мнение, что MySQL гораздо проще для начинающего разработчика.

Я с этим мнением не согласен. И попытаюсь Вам это доказать.

За 8 простых шагов я покажу как установить PostgreSQL в Ubuntu 14.04 LTS и настроить Django для работы с ним.

Шаг 1
-----

Ставим сам сервер PostgreSQL и библиотеку разработчика (она пригодится нам при установке бэкэнда)

    $ sudo apt-get install postgresql postgresql-server-dev-9.3

Если вы решите использовать более свежую Ubuntu 16.04 LTS, то PostgreSQL там будет уже версии 9.5.

    $ sudo apt-get install postgresql postgresql-server-dev-9.5

Шаг 2
-----

Открываем консоль PostgreSQL

    $ sudo -u postgres psql postgres

Шаг 3
-----

Задаем пароль администратора БД

    \password postgres

Шаг 4
-----

Создаем и настраиваем пользователя при помощи которого будем соединяться с базой данных из Django (ну очень плохая практика все делать через ... суперпользователя). Заодно указываем значения по умолчанию для кодировки, уровня изоляции транзакций и временного пояса.

    CREATE USER user_name WITH PASSWORD 'password';
    ALTER ROLE user_name SET CLIENT_ENCODING TO 'utf8';
    ALTER ROLE user_name SET DEFAULT_TRANSACTION_ISOLATION TO 'READ COMMITED';
    ALTER ROLE user_name SET TIMEZONE TO 'UTC';

Временной пояс можно указать свой, согласно тому, который вы прописываете в settings.py проекта. А про страшное определение уровень изоляции транзакций, если оно вам не знакомо, лучше все таки прочитать из учебника по SQL - пригодится.

Шаг 5
-----

Создаем базу для нашего проекта

    CREATE DATABASE django_db OWNER user_name;

Шаг 6
-----

Выходим из консоли

    \q

Шаг 7
-----

Устанавливаем бэкэнд для PostgreSQL

    $ apt-get install python-psycopg2

Шаг 8
-----

Последний наш шаг - настроить раздел DATABASES конфигурационного файла проекта settings.py

    'ENGINE': 'django.db.backends.postgresql_psycopg2',
    'NAME': 'django_db',
    'USER' : 'user_name',
    'PASSWORD' : 'password',
    'HOST' : '127.0.0.1',
    'PORT' : '5432',
    'OPTIONS': {'connect_timeout': 3}

На этом все!

Дальше все как обычно:

* делаем миграцию ./manage.py migrate,
* создаем суперпользователя ./manage.py createsuperuser
* и запускаем сервер ./manage runserver.

Если у вас настроен SSH на сервере, то можно еще научить pgAdmin с локальной машины управлять удаленным сервером PostgreSQL. Для этого мы можем создать ssh-тунель командой ssh -fNq -L 5555:localhost:5432 user@domain.com.

Теперь можно из локального pgAdmin соединяться с удаленной БД по адресу localhost:5555
