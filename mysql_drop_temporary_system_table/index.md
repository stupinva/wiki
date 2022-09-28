Удаление временной системной таблицы MySQL
==========================================

[[!tag mysql xtrabackup]]

Столкнулся с проблемой: сервер MySQL упал при выполнении операции `ALTER TABLE`, в результате чего в системе образовалась временная таблица. При запуске сервера MySQL в журналах появляются сообщения следующего вида:

    2022-09-28T06:17:09.392157Z 0 [ERROR] InnoDB: In file './neftekamsk/#sql-5449_a1e6f.ibd', tablespace id and flags are 53633 and 0, but in the InnoDB data dictionary they are 23619861 and 0. Have you moved InnoDB .ibd files around without using the commands DISCARD TABLESPACE and IMPORT TABLESPACE? Please refer to 
    http://dev.mysql.com/doc/refman/5.7/en/innodb-troubleshooting-datadict.html for how to resolve the issue.
    2022-09-28T06:17:09.392288Z 0 [ERROR] InnoDB: Operating system error number 2 in a file operation.
    2022-09-28T06:17:09.392301Z 0 [ERROR] InnoDB: The error means the system cannot find the path specified.
    2022-09-28T06:17:09.392307Z 0 [ERROR] InnoDB: If you are installing InnoDB, remember that you must create directories yourself, InnoDB does not create them.
    2022-09-28T06:17:09.392316Z 0 [ERROR] InnoDB: Could not find a valid tablespace file for `neftekamsk/#sql-5449_a1e6f`. Please refer to http://dev.mysql.com/doc/refman/5.7/en/innodb-troubleshooting-datadict.html for how to resolve the issue.
    2022-09-28T06:17:09.392335Z 0 [Warning] InnoDB: Ignoring tablespace `neftekamsk/#sql-5449_a1e6f` because it could not be opened.

В принципе, эту ошибку можно было бы смело игнорировать, т.к. на работе сервера она никак не сказывается. Но снять резервную копию с этой базы данных с помощью 'xtrabackup' не получится, т.к. `xtrabackup`, дойдя до этой таблицы, будет ругаться, что эта временная таблица находится в том же табличном пространстве, что и исходная таблица, при попытке изменения которой с помощью операции `ALTER TABLE` и произошёл сбой.

Для исправления ситуации нужно скопировать файл с расширением `.frm`, соответствующий исходной таблице (или любой другой), под именем, соответствующим временной таблице:

    # cd /var/lib/mysql/neftekamsk/
    # cp contract.frm \#sql-5449_a1e6f.frm
    # chown mysql:mysql \#sql-5449_a1e6f

Теперь можно удалить временную таблицу, добавив слева к её имени префикс `#mysql50#`:

    mysql> USE neftekamsk
    mysql> DROP TABLE '#mysql50##sql-5449_a1e6f';

Проверить, что временная таблица пропала из списка системных, можно с помощью следующего запроса:

    mysql> SELECT * FROM INFORMATION_SCHEMA.INNODB_SYS_TABLES WHERE NAME LIKE '%#sql%';

После этого стоит перезапустить MySQL и убедиться в отсутствии сообщений об ошибке в журнале.

Использованные материалы
------------------------

* [Get rid of orphaned InnoDB temporary tables, the right way](https://mariadb.com/resources/blog/get-rid-of-orphaned-innodb-temporary-tables-the-right-way/)
