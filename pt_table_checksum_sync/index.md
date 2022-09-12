Актуализация реплики mysql с помощью pt-table-checksum и pt-table-sync
======================================================================

[[!tag mysql]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

При использовании механизма репликации MySQL необходимо иметь идентичные наборы данных на всех серверах, участвующих в репликации данных.

Если появляется расхождение данных, необходимо его устранить. Для этого можно пересоздать реплику, что не всегда удобно, или воспользоваться утилитами `pt-table-checksum` и `pt-table-sync`.


Установка percona-tools
-----------------------

На всех серверах, участвующих в репликации данных, нужно установить пакет `percona-toolkit` в который входят утилиты `pt-table-checksum` и `pt-table-sync`:

    # apt-get install percona-toolkit

Создание тестовой базы данных
-----------------------------

Рассмотрим использование утилит на примере одного источника (node-master) и двух реплик (node-slave-1, node-slave-2). 

Создаем тестовую базу данных:

    mysql> CREATE DATABASE test;
    Query OK, 0 rows affected (0.02 sec)
     
    mysql> CREATE TABLE table1 (id INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY, name CHAR(5)) ENGINE=InnoDB;
    Query OK, 0 rows affected (0.02 sec)
     
    mysql> INSERT INTO table1 VALUES (1, 'a'), (2, 'b'), (3, 'c'), (4, 'd'), (5, 'e'), (6, 'f'), (7, 'g'), (8, 'h'), (9, 'i'), (10, 'j');
    Query OK, 10 rows affected (0.00 sec)
    Records: 10  Duplicates: 0  Warnings: 0
     
    mysql> SELECT * FROM table1;
    +------+------+
    | id   | name |
    +------+------+
    |    1 | a    |
    |    2 | b    |
    |    3 | c    |
    |    4 | d    |
    |    5 | e    |
    |    6 | f    |
    |    7 | g    |
    |    8 | h    |
    |    9 | i    |
    |   10 | j    |
    +------+------+
    10 rows in set (0.00 sec)

Теперь удалим часть данных на репликах:

    node-slave-1
    
    mysql> DELETE FROM table1 WHERE id > 7;
    Query OK, 3 rows affected (0.00 sec)
     
    mysql> SELECT * FROM table1;
    +----+------+
    | id | name |
    +----+------+
    |  1 | a    |
    |  2 | b    |
    |  3 | c    |
    |  4 | d    |
    |  5 | e    |
    |  6 | f    |
    |  7 | g    |
    +----+------+
    7 rows in set (0.00 sec)

    node-slave-2
    
    mysql> DELETE FROM table1 WHERE id > 5;
    Query OK, 4 rows affected (0.00 sec)
     
    mysql> SELECT * FROM table1;
    +----+------+
    | id | name |
    +----+------+
    |  5 | e    |
    |  6 | f    |
    |  7 | g    |
    |  8 | h    |
    |  9 | i    |
    | 10 | j    |
    +----+------+
    6 rows in set (0.00 sec)

Создание служебной базы данных
------------------------------

Для работы `percona-toolkit` на всех серверах нужно создать таблицу и пользователя:

    mysql> CREATE DATABASE PERCONA;
    Query OK, 1 row affected (0.00 sec)
     
    mysql> USE PERCONA;
    Database changed
     
    mysql> CREATE TABLE checksums (
        ->    db             CHAR(64)     NOT NULL,
        ->    tbl            CHAR(64)     NOT NULL,
        ->    chunk          INT          NOT NULL,
        ->    chunk_time     FLOAT            NULL,
        ->    chunk_index    VARCHAR(200)     NULL,
        ->    lower_boundary TEXT             NULL,
        ->    upper_boundary TEXT             NULL,
        ->    this_crc       CHAR(40)     NOT NULL,
        ->    this_cnt       INT          NOT NULL,
        ->    master_crc     CHAR(40)         NULL,
        ->    master_cnt     INT              NULL,
        ->    ts             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        ->    PRIMARY KEY (db, tbl, chunk),
        ->    INDEX ts_db_tbl (ts, db, tbl)
        -> ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    Query OK, 0 rows affected (0.01 sec)
     
    mysql> GRANT REPLICATION SLAVE,PROCESS,SUPER, SELECT ON *.* TO `checksum_user`@'%' IDENTIFIED BY 'checksum_password';
    Query OK, 0 rows affected (0.00 sec)
     
    mysql> GRANT ALL PRIVILEGES ON percona.* TO `checksum_user`@'%';
    Query OK, 0 rows affected (0.03 sec)
     
    mysql> FLUSH PRIVILEGES;
    Query OK, 0 rows affected (0.00 sec)

Сверка данных
-------------

После создания таблицы и пользователя, запускаем проверку целостности данных:

    root@node-server:/# pt-table-checksum --replicate=percona.checksums --databases=test --host=localhost --user=checksum_user --password=checksum_password
                TS ERRORS  DIFFS     ROWS  CHUNKS SKIPPED    TIME TABLE
    09-01T14:07:26      0      1       10       1       0   0.013 test.table1

В результате видим, что значение в поле `DIFFS` отличается от 0. Можно подключиться к репликам и проверить, в каких таблицах данные повреждены.

На node-slave-1:
    
    mysql> SELECT db, tbl, SUM(this_cnt) AS total_rows, COUNT(*) AS chunks
        -> FROM percona.checksums
        -> WHERE master_cnt <> this_cnt
        ->   OR master_crc <> this_crc
        ->   OR ISNULL(master_crc) <> ISNULL(this_crc)
        -> GROUP BY db, tbl;
    +------+--------+------------+--------+
    | db   | tbl    | total_rows | chunks |
    +------+--------+------------+--------+
    | test | table1 |          7 |      1 |
    +------+--------+------------+--------+
    1 row in set (0.00 sec)

На node-slave-2:
    
    mysql> SELECT db, tbl, SUM(this_cnt) AS total_rows, COUNT(*) AS chunks
    -> FROM percona.checksums
    -> WHERE master_cnt <> this_cnt
    ->   OR master_crc <> this_crc
    ->   OR ISNULL(master_crc) <> ISNULL(this_crc))
    -> GROUP BY db, tbl;
    +------+--------+------------+--------+
    | db   | tbl    | total_rows | chunks |
    +------+--------+------------+--------+
    | test | table1 |          6 |      1 |
    +------+--------+------------+--------+
    1 row in set (0.00 sec)

Синхронизация данных
--------------------

На каждой реплике выполняем команду синхронизации данных.

На node-slave-1:
    
    root@node-slave-1:/# pt-table-sync --print --replicate=percona.checksums --sync-to-master h=localhost,u=checksum_user,p=checksum_password
     
    # A software update is available:
    #   * The current version for Percona::Toolkit is 3.0.5
     
    REPLACE INTO `test`.`table1`(`id`, `name`) VALUES ('8', 'h') /*percona-toolkit src_db:test src_tbl:table1 src_dsn:P=3306,h=192.168.5.56,p=...,u=checksum_user dst_db:test dst_tbl:table1 dst_dsn:h=localhost,p=...,u=checksum_user lock:1 transaction:1 changing_src:percona.checksums replicate:percona.checksums bidirectional:0 pid:3248 user:root host:node-slave-1*/;
    REPLACE INTO `test`.`table1`(`id`, `name`) VALUES ('9', 'i') /*percona-toolkit src_db:test src_tbl:table1 src_dsn:P=3306,h=192.168.5.56,p=...,u=checksum_user dst_db:test dst_tbl:table1 dst_dsn:h=localhost,p=...,u=checksum_user lock:1 transaction:1 changing_src:percona.checksums replicate:percona.checksums bidirectional:0 pid:3248 user:root host:node-slave-1*/;
    REPLACE INTO `test`.`table1`(`id`, `name`) VALUES ('10', 'j') /*percona-toolkit src_db:test src_tbl:table1 src_dsn:P=3306,h=192.168.5.56,p=...,u=checksum_user dst_db:test dst_tbl:table1 dst_dsn:h=localhost,p=...,u=checksum_user lock:1 transaction:1 changing_src:percona.checksums replicate:percona.checksums bidirectional:0 pid:3248 user:root host:node-slave-1*/;

На node-slave-2:
    
    root@node-slave-2:/# pt-table-sync --print --replicate=percona.checksums --sync-to-master h=localhost,u=checksum_user,p=checksum_password
     
    # A software update is available:
    #   * The current version for Percona::Toolkit is 3.0.5
     
    REPLACE INTO `test`.`table1`(`id`, `name`) VALUES ('1', 'a') /*percona-toolkit src_db:test src_tbl:table1 src_dsn:P=3306,h=192.168.5.56,p=...,u=checksum_user dst_db:test dst_tbl:table1 dst_dsn:h=localhost,p=...,u=checksum_user lock:1 transaction:1 changing_src:percona.checksums replicate:percona.checksums bidirectional:0 pid:2566 user:root host:node-slave-2*/;
    REPLACE INTO `test`.`table1`(`id`, `name`) VALUES ('2', 'b') /*percona-toolkit src_db:test src_tbl:table1 src_dsn:P=3306,h=192.168.5.56,p=...,u=checksum_user dst_db:test dst_tbl:table1 dst_dsn:h=localhost,p=...,u=checksum_user lock:1 transaction:1 changing_src:percona.checksums replicate:percona.checksums bidirectional:0 pid:2566 user:root host:node-slave-2*/;
    REPLACE INTO `test`.`table1`(`id`, `name`) VALUES ('3', 'c') /*percona-toolkit src_db:test src_tbl:table1 src_dsn:P=3306,h=192.168.5.56,p=...,u=checksum_user dst_db:test dst_tbl:table1 dst_dsn:h=localhost,p=...,u=checksum_user lock:1 transaction:1 changing_src:percona.checksums replicate:percona.checksums bidirectional:0 pid:2566 user:root host:node-slave-2*/;
    REPLACE INTO `test`.`table1`(`id`, `name`) VALUES ('4', 'd') /*percona-toolkit src_db:test src_tbl:table1 src_dsn:P=3306,h=192.168.5.56,p=...,u=checksum_user dst_db:test dst_tbl:table1 dst_dsn:h=localhost,p=...,u=checksum_user lock:1 transaction:1 changing_src:percona.checksums replicate:percona.checksums bidirectional:0 pid:2566 user:root host:node-slave-2*/;

Ключ `--print` выводит запросы для актуализации данных без выполнения. Можно вручную выполнить их или запустить команду, заменив опцию `--print` на `--execute`.

Повторная сверка данных
-----------------------

После выполнения команды нужно проверить, что данные синхронизированы. Повторно запускаем проверку на источнике:

    root@node-server:/# pt-table-checksum --replicate=percona.checksums --databases=test --host=localhost --user=checksum_user --password=checksum_password
                TS ERRORS  DIFFS     ROWS  CHUNKS SKIPPED    TIME TABLE
    09-01T14:15:17      0      0       10       1       0   1.015 test.table1

Источник
--------

* [Актуализация реплики mysql с помощью pt-table-checksum и pt-table-sync](https://blogosys.ru/2018/09/aktualizatsiya-repliki-mysql-s-pomoshhyu-pt-table-checksum-i-pt-table-sync/)
