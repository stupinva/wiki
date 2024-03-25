Настройка реплики MySQL с помощью mysqldump
===========================================

[[!tag mysql mysqldump backup restore]]

Действия на источнике
---------------------

При небольшом объёме базы данных для настройки реплики можно воспользоваться утилитой `mysqldump`, сняв резервную копию интересующей базы данных с сервера-источника:

    $ mysqldump -uroot -p --single-transaction --routines --triggers --events --master-data --hex-blob --quick --databases db01 db02 | gzip > dbs.sql.sql

Для снятия максимально согласованной и полной резервной копии с сервера-источника можно воспользоваться командой следующего вида:

    $ mysqldump -uroot -p --single-transaction --routines --triggers --events --master-data --hex-blob --quick --all-databases | gzip > dbs.sql.gz

Объяснение используемых опций:

* `--single-transaction` - операции чтения данных из таблиц выполняются в рамках одной транзакции для получения согласованной копии данных,
* `--routines` - сохранить хранимые процедуры,
* `--triggers` - сохранить триггеры,
* `--events` - сохранить периодические задачи,
* `--master-data` - сохранить в резервную копию имя файла журнала репликации и позицию в нём для настройки реплики,
* `--hex-blob` - сохранять двоичные данных из таблиц в шестнадцатеричном виде,
* `--quick` - сохранять строки таблиц по мере чтения, не пытаясь считать таблицу целиком в оперативную память перед записью.

Действия на реплике
-------------------

Если нужно восстановить уже существующую реплику, то предварительно может понадобиться сохранить права доступа на существующей реплике при помощи команды следующего вида:

    $ pt-show-grants > grants.sql

Перед заливкой данных в работающую реплику может понадобиться остановить репликацию, даже если она уже находится в неисправном состоянии. Сделать это можно следующим образом:

    STOP SLAVE;

Затем можно восстановить резервную копию на сервере, который станет репликой:

    $ zcat dbs.sql.gz | mysql

Внутри файла резервной копии будет отмечено имя журнала и позиция, с которой можно будет продолжить репликацию:

    CHANGE MASTER TO MASTER_LOG_FILE='node-1.005814', MASTER_LOG_POS=16159;

Увидеть эти значения можно в строках `Master_Log_File` и `Exec_Master_Log_Pos` в выводе следующей команды:

    SHOW SLAVE STATUS\G

Перед запуском репликации нужно указать дополнительно сервер-источник и учётные данные пользователя для подключения, а имя журнала и позицию взять из вывода предыдущей команды. Для настройки источника репликации воспользуемся командой вида:

    CHANGE MASTER TO MASTER_HOST = '192.168.0.101',
                     MASTER_USER = 'repl',
                     MASTER_PASSWORD = 'xxxxxxxxxx',
                     MASTER_LOG_FILE = 'node-1.005814',
                     MASTER_LOG_POS = 16159;

После чего можно запустить репликацию:

    START SLAVE;

Решение проблемы с max_prepared_stmt_count
------------------------------------------

При восстановлении данных из резервной копии с большим количеством таблиц может произойти ошибка следующего вида:

    # zcat dbs.sql.gz | mysql
    ERROR 1461 (42000) at line 283987: Can't create more than max_prepared_stmt_count statements (current value: 16382)

Если посмотреть в окрестности строки 283987 резервной копии, то можно увидеть следующее:

    # zcat /srv/db0.sql.gz | awk 'NR > 283980 && NR < 284000 { print $0; }'
    /*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
    /*!50001 VIEW `user_login_22` AS select `user_login_3`.`id` AS `id`,`user_login_3`.`cid` AS `cid`,`user_login_3`.`login` AS `login`,`user_login_3`.`pswd` AS `pswd`,`user_login_3`.`date1` AS `date1`,`user_login_3`.`date2` AS `date2`,`user_login_3`.`status` AS `status`,3 AS `session`,`user_login_3`.`rp_mode` AS `rp_mode`,`user_login_3`.`realm_group` AS `realm_group`,`user_login_3`.`comment` AS `comment`,`user_login_3`.`object_id` AS `object_id` from `user_login_3` */;
    /*!50001 SET character_set_client      = @saved_cs_client */;
    /*!50001 SET character_set_results     = @saved_cs_results */;
    /*!50001 SET collation_connection      = @saved_col_connection */;
    /*!50112 SET @disable_bulk_load = IF (@is_rocksdb_supported, 'SET SESSION rocksdb_bulk_load = @old_rocksdb_bulk_load', 'SET @dummy_rocksdb_bulk_load = 0') */;
    /*!50112 PREPARE s FROM @disable_bulk_load */;
    /*!50112 EXECUTE s */;
    /*!50112 DEALLOCATE PREPARE s */;
    /*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;
    
    /*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
    /*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
    /*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
    /*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
    /*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
    /*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
    /*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

Ошибка произошла в строке:

    /*!50112 PREPARE s FROM @disable_bulk_load */;

Как можно догадаться, при восстановлении каждой таблицы создаётся новое подготовленное выражение, которое в дальнейшем должно быть удалено в этой строке:

    /*!50112 DEALLOCATE PREPARE s */;

Однако этого по каким-то причинам не происходит. Одно из решений заключается в том, чтобы выставить большее значение `max_prepared_stmt_count` перед восстановлением из резервной копии, например, следующим образом:

    SET GLOBAL max_prepared_stmt_count = 32*1024;

Другое решение заключается в том, чтобы вырезать из резервной копии строчки, начинающиеся с текста `/*!50112`, например, следущим образом:

    # mysqldump --single-transaction --routines --triggers --events --master-data --hex-blob --quick --databases db01 db02 | grep -UEv '^\/\*!50112' | gzip > dbs.sql.gz

Эти выражения выполняют проверку, поддерживается ли сервером MySQL массовая загрузка данных, характерная для RocksDB. Если поддерживается, то делается попытка включить её, видимо, для ускорения восстановления данных. Однако на деле эта услуга оказывается медвежьей, т.к. приводит к ошибке восстановления резервной копии в целом.
