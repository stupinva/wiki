Поиск медленных запросов с помощью pg_stat_statements в PostgreSQL
==================================================================

[[!tag postgresql pg_stat_statements debian bullseye]]

Расширение `pg_stat_statements` предназначено для сбора и агрегации статистики по запросам, выполнявшимся в PostgreSQL.

Для включения расширения нужно вписать его в опцию `shared_preload_libraries` в файле конфигурации `/etc/postgresql/13/main/postgresql.conf`, например, следующим образом:

    shared_preload_libraries = 'auth_delay, timescaledb, pg_stat_statements, pg_repack'

После включения расширения нужно перезапустить СУБД:

    # systemctl restart postgresql

Теперь нужно включить расширение на уровне баз данных. Для этого, подключившись к определённой базе данных, нужно выполнить запрос следующего вида:

    CREATE EXTENSION pg_stat_statements;

У меня под рукой был почти готовый сценарий оболочки, с помощью которого, после его доработки, я включил сбор и агрегацию статистики во всех базах данных:


    #!/bin/sh
    
    pgsql() {
    psql -d "$1" -Aqt <<END
    SET SESSION statement_timeout = 0;
    $2
    END
    }
    
    pgsql "postgres" "
            SELECT datname
            FROM pg_database
            WHERE datistemplate = false
            ORDER BY datname;" \
            | while read database ; do
                    echo "$database: checking extension pg_stat_statements"
                    pgstat=`pgsql "$database" "
                            SELECT COUNT(*)
                            FROM pg_catalog.pg_extension e
                            WHERE e.extname = 'pg_stat_statements';"`
                    if [ "$pgstat" != "1" ]; then
                            echo "$database: installing extension pg_stat_statements"
                            pgsql "$database" "
                                    CREATE EXTENSION pg_stat_statements;"
                    fi
    
            done

Теперь можно подключиться к PostgreSQL и извлекать статистику, например, с помощью такого запроса:

    SELECT pg_stat_statements.total_exec_time,
           pg_database.datname,
           pg_stat_statements.query
    FROM pg_stat_statements
    JOIN pg_database ON pg_database.oid = pg_stat_statements.dbid
    ORDER BY pg_stat_statements.total_exec_time desc
    LIMIT 10;

После изменения индексов и оптимизации запроса имеет смысл сбросить накопившуюся статистику, чтобы определить новых лидеров. Для сброса статистики можно воспользоваться функцией `pg_stat_statements_reset`, вызвав её следующим образом:

    SELECT pg_stat_statements_reset();

Использованные материалы
------------------------

* [Документация к PostgreSQL 13.10 / Часть VIII. Приложения / Приложение F. Дополнительно поставляемые модули / F.29. pg_stat_statements](https://postgrespro.ru/docs/postgresql/13/pgstatstatements)
