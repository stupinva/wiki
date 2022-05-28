Перенос базы данных с одного сервера MySQL на другой с помощью xtrabackup
=========================================================================

Постановка задачи
-----------------

На сервере исходном есть база данных, которую нужно перенести на новый сервер. На новом сервере уже есть базы данных, так что создание полной резерной копии и её восстановление в данном случае не подходит.

Для переноса базы данных воспользуемся `xtrabackup` и выражениями `ALTER TABLE <таблица> DISCARD TABLESPACE` и `ALTER TABLE <таблица> IMPORT TABLESPACE`.

Создание и подготовка резерной копии
------------------------------------

Запустим на целевом сервере команду для приёма резервной копии в каталог `/srv/backup` с TCP-порта 4444:

    # socat -u TCP-LISTEN:4444,reuseaddr stdio | pigz -dc -p 4 - | xbstream -p 4 -x -C /srv/backup

На исходном сервере запустим команду для создания резервной копии базы данных `db`, указав её имя в опции `--databases`:

    # xtrabackup --open-files-limit=100000 --backup --databases=db --stream=xbstream --parallel 4 --no-timestamp --target-dir=/tmp | pigz -k -1 -p4 - | socat -u stdio TCP:192.168.169.70:4444

Отправляться резервная копия будет в TCP-подключение на IP-адрес 192.168.169.70 и порт 4444, где её уже ждёт запущенная ранее команда.

Затем подготовим резервную копию к использованию:

    # xtrabackup --use-memory=1G --prepare --target-dir=/srv/backup/

Копирование структуры базы данных
---------------------------------

Создадим резервную копию структуры исходной базы данных с исходного сервера одной из двух команд:

    # mysqldump -d db > db_scheme.sql
    # mysqldump -d --databases db > db_scheme.sql

Поскольку я собираюсь восстанавливать базу данных под тем же именем, я воспользовался вторым вариантом, при котором в файл `db_scheme.sql` попадёт выражение, создающее базу данных с именем `db`.

Добавим к файлу выражения `ALTER TABLE <таблица> DISCARD TABLESPACE;` для того, чтобы отделить от таблиц файлы, в которых хранятся данные:

    # mysql db -BNe 'SHOW TABLES;' | awk '{ print "ALTER TABLE " $0 " DISCARD TABLESPACE;" }' >> db_scheme.sql

И подготовим файл с выражениями `ALTER TABLE <таблица> IMPORT TABLESPACE;`:

    # mysql db -BNe 'SHOW TABLES;' | awk '{ print "ALTER TABLE " $0 " IMPORT TABLESPACE;" }' > db_import.sql

Файлы `db_scheme.sql` и `db_import.sql` нужно перенести на целевой сервер.

Восстановление резервной копии
------------------------------

Сначала создадим базу данных `db` со структурой как у исходной и отсоединим от таблиц файлы с данными:

    # mysql < db_scheme.sql

Если восстановить базу данных нужно под именем, отличающимся от исхоодного, то последовательность действий будет несколько иной:

    > CREATE DATABASE newdb;
    > USE newdb
    > SOURCE db_scheme.sql

Теперь перенесём файлы из каталога с резервной копией в каталог с файлами базы данных:

    # mv /srv/backup/db/* /var/lib/mysql/db/*

Поменяем владельца файлов и группу владельца на `mysql`:

    # chown mysql:mysql /var/lib/mysql/db/*

И подсоединим файлы с данными к таблицам базы данных `db`:

    # myqsl db < db_import.sql

Если имя базы данных меняется, то здесь используем новое имя `newdb`:

    # myqsl newdb < db_import.sql

Импорт таблиц может быть довольно длительным и зависит от размера файлов данных таблиц.

Использованные материалы
------------------------

* [Manish Chawla. Percona XtraBackup: Backup and Restore of a Single Table or Database](https://www.percona.com/blog/2020/04/10/percona-xtrabackup-backup-and-restore-of-a-single-table-or-database/)
* [[Настройка реплики MySQL с помощью xtrabackup|mysql_slave_xtrabackup]]
