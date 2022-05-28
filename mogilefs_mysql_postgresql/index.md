Миграция трекера MogileFS с MySQL на PostgreSQL
===============================================

Вступление
----------

Имеется большое количество серверов баз данных, настроенных разными людьми и под разные задачи. Поскольку многие серверы по-сути друг друга дублируют, то было бы неплохо перенести базы данных так, чтобы вывести из эксплуатации часть серверов.

В рамках этой затеи задумал перенести базы данных трекеров MogileFS с виртуальной машины с Percona Server 5.7 на кластер виртуальных машин Percona XtraDB Cluster 5.7. Однако после переноса базы данных и переключения трекеров на использвание новой базы данных в журнале ошибок /var/log/mysql/error.log на Percona XtraDB Cluster стали появляться ошибки следующего вида:

    [ERROR] WSREP: Percona-XtraDB-Cluster prohibits use of GET_LOCK with pxc_strict_mode = ENFORCING

Оказалось, что трекер MogileFS использует функций `GET_LOCK` и `RELEASE_LOCK`, которые Percona XtraDB Cluster не поддерживает.

Функции `GET_LOCK` и `RELEASE_LOCK` используются в модуле `MogileFS::Store::MySQL`. Самая свежая версия этого модуля, доступная в репозитории, также использует эти функции. В этом можно убедиться, заглянув на страницу по ссылке [[https://github.com/mogilefs/MogileFS-Server/blob/master/lib/MogileFS/Store/MySQL.pm]]

Поскольку кроме модуля `MogileFS::Store::MySQL` я нашёл также модули `MogileFS::Store::Postgres` и `MogileFS::Store::SQLite`, то решил попробовать перенести данные из имеющейся базы данных на сервер баз данных под управлением PostgreSQL. SQLite не подходит хотя бы по той простой причине, что есть несколько трекеров, работающих с общей для них базой данных.

В прошлом у меня уже был успешный опыт использоавния инструмента `pgloader` для переноса данных из MySQL в PostgreSQL, поэтому я решил воспользоваться им. Но прежде чем переносить сами данные, мне нужна структура таблиц базы данных, которая используется трекером для хранения своих данных в PostgreSQL.

Структура базы данных
---------------------

Получим исходные тексты из репозитория (я использовал для этого свой компьютер):

    $ git clone https://github.com/mogilefs/MogileFS-Server

Последней версией сервера MogileFS является версия 2.72, но в моём случае используется версия 2.70. Переключимся на нужную нам версию воизбежание дальнейших проблем со структурой базы данных:

    $ git checkout 2.70

Для получения структуры базы данных нам потребуется утилита `mogdbsetup`. MogileFS написан на Perl, а для работы утилиты понадобится доустановить в систему некоторые дополнительные пакеты:

    # apt-get install libdbi-perl libdanga-socket-perl libdbd-pg-perl libnet-netmask-perl

Создадим пользователя и базу данных:

    # su - postgres
    $ createuser -P mogilefs
    $ createdb -O mogilefs -E UTF-8 mogilefs
    $ exit

Теперь воспользуемся утилитой mogdbsetup и создадим в базе данных таблицы и последовательности для MogileFS:

    $ ./mogdbsetup --yes --type=Postgres --dbname=mogilefs --dbuser=mogilefs --dbpass=deeva7Er

Сохраняем структуру базы данных без самих данных:

    $ pg_dump -s -U mogilefs -W -d mogilefs > mogilefs_schema.sql

Структура базы данных у нас есть. Теперь можно удалить исходные тексты MogileFS и установленные для неё дополнительные пакеты, если они больше ничем не используются, например, вот так:

    $ rm -R MogileFS-Server

И вот так:

    # apt-get remove libdbi-perl libdanga-socket-perl libdbd-pg-perl libnet-netmask-perl
    # apt-get autoremove

Перенос данных
--------------

Первым делом установим пакет `pgloader`:

    # apt-get instal pgloader

Теперь создадим файл конфигурации `migrate_mogilefs.load` для переноса данных, в который поместим следующее содержимое:

    LOAD DATABASE
      FROM mysql://mysql_user:mysql_password@mysql.domain.tld:3306/mysql_db
      INTO postgresql://postgres_user:postgres_passwor@postgres.domain.tld:5432/postgres_db
    
    ALTER SCHEMA 'mysql_db' RENAME TO 'public'
    
    WITH include no drop,
         truncate,
         create no tables,
         create no indexes,
         no foreign keys,
         reset sequences,
         data only
    
    SET PostgreSQL PARAMETERS
          maintenance_work_mem to '128MB',
          work_mem to '12MB',
          search_path to 'postgres_db, public, "$user"'
    
    BEFORE LOAD EXECUTE mogilefs_schema.sql
    
    AFTER LOAD EXECUTE mogilefs_seq.sql;

В этом файле конфигруации используются следующие настройки для подключения к исходной базе данных MySQL и для целевой базе данных PostgreSQL:

* `mysql_user` - пользователь, имеющий права на чтение содержимого базы данных на сервере MySQL,
* `mysql_password` - пароль пользователя на сервере MySQL,
* `mysql.domain.tld` - доменное имя сервера MySQL (можно использовать и IP-адрес),
* `mysql_db` - имя базы данных в MySQL,
* `postgres_user` - пользователь, имеющий права как минимум на вставку строк в таблицы базы данных на сервере PostgreSQL,
* `postgres_password` - пароль пользователя на сервере PostgreSQL,
* `postgres.domain.tld` - доменное имя сервера PostgreSQL (можно использовать и IP-адрес),
* `postgres_db` - имя базы данных в PostgreSQL.

Кроме этого, если вы используете нестандартные порты на сервере MySQL или на сервере PostgreSQL, не забудьте поменять номера портов 3306 и 5432 на используемые вами.

По сравнению с моими прошлыми статьями, в которых был описан перенос данных между MySQL и PostgreSQL на примере баз данных Zabbix и Redmine, в этой статье в файле конфигурации появилось одно важное выражение:

    ALTER SCHEMA 'mysql_db' RENAME TO 'public'

Дело в том, что в `pgloader`, начиная с версии 3.4, происходит попытка импортировать данные в таблицы PostgreSQL, находящиеся в схеме, имя которой совпадает с именем базы данных в MySQL. Указанное выше выражение нужно для того, чтобы в процессе импорта использовались таблицы из схемы public.

Перед переносом данных выполняются SQL-запросы из файла `mogilefs_schema.sql`. 

Получненный до этого файл `mogilefs_schema.sql` нужно доработать следующим образом:

* Удалить комментарии и пустые строки, т.к. `pgloader` ожидает, что в каждой строчке будет указан какой-то запрос, который что-то изменяет,
* Удалить двойные кавычки вокруг имён полей, совпадающих с зарезервированными словами,
* Сменить владельца базы данных, если владелец реальной базы данных отличается от владельца тестовой базы данных, с помощью которой был получен файл `mogilefs_schema.sql`.

Сделать это можно вот так:

    $ cat mogilefs_scheme.sql | sed -e 's/^--.*$//g; /^$/d; s/"//g; s/TO mogilefs/TO mogilefs_12/g' > mogilefs_scheme.new
    $ mv mogilefs_scheme.new mogilefs_scheme.sql

Поскольку перед окончательным переносом базы данных я делал тестовые прогоны, то я также добавил в начало файла `mogilefs_scheme.sql` запрос, удаляющий все таблицы, которые будут создаваться скриптом:

    DROP TABLE IF EXISTS public.checksum,
                         public.class,
                         public.device,
                         public.domain,
                         public.file,
                         public.file_on,
                         public.file_on_corrupt,
                         public.file_to_delete,
                         public.file_to_delete2,
                         public.file_to_delete_later,
                         public.file_to_queue,
                         public.file_to_replicate,
                         public.fsck_log,
                         public.host,
                         public.lock,
                         public.server_settings,
                         public.tempfile,
                         public.unreachable_fids;

Получившийся файл, соответствующий MogileFS версии 2.70, можно взять по ссылке [[mogilefs_schema.sql]].

После перноса данных выполняются SQL-запросы из файла `mogilefs_seq.sql`, в который я поместил запросы для обновления текущих значений двух последовательностей, используемых для назначения идентификаторов записей в таблицах:

    SELECT SETVAL('fsck_log_logid_seq', (SELECT MAX(logid)
                                         FROM fsck_log));
    
    SELECT SETVAL('tempfile_fid_seq', (SELECT MAX(fid)
                                       FROM (
                                               SELECT MAX(fid) AS fid
                                               FROM tempfile
                                               UNION SELECT MAX(fid)
                                               FROM checksum
                                               UNION SELECT MAX(fid)
                                               FROM file
                                               UNION SELECT MAX(fid)
                                               FROM file_on
                                               UNION SELECT MAX(fid)
                                               FROM file_on_corrupt
                                               UNION SELECT MAX(fid)
                                               FROM file_to_delete
                                               UNION SELECT MAX(fid)
                                               FROM file_to_delete2
                                               UNION SELECT MAX(fid)
                                               FROM file_to_delete_later
                                               UNION SELECT MAX(fid)
                                               FROM file_to_queue
                                               UNION SELECT MAX(fid)
                                               FROM file_to_replicate
                                               UNION SELECT MAX(fid)
                                               FROM fsck_log
                                               UNION SELECT MAX(fid)
                                               FROM tempfile
                                               UNION SELECT MAX(fid)
                                               FROM unreachable_fids
                                            ) AS t
                                       )
                 );

Эти запросы находят максимальное значение каждого из идентификаторов среди уже существующих в таблицах записей и присваивают эти значения последовательностям.

Для запуска переноса данных остаётся запустить сам `pgloader`:

    $ pgloader migrate_mogilefs.load

После завершения переноса данных программа выведет отчёт о проделанной работе. Стоит убедиться, что в колонке errors фигурируют только нули. Это будет означать, что перенос данных завершился успешно.

Переключение трекера
--------------------

Для переключения трекера на использование новой базы данных необходимо доустановить в систему модуль `DBD::Pg`:

    # apt-get install libdbd-pg-perl

И заменить в файле конфигурации `/etc/mogilefs/mogilefsd.conf` настройки подключения к базе данных и, при необходимости, логин и пароль:

    db_dsn = DBI:Pg:dbname=postgres_db;host=postgres.domain.tld;port=5432;connect_timeout=5
    db_user = postgres_user
    db_pass = postgres_password

Перед переключением можно проверить наличие возможности подключения с помощью простого скрипта на Perl:

    #!/usr/bin/perl
    
    use warnings;
    use strict;
    use DBI;
    
    my $dh = DBI->connect(
                            "DBI:Pg:dbname=postgres_db;host=postgres.domain.tld;port=5432;connect_timeout=5",
                            "postgres_user",
                            "postgres_password",
                            {
                                    RaiseError => 0,
                                    PrintError => 0
                            }
                    );
    
    if (defined $dh) {
            print "Connection successful.\n";
    } else {
            print "Connection failed!\n";
    }

Достаточно сделать скрипт исполняемым и запустить:

    $ chmod +x test.pl
    $ ./test.pl

Если скрипт вывел текст "Connection successful.", то можно смело перезапустить трекер:

    # systemctl restart mogilefsd

Использованные материалы
------------------------

* [Миграция Redmine с MySQL на PostgreSQL](https://stupin.su/blog/redmine-mysql-postgresql/)
* [Миграция Zabbix с MySQL на PostgreSQL](https://stupin.su/blog/zabbix-mysql-postgresql/)
* [MySQL -> PostgreSQL not using public schema / dimitri commented on 17 Jul 2017](https://github.com/dimitri/pgloader/issues/594#issuecomment-315696831)
