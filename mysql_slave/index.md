Настройка реплики в MySQL
=========================

[[!tag mysql]]

Прописываем в секцию `[mysqld]` файла конфигурации сервера MySQL (например, `/etc/my.cnf`), следующие опции:

    server_id = 2
    relay_log = /var/lib/mysql/mysql-relay-bin
    relay_log_index = /var/lib/mysql/mysql-relay-bin.index
    relay_log_space_limit = 10G
    replicate_do_db = db
    slave_transaction_retries = 20

Назначение опций:

* `server_id` - идентификатор сервера, должен отличаться от идентификатора источника и других реплик,
* `relay_log` - префикс имён файлов журналов репликации подчинённого сервера, к которому через точку будут добавляться порядковые номера частей,
* `relay_log_index` - файл, в который будет записан индекс файлов журналов репликации,
* `relay_log_space_limit` - ограничение на объём журналов репликации, полученных с сервера-источника,
* `replicate_do_db` - реплицируемая база данных. При необходимости можно указать опцию несколько раз,
* `replicate_ignore_db` - база данных, репликация которой не будет выполняться. При необходимости можно указать опцию несколько раз. Опция игнорируется, если список реплицируемых баз данных явным образом указан с помощью опции `replicate_do_db`,
* `replicate_do_table` - реплицируемая таблица в виде `db.table`. Опцию можно указать несколько раз. Опция игнорируется, если указана одна из опций `replicate_do_db` или `replicate_ignore_db`,
* `replicate_ignore_table` - таблица в виде `db.table`, репликация которой не будет выполняться. Опцию можно указать несколько раз. Опция игнорируется, если указана одна из опций `replicate_do_db`, `replicate_ignore_db` или `replicate_do_table`,
* `replicate_wild_do_table` - шаблон реплицируемых таблиц в виде, пригодном для подстановки в оператор LIKE. Опцию можно указать несколько раз. Опция будет игнорироваться, если указана одна из опций `replicate_do_db` или `replicate_ignore_db`,
* `replicate_wild_ignore_table` - шаблон таблиц в виде, пригодном для подстановки в оператор LIKE, репликация которых не будет выполняться. Опцию можно указать несколько раз. Опция будет игнорироваться, если указана одна из опций `replicate_do_db`, `replicate_ignore_db` или `replicate_wild_do_table`,
* `slave_transaction_retries` (начиная с MySQL 8.0 - `replica_transaction_retries`) - количество попыток повторить выполнение транзакции из журнала репликации при ошибках блокировки и т.п. По умолчанию 10.

После редактирования файла конфигурации перезапускаем сервер:

    # systemctl restart mysql

Запуск репликации
-----------------

После восстановления базы данных из резервной копии нужно выставить настройки для отслеживания изменений в источнике:

    CHANGE MASTER TO MASTER_HOST = '192.168.1.1',
                     MASTER_USER = 'slave',
                     MASTER_PASSWORD = 'password',
                     MASTER_LOG_FILE = 'mysql-bin.000126',
                     MASTER_LOG_POS = 1038494360;

Значения опций `MASTER_LOG_FILE` и `MASTER_LOG_POS` должны соответствовать значениям, которые были текущими на источнике в момент создания резервной копии.

После выставления настроек источника можно запускать репликацию:

    START SLAVE;

Отслеживать состояние процесса репликации можно с помощью слеующей команды:

    SHOW SLAVE STATUS\G

Настройка промежуточного сервера
--------------------------------

Если сервер-реплика сам будет выступать в качестве источника для одного или нескольких других серверов, то нужно разрешить и настроить ведение журналов:

    log_slave_updates = 1
    log_bin = /var/lib/mysql/mysql-bin
    log_bin_index = /var/lib/mysql/mysql-bin.index
    binlog_format = ROW
    binlog_expire_logs_seconds = 86400

Где:

* `log_slave_updates` - булева опция, разрешающая серверу-реплике вести собственные журналы,
* `log_bin` - префикс имён файлов журналов репликации, к которому через точку будут добавляться порядковые номера частей,
* `log_bin_index` - имя файла индекса журналов репликации, в котором будут отмечены все имеющиеся файлы журналов репликации,
* `binlog_format` - формат журнала: `STATEMENT` - в журнал пишутся SQL-запросы, `ROW` - в журнал пишутся изменения строк, `MIXED` - смешанный режим, в котором предпочтение отдаётся SQL-запросам, если они не содержат функций `RANDOM()`, `NOW()` и т.п.,
* `binlog_row_image` - режим записи строк в формате ROW: `FULL` - в журнал записываются значния всех колонок (по умолчанию), `MINIMAL` - записываются только идентификатор записи и значения изменённых колонок, `NOBLOB` - записываются значения всех колонок, кроме неизменных колонок типа `BLOB` и `TEXT`,
* `binlog_expire_logs_seconds` - аналог устаревшей опции `expire_logs_days`, указывает, сколько секунд хранить журналы репликации. Файлы старше будут автоматически удаляться,
* `binlog_rows_query_log_events` - булева опция, предписывающая записывать в журнал репликации оригинальный SQL-запрос (по умолчанию отключена),
* `gtid_mode` - булевое занчение, указывающее, нужно ли добавлять в записи журнала транзакций GTID - Global Transaction IDentifier, то есть - глобальный идентификатор транзакции (по умолчанию выключено),
* `enforce_gtid_consistency` - булевое значение, при включении которого в журнал транзакций не будут попадать операции, не безопасные с точки зрения транзакционной целостности (по умолчанию включено).

Переименование сервера
----------------------

Если значения для опций `relay_log` и `relay_log_index` не были заданы, то для избежания проблем с репликацией нужно менять `hostname` сервера в следующей последовательности:

* Остановить MySQL,
* Поменять имя сервера (отредактировать файл `/etc/hostname` и выполнить `hostname -F /etc/hostname`),
* Переименовать файл `/var/lib/mysql/`*hostname*`-relay-bin.index` в соответствии с новым именем сервера,
* Запустить MySQL.

MySQL найдёт файл `/var/lib/mysql/`*hostname*`-relay-bin.index` и использует для репликации все файлы, которые имеются в индексе, для репликации. Новые файлы репликации, которые будут добавляться в индекс, будут иметь уже новые имена, соответствующие новому имени сервера.

Если же вы обнаружили неработающую репликацию после переименования, то, в соответствии с официальной документацией, нужно дописать в начало нового индексного файла содержимое старого индексного файла следующим образом:

    # cd /var/lib/mysql
    # cat new-relay-bin.index >> old-relay-bin.index
    # mv old-relay-bin.index new-relay-bin.index

О репликации
------------

На сервере-реплике лучше выставлять значения true у следующих опций:

* `read_only` - запретить запись всем пользователям, кроме root и пользователей репликации,
* `super_read_only` - запретить запись и пользователю root.

Формат GTID в MariaDB и Oracle MySQL отличается, поэтому при необходимости реплицировать базы данных между разными серверами необходимо использовать классическую репликацию.

Источники
---------

* [Александр Светкин. Основы репликации в MySQL](https://habr.com/ru/post/56702/)
* [MySQL. Настройка репликации Master-Slave](https://wiki.nareyko.by/mysql._nastrojka_replikacii_master-slave)
* [MySQL 5.7 Reference Manual / Replica Server Options and Variables](https://dev.mysql.com/doc/refman/5.7/en/replication-options-replica.html)
* [MySQL 5.7 Reference Manual / How Servers Evaluate Replication Filtering Rules](https://dev.mysql.com/doc/refman/5.7/en/replication-rules.html)
* [MySQL 5.7 Reference Manual / Evaluation of Table-Level Replication Options](https://dev.mysql.com/doc/refman/5.7/en/replication-rules-table-options.html)
* [MySQL 5.7 Reference Manual / CHANGE REPLICATION FILTER Statement](https://dev.mysql.com/doc/refman/5.7/en/change-replication-filter.html)
* [MySQL 5.7 Reference Manual / CHANGE MASTER TO Statement](https://dev.mysql.com/doc/refman/5.7/en/change-master-to.html)
* [MySQL 5.7 Reference Manual / The Relay Log](https://dev.mysql.com/doc/refman/5.7/en/replica-logs-relaylog.html)
