Утилита для проверки синхронности баз данных pt-table-checksum
==============================================================

[[!tag mysql]]


Утилита сравнивает базы данных на источнике и его репликах потаблично. Каждая таблица делится на небольшие фрагменты, для каждого фрагмента подсчитывается количество строк и контрольная сумма значений всех колонок. Полученные данные вставляются в таблицу `checksums` в базе данных percona. Каждая операция подсчёта контрольной суммы фрагмента таблицы выполняется в виде запроса `REPLACE INTO percona.checksums ... SELECT ... FROM database.table`.

Утилита меняет на источнике формат журнала на `STATEMENT` в рамках установленного подключения и выполняет запрос на вычисление контрольной суммы фрагмента таблицы. Этот запрос уходит на реплики и выполняется на них тоже, но результат выполнения запроса будет зависеть от исходных данных, имеющихся на том сервере, где выполняется запрос. Благодаря этому можно затем просто сравнить результаты выполнения запросов, записанные в таблицы `checksums` в базах данных `percona`.

Утилита рассчитана на то, что таблица checksums из базы данных percona не реплицируется с источника на реплику. В противном случае контрольные суммы на реплике будут перезаписываться контрольными суммами источника и результат сверки баз данных будет заведомо успешным.

Перед запуском утилиты нужно создать на СУБД, базы данных на которых подлежат сверке, базы данных percona с таблицами checksums при помощи следующих запросов:

    CREATE DATABASE `percona`;
    
    USE `percona`;
    
    CREATE TABLE `checksums` (
      `db` char(64) NOT NULL,
      `tbl` char(64) NOT NULL,
      `chunk` int(11) NOT NULL,
      `chunk_time` float DEFAULT NULL,
      `chunk_index` varchar(200) DEFAULT NULL,
      `lower_boundary` text,
      `upper_boundary` text,
      `this_crc` char(40) NOT NULL,
      `this_cnt` int(11) NOT NULL,
      `master_crc` char(40) DEFAULT NULL,
      `master_cnt` int(11) DEFAULT NULL,
      `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`db`,`tbl`,`chunk`),
      KEY `ts_db_tbl` (`ts`,`db`,`tbl`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

Для сравнения синхронности базы данных db на источнике с IP-адресом 192.168.1.2 и на его репликах можно запустить такую команду:

    $ pt-table-checksum --nocheck-replication-filters --no-check-binlog-format --databases=db u=root,p=p4$$w0rd,h=192.168.1.2,P=3306

Смысл опций:

* `--nocheck-replication-filters` - не проверять фильтры репликации, настроенные, например, с помощью опций binlog-do-db, replicate-do-db,
* `--no-check-binlog-format` - не проверять формат журнала репликации. Утилите нужен формат STATEMENT, но она может работать и с форматом ROW, если таблица checksums в базе данных percona не будет реплицироваться,
* `--databases=db` - список сверяемых баз данных, перечисленных через запятую.

Далее следует так называемый DSN, который указывает на настройки подключения к серверу-источнику:

* `u=root` - имя пользователя,
* `p=p4$$w0rd` - пароль пользователя,
* `h=192.168.1.2` - IP-адрес сервера,
* `P=3306` - порт сервера.

Для подключения к серверу-источнику через SSH-туннель можно воспользоваться такими командами:

    $ ssh -NL3307:127.0.0.1:3306 192.168.1.2
    $ pt-table-checksum --nocheck-replication-filters --no-check-binlog-format --databases=db u=root,p=p4$$w0rd,h=127.0.0.1,P=3307

Если в процессе сверки таблиц часто появляются сообщения об отсутствии подходящих индексов или о слишком большом размере фрагмента, то можно добавить к команде дополнительные опции:

* `--chunk-time=4` - увеличить максимальное время вычисления контрольной суммы одного фрагмента до 2 секунд (со значения 0,5, которое используется по умолчанию),
* `--chunk-size-limit=10` - увеличить терпимость к превышению размера фрагмента до 4 раз (по умолчанию используются фрагменты по 10000 строк и допускается превышение размера одного фрагмента только в 2 раза).

С этими опциями команда примет следующий вид:

    $ pt-table-checksum --nocheck-replication-filters --no-check-binlog-format --chunk-time=2 --chunk-size-limit=4 --databases=db u=root,p=p4$$w0rd,h=192.168.1.2,P=3306

Для устранения расхождений на реплике можно запустить утилиту `pt-table-sync`, например, следующим образом:

    $ pt-table-sync --execute --sync-to-master u=root,p=p4$$w0rd,h=192.168.1.2,P=3306,D=db,t=table

Дополнительные материалы
------------------------

* [pt-table-checksum](https://docs.percona.com/percona-toolkit/pt-table-checksum.html)
* [How to Handle pt-table-checksum Errors](https://www.percona.com/blog/2018/04/06/how-to-handle-pt-table-checksum-errors/)
* [MySQL replication primer with pt-table-checksum and pt-table-sync](https://www.percona.com/blog/2015/08/12/mysql-replication-primer-with-pt-table-checksum-and-pt-table-sync/)
* [Актуализация реплики mysql с помощью pt-table-checksum и pt-table-sync](https://blogosys.ru/2018/09/aktualizatsiya-repliki-mysql-s-pomoshhyu-pt-table-checksum-i-pt-table-sync/)
