Настройка реплики MySQL с помощью mysqldump
===========================================

[[!tag mysql mysqldump]]

При небольшом объёме базы данных для настройки реплики можно воспользоваться утилитой `mysqldump`, сняв резервную копию интересующей базы данных с сервера-источника:

    $ mysqldump -uroot -p --single-transaction --master-data --databases db01 db02 > dump.sql

Для снятия максимально согласованной и полной резервной копии с сервера-источника можно воспользоваться командой следующего вида:

    $ mysqldump -uroot -p --single-transaction --routines --triggers --events --master-data --all-databases > dumpfile.sql

После чего можно восстановить эту резервную копию на сервере, который станет репликой:

    $ mysql < dump.sql

Внутри файла резервной копии будет отмечено имя журнала и позиция, с которой можно будет продолжить репликацию:

    CHANGE MASTER TO MASTER_LOG_FILE='node-1.005814', MASTER_LOG_POS=16159;

Для запуска репликации нужно будет только указать дополнительно сервер-источник и учётные данные пользователя для подключения:

    CHANGE MASTER TO MASTER_HOST = '192.168.0.101',
                     MASTER_USER = 'repl',
                     MASTER_PASSWORD = 'xxxxxxxxxx';

После чего можно запустить репликацию:

    START SLAVE;
