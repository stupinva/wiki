Ещё одна шпаргалка по PostgreSQL
================================

[[!tag postgresql pg_activity]]

Содержание
----------

[[!toc startlevel=2 levels=3]]

INSERT IGNORE
-------------

Вместо `INSERT IGNORE` из MySQL можно воспользоваться `INSERT INTO` с выражением `ON CONFLICT DO NOTHING`:

    INSERT INTO ncc_snmp(snmp_port,
                         snmp_version,
                         snmp_community,
                         snmpv3_contextname,
                         snmpv3_securityname,
                         snmpv3_securitylevel,
                         snmpv3_authprotocol,
                         snmpv3_authpassphrase,
                         snmpv3_privprotocol,
                         snmpv3_privpassphrase,
                         discovered)
    SELECT DISTINCT snmp_port,
                    snmp_version,
                    snmp_community,
                    snmpv3_contextname,
                    snmpv3_securityname,
                    snmpv3_securitylevel,
                    snmpv3_authprotocol,
                    snmpv3_authpassphrase,
                    snmpv3_privprotocol,
                    snmpv3_privpassphrase,
                    true
    FROM discovery_snmp
    ON CONFLICT DO NOTHING;

JOIN в запросах UPDATE
----------------------

В отличие от MySQL, в PostgreSQL:

* в выражении `SET` должны быть указаны только имена колонок обновляемой таблицы, а указание имени таблицы вместе с колонкой считается ошибкой,
* выражение `WHERE` обязательно; если в запросе участвует более одной таблицы, вторая таблица должна соединяться с обновляемой таблицей в рамках этого выражения,
* выражение `JOIN` можно использовать только в том случае, если в запросе участвуют более двух таблиц.

Пример запроса:

    UPDATE discovery_device
    SET _snmp_id = ncc_snmp.id
    FROM discovery_snmp
    JOIN ncc_snmp ON ncc_snmp.snmp_port = discovery_snmp.snmp_port
      AND ncc_snmp.snmp_version = discovery_snmp.snmp_version
      AND ncc_snmp.snmp_community = discovery_snmp.snmp_community
      AND discovery_snmp.snmp_version IN (1, 2)
    WHERE discovery_snmp.id = discovery_device.snmp_id;

В этом примере:

* обновляется таблица `discovery_device`,
* в выражении `WHERE` с ней соединяется таблица discovery_snmp,
* в выражении `JOIN` к таблице `discovery_snmp` присоединяется таблица `ncc_snmp`.

Удаление автоинкремента поля таблицы
------------------------------------

    ALTER TABLE ufa_rs485_archives_bak ALTER COLUMN id DROP DEFAULT;

Просмотр и изменение таймаута запросов
--------------------------------------

Для просмотра текущего таймаута выполнения запросов можно воспользоваться следующим выражением:

    SHOW statement_timeout;

Для изменения текущего таймаута в рамках сессии можно воспользоваться следующим запросом:

    SET SESSION statement_timeout = '60 s';

Сжатие таблиц
-------------

Сжать таблицу, освободив неиспользуемое место, можно следующим образом:

    VACUUM first_table, second_table, ...;

Дополнительно после ключевого слова VACUUM можно указать одно или несколько дополнительных ключевых слов:

* `FULL` - полное сжатие, сопровождающееся блокировкой всей таблицы и копированием данных в другой файл,
* `ANALYZE` - дополнительно обновить статистику, используемую оптимизатором запросов для выбора плана выполнения запроса,
* `VERBOSE` - выводить отчёт по каждой обработанной таблице.

10 самых больших таблиц и индексов
----------------------------------

Подключаемся к интересующей базе данных, например, при помощи команды `psql -d <database>`, и выполняем запрос:

    SELECT nspname || '.' || relname AS "relation",
        pg_size_pretty(pg_relation_size(C.oid)) AS "size"
    FROM pg_class C
    LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
    WHERE nspname NOT IN ('pg_catalog', 'information_schema')
    ORDER BY pg_relation_size(C.oid) DESC
    LIMIT 10;

Или то же самое в байтах и с явными именами таблиц в запросе:

    SELECT pg_namespace.nspname || '.' || pg_class.relname AS relation,
           pg_relation_size(pg_class.oid) AS size
    FROM pg_class
    LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    WHERE pg_namespace.nspname NOT IN ('pg_catalog', 'information_schema')
    ORDER BY pg_relation_size(pg_class.oid) DESC
    LIMIT 10;

Источник: [https://imbolc.name/notes/pg/size-of-databases](https://imbolc.name/notes/pg/size-of-databases)

Список неиспользуемых таблиц
----------------------------

    SELECT schemaname, 
           relname, 
           pg_size_pretty(pg_relation_size(schemaname ||'.'|| relname)) AS RelationSize
    FROM pg_stat_all_tables
    WHERE schemaname NOT IN ('pg_catalog', 'pg_toast', 'information_schema')
      AND seq_scan + idx_scan = 0
    ORDER BY pg_relation_size(schemaname ||'.'|| relname) DESC;

Список неиспользуемых индексов
------------------------------

Внимание! Этот запрос возвращает также ключи уникальности, удаление которых может привести к появлению дублирующихся записей и поломке приложения:

    SELECT schemaname, 
           relname, 
           indexrelname,
           pg_size_pretty(pg_relation_size(schemaname ||'.'|| indexrelname)) AS RelationSize
    FROM pg_stat_all_indexes
    WHERE schemaname NOT IN ('pg_catalog', 'pg_toast', 'information_schema')
      AND idx_scan = 0
      AND indexrelname NOT LIKE '%pkey%'
    ORDER BY pg_relation_size(schemaname ||'.'|| indexrelname) DESC;

Поле описания базы данных
-------------------------

Для просмотра строк описания всех баз данных можно воспользоваться командой `\l+` клиента `psql`:

                                                                                                                     List of databases
              Name           |          Owner          | Encoding |   Collate   |    Ctype    | ICU Locale | Locale Provider |                  Access privileges                  |  Size   | Tablespace |                Description                 
    -------------------------+-------------------------+----------+-------------+-------------+------------+-----------------+-----------------------------------------------------+---------+------------+--------------------------------------------
     postgres                | postgres                | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            | =Tc/postgres                                       +| 7485 kB | pg_default | default administrative connection database
                             |                         |          |             |             |            |                 | postgres=CTc/postgres                              +|         |            | 
                             |                         |          |             |             |            |                 | zabbix=c/postgres                                   |         |            | 
     template0               | postgres                | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            | =c/postgres                                        +| 7297 kB | pg_default | unmodifiable empty database
                             |                         |          |             |             |            |                 | postgres=CTc/postgres                               |         |            | 
     template1               | postgres                | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            | =c/postgres                                        +| 7369 kB | pg_default | default template for new databases
                             |                         |          |             |             |            |                 | postgres=CTc/postgres                               |         |            | 

Для того, чтобы прописать в поле описания базы данных новое значение, можно воспользоваться запросом следующего вида:

    COMMENT ON DATABASE postgres IS 'default administrative connection database';

Для сброса поля описания базы данных вместо строки описания нужно указать ключевое слово `NULL`:

    COMMENT ON DATABASE postgres IS NULL;

Просмотр количества таблиц в базе данных
----------------------------------------

Для просмотра количества таблиц в определённой базе данных, нужно подключиться к ней и выполнить следующий запрос:

    SELECT COUNT(*)
    FROM information_schema.tables
    WHERE table_schema NOT IN ('pg_catalog', 'information_schema', 'repack', '_timescaledb_catalog', '_timescaledb_internal', '_timescaledb_config', '_timescaledb_cache', 'timescaledb_information', 'timescaledb_experimental');

Из выборки исключены системные табличные пространства и табличные пространства расширений `repack` и `timescaledb`.

Просмотр количества колонок в таблицах базе данных
-------------------------------------------------

Для просмотра количества колонок в таблицах в определённой базе данных, нужно подключиться к ней и выполнить следующий запрос:

    SELECT COUNT(*)
    FROM information_schema.columns
    WHERE table_schema NOT IN ('pg_catalog', 'information_schema', 'repack', '_timescaledb_catalog', '_timescaledb_internal', '_timescaledb_config', '_timescaledb_cache', 'timescaledb_information', 'timescaledb_experimental');

Из выборки исключены системные табличные пространства и табличные пространства расширений `repack` и `timescaledb`.

Просмотр объёма базы данных
---------------------------

Для просмотра объёма определённой базы данных в гигабайтах, нужно подключиться к ней и выполнить следующий запрос:

    SELECT SUM(pg_relation_size(C.oid)) / (1024 * 1024 * 1024) AS s
    FROM pg_class C
    LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
    WHERE nspname NOT IN ('pg_catalog', 'information_schema', 'repack', '_timescaledb_catalog', '_timescaledb_internal', '_timescaledb_config', '_timescaledb_cache', 'timescaledb_information', 'timescaledb_experimental');

Из выборки исключены системные табличные пространства и табличные пространства расширений `repack` и `timescaledb`.

Тажке для просмотра списка всех баз данных с информацией об их объёме можно воспользоваться командой клиента `psql`:

    \l+

Выполнение SQL-запросов из сценариев оболочки
---------------------------------------------

Для выполнения SQL-запросов из сценариев оболочки можно воспользоваться такой конструкцией:

    PGPASSWORD=p4$$w0rd psql -U username -d database -h host.domain.tld -t <<END
    SELECT 1;
    END

Перенос данных из таблицы MySQL в таблицу PostgreSQL
----------------------------------------------------

Сохраняем содержимое таблицы из MySQL:

    $ mysqldump --single-transaction --no-create-info --add-locks=0 --complete-insert --compatible=postgresql -uroot -p base table > table.sql

Восстанавливаем резервную копию в PostgreSQL:

    $ cat table.sql | psql database

Использованный источник: [Import MySQL dump to PostgreSQL database](https://stackoverflow.com/questions/5417386/import-mysql-dump-to-postgresql-database)

После переноса данных может потребоваться также скорректировать значение последовательности целых чисел, используемой в индексах таблицы.

Обновление PostgreSQL до нового релиза
--------------------------------------

Создаём резервную копию. Убедитесь, что база данных не находится в процессе обновления.

    $ pg_dumpall > outputfile

Устанавливаем Postgres 10. Следуем инструкциям на странице: [PostgreSQL Apt Repository](https://www.postgresql.org/download/linux/ubuntu/)

Теперь запускаем `apt-get install postgresql-10`. Новая версия будет установлена рядом со старой версией.

Запускаем `pg_lsclusters`:

    Ver Cluster Port Status Owner    Data directory               Log file
    9.6 main    5432 online postgres /var/lib/postgresql/9.6/main /var/log/postgresql/postgresql-9.6-main.log
    10  main    5433 online postgres /var/lib/postgresql/10/main  /var/log/postgresql/postgresql-10-main.log

Уже есть кластер `main` в 10 версии (потому что он создаётся по умолчанию при установке пакета). Это делается для того, чтобы свежие инсталляции работали сразу после установки без необходимости создавать кластер, но, конечно, это препятствует обновлению `9.6/main`, т.к. уже есть `10/main`. Рекомендуется удалить кластер 10 при помощи `pg_dropcluster`, а затем выполнить обновление при помощи `pg_upgradecluster`.

Останавливаем кластер 10 и удаляем его:

    # pg_dropcluster 10 main --stop

Останавливаем все процессы и сервисы, пишущие в базу данных. Останавливаем базу данных:

    # systemctl stop postgresql 

Обновляем кластер 9.6:

    # pg_upgradecluster -m upgrade 9.6 main

Запускаем PostgreSQL снова:

    # systemctl start postgresql

Запускаем `pg_lsclusters`. Кластер 9.6 должен быть в состоянии `down`, а кластер 10 должен быть в состоянии `online` на порту 5432:

    Ver Cluster Port Status Owner    Data directory               Log file
    9.6 main    5433 down   postgres /var/lib/postgresql/9.6/main /var/log/postgresql/postgresql-9.6-main.log
    10  main    5432 online postgres /var/lib/postgresql/10/main  /var/log/postgresql/postgresql-10-main.log

Первым делом проверяем, что всё работает. Затем удаляем кластер 9.6:

    # pg_dropcluster 9.6 main --stop

Заметки по `pg_upgradecluster`:

Это руководство годится для обновления с 9.5 до 10.1. При обновлении с более старых версий, возможно потребуется пропустить `-m upgrade` на шаге №6:

    # pg_upgradecluster 9.6 main

Если у вас очень большой кластер, вы можете воспользоваться `pg_upgradecluster` с опцией `--link option`, чтобы обновление происходило без копирования, на месте. Однако это опасно - если случится ошибка, можно потерять данные. Просто не используйте эту опцию без необходимости, т.к. `-m upgrade` работает достаточно быстро.

Использованные материалы:

* Документация: [Upgrading a PostgreSQL Cluster](https://www.postgresql.org/docs/10/static/upgrading.html)
* Gist #1: [delameko/upgrade-postgres-9.5-to-9.6.md](https://gist.github.com/delameko/bd3aa2a54a15c50c723f0eef8f583a44)
* Gist #2: [johanndt/upgrade-postgres-9.3-to-9.5.md](https://gist.github.com/johanndt/6436bfad28c86b28f794)
* [What happens if I interrupt or cancel pg_upgradecluster?](https://dba.stackexchange.com/questions/173382/what-happens-if-i-interrupt-or-cancel-pg-upgradecluster/173400)
* [Ubuntu manpage for pg_upgradecluster](http://manpages.ubuntu.com/manpages/trusty/en/man8/pg_upgradecluster.8.html)

P.S. Это руководство годится для обновления с 9.6 до 11 и с 10 до 11.

Источник: [Upgrade PostgreSQL from 9.6 to 10.0 on Ubuntu 16.10 - A Step-by-Step Guide](https://stackoverflow.com/a/47233300)

Использование файла ~/.pgpass
-----------------------------

В домашнем каталоге пользователя можно разместить файл `~/.pgpass`, в котором можно указать пароли, которые клиенты PostgreSQL будут использовать для подключения к базам данных. Формат фала такой:

    <server>:<port>:<database>:<user>:<password>

Например, для подключения к базе данных `ncc` через локальный PgBouncer под пользователем `ncc` может использоваться такая строчка:

    localhost:6432:ncc:ncc:Sho9aePh6Koog8ag

Просмотр и завершение активных процессов
----------------------------------------

Для просмотра активных процессов можно воспользоваться одним из запросов:

    SELECT * FROM pg_stat_activity WHERE state = 'active';
    SELECT pid, state, usename, query FROM pg_stat_activity;

Вежливое завершение процесса:

    SELECT pg_cancel_backend(PID);

Принудительное завершение процесса:

    SELECT pg_terminate_backend(PID);

Где `PID` - идентификатор процесса для завершения.

Установка и настройка pg_activity
---------------------------------

Утилита `pg_activity` используется для просмотра SQL-запросов, выполняемых в СУБД PostgreSQL в настоящее время. По существу эта утилита аналогична более известной утилите `mytop` для MySQL.

Установим `pg_activity`:

    # apt-get install pg-activity

Для локального запуска `pg_activity` пользователем `stupin` без запроса пароля отредактируем файл `/etc/postgresql/9.6/main/pg_hba.conf` следующим образом:

    local   all             stupin                                  peer

Перезагрузим PostgreSQL с новой конфигурацией:

    # /etc/init.d/postgresql reload

Теперь создадим пользователя `stupin` в СУБД и выдадим ему права.

Переключимся на учётную запись администратора СУБД PostgreSQL:

    # su - postgres

Запустим SQL-клиента PostgreSQL:

    $ psql postgres

Выполним следующие SQL-запросы для создания пользователя `stupin` и предоставления прав, необходимых для работы `pg_activity`:

    CREATE USER stupin;
    ALTER USER stupin WITH SUPERUSER;

Для запуска `pg_activity` этого должно быть достаточно.

Восстановление резервной копии базы данных
------------------------------------------

Для восстановления содержимого таблиц базы данных из резервной копии поверх имеющихся таблиц и с игнорированием ошибок смены владельца базы данных можно воспользоваться командой следующего вида:

    PGPASSWORD="p4$$w0rd" pg_restore -cO -U stupin -d database backup.bak

Скрипт для обновления локальной резервной копии базы данных
-----------------------------------------------------------

Для автоматизации пересоздания локального пользователя, базы данных, скачивания резервной копии с удалённого сервера, доступного по SSH, и восстановления скачанной резервной копии в локальную базу данных можно воспользоваться скриптом [[dev_db.sh|dev_db.sh]]. Настройки для скачивания резервной копии и развёртывания базы данных можно выставить в переменных внутри самого скрипта. Скрипту нужно передать один аргумент, при помощи которого указывается действие, которое необходимо выполнить:

* `create` - создать пользователя и базу данных,
* `drop` - удалить пользователя и базу данных,
* `test` - проверить доступность базы данных для пользователя,
* `fetch` - скачать резервную копию с удалённого сервера,
* `restore` - восстановить резервную копию в локальную базу данных.

Если действие не указано, то скрипт лишь выведет однострочную справку по использованию:

    $ ./dev_db.sh 
    ./dev_db.sh create | drop | test | fetch | restore

Для настройки беспарольного доступа к удалённому серверу по SSH можно обратиться к статье [[Настройка SSH|ssh]].

Просмотр списка расширений
--------------------------

Для просмотра списка расширений, активных в базе данных, нужно подключиться к ней консольным клиентом `psql` и выполнить команду:

    \dx

Для просмотра доступных расширений и их версий можно воспользоваться следующим запросом:

    SELECT name, version, installed
    FROM   pg_available_extension_versions;

Просмотр прав доступа
---------------------

    api_ufanet=# \dp

Права на использование схемы
----------------------------

Если нужно выдать пользователю доступ на чтение к отдельным таблицам, то для этого можно воспользоваться запросами следующего вида:

    GRANT SELECT ON core_cameraextra TO ncc;
    GRANT SELECT ON core_camera TO ncc;

Однако, этого может оказаться недостаточно. При попытке доступа к таблицам базы данных можно получить сообщения об отсутствии отношений в базе данных:

    ucams_office=> SELECT * FROM core_camera LIMIT 10;
    ERROR:  relation "core_camera" does not exist
    СТРОКА 1: SELECT * FROM core_camera LIMIT 10;
                            ^
    ucams_office=> \d
    Отношения не найдены.

Для решения проблемы нужно выдать пользователю права на доступ к схеме `public`:

    GRANT USAGE ON SCHEMA public TO ncc;

Удаление прав доступа к таблицам
--------------------------------

Проблема при удалении пользователя:

    api_ufanet=# DROP USER api_ufanet_ro;
    ERROR:  role "api_ufanet_ro" cannot be dropped because some objects depend on it
    DETAIL:  privileges for schema public
    privileges for table admin_tools_dashboard_preferences

Решение:

    api_ufanet=# REVOKE ALL PRIVILEGES FROM ALL TABLES IN SCHEME api_ufanet FROM api_ufanet_ro;
    REVOKE

Удаление прав доступа к последовательностям
-------------------------------------------

Проблема при удалении пользователя:

    api_ufanet=# DROP USER api_ufanet_ro;
    ERROR:  role "api_ufanet_ro" cannot be dropped because some objects depend on it
    DETAIL:  privileges for schema public
    privileges for sequence admin_tools_dashboard_preferences_id_seq

Решение:

    api_ufanet=# REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM api_ufanet_ro;
    REVOKE

Удаление прав доступа по умолчанию к таблицам
---------------------------------------------

Проблема при удалении пользователя:

    api_ufanet=# DROP USER api_ufanet_ro;
    ERROR:  role "api_ufanet_ro" cannot be dropped because some objects depend on it
    DETAIL:  privileges for schema public
    privileges for default privileges on new relations belonging to role postgres in schema public

Решение:

    api_ufanet=# ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM api_ufanet_ro;
    ALTER DEFAULT PRIVILEGES

Удаление прав доступа по умолчанию к последовательностям
--------------------------------------------------------

Проблема при удалении пользователя:

    api_ufanet=# DROP USER api_ufanet_ro;
    ERROR:  role "api_ufanet_ro" cannot be dropped because some objects depend on it
    DETAIL:  privileges for schema public
    privileges for default privileges on new sequences belonging to role postgres in schema public

Решение:

    api_ufanet=# ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM api_ufanet_ro;
    ALTER DEFAULT PRIVILEGES

Удаление прав доступа к схеме
-----------------------------

Проблема при удалении пользователя:

    api_ufanet=# DROP USER api_ufanet_ro;
    ERROR:  role "api_ufanet_ro" cannot be dropped because some objects depend on it
    DETAIL:  privileges for schema public

Решение:

    api_ufanet=# REVOKE ALL PRIVILEGES ON SCHEMA public FROM api_ufanet_ro;
    REVOKE

Удаление пользователя
---------------------

    api_ufanet=# DROP USER api_ufanet_ro;
    DROP ROLE

Дополнительные материалы
------------------------

* [Restoring a single table from a Postgres database or backup](https://feeding.cloud.geek.nz/posts/restoring-single-table-from-postgres/)
* [Stopping long-running Postgres queries](https://feeding.cloud.geek.nz/posts/stopping-long-running-postgres-queries/)
* [Troubleshooting Postgres Performance Problems](https://feeding.cloud.geek.nz/posts/troubleshooting-postgres-performance/)
* [Роли и атрибуты в PostgreSQL](https://sysadminium.ru/roli_i_atributy_v_postgresql/)
* [Статистика работы PostgreSQL](https://sysadminium.ru/statistika_raboty_postgresql/)
* [Привилегии в PostgreSQL](https://sysadminium.ru/privilegii_v_postgresql/)
* [Схемы и шаблоны в СУБД PostgreSQL](https://sysadminium.ru/shemy_i_shablony_v_subd_postgresql/)
* [Табличные пространства в PostgreSQL](https://sysadminium.ru/tablichnye_prostranstva_v_postgresql/)
* [Авторизация в PostgreSQL. Часть 1. Роли и Привилегии](https://habr.com/ru/company/timeweb/blog/661771/)
* [Авторизация в PostgreSQL. Часть 2. Безопасность на уровне строк](https://habr.com/ru/company/timeweb/blog/662209/)
