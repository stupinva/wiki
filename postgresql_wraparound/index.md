Исчерпание номеров транзакций в PostgreSQL
==========================================

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

Первым делом найдём проблемную базу данных. Следующий запрос может помочь обнаружить базы данных, автовакуум в которых не срабатывает должным образом:

    SELECT datname,
           age(datfrozenxid),
           current_setting('autovacuum_freeze_max_age')
    FROM pg_database
    ORDER BY 2 DESC;

Если значение во второй превышает значение из третьей колонки, то имеются проблемы с автоматическим вакуумом в этой базе данных.

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

Большие значеия age указывают на то, что автовакуум по каким-то причинам не срабатывает. С помощью следующего запроса можно найти осиротевшие и просроченные подготовленные транзакции:

    SELECT age(transaction), * FROM pg_prepared_xacts;

Устранение проблемы
-------------------

Если обнаружены осиротевшие или просроченные подготовленные транзакции, их можно заверршить с помощью следующего запроса, подставив на место `<gid>` идентификатор из результатов, выведенных предыдущим запросом:

    ROLLBACK PREPARED <gid>;

Для того, чтобы запустить полный вакуум таблицы, можно воспользоваться следующим запросом, подставив вместо `<table>` имя таблицы:

    VACUUM FULL FREEZE ANALYSE <table>;

Учтите, что во время выполнения этого запроса таблица будет недоступна для изменений.

Устранение аварии
-----------------

Наконец, если проблема не была устранена заранее и база данных всё-таки перешла в режим "только чтение", можно попробовать описанные выше операции. Более кардинальное решение заключается в выполнении сжатия баз данных целиком, в однопользовательском режиме. Для этого нужно сначала остановить СУБД:

    # systemctl stop postgresql

А затем запустить однопользовательский сервер, указав в конце команды имя базы данных, которую собираемся сжимать:

    # /usr/lib/postgresql/10/bin/postgres --single -D /var/lib/postgresql/10/main -c config_file=/etc/postgresql/10/main/postgresql.conf redqueen

В запустившейся диалоговой среде введём команду сжатия базы данных:

    VACUUM FULL VERBOSE;

В зависимости от производительности сервера, его загруженности, настроек СУБД, объёма и структуры базы данных, сжатие может занять продолжительное время, в течение которого ни одна из баз данных не будет доступна.

Настройка автовакуума
---------------------

Источники
---------

* [Nishchay Kothari. How to fix transaction wraparound in PostgreSQL?](https://www.postgresql.fastware.com/blog/how-to-fix-transaction-wraparound-in-postgresql)
* [Keith Fiske. Managing Transaction ID Exhaustion (Wraparound) in PostgreSQL](https://www.crunchydata.com/blog/managing-transaction-id-wraparound-in-postgresql)
* [David Cramer. Transaction ID Wraparound in Postgres](https://blog.sentry.io/transaction-id-wraparound-in-postgres/)
* [Joe Wilm. Challenges and Solutions When Scaling PostgreSQL](https://onesignal.com/blog/lessons-learned-from-5-years-of-scaling-postgresql/)
