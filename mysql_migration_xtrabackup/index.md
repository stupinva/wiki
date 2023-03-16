Перенос базы данных с одного сервера MySQL на другой с помощью xtrabackup
=========================================================================

[[!tag mysql xtrabackup]]

Постановка задачи
-----------------

На сервере исходном есть несколько баз данных, которые нужно перенести на новый сервер. На новом сервере уже есть базы данных, так что создание полной резервной копии и её восстановление в данном случае не подходит. Кроме этого, одна из баз данных на новом сервере уже существует и необходимо добавить в неё новые таблицы, не затрагивая уже имеющиеся.

Для переноса базы данных воспользуемся `xtrabackup` и выражениями `ALTER TABLE <таблица> DISCARD TABLESPACE` и `ALTER TABLE <таблица> IMPORT TABLESPACE`.

Копирование структуры базы данных
---------------------------------

Создадим резервную копию структуры исходных баз данных с исходного сервера в файле `db_scheme.sql`:

    $ mysqldump -d --databases icsms_statistic neftekamsk oktyabrsky sterlitamak ishimbay salavat | sed '/^CREATE DATABASE .*icsms_statistic.*$/d' > db_schema.sql

Обратите внимание, что из файла `db_scheme.sql` с помощи команды `sed` удаляется команда для создания базы данных, т.к. эта база данных уже существует на целевом сервере и нужно лишь перенести в неё дополнительные таблицы.

Добавим к файлу выражения `ALTER TABLE <таблица> DISCARD TABLESPACE` для того, чтобы отделить от таблиц файлы, в которых хранятся данные:

    $ echo "USE icsms_statistic;" >> db_schema.sql
    $ mysql information_schema -BNe "SELECT table_name FROM tables WHERE table_schema = 'icsms_statistic' AND table_type = 'BASE TABLE';" | awk '{ print "ALTER TABLE " $0 " DISCARD TABLESPACE;" }' >> db_schema.sql
    $ echo "USE neftekamsk;" >> db_schema.sql
    $ mysql information_schema -BNe "SELECT table_name FROM tables WHERE table_schema = 'neftekamsk' AND table_type = 'BASE TABLE';" | awk '{ print "ALTER TABLE " $0 " DISCARD TABLESPACE;" }' >> db_schema.sql
    $ echo "USE oktyabrsky;" >> db_schema.sql
    $ mysql information_schema -BNe "SELECT table_name FROM tables WHERE table_schema = 'oktyabrsky' AND table_type = 'BASE TABLE';" | awk '{ print "ALTER TABLE " $0 " DISCARD TABLESPACE;" }' >> db_schema.sql
    $ echo "USE sterlitamak;" >> db_schema.sql
    $ mysql information_schema -BNe "SELECT table_name FROM tables WHERE table_schema = 'sterlitamak' AND table_type = 'BASE TABLE';" | awk '{ print "ALTER TABLE " $0 " DISCARD TABLESPACE;" }' >> db_schema.sql
    $ echo "USE ishimbay;" >> db_schema.sql
    $ mysql information_schema -BNe "SELECT table_name FROM tables WHERE table_schema = 'ishimbay' AND table_type = 'BASE TABLE';" | awk '{ print "ALTER TABLE " $0 " DISCARD TABLESPACE;" }' >> db_schema.sql
    $ echo "USE salavat;" >> db_schema.sql
    $ mysql information_schema -BNe "SELECT table_name FROM tables WHERE table_schema = 'salavat' AND table_type = 'BASE TABLE';" | awk '{ print "ALTER TABLE " $0 " DISCARD TABLESPACE;" }' >> db_schema.sql

Обратите внимание, что имена таблиц берутся специальным запросом из базы данных `information_schema`, а не с помощью простой команды `SHOW TABLES`. Дело в том, что среди таблиц, выводимых командой `SHOW TABLES` присутствуют представления, которые не являются таблицами и отсоединять от которых файлы с данными не нужно.

Тип строк
---------

Следует учитывать, что для успешного импорта данных таблиц, таблицы на целевом сервере должны создаваться с тем же форматом строк, какой используется на исходном сервере. В противном случае при импорте данных таблиц можно столкнуться с ошибками следующего вида:

    ERROR 1808 (HY000): Schema mismatch (Table has ROW_TYPE_DYNAMIC row format, .ibd file has ROW_TYPE_COMPACT row format.)

Дело в том, что `mysqldump` не сохраняет информацию о типе строк таблицы, а при создании таблиц на целевом сервере используется тип строк, настроенный в глобальной переменной сервера `innodb_default_row_format`:

    mysql> SHOW GLOBAL VARIABLES WHERE Variable_name = 'innodb_default_row_format';
    +---------------------------+---------+
    | Variable_name             | Value   |
    +---------------------------+---------+
    | innodb_default_row_format | dynamic |
    +---------------------------+---------+
    1 row in set (0.00 sec)

Можно поступить одним из двух способов:

* добавить в файл `db_schema.sql` команды для смены формата строк таблиц так, чтобы после создания таблиц на целевом сервере их формат строк соответствовал формату строк у таблиц на исходном сервере,
* поменять формат строк на исходном сервере так, чтобы он соответствовал формату строк, используемому по умолчанию на целевом сервере.

Первый способ реализуется проще:

    $ echo "USE icsms_statistic;" >> db_schema.sql
    $ mysql information_schema -BNe "SELECT table_name, row_format FROM tables WHERE table_schema = 'icsms_statistic' AND table_type = 'BASE TABLE' AND row_format <> 'Dynamic';" | awk '{ print "ALTER TABLE " $1 " ROW_FORMAT=" $2 ";" }' >> db_schema.sql
    $ echo "USE neftekamsk;" >> db_schema.sql
    $ mysql information_schema -BNe "SELECT table_name, row_format FROM tables WHERE table_schema = 'neftekamsk' AND table_type = 'BASE TABLE' AND row_format <> 'Dynamic';" | awk '{ print "ALTER TABLE " $1 " ROW_FORMAT=" $2 ";" }' >> db_schema.sql
    $ echo "USE oktyabrsky;" >> db_schema.sql
    $ mysql information_schema -BNe "SELECT table_name, row_format FROM tables WHERE table_schema = 'oktyabrsky' AND table_type = 'BASE TABLE' AND row_format <> 'Dynamic';" | awk '{ print "ALTER TABLE " $1 " ROW_FORMAT=" $2 ";" }' >> db_schema.sql
    $ echo "USE sterlitamak;" >> db_schema.sql
    $ mysql information_schema -BNe "SELECT table_name, row_format FROM tables WHERE table_schema = 'sterlitamak' AND table_type = 'BASE TABLE' AND row_format <> 'Dynamic';" | awk '{ print "ALTER TABLE " $1 " ROW_FORMAT=" $2 ";" }' >> db_schema.sql
    $ echo "USE ishimbay;" >> db_schema.sql
    $ mysql information_schema -BNe "SELECT table_name, row_format FROM tables WHERE table_schema = 'ishimbay' AND table_type = 'BASE TABLE' AND row_format <> 'Dynamic';" | awk '{ print "ALTER TABLE " $1 " ROW_FORMAT=" $2 ";" }' >> db_schema.sql
    $ echo "USE salavat;" >> db_schema.sql
    $ mysql information_schema -BNe "SELECT table_name, row_format FROM tables WHERE table_schema = 'salavat' AND table_type = 'BASE TABLE' AND row_format <> 'Dynamic';" | awk '{ print "ALTER TABLE " $1 " ROW_FORMAT=" $2 ";" }' >> db_schema.sql

Второй способ сложнее. Придётся менять формат таблиц на работающем сервере, что может вызывать блокировку таблиц. Для таблиц с первичными ключами и ключами уникальности можно воспользоваться утилитой [[pt-online-schema-change|pt_online_schema_change]], например, следующим образом:

    $ mysql information_schema -BN <<END | sh
    SELECT CONCAT('    pt-online-schema-change --alter row_format=Dynamic --execute D=',
           tables.table_schema,
           ',t=',
           tables.table_name)
    FROM tables
    JOIN table_constraints ON tables.table_schema = table_constraints.table_schema
      AND tables.table_name = table_constraints.table_name
      AND table_constraints.constraint_type IN ('PRIMARY KEY', 'UNIQUE')
    WHERE tables.engine = 'InnoDB'
      AND tables.row_format <> 'Dynamic'
      AND tables.table_schema IN ('icsms_statistic', 'neftekamsk', 'oktyabrsky', 'sterlitamak', 'ishimbay', 'salavat')
      AND tables.table_type = 'BASE TABLE'
    ORDER BY tables.data_length + tables.index_length DESC,
             tables.table_schema ASC,
             tables.table_name ASC;
    END

Для остальных таблиц придётся воспользоваться запросами `ALTER TABLE` с блокировкой таблиц на время их изменения:

    $ mysql information_schema -BN <<END | mysql
    SELECT CONCAT('    ALTER TABLE \`',
           tables.table_schema,
           '\`.\`',
           tables.table_name,
           '\` row_format=Dynamic; -- ',
           (tables.data_length + tables.index_length) / (1024 * 1024),
           ' MB')
    FROM tables
    LEFT JOIN table_constraints ON tables.table_schema = table_constraints.table_schema
      AND tables.table_name = table_constraints.table_name
      AND table_constraints.constraint_type IN ('PRIMARY KEY', 'UNIQUE')
    WHERE table_constraints.constraint_type IS NULL
      AND tables.engine = 'InnoDB'
      AND tables.table_schema IN ('icsms_statistic', 'neftekamsk', 'oktyabrsky', 'sterlitamak', 'ishimbay', 'salavat')
      AND tables.table_type = 'BASE TABLE'
    ORDER BY tables.data_length + tables.index_length DESC,
             tables.table_schema ASC,
             tables.table_name ASC;
    END

Команды импорта таблиц
----------------------

И подготовим файл с выражениями `ALTER TABLE <таблица> IMPORT TABLESPACE`:

    $ echo "USE icsms_statistic;" > db_import.sql
    $ mysql information_schema -BNe "SELECT table_name FROM tables WHERE table_schema = 'icsms_statistic' AND table_type = 'BASE TABLE';" | awk '{ print "ALTER TABLE " $0 " IMPORT TABLESPACE;" }' >> db_import.sql
    $ echo "USE neftekamsk;" >> db_import.sql
    $ mysql information_schema -BNe "SELECT table_name FROM tables WHERE table_schema = 'neftekamsk' AND table_type = 'BASE TABLE';" | awk '{ print "ALTER TABLE " $0 " IMPORT TABLESPACE;" }' >> db_import.sql
    $ echo "USE oktyabrsky;" >> db_import.sql
    $ mysql information_schema -BNe "SELECT table_name FROM tables WHERE table_schema = 'oktyabrsky' AND table_type = 'BASE TABLE';" | awk '{ print "ALTER TABLE " $0 " IMPORT TABLESPACE;" }' >> db_import.sql
    $ echo "USE sterlitamak;" >> db_import.sql
    $ mysql information_schema -BNe "SELECT table_name FROM tables WHERE table_schema = 'sterlitamak' AND table_type = 'BASE TABLE';" | awk '{ print "ALTER TABLE " $0 " IMPORT TABLESPACE;" }' >> db_import.sql
    $ echo "USE ishimbay;" >> db_import.sql
    $ mysql information_schema -BNe "SELECT table_name FROM tables WHERE table_schema = 'ishimbay' AND table_type = 'BASE TABLE';" | awk '{ print "ALTER TABLE " $0 " IMPORT TABLESPACE;" }' >> db_import.sql
    $ echo "USE salavat;" >> db_import.sql
    $ mysql information_schema -BNe "SELECT table_name FROM tables WHERE table_schema = 'salavat' AND table_type = 'BASE TABLE';" | awk '{ print "ALTER TABLE " $0 " IMPORT TABLESPACE;" }' >> db_import.sql

Создание и подготовка резервной копии
-------------------------------------

Запустим на целевом сервере команду для приёма резервной копии в каталог `/srv/backup` с TCP-порта 4444:

    # socat -u TCP-LISTEN:4444,reuseaddr stdio | pigz -dc -p 4 - | xbstream -p 4 -x -C /srv/backup

На исходном сервере запустим команду для создания резервной копии баз данных `icsms_statistic`, `neftekamsk`, `oktyabrsky`, `sterlitamak`, `ishimbay` и `salavat`, указав их имя в опции `--databases`:

    # xtrabackup --open-files-limit=100000 --backup --databases='icsms_statistic neftekamsk oktyabrsky sterlitamak ishimbay salavat' --stream=xbstream --parallel 4 --no-timestamp --target-dir=/tmp | pigz -k -1 -p4 - | socat -u stdio TCP:192.168.169.70:4444

Отправляться резервная копия будет в TCP-подключение на IP-адрес 192.168.169.70 и порт 4444, где её уже ждёт запущенная ранее команда.

Затем подготовим резервную копию к использованию:

    # xtrabackup --use-memory=1G --prepare --target-dir=/srv/backup/

Поменяем права доступа к полученным файлам:

    # chown mysql:mysql -R /srv/backup/

Восстановление резервной копии
------------------------------

Сначала создадим базы данных со структурой как у исходных и отсоединим от таблиц файлы с данными:

    # mysql < db_schema.sql

Теперь перенесём файлы из каталога с резервной копией в каталог с файлами базы данных:

    # mv /srv/backup/icsms_statistic/*.ibd /srv/mysql/icsms_statistic/
    # mv /srv/backup/neftekamsk/*.ibd /srv/mysql/neftekamsk/
    # mv /srv/backup/oktyabrsky/*.ibd /srv/mysql/oktyabrsky/
    # mv /srv/backup/sterlitamak/*.ibd /srv/mysql/sterlitamak/
    # mv /srv/backup/ishimbay/*.ibd /srv/mysql/ishimbay/
    # mv /srv/backup/salavat/*.ibd /srv/mysql/salavat/

И подсоединим файлы с данными к таблицам баз данных:

    # myqsl < db_import.sql

Импорт таблиц может быть довольно длительным и зависит от размера файлов данных таблиц.

Проблемы
--------

Этот способ имеет ограниченную пригодность к применению. Один раз мне удалось перенести базы данных этим способом довольно быстро и без каких-либо проблем. В другой раз столкнулся с некоторыми проблемами.

Во-первых, во время выполнения команд `ALTER TABLE ... DISCARD TABLESPACE` запросы на вставку новых данных в таблицы других баз данных начинают выполняться заметно медленнее. Это отрицательно сказывается на комфорте работы с интерактивными приложениями. Для смягчения проблемы пришлось проводить работы в ночное нерабочее время, когда нагрузка на СУБД значительно снижается, а интерактивные приложения не используются.

Во-вторых, во время выполнения команд `ALTER TABLE ... IMPORT TABLESPACE` спорадически происходят обращения к таблицам, что приводит к ошибкам следующего вида, приводящим к аварийному завершению работы сервера MySQL:

    2023-03-10T09:25:35.920940Z 804144 [ERROR] InnoDB: Trying to access page number 2044638464 in space 86995138, space name neftekamsk/contract_logon_error, which is outside the tablespace bounds. Byte offset 0, len 16384, i/o type read. If you get this error at mysqld startup, please check that your my.cnf matches the ibdata files that you have in the MySQL server.
    2023-03-10T09:25:35.920967Z 804144 [ERROR] InnoDB: Server exits.

    2023-03-10T09:29:01.917753Z 57 [ERROR] InnoDB: trying to read page [page id: space=86998512, page number=4294967295] in nonexisting or being-dropped tablespace
    2023-03-10T09:29:01.917773Z 57 [ERROR] [FATAL] InnoDB: Unable to read page [page id: space=86998512, page number=4294967295] into the buffer pool after 100 attempts. The most probable cause of this error may be that the table has been corrupted. Or, the table was compressed with with an algorithm that is not supported by this instance. If it is not a decompress failure, you can try to fix this problem by using innodb_force_recovery. Please see http://dev.mysql.com/doc/refman/5.7/en/ for more details. Aborting...
    2023-03-10 14:29:01 0x7f27b3210700  InnoDB: Assertion failure in thread 139808485738240 in file ut0ut.cc line 924

Также после импорта каждого табличного пространства происходили ошибки следующего вида, которые не приводили к падению сервера:

    2023-03-14T01:07:49.676086Z 24 [Warning] InnoDB: Tablespace for table `salavat`.`setup` is set as discarded.
    2023-03-14T01:07:49.676177Z 24 [Warning] InnoDB: Trying to access missing tablespace 87012042
    2023-03-14T01:07:49.676200Z 24 [Warning] InnoDB: Cannot save statistics for table `salavat`.`setup` because the .ibd file is missing. Please refer to http://dev.mysql.com/doc/refman/5.7/en/innodb-troubleshooting.html for how to resolve the issue.

В частности, из-за этих сообщений возникли подозрения, что при импорте табличных пространств происходит состояние гонки между процессом импорта данных и процессом пересчёта статистики, в результате которого с небольшой вероятностью может произойти попытка посчитать статистику для таблицы, импорт табличного пространства которой ещё не завершён, но таблица уже помечена как импортированная. Чтобы проверить догадку, пробовал отключать через глобальные переменные и файлы конфигурации опции `innodb_stats_auto_recalc` и `innodb_stats_persistent`, но это не помогало. Изучать ситуацию подробно на сервере, используемом для обработки бизнес-процессов, времени не было.

В-третьих, описанная выше проблема возникает, хоть и значительно реже, и на серверах-репликах, работающих в режиме только чтения. Первая же возникшая проблема на сервере-реплике привела к поломке репликации.

Из-за падений основного сервера на нём было потеряно две таблицы, которые должны были быть импортированы. От них остались ibd-файлы с табличными пространствами, но frm-файлы с определениями структуры таблиц пропали. Кроме того, из-за падений сервера-реплики репликация остановилась на попытке импортировать табличное пространство, которое уже было отмечено как импортированное.

В итоге я посчитал этот метод переноса баз данных непригодным для данного случая и воспользовался для переноса баз данных утилитами `mysqldump` и `mysql`. Перенос с нескольких часов растянулся почти на сутки, но не вызывал проблем с отзывчивостью запросов вставки и не приводил к падениям серверов MySQL.

Использованные материалы
------------------------

* [Manish Chawla. Percona XtraBackup: Backup and Restore of a Single Table or Database](https://www.percona.com/blog/2020/04/10/percona-xtrabackup-backup-and-restore-of-a-single-table-or-database/)
* [[Настройка реплики MySQL с помощью xtrabackup|mysql_slave_xtrabackup]]
