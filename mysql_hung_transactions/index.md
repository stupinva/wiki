Решение проблем с длиной истории InnoDB при зависании транзакций MySQL
======================================================================

[[!tag mysql innodb]]

Это перевод статьи: [Troubleshooting InnoDB History Length with Hung MySQL Transaction](https://minervadb.xyz/troubleshooting-innodb-history-length-with-hung-mysql-transaction/)

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

В этой статье подробно объясняется, как зависание транзакции может привести к неконтролируемому росту длины истории InnoDB и отрицательно сказаться на производительности MySQL. Иногда к нам в MinervaDB поступают звонки о чрезвычайных ситуациях, в которых запросы SELECT выполняются всё медленнее и медленнее. В конце-концов заказчики перезагружают сервер MySQL, но это не решает проблем с производительностью MySQL. В заявках перечисляются признаки проблемы, сбивающие с толку (обычно вначале тратится время на анализ производительности запроса и на создание индексов, но это не даёт результата) и лишь позднее, после команды "SWOW ENGINE InnoDB STATUS", ситуация несколько проясняется. Вот фрагмент вывода этой команды:

    Trx read view will not see trx with id >= 75163496241, sees < 53179273519
    ---TRANSACTION 75392513195, ACTIVE 915248 sec 5 lock struct(s), heap size 81751, 3 row lock(s), undo log entries 2 ...

Воспроизведение проблемы
------------------------

Мы попробовали воспроизвести проблему с помощью sysbench (для этого мы воспользовались скриптом Sysbench от Percona):

    conn=" --db-driver=mysql --mysql-host=localhost --mysql-user=user --mysql-password=password --mysql-db=sbtest " sysbench --test=/usr/share/sysbench/tests/include/oltp_legacy/oltp.lua --mysql-table-engine=InnoDB --oltp-table-size=20000000$conn prepare sysbench --num-threads=64 --max-requests=0 --max-time=240 --test=/usr/share/sysbench/tests/include/oltp_legacy/oltp.lua --oltp-table-size=20000000$conn --oltp-test-mode=complex --oltp-point-selects=0 --oltp-simple-ranges=0 --oltp-sum-ranges=0 --oltp-order-ranges=0 --oltp-distinct-ranges=0 --oltp-index-updates=1 --oltp-non-index-updates=0 run

Указанный выше вывод натолкнул на мысль проверить значение [InnoDB_history_list_length](https://planet.mysql.com/entry/?id=5991415):

    mdbperflab> show status like 'Innodb_history_list_%';
    +----------------------------+-------+
    | Variable_name              | Value |
    +----------------------------+-------+
    | Innodb_history_list_length | 7625  |
    +----------------------------+-------+
    1 row in set (0.00 sec)

Если история транзакций InnoDB непрерывно растёт, запросам SELECT нужно просматривать всё больше и больше предыдущих версий строк. Это приводит к появлению важного узкого места. Но почему InnoDB_history_list_length непрерывно растёт? В данном случае есть 1278 активных транзакций, которые находятся в таком состоянии 915248 секунд. В списке процессов MySQL они отображаются в спящем состоянии “Sleep”, что ясно говорит о том, что эти транзакции либо потеряны, либо зависли. Также можно заметить, что каждая из этих транзакций удерживает две структуры блокировки и одну запись отмены, которые не были ни подтверждены, ни отменены. Эти транзакции ничего не делают. Это происходит потому, что в InnoDB по умолчанию используется [уровень изоляции транзакций REPEATABLE-READ](https://minervadb.com/index.php/2018/02/21/innodb-transaction-isolation-level/) - воспроизводимое чтение. InnoDB - это многоверсионное хранилище и это означает, что можно начать транзакцию и видеть непротиворечивый снимок данных, даже если впоследствии они уже были изменены. Для этого старые версии строк сохраняются перед их изменением. Поэтому список истории InnoDB - это журнал отмен, который исползуется для хранения таких изменений. Они являются основополагающим элементом в архитектуре обработки транзакций InnoDB.

Как измерить список истории InnoDB и в каких единицах он измеряется?
--------------------------------------------------------------------

Что на самом деле означает длина списка истории InnoDB 7625?

Это очень противоречивая тема, поскольку существует несколько интерпретаций единиц длины списка истории InnoDB:

- неочищенные версии старых строк
- неочищенные транзакции в пространстве отмены
- изменения базы данных
- сегменты отмены
- незаписанные сегменты в журнале отмены
- страницы отмены или количество страниц в журнале отмены
- журналы отмены

Так что же это на самом деле?

Обратимся к первоисточнику:

- [Вот где выводится значение из trx_sys->rseg_history_len](https://github.com/mysql/mysql-server/blob/09ddec8757b57893ccd2f2c2482b3eec5ca811e5/storage/innobase/lock/lock0lock.cc#L4833-L4835)
- [Которое определено здесь](https://github.com/mysql/mysql-server/blob/09ddec8757b57893ccd2f2c2482b3eec5ca811e5/storage/innobase/include/trx0sys.h#L610)
- [И изменяется в этом и других местах](https://github.com/mysql/mysql-server/blob/09ddec8757b57893ccd2f2c2482b3eec5ca811e5/storage/innobase/trx/trx0purge.cc#L373)
- [Использование параметра для функции с именем trx_purge_add_update_undo_to_history, которая вызывается только тут](https://github.com/mysql/mysql-server/blob/09ddec8757b57893ccd2f2c2482b3eec5ca811e5/storage/innobase/trx/trx0undo.cc#L1954)
- [Которая вызывается из этого и множества других мест](https://github.com/mysql/mysql-server/blob/09ddec8757b57893ccd2f2c2482b3eec5ca811e5/storage/innobase/trx/trx0trx.cc#L1654)

Благодаря ей можно узнать многое о внутреннем устройстве InnoDB.

Наиболее подходящим названием для единицы журнала отмены, согласно исходным текстам, будет “обновление журнала отмен для подтверждённых транзакций”. Но “журнал отмен” - это специальный термин с особым смыслом в InnoDB. Журнал отмен - это единое множество атомарных изменений, выполненных транзакцией, которые на самом деле могли изменить несколько строк.

Решение проблем с историей транзакций InnoDB
--------------------------------------------

Ниже приведены уровни изоляции транзакций InnoDB и как они действуют на длину истории InnoDB:

|Версия MySQL|Уровень изоляции транзакций|Длина истории InnoDB                                                        |
|:-----------|---------------------------|----------------------------------------------------------------------------|
|MySQL 5.6   |Воспроизводимое чтение     |История InnoDB не очищается, пока не завершится зависшая транзакция         |
|MySQL 5.6   |Воспроизводимое чтение     |История InnoDB очищается (это решение работает у большинства наших клиентов)|
|Aurora      |Воспроизводимое чтение     |История InnoDB не очищается, пока не завершится зависшая транзакция         |
|Aurora      |Воспроизводимое чтение     |История InnoDB не очищается, пока не завершится зависшая транзакция         |

InnoDB на уровне изоляции транзакций [READ COMMITTED](https://minervadb.com/index.php/2018/02/21/innodb-transaction-isolation-level/) не нужно поддерживать длину истории, если в других транзакциях имеются подтверждённые изменения. Такая настройка работает для решения проблем с длиной истории InnoDB в MySQL 5.6 и более поздних. **Эта рекомендация (уровень изоляции транзакций READ COMMITTED) не работает в случае с Amazon Aurora, где длина истории продолжает расти.**

Отслеживание зависших транзакций и списка запросов
--------------------------------------------------

Есть несколько способов обнаружения узких мест производительности транзакций и запросов, применимых к тому же MySQL:

- Журнал медленных запросов MySQL
- [Плагин Audit Log для Percona Server](This recommendation - READ COMMITTED isolation level - doesn’t work with Amazon Aurora, the history length still continues to grow.) (Если используется Percona Server для MySQL)
- [Общий журнал запросов MySQL](https://dev.mysql.com/doc/refman/8.0/en/query-log.html)
- [Утилита Percona Monitoring and Management](https://www.percona.com/software/database-tools/percona-monitoring-and-management)
- [Performance Schema](https://dev.mysql.com/doc/refman/8.0/en/performance-schema.html)

Поиск запросов в зависших транзакциях с использованием Performance Schema

Чтобы найти зависшие запросы в MySQL с использованием Performance Schema, воспользуйтесь следующей последовательностью действий:

- Включите Performance Schema
- Включите **events_statement_history**

        mysql> UPDATE performance_schema.setup_consumers SET enabled = 'YES' WHERE name = 'events_statements_history';
        Query OK, 1 row affected (0.00 sec)
        Rows matched: 1 Changed: 1 Warnings: 0

Чтобы найти все транзакции, начавшиеся более 60 секунд назад, воспользуйтесь следующим запросом:

    SELECT ps.id as processlist_id,
           trx_started,
           trx_isolation_level,
           esh.EVENT_ID,
           esh.TIMER_WAIT,
           esh.event_name as EVENT_NAME,
           esh.sql_text as SQL,
           esh.RETURNED_SQLSTATE,
           esh.MYSQL_ERRNO,
           esh.MESSAGE_TEXT,
           esh.ERRORS,
           esh.WARNINGS
    FROM information_schema.innodb_trx trx
    JOIN information_schema.processlist ps ON trx.trx_mysql_thread_id = ps.id
    LEFT JOIN performance_schema.threads th ON th.processlist_id = trx.trx_mysql_thread_id
    LEFT JOIN performance_schema.events_statements_history esh ON esh.thread_id = th.thread_id
    WHERE trx.trx_started < CURRENT_TIME - INTERVAL 60 SECOND
      AND ps.USER != 'SYSTEM_USER'
    ORDER BY esh.EVENT_ID\G
    
    *************************** 1. row ***************************
         processlist_id: 5420618
            trx_started: 2016-05-18 18:41:30
    trx_isolation_level: READ COMMITTED
               EVENT_ID: 1
             TIMER_WAIT: 66057000
             EVENT_NAME: statement/sql/select
                   SSQL: select @@version_comment limit 1
      RETURNED_SQLSTATE: NULL
            MYSQL_ERRNO: 0
           MESSAGE_TEXT: NULL
                 ERRORS: 0
               WARNINGS: 0
    *************************** 2. row ***************************
         processlist_id: 5420618
            trx_started: 2016-05-18 18:41:56
    trx_isolation_level: READ COMMITTED
               EVENT_ID: 2
             TIMER_WAIT: 135117000
             EVENT_NAME: statement/sql/show_processlist
                   SSQL: show processlist
      RETURNED_SQLSTATE: NULL
            MYSQL_ERRNO: 0
           MESSAGE_TEXT: NULL
                 ERRORS: 0
               WARNINGS: 0
    2 rows in set (0.01 sec)

*Примечание: Измените количество секунд в соответствии с нагрузкой системы.*

Заключение
----------

Зависшие транзакции в InnoDB приводят к неконтролируемому росту длины истории InnoDB, что непосредственно отрицательно сказывается на производительности запросов SELECT в MySQL. У нескольких клиентов проблема была решена изменением TRANSACTION ISOLATION LEVEL на READ-COMMITTED. Технически, длина истории InnoDB - это журналы отмены, которые могут быть использованы для повторного создания истории для задач многоверсионности или могут быть отменены. Просим поделиться комментариями!

Ссылки:

- [https://planet.mysql.com/](https://planet.mysql.com/)
- Уровни изоляции транзакций InnoDB - [https://minervadb.com/index.php/2018/02/21/innodb-transaction-isolation-level/](https://minervadb.com/index.php/2018/02/21/innodb-transaction-isolation-level/)
- [https://www.xaprb.com](https://www.xaprb.com)
- [http://blog.jcole.us/2014/04/16/the-basics-of-the-innodb-undo-logging-and-history-system/](http://blog.jcole.us/2014/04/16/the-basics-of-the-innodb-undo-logging-and-history-system/)
- [http://vividcortex.com/](http://vividcortex.com/)
- [https://www.percona.com/blog/2014/10/17/innodb-transaction-history-often-hides-dangerous-debt/](https://www.percona.com/blog/2014/10/17/innodb-transaction-history-often-hides-dangerous-debt/)
