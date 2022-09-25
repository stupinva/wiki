Исправление ошибок в таблице InnoDB
===================================

[[!tag mysql innodb]]

Несмотря на то, что формат таблиц InnoDB в MySQL гораздо надёжнее формата MyISAM, они тоже могут быть повреждены. Вероятнее всего это может произойти из-за ошибок чтения сектора с диска. Даже если сбойный диск был заменён на новый, содержимое сбойного сектора будет скопировано на новый диск и таблица так и останется повреждённой. До поры до времени повреждённая таблица может никак не проявлять себя, пока нет обращений к строкам, находящимся на сбойном фрагменте таблицы. Если же это случилось, то в журнале MySQL могут появляться ошибки следующего вида:

    2022-09-23T22:26:24.247151Z 4359 [ERROR] InnoDB: Database page corruption on disk or a failed file read of tablespace sterlitamak/contract_balance page [page id: space=53799, page number=49476]. You may have to recover from a backup.
     len 16384; hex ...
    InnoDB: End of page dump
    InnoDB: Page may be an index page where index id is 55389

Где вместо многоточия будет фигурировать шестнадцатеричное содержимое сбойной страницы таблицы. При этом сервер MySQL может перестать отвечать на запросы, продолжая оставаться активным, а может и внезапно завершиться.

Для исправления подобных ошибок нужно внести в файл конфигурации опцию, предписывающую игнорировать возникающие ошибки и возвращать те данные, которые удаётся прочитать:

    innodb_force_recovery = 1

Опция вступит в силу только после перезапуска сервера MySQL. Когда активирована эта опция, запрещены любые операции, пытающиеся изменить хранящиеся на диске данные. В том числе, если сервер выполняет репликацию данных с другого сервера, репликация тоже будет заблокирована. Опция предназначена только для того, чтобы сохранить из повреждённой таблицы все доступные данные, например, следующим образом:

    $ mysqldump --single-transaction sterlitamak contract_balacne | gzip > sterlitamak_contract_balance.sql.gz

Далее сервер нужно перезапустить уже без опции `innodb_force_recovery`, удалить таблицу и восстановить её из резервной копии:

    $ mysql -BNe 'DROP TABLE sterlitamak.contract_balance;'
    $ zcat sterlitamak_contract_balance.sql.gz | mysql sterlitamak

Если эта операция будет выполняться на реплике, то перед перезапуском MySQL стоит внести в конфигурацию сервера опцию, предписывающую на запускать процесс репликации при запуске:

    skip_slave_start = 1

После восстановления таблицы из резервной копии можно будет удалить эту опцию из файла конфигурации, чтобы она не использовалась при последующих запусках и перезапусках сервера, и запустить репликацию без перезапуска сервера:

    $ mysql -BNe 'START SLAVE;'

Использованные материалы
------------------------

* [How To Fix Corrupted Tables in MySQL](https://www.digitalocean.com/community/tutorials/how-to-fix-corrupted-tables-in-mysql)
* [MySQL 5.7 Reference Manual / Replica Server Options and Variables / 16.1.6.3 Replica Server Options and Variables](https://dev.mysql.com/doc/refman/5.7/en/replication-options-replica.html#option_mysqld_skip-slave-start)
