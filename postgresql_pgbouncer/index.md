Настройка PgBouncer
===================

[[!tag pgbouncer]]

Ранее я уже описывал настройку PgBouncer и зачем он нужен в статье [Проксирование запросов к PostgreSQL через PgBouncer](http://stupin.su/blog/pgbouncer/). В этот раз мы настроим PgBouncer без указания списка пользователей и их паролей. Вместо этого аутентификация будет происходить с использованием учётных данных, имеющихся в самом PostgreSQL.

Установим PgBouncer на компьютер с PostgreSQL:

    # apt-get install pgbouncer

Отредактируем файл `/etc/pgbouncer/pgbouncer.ini` таким образом, чтобы вывод следующей команды `grep` соответствовал приведённому ниже:

    # grep -vE '^(;|$)' /etc/pgbouncer/pgbouncer.ini
    [databases]
    * = auth_user=postgres host=/var/run/postgresql
    [users]
    [pgbouncer]
    logfile = /var/log/postgresql/pgbouncer.log
    pidfile = /var/run/postgresql/pgbouncer.pid
    listen_addr = *
    listen_port = 6432
    unix_socket_dir = /var/run/postgresql
    auth_type = hba
    auth_hba_file = /etc/postgresql/13/main/pg_hba.conf
    auth_query = SELECT usename, passwd FROM pg_shadow WHERE usename=$1
    admin_users = postgres, root
    stats_users = postgres, root
    pool_mode = transaction
    ignore_startup_parameters = extra_float_digits
    max_client_conn = 600
    default_pool_size = 16

Поясню смысл настроек:

* `* = auth_user=postgres host=/var/run/postgresql` - для всех баз данных для аутентификации подключающихся пользователей будет использоваться пользователь `postgres`, подключение будет осуществляться через Unix-сокет, находящийся в каталоге `/var/run/postgresql` (порту по умолчанию 5432 соответствует Unix-сокет `.s.PGSQL.5432`),
* `listen_addr = *` - входящие подключения к PgBouncer будут приниматься на всех сетевых интерфейсах системы,
* `listen_port = 6432` - входящие подключения к PgBouncer будут приниматься на TCP-порту 6432,
* `unix_socket_dir = /var/run/postgresql` - Unix-сокет для подключений к PgBouncer будет помещён в каталог `/var/run/postgresql` (порту 6432 соответствует Unix-сокет `.s.PGSQL.6432`),
* `auth_type = hba` - в процессе аутентификации будет учитываться содержимое файла `hba`,
* `auth_hba_file = /etc/postgresql/13/main/pg_hba.conf` - путь к файлу `pg_hba.conf`, содержимое которого будет учитываться при аутентификации входящих подключений,
* `auth_query = SELECT usename, passwd FROM pg_shadow WHERE usename=$1` - запрос, используемый для аутентификации входящих подключений. Вместо шаблона `$1` в запрос будет подставляться логин подключившегося пользователя, запрос должен возвращать логин и хэш пароля пользователя,
* `admin_users = postgres, root` - пользователи операционной системы, имеющие право выполнять команды по управлению PgBouncer'ом,
* `stats_users = postgres, root` - пользователи операционной системы, имеющие право узнавать статистику PgBouncer'а,
* `pool_mode = transaction` - режим использования пула подключений к серверу PostgreSQL, при котором одно и то же подключение может использоваться разными транзакциями, но запросы внутри транзакции будут всегда попдадать в одно и то же подключене,
* `ignore_startup_parameters = extra_float_digits` - режим совместимости, позволяющий избегать некоторых проблем при подключении со стороны программ, использующих независимую реализацию протокола подключения к PostgreSQL,
* `max_client_conn = 600` - максимальное количество одновременных входящих подключений к PgBouncer,
* `default_pool_size = 16` - максимальное количество исходящих подключений к PostgreSQL.

После внесения этих настроек нужно перезагрузить PgBouncer:

    # systemctl reload pgbouncer

Осталось заменить в файле `/etc/postgresql/13/main/pg_hba.conf` строчку, разрешающую устанавливать локальные подключения к PostgreSQL через Unix-сокет:

    #local   all             all                                     peer
    local   all             all                                     md5

Перезагрузим PostgreSQL для вступления настроек в силу:

    # systemctl reload postgresql

Использование с django
----------------------

Для беспроблемной работы django-приложений через PgBouncer необходимо выставить в настройках приложения опцию:

    DISABLE_SERVER_SIDE_CURSORS = True

Опция поддерживается в Django версии 1.11.1 и выше. Подробнее об этом можно прочитать в документации [Databases / Transaction pooling and server-side cursors](https://docs.djangoproject.com/en/4.0/ref/databases/#transaction-pooling-server-side-cursors).

В случае с Django предыдущих версий можно воспользоваться опцией `CONN_MAX_AGE` в сочетании с `pool_mode = session`.

Для этого выставляем в конфигурации подключения к базе данных в проекте Django опцию CONN_MAX_AGE, равную очень малому значению, позволяющему закрывать неиспользуемые подключения к pgbouncer'у как можно скорее. Обычно я выставляю значение, равное 2 секундам.

Далее в файле `/etc/pgbouncer/pgbouncer.ini` можно поменять значение опции `pool_mode` на `session` глобально в секции `[pgbouncer]`, если нет других баз данных. Или можно прописать индивидуальные настройки для выбранной базы данных в секцию `[databases]`, например, следующим образом:

    db = auth_user=postgres host=/var/run/postgresql pool_mode=session

Генерация хэша
--------------

Если для аутентификации пользователей используется файл, то в файле `/etc/pgbouncer/pgbouncer.ini` обычно используются такие настройки:

    auth_type = md5
    auth_file = /etc/pgbouncer/users.txt

Внутри файла `/etc/pgbouncer/users.txt` перечисляются имена пользователей и хэш-суммы их паролей.

Для вычисления хэш-суммы пароля пользователя можно воспользоваться таким однострочным скриптом:

    $ printf "md5" ; printf "passworduser" | md5sum | cut -d" " -f1

Вместо `password` нужно подставить пароль, а вместо `user` - имя пользователя.
