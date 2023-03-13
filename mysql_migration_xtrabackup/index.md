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

Второй способ сложнее. Придётся менять формат таблиц на работающем сервере, что может вызывать блокировку таблиц. Для таблиц с первичными ключами и ключами уникальности можно воспользоваться утилитой [[pt_online_schema_change|pt-online-schema-change]]. Для остальных таблиц придётся воспользоваться запросами `ALTER TABLE` с блокировкой таблиц на время их изменения.

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

Использованные материалы
------------------------

* [Manish Chawla. Percona XtraBackup: Backup and Restore of a Single Table or Database](https://www.percona.com/blog/2020/04/10/percona-xtrabackup-backup-and-restore-of-a-single-table-or-database/)
* [[Настройка реплики MySQL с помощью xtrabackup|mysql_slave_xtrabackup]]
