Резервное копирование и восстановление PostgreSQL
=================================================

[[!tag postgresql backup restore]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Полная резервная копия всех баз данных со всеми пользователями и их правами
---------------------------------------------------------------------------

    pg_dumpall > savedfile.sql

Восстановление резервной копии всех баз данных со всеми пользователями и их правами
-----------------------------------------------------------------------------------

    psql postgres -f savedfile.sql

Резервная копия только одной базы данных
----------------------------------------

    pg_dump -d dname > savedfile.sql

Восстановление резервной копии только одной базы данных
-------------------------------------------------------

    psql dbname -f savedfile.sql

Резервное копирование только одной или нескольких таблиц одной базы данных
--------------------------------------------------------------------------

    pg_dump -d dname -t table1 -t table2 -t table3 > savedfile.sql

Резервное копирование только пользователей и их прав
----------------------------------------------------

    pg_dumpall -g > users.sql

Резервное копирование и восстановление базы данных под другим владельцем
------------------------------------------------------------------------

    pg_dump -d database --no-owner > savedfile.sql

    psql -U newowner dbname -f savedfile.sql

Физическая резервная копия в каталог
------------------------------------

    pg_basebackup -D /destination/path -Pv --checkpoint=fast

Восстановление физической резервной копии из каталога
-----------------------------------------------------

    chown postgres:postgres -R /destination/path
    chmod 700 -R /destination/path

Физическая резервная копия в tar-файлы
--------------------------------------

    pg_basebackup -D /destination/path -Pv --checkpoint=fast -F t

Будут сформированы файлы base.tar и pg_wal.tar

Восстановление из физической резервной копии
--------------------------------------------

Распаковываем файл base.tar в каталог с файлами баз данных, затем распаковываем файл pg_wal.tar в подкаталог pg_wal.

Физическая резервная копия в один сжатый tar-файл
-------------------------------------------------

    pg_basebackup -D /destination/path -Pv --checkpoint=fast -F t -X stream -z

Использованные материалы
------------------------

* [Jorge Torralba. PostgreSQL 101 for Non-Postgres DBAs (Simple Backup and Restore)](https://www.percona.com/blog/postgresql-101-simple-backup-and-restore/)
* [AkashKathiriya. PostgreSQL Backups: What is pg_basebackup?](https://backup.ninja/news/postgresql-backups-what-is-pgbasebackup)
