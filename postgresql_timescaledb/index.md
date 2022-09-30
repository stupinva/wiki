PostgreSQL и TimescaleDB
========================

[[!tag postgresql timescaledb]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Настройка репозиториев Debian
-----------------------------

Установим в систему пакеты `gpg` и `gpg-agent` для проверки подписи репозитория пакетов TimescaleDB:

    # apt-get install wget ca-certificates gpg gpg-agent

Установим в систему GPG-ключ репозитория пакетов TimescaleDB:

    # wget -O - https://packagecloud.io/timescale/timescaledb/gpgkey | apt-key add -

Пропишем в файл `/etc/apt/sources.list` строку репозитория пакетов TimescaleDB, в данном случае для Debian Bullseye:

    deb https://packagecloud.io/timescale/timescaledb/debian/ bullseye main

Для Ubuntu также доступен альтернативный репозиторий:

    deb http://ppa.launchpad.net/timescale/timescaledb-ppa/ubuntu bionic main

Выполним обновление списка пакетов, доступных через репозитории:

    # apt-get update

Установка TimescaleDB
---------------------

Установим пакет с расширением версии, подходящей к установленной версии PostgreSQL:

    # apt-get install timescaledb-2-postgresql-13

Прописываем в файл конфигруации `/etc/postgresql/13/main/postgresql.conf` в опцию `shared_preload_libraries` значение `timescaledb`:

    shared_preload_libraries = 'timescaledb'

Если у опции уже есть включенные расширения, то новые значения нужно добавлять через запятую:

    shared_preload_libraries = 'auth_delay, timescaledb'

Настройка TimescaleDB
---------------------

В конце файла конфигурации `/etc/postgresql/13/main/postgresql.conf` добавляем опции:

    timescaledb.telemetry_level = off
    timescaledb.max_background_workers = 8

Где:

* `telemetry_level` - уровень подробности [телеметрии](https://docs.timescaledb.com/using-timescaledb/telemetry), отправляемой разработчикам TimescaleDB, допустимо одно из двух значений `off` - выключено и `basic` - базовая информация,
* `max_background_workers` - максимальное количество фоновых процессов, рекомендуется выбирать на единицу больше, чем количество баз данных в PostgreSQL.

Для выбора значений настроек можно установить пакет `timescaledb-tools` и воспользоваться утилитой `timescaledb-tune`, входящей в его состав:

    # apt-get install timescaledb-tools
    # timescaledb-tune
    Using postgresql.conf at this path:
    /etc/postgresql/13/main/postgresql.conf
    
    Is this correct? [(y)es/(n)o]: y
    Writing backup to:
    /tmp/timescaledb_tune.backup202206291627
    
    success: shared_preload_libraries is set correctly
    
    Tune memory/parallelism/WAL and other settings? [(y)es/(n)o]: y
    Recommendations based on 1.94 GB of available memory and 1 CPUs for PostgreSQL 13
    
    Memory settings recommendations
    Current:
    shared_buffers = 1280MB
    #effective_cache_size = 4GB
    #maintenance_work_mem = 64MB
    #work_mem = 4MB
    Recommended:
    shared_buffers = 507618kB
    effective_cache_size = 1487MB
    maintenance_work_mem = 253809kB
    work_mem = 10152kB
    Is this okay? [(y)es/(s)kip/(q)uit]: y
    success: memory settings will be updated
    
    WAL settings recommendations
    Current:
    #wal_buffers = -1
    min_wal_size = 80MB
    Recommended:
    wal_buffers = 15227kB
    min_wal_size = 512MB
    Is this okay? [(y)es/(s)kip/(q)uit]: y
    success: WAL settings will be updated
    
    Miscellaneous settings recommendations
    Current:
    #default_statistics_target = 100
    #random_page_cost = 4.0
    #checkpoint_completion_target = 0.5
    max_connections = 100
    #max_locks_per_transaction = 64
    #autovacuum_max_workers = 3
    #autovacuum_naptime = 1min
    #effective_io_concurrency = 1
    Recommended:
    default_statistics_target = 500
    random_page_cost = 1.1
    checkpoint_completion_target = 0.9
    max_connections = 25
    max_locks_per_transaction = 64
    autovacuum_max_workers = 10
    autovacuum_naptime = 10
    effective_io_concurrency = 256
    Is this okay? [(y)es/(s)kip/(q)uit]: y
    success: miscellaneous settings will be updated
    Saving changes to: /etc/postgresql/13/main/postgresql.conf

Резервную копию конфигурации можно взять из файла `/tmp/timescaledb_tune.backup202206291627`, имя которого утилита сообщает в начале своей работы.

Для применения настроек нужно перезапустить сервер PostgreSQL:

    # systemctl restart postgresql

Резервное копирование и восстановление
--------------------------------------

Снимаем резервную копию, выполняя команду от имени пользователя `postgres`:

    $ pg_dump -d db | gzip db.sql.gz

Восстанавливаем резервную копию следующим образом также командами от имени пользователя `postgres` в следующей последовательности:

    $ createdb db -O owner
    $ psql -d db -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"
    $ psql -d db -c "SELECT timescaledb_pre_restore();"
    $ zcat db.sql.gz | psql -qd db
    $ psql -d db -c "SELECT timescaledb_post_restore();"

После создания пустой базы данных `db`, которой владеет пользователь `owner` нужно установить в базу данных расширение `timescaledb` версии, соотвесттвующей версии TimescaleDB в резервной копии. Далее нужно вызвать функцию `timescaledb_pre_restore` для подготовки к восстановлению, после чего восстановить базу данных и вызывать функцию `timescaledb_post_restore` для завершения резервного копирования.

Обновление TimescaleDB
----------------------

После восстановления базы данных можно обновить расширение до актуальной версии или до строго определённой с помощью запросов следующего вида:

    ALTER EXTENSION timescaledb UPDATE;
    ALTER EXTENSION timescaledb UPDATE TO '2.5.1';

Посмотреть список доступных версий расширения можно с помощью следующего запроса:

    SELECT name, version, installed
    FROM   pg_available_extension_versions
    WHERE  name = 'timescaledb';

При обновлении нужно руководствоваться таблицей совместимости PostgreSQL и TimescaleDB:

|Выпуск TimescaleDB|Поддерживаемые выпуски PostgreSQL|
|:----------------:|:-------------------------------:|
|1.7               |9.6, 10, 11, 12                  |
|2.0               |11, 12                           |
|2.1-2.3           |11, 12, 13                       |
|2.4               |12, 13                           |
|2.5+              |12, 13, 14                       |

Использованные материалы
------------------------

* [Installation instructions / Manual Installation / deb](https://packagecloud.io/timescale/timescaledb/install#manual-deb)
* [TimescaleDB / How-to Guides / Configuration / TimescaleDB configuration / TimescaleDB configuration and tuning](https://docs.timescale.com/timescaledb/latest/how-to-guides/configuration/timescaledb-config/#administration)
* [TimescaleDB / How-to Guides / Backup and restore / Using pg_dump/pg_restore / Logical backups with pg_dump and pg_restore](https://docs.timescale.com/timescaledb/latest/how-to-guides/backup-and-restore/pg-dump-and-restore/#backup-entiredb)
* [TimescaleDB / How-to Guides / Update TimescaleDB / TimescaleDB release compatibility](https://docs.timescale.com/timescaledb/latest/how-to-guides/update-timescaledb/#timescaledb-release-compatibility)
