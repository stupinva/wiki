Настройка реплики MySQL с помощью снимков LVM и rysnc
=====================================================

[[!tag mysql lvm rsync]]

Если реплика ранее уже была настроена, но необходимо развернуть её повторно, то перед началом работ лучше сохранить права доступа, например, при помощи утилиты `pt-show-grants`:

    # pt-show-grants > grants.sql

Также нам понадобится информация об источнике репликации и пользователе, от имени которого реплика забирает журналы с источника. Эти данные можно взять из файла `master.info`. Например, вот так можно сохранить адрес исходного сервера, имя пользователя, от имени которого происходит репликация, его пароль и номер порта на исходном сервере, если он отличается от порта по умолчанию 3306:

    # awk 'NR>3 && NR<8 { print $0; }' /var/lib/mysql/master.info
    192.168.0.101
    repl
    p4$$w0rd
    3306

Подключаемся через консольный клиент MySQL под пользователем `root` к серверу-источнику, блокируем таблицы и выводим состояние источника:

    mysql> FLUSH LOCAL TABLES WITH READ LOCK;
    Query OK, 0 rows affected (0.10 sec)
    
    mysql> SHOW MASTER STATUS;
    +----------------+----------+--------------+------------------+
    | File           | Position | Binlog_Do_DB | Binlog_Ignore_DB |
    +----------------+----------+--------------+------------------+
    | bin-log.001038 | 96682764 | nnovgorod    |                  |
    +----------------+----------+--------------+------------------+
    1 row in set (0.02 sec)

Не закрывая клиента MySQL выполняем в соседнем окне команду создания мгновенного снимка логического тома, на котором находятся данные источника:

    # lvcreate -L 100G -s vg0/storage -n storage-snapshot

Возвращаемся к консольному клиенту MySQL и снимаем блокировки с таблиц (или можно просто выйти из клиента):

    mysql> UNLOCK TABLES;
    Query OK, 0 rows affected (0.00 sec)

Теперь можно смонтировать снимок:

    # mount /dev/vg0/storage-snapshot /mnt/

И скопировать его на удалённый сервер с помощью `rsync` через SSH-клиента:

    # rsync -axv --delete -e 'ssh -i /storage/mysql/.ssh/id_rsa' /mnt/mysql/ mysql@bill1.nnov.ufanet.ru:/failover/storage/mysql.new/

После завершения копирования снимок больше не нужен, его можно размонтировать и удалить:

    # umount /mnt
    # lvremove vg0/storage-snapshot
    Do you really want to remove active logical volume storage-snapshot? [y/n]: y
      Logical volume "storage-snapshot" successfully removed

Из каталога с данными на реплике можно удалить файлы журналов репликации, а также файл `auto.cnf`, в котором содержится UUID сервера. При совпадении UUID у источника и реплики репликация не запустится с сообщением об ошибке следующего вида:

    Fatal error: The slave I/O thread stops because master and slave have equal MySQL server UUIDs; these UUIDs must be different for replication to work.

Запускаем на реплике сервер MySQL с использованием каталога с данными, скопированными с источника. Восстанавливаем права доступа:

    mysql> SOURCE grants.sql
    mysql> FLUSH PRIVILEGES;
    mysql> FLUSH HOSTS;

Осталось подключиться консольным клиентом MySQL к реплике, указать настройки источника и запустить репликацию:

    mysql> CHANGE MASTER TO MASTER_HOST = '192.168.0.101',
                            MASTER_USER = 'repl',
                            MASTER_PASSWORD = 'xxxxxxxxxx',
                            MASTER_LOG_FILE = 'bin-log.001038',
                            MASTER_LOG_POS = 96682764;
    mysql> START SLAVE;

За процессом репликации можно наблюдать при помощи команды следующего вида:

    # watch "mysql -Be 'SHOW SLAVE STATUS\G' | grep Seconds_Behind_Master"

Она выводит количество секунд, на которое реплика отстаёт от источника. Когда отставание станет нулевым, можно считать реплику полностью синхронизированной с источником. Если же вместо числа выводится значение `NULL`, то процесс синхронизации по каким-то причинам не активен. Стоит посмотреть на полный вывод запроса `SHOW SLAVE STATUS\G`.

Источники
---------

* [Stephen R Lang. Setting up MySQL Master Slave Replication with LVM snapshots](https://www.stephenrlang.com/2016/08/setting-up-mysql-master-slave-replication-with-lvm-snapshot/)
* [Peter Zaitsev. Using LVM for MySQL Backup and Replication Setup](https://www.percona.com/blog/2006/08/21/using-lvm-for-mysql-backup-and-replication-setup/)
