Исчерпание номеров транзакций в PostgreSQL
==========================================

[[!tag postgresql]]

Содержание
----------

[[!toc startlevel=1 levels=4]]

Введение
--------

При исчерпании свободных идентификаторов транзакций в журнале PostgreSQL, например в `/var/log/postgresql/postgresql-10-main.log`, начнут появляться предупреждающие сообщения следующего вида:

    2023-08-27 23:41:20.242 +05 [1496] redqueen@redqueen WARNING:  database "redqueen" must be vacuumed within 11000000 transactions
    2023-08-27 23:41:20.242 +05 [1496] redqueen@redqueen HINT:  To avoid a database shutdown, execute a database-wide VACUUM in that database.
            You might also need to commit or roll back old prepared transactions.

Если не обращать внимание на эти предупреждения и не предпринять своевременных мер по устранению проблемы, то проблемная база данных перейдёт в режим "только чтение":

    2023-08-28 03:33:50.341 +05 [19781] redqueen@redqueen WARNING:  database "redqueen" must be vacuumed within 1000001 transactions
    2023-08-28 03:33:50.341 +05 [19781] redqueen@redqueen HINT:  To avoid a database shutdown, execute a database-wide VACUUM in that database.
            You might also need to commit or roll back old prepared transactions.
    2023-08-28 03:33:50.341 +05 [6557] redqueen@redqueen ERROR:  database is not accepting commands to avoid wraparound data loss in database "redqueen"
    2023-08-28 03:33:50.341 +05 [6557] redqueen@redqueen HINT:  Stop the postmaster and vacuum that database in single-user mode.
            You might also need to commit or roll back old prepared transactions.

Своевременное обнаружение проблемы
----------------------------------

Для своевременного обнаружения проблемы на уровне СУБД можно поставить на контроль в систему мониторинга значение, возвращаемое следующим запросом:

    SELECT MIN(power(2, 31) - age(datfrozenxid)) AS remaining
    FROM pg_database;

Если это значение опускается ниже порогового значения 11000000, при котором в журнале PostgreSQL начинают появляться предупреждения, значит пора локализовать и устранить проблему.

Поиск источника проблемы
------------------------

Первым делом найдём проблемную базу данных. Следующий запрос может помочь обнаружить базы данных, автоматическая очистка в которых не срабатывает должным образом:

    SELECT datname,
           age(datfrozenxid),
           current_setting('autovacuum_freeze_max_age')
    FROM pg_database
    ORDER BY 2 DESC;

Если значение во второй превышает значение из третьей колонки, то имеются проблемы с автоматическим очисткой в этой базе данных.

Или можно сразу посмотреть список проблемных баз данных:

    SELECT datname,
           age(datfrozenxid),
           current_setting('autovacuum_freeze_max_age')
    FROM pg_database
    WHERE age(datfrozenxid)::bigint > current_setting('autovacuum_freeze_max_age')::bigint
    ORDER BY 2 DESC;

Теперь, когда известны проблемные базы данных, можно найти в них проблемные таблицы:

    SELECT c.relnamespace::regnamespace AS schema_name,
           c.relname as table_name,
           greatest(age(c.relfrozenxid), age(t.relfrozenxid)) AS age,
           2^31 - 1000000 - greatest(age(c.relfrozenxid), age(t.relfrozenxid)) AS remaining
    FROM pg_class c LEFT JOIN pg_class t ON c.reltoastrelid = t.oid
    WHERE c.relkind IN ('r', 'm')
    ORDER BY 4;

Большие значеия `age` указывают на то, что автоматическая очистка по каким-то причинам не срабатывает. С помощью следующего запроса можно найти осиротевшие и просроченные подготовленные транзакции:

    SELECT age(transaction), * FROM pg_prepared_xacts;

Устранение проблемы
-------------------

Если обнаружены осиротевшие или просроченные подготовленные транзакции, их можно заверршить с помощью следующего запроса, подставив на место `<gid>` идентификатор из результатов, выведенных предыдущим запросом:

    ROLLBACK PREPARED <gid>;

Для того, чтобы запустить полную очистку таблицы, можно воспользоваться следующим запросом, подставив вместо `<table>` имя таблицы:

    VACUUM FULL FREEZE ANALYSE <table>;

Учтите, что во время выполнения этого запроса таблица будет недоступна для изменений.

Устранение аварии
-----------------

Наконец, если проблема не была устранена заранее и база данных всё-таки перешла в режим "только чтение", можно попробовать описанные выше операции. Более кардинальное решение заключается в выполнении очистки баз данных целиком, в однопользовательском режиме. Для этого нужно сначала остановить СУБД:

    # systemctl stop postgresql

А затем запустить однопользовательский сервер, указав в конце команды имя базы данных, которую собираемся сжимать:

    # /usr/lib/postgresql/10/bin/postgres --single -D /var/lib/postgresql/10/main -c config_file=/etc/postgresql/10/main/postgresql.conf redqueen

В запустившейся диалоговой среде введём команду очистки базы данных:

    VACUUM FULL VERBOSE;

В зависимости от производительности сервера, его загруженности, настроек СУБД, объёма и структуры базы данных, очистка может занять продолжительное время, в течение которого ни одна из баз данных не будет доступна.

Настройка автоматической очистки
--------------------------------

При настройке автоматической очистки рекомендуется обратить внимание на следующие настройки:

    autovacuum_freeze_max_age = 500000000
    autovacuum_max_workers = 6
    autovacuum_naptime = '15s'
    autovacuum_vacuum_cost_delay = 0
    maintenance_work_mem = '10GB'
    vacuum_freeze_min_age = 10000000

Для подбора подходящих значений можно воспользоваться утилитой `timescaledb-tune` из пакета `timescaledb-tools`. Ниже приведено объяснение каждого из значений из документации.

### autovacuum_freeze_max_age (integer)

Задаёт максимальный возраст (в транзакциях) для поля `pg_class.relfrozenxid` некоторой таблицы, при достижении которого будет запущена операция `VACUUM` для предотвращения зацикливания идентификаторов транзакций в этой таблице. Заметьте, что система запустит процессы автоочистки для предотвращения зацикливания, даже если для всех других целей автоочистка отключена.

При очистке могут также удаляться старые файлы из подкаталога `pg_xact`, поэтому значение по умолчанию сравнительно мало - 200 миллионов транзакций. Задать этот параметр можно только при запуске сервера, но для отдельных таблиц его можно определить по-другому, изменив их параметры хранения.

### autovacuum_max_workers (integer)

Задаёт максимальное число процессов автоочистки (не считая процесс, запускающий автоочистку), которые могут выполняться одновременно. По умолчанию это число равно трём. Задать этот параметр можно только при запуске сервера.

### autovacuum_naptime (integer)

Задаёт минимальную задержку между двумя запусками автоочистки для отдельной базы данных. Демон автоочистки проверяет базу данных через заданный интервал времени и выдаёт команды `VACUUM` и `ANALYZE`, когда это требуется для таблиц этой базы. Если это значение задаётся без единиц измерения, оно считается заданным в секундах. По умолчанию задержка равна одной минуте (1min). Этот параметр можно задать только в `postgresql.conf` или в командной строке при запуске сервера.

### autovacuum_vacuum_cost_delay (floating point)

Задаёт задержку при превышении предела стоимости, которая будет применяться при автоматических операциях `VACUUM`. Если это значение задаётся без единиц измерения, оно считается заданным в миллисекундах. При значении -1 применяется обычная задержка `vacuum_cost_delay`. Значение по умолчанию - 2 миллисекунды. Задать этот параметр можно только в `postgresql.conf` или в командной строке при запуске сервера. Однако его можно переопределить для отдельных таблиц, изменив их параметры хранения.

### maintenance_work_mem (integer)

Задаёт максимальный объём памяти для операций обслуживания БД, в частности `VACUUM`, `CREATE INDEX` и `ALTER TABLE ADD FOREIGN KEY`. Если это значение задаётся без единиц измерения, оно считается заданным в килобайтах. Значение по умолчанию - 64 мегабайта (64MB). Так как в один момент времени в сеансе может выполняться только одна такая операция и обычно они не запускаются параллельно, это значение вполне может быть гораздо больше `work_mem`. Увеличение этого значения может привести к ускорению операций очистки и восстановления БД из копии.

Учтите, что когда выполняется автоочистка, этот объём может быть выделен `autovacuum_max_workers` раз, поэтому не стоит устанавливать значение по умолчанию слишком большим. Возможно, будет лучше управлять объёмом памяти для автоочистки отдельно, изменяя `autovacuum_work_mem`.

Заметьте, что для сбора идентификаторов мёртвых кортежей `VACUUM` может использовать не более 1GB памяти.

### vacuum_freeze_min_age (integer)

Задаёт возраст для отсечки (в транзакциях), при достижении которого команда `VACUUM` должна замораживать версии строк при сканировании таблицы. Значение по умолчанию - 50 миллионов транзакций. Хотя пользователи могут задать любое значение от нуля до одного миллиарда, в `VACUUM` введён внутренний предел для действующего значения, равный половине `autovacuum_freeze_max_age`, чтобы принудительная автоочистка выполнялась не слишком часто.

Источники
---------

* [Nishchay Kothari. How to fix transaction wraparound in PostgreSQL?](https://www.postgresql.fastware.com/blog/how-to-fix-transaction-wraparound-in-postgresql)
* [Keith Fiske. Managing Transaction ID Exhaustion (Wraparound) in PostgreSQL](https://www.crunchydata.com/blog/managing-transaction-id-wraparound-in-postgresql)
* [David Cramer. Transaction ID Wraparound in Postgres](https://blog.sentry.io/transaction-id-wraparound-in-postgres/)
* [Joe Wilm. Challenges and Solutions When Scaling PostgreSQL](https://onesignal.com/blog/lessons-learned-from-5-years-of-scaling-postgresql/)
* [Документация PostgresPro Standard 15 / 18.4.1. Память](https://postgrespro.ru/docs/postgrespro/15/runtime-config-resource)
* [Документация PostgresPro Standard 15 / 18.10. Автоматическая очистка](https://postgrespro.ru/docs/postgrespro/15/runtime-config-autovacuum)
* [Документация PostgresPro Standard 15 / 18.11.1. Поведение команд](https://postgrespro.ru/docs/postgrespro/15/runtime-config-client)
* [Алексей Лесовский. Давайте отключим vacuum?!](https://habr.com/ru/articles/501516/)
