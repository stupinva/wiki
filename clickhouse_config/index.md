Настройка ClickHouse
====================

Для настройки сервера ClickHouse используется XML-файл `/etc/clickhouse-server/config.xml`.

Настройка журналов
------------------

Для настройки журналирования используется секция `clickhouse`/`logger`:

    <clickhouse>
        <logger>
            <level>warning</level>
            <log>/var/log/clickhouse-server/clickhouse-server.log</log>
            <errorlog>/var/log/clickhouse-server/clickhouse-server.err.log</errorlog>
            <size>1000M</size>
            <count>10</count>
        </logger>
    </clickhouse>

Назначение опций:

* `level` - уровень журналирования: `test` - для использования только разработчиками, `trace`, `debug`, `information`, `notice`, `warning`, `error`, `critical`, `fatal`, `none` - отключение журналирования,
* `log` - файл журнала со всеми сообдениями уровня level,
* `errorlog` - файл журнала ошибок,
* `size` - размер одного файла журнала, по достижении которого ClickHouse продолжит ведение журнала в новом файле,
* `count` - количество архивных файлов журнала.

Также имеется возможность вести журнал через syslog. Подробности см. в официальной документации.

[Документация ClickHouse / Конфигурационные параметры сервера / logger](https://clickhouse.com/docs/ru/operations/server-configuration-parameters/settings/#server_configuration_parameters-logger)

Настройка доступа по протоколу MySQL
------------------------------------

Для включения доступа к серверу ClickHouse по протоколу MySQL можно добавить в секцию `clickhouse` опцию `mysql_port`:

    <clickhouse>
        <mysql_port>9004</mysql_port>
    </clickhouse>

[Документация ClickHouse / Конфигурационные параметры сервера / mysql_port](https://clickhouse.com/docs/ru/operations/server-configuration-parameters/settings/#server_configuration_parameters-mysql_port)

Настройка прослушиваемых адресов
--------------------------------

Для настройки прослушиваемых IP-адресов предназначена опция `listen_host`, которую можно указывать более одного раза:

    <clickhouse>
        <listen_host>::1</listen_host>
    </clickhouse>

Возможные варианты:

* `::` - прослушивание всех адресов IPv4 и IPv6,
* `0.0.0.0` - прослушивание всех адресов только IPv4,
* `::1` - прослушивание локального петлевого интерфейса IPv6,
* `127.0.0.1` - прослушивание локального петлевого интерфейса IPv4.

[Документация ClickHouse / Конфигурационные параметры сервера / listen_host](https://clickhouse.com/docs/ru/operations/server-configuration-parameters/settings/#server_configuration_parameters-listen_host)

Размер кэша несжатых данных
---------------------------

Для включения использования кэша несжатых данных и для настройки его размера предназначены следующие опции:

    <clickhouse>
        <use_uncompressed_cache>0</use_uncompressed_cache>
        <uncompressed_cache_size>8589934592</uncompressed_cache_size>
    </clickhouse>

Обратите внимание, что по умолчанию кэш несжатых данных отключен, а при включении его размер по умолчанию составит 8 гигабайт максимум. Кэш используется только для таблиц семейства MergeTree. Размер кэша будет увеличиваться по мере его наполнения, а по достижении максимального размера из него начнут удаляться наименее востребованные данные.

[Документация ClickHouse / Конфигурационные параметры сервера / use_uncompressed_cache](https://clickhouse.com/docs/ru/operations/settings/settings/#setting-use_uncompressed_cache)

[Документация ClickHouse / Конфигурационные параметры сервера / uncompressed_cache_size](https://clickhouse.com/docs/ru/operations/server-configuration-parameters/settings/#server-settings-uncompressed_cache_size)

Размер кэша засечек
-------------------

Для настройки размера кэша засечек используется опция `mark_cache_size` из секции `clickhouse`:

    <clickhouse>
        <mark_cache_size>5368709120</mark_cache_size>
    </clickhouse>

По умолчанию размер кэша ограничен 5 гигабайтами. Засечки являются разновидностью индексов, которые используются для таблиц семейства MergeTree. Каждая засечка в индексе соответствует некоторому количеству строк, упорядоченных по первичному ключу. Для поиска интересующих данных ClickHouse ищет засечки, между которыми могут находиться интересующие строки, после чего считывает и фильтрует сами строки. Размер кэша будет увеличиваться по мере его наполнения, а по достижении максимального размера из него начнут удаляться нименее востребованные засечки.

[Документация ClickHouse / Конфигурационные параметры сервера / mark_cache_size](https://clickhouse.com/docs/ru/operations/server-configuration-parameters/settings/#server-mark-cache-size)

Настройка журнала запросов
--------------------------

Для отключения всех журналов, которые ClickHouse ведёт в таблицах базы данных, кроме таблиц `query_log` и `query_thread_log`, можно воспользоваться такими опциями:

    <clickhouse>
        <asynchronous_metric_log remove="1"/>
        <metric_log remove="1"/>
        <part_log remove="1" />
        <session_log remove="1"/>
        <text_log remove="1" />
        <trace_log remove="1"/>
    </clickhouse>

Для отключения журналов, которые ClickHouse ведёт в таблицах `query_log` и `query_thread_log`, можно воспользоваться такими опциями, которые отключат ведение журналов на уровне настроек по умолчанию для всех пользователей:

    <clickhouse>
        <profiles>
            <default>
                <log_queries>0</log_queries>
                <log_query_threads>0</log_query_threads>
            </default>
        </profiles>
    </clickhouse>

Для настройки таблицы, в которой будет вестись журнал запросов, предназначена секция `yandex`/`query_log` файла конфигурации:

    <clickhouse>
        <query_log>
            <database>system</database>
            <table>query_log</table>
            <engine>Engine = MergeTree PARTITION BY event_date ORDER BY event_time TTL event_date + INTERVAL 30 day</engine>
            <flush_interval_milliseconds>7500</flush_interval_milliseconds>
        </query_log>
    </clickhouse>

Назначение опций:

* `database` - имя базы данных, в которой находится таблица журнала запросов,
* `table` - имя таблицы журнала запросов,
* `partition_by` - ключ секционирования таблицы, нельзя указывать вместе с опцией engine,
* `ttl` - настройки времени хранения записей в таблице, нельзя указывать вместе с опцией engine,
* `engine` - настройки таблицы семейства MergeTree, нельзя указывать вместе с опцией partition_by,
* `flush_interval_milliseconds` - интервал, с которым записи из буфера будут помещаться в таблицу.

Возможные значения опции partition_by:

* `toStartOfHour(event_time)` - почасовые секции,
* `event_date` - посуточные секции,
* `toMonday(event_date)` - понедельные секции, каждая секция начинается с понедельника и заканчивается воскресеньем,
* `toYYYYMM(event_date)` - помесячные секции.

Значения опции ttl можно указывать, например, в следующем виде: `event_date + INTERVAL 30 DAY DELETE`.

Для настройки таблицы, в которой будет вестись журнал выполнения запросов отдельными потоками, предназначена секция `yandex`/`query_thread_log`, которая настраивается полностью аналогично предыдущей таблице.

Рекомендуется использовать посуточные секции и опцию таблицы `SETTING ttl_only_drop_parts = 1`, которая предписывает не вычищать из таблицы устаревшие записи поотдельности, а удалять устаревшие секции целиком.

[Документация ClickHouse / Конфигурационные параметры сервера / query_log](https://clickhouse.com/docs/ru/operations/server-configuration-parameters/settings/#server_configuration_parameters-query-log)

[Altinity Knowledge Base / System tables eat my disk](https://kb.altinity.com/altinity-kb-setup-and-maintenance/altinity-kb-system-tables-eat-my-disk/)

Включение управлния доступом через SQL-запросы
----------------------------------------------

По умолчанию список пользователей и их права настраиваются с помощью файла `/etc/clickhouse-server/users.xml`. Однако ClickHouse умеет хранить эту информацию в базе данных. Для включения этой функциональности нужно вписать в файл конфигурации
