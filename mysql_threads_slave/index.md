Настройка многопоточной репликации MySQL
========================================

Для настройки репликации в несколько потоков нужно дописать в секцию `[mysqld]` файла конфигурации сервера (например, /etc/my.cnf), следующие опции:

    slave_parallel_type = LOGICAL_CLOCK
    slave_preserve_commit_order = ON
    slave_parallel_workers = 40
    log_slave_updates = 1
    log_bin = /var/lib/mysql/mysql-bin
    expire_logs_days = 1

Где:

* `slave_parallel_type` - тип параллельной репликации. Возможны только значения `DATABASE` и `LOGICAL_CLOCK`. Значение `DATABASE` позволяет настроить параллельную репликацию разных баз данных, при этом каждая из них реплицируется в один поток. Значение `LOGICAL_CLOCK` - параллельное применение транзакций из одной группы в журнале репликации.
* `slave_preseve_commit_order` - опция указывает, нужно ли сохранять порядок транзакций при многопоточной репликции, однако эта опция не действует на транзакции с операциями, отличными от SELECT, INSERT, UPDATE и DELETE.
* `slave_parallel_workers` - указывает количество потоков, которые будут применять обновления из журнала репликации.

В MySQL 8.0 переменные переименованы в `replica_parallel_type`, `replica_preserve_commit_order` и `replica_parallel_workers` (видимо, в связи с переходом на инклюзивную терминологию).

Для работы многопоточной репликации понадобится включить ведение журналов репликации на подчинённом сервере. Для этого используются следующие опции:

* `log_slave_updates` - включение записи журналов репликации на подчинённом сервере,
* `log_bin` - префикс имён файлов журналов репликации, к которому через точку будут добавляться порядковые номера частей,
* `expire_logs_days` - указывает, сколько дней хранить журналы репликации. Файлы старше будут автоматически удаляться.

Оценить количество простаивающих потоков репликации можно при помощи следующего запроса:

    SELECT COUNT(*)
    FROM information_schema.processlist
    WHERE user = 'system user'
      AND state = 'Waiting for an event from Coordinator';

Для изменения количества потоков репликации без перезапуска сервера можно воспользоваться такими запросами:

    STOP SLAVE SQL_THREAD;
    SET GLOBAL slave_parallel_workers = 8;
    START SLAVE SQL_THREAD;

Использованные материалы
------------------------

* [Tibor Korocz. Can MySQL Parallel Replication Help My Slave?](https://www.percona.com/blog/2018/10/17/can-mysql-parallel-replication-help-my-slave/)
* [Stephane Combaudon. Estimating potential for MySQL 5.7 parallel replication](https://www.percona.com/blog/2016/02/10/estimating-potential-for-mysql-5-7-parallel-replication/)
* [califdon. mysql multithreaded replication](https://programmer.help/blogs/mysql-multithreaded-replication.html)
* [MySQL 5.7 Reference Manual / Replica Server Options and Variables](https://dev.mysql.com/doc/refman/5.7/en/replication-options-replica.html)
* [MySQL 8.0 Reference Manual / Replica Server Options and Variables](https://dev.mysql.com/doc/refman/8.0/en/replication-options-replica.html)
* [MySQL 8.0 Reference Manual / The INFORMATION_SCHEMA PROCESSLIST Table](https://dev.mysql.com/doc/refman/8.0/en/information-schema-processlist-table.html)
* [MySQL 8.0 Reference Manual / Replication SQL Thread States](https://dev.mysql.com/doc/refman/8.0/en/replica-sql-thread-states.html)
