Добавление нового узла в кластер Percona XtraDB Cluster
=======================================================

Предположим, что база MySQL лежит в `/srv/mysql`, IP-адрес источника - 192.168.1.1, IP-адрес приемника - 192.168.1.2.

На источнике и приемнике должны быть установлены пакеты `percona-xtrabackup`, `socat` и `pigz`, а версии Percona XtraDB Cluster должны быть одинаковыми.

1. Конфигурацию Percona XtraDB Cluster для нового узла можно взять с источника, главное - правильно настроить переменные, касающиеся Writeset Replication. В случае, если мы имеем дело с deb-пакетом, файл конфигурации сервера MySQL находится в файле `/etc/mysql/percona-xtradb-cluster.conf.d/mysqld.cnf`, а настройки репликации находятся в файле `/etc/mysql/percona-xtradb-cluster.conf.d/wsrep.cnf`.

2. Важно! На источнике выполняем команду:

    SET GLOBAL wsrep_provider_options="gcache.freeze_purge_at_seqno = now";

Эта команда отключит удаление Writeset'ов из журналов Galera. Если этого не сделать, то к моменту окончания снятия резервной копии записи в этом файле устареют и новый узел кластера не сможет догнать источник по IST.

3. На приемнике запускаем команду:

    # socat -u TCP-LISTEN:4444,reuseaddr stdio | pigz -dc -p 4 - | xbstream —p 4 -x -C /srv/mysql

4. На источнике запускаем команду:

    # xtrabackup --defaults-file=/root/.my.cnf --open-files-limit=100000 --backup --stream=xbstream --parallel 4 --no-timestamp --target-dir=/tmp | pigz -k -1 -p4 - | socat -u stdio TCP:192.168.1.2:4444

5. Дожидаемся завершения запущенных команд. Если резервное копирование прервалось, то повторять нужно с пункта 3.

6. На приемнике готовим каталог с данными для запуска MySQL:

    # xtrabackup --use-memory=1G --prepare --target-dir=/srv/mysql
    # chown -R mysql:mysql /srv/mysql

7. Далее заглядываем на приёмнике в файл `/srv/mysql/xtrabackup_galera_info`. В нём в одной строчке через двоеточие указаны UUID кластера и номер последовательности Writeset'а. Пусть это будут UUID "d2270c6d-3195-11e7-a33c-12e6ebfb7267" и "46050303461" соответственно.

8. Создаём на приёмнике файл `/srv/mysql/grastate.dat` со следующим содержимым:

    # GALERA saved state
    version: 2.1
    uuid:    d2270c6d-3195-11e7-a33c-12e6ebfb7267
    seqno:   46050303461
    cert_index:

И выставим права доступа:

    # chmod u=rw,g=r,o= /srv/mysql/grastate.dat
    # chown mysql:mysql /srv/mysql/grastate.dat

9. Запускаем MySQL на приемнике. Заглядываем в журнал. В журнале должно быть написано, что новый узел присоединился к кластеру и начал синхронизацию по IST.

10. Отслеживаем состояние синхронизации по журналу и по выводу команды:

    # mysql -Bse "SHOW GLOBAL STATUS LIKE 'wsrep%'" | egrep 'state|status'

Когда синхронизация завершится, переменная статуса `wsrep_local_state_comment` в выводе предыдущей команды примет значение "Synced", а переменная `wsrep_cluster_status` - значение "Primary".

11. При успешном завершении синхронизации на источнике выполняем команду:

    SET GLOBAL wsrep_provider_options="gcache.freeze_purge_at_seqno = -1";

Кэш Galera вернётся в нормальный режим, а временные файлы с Writeset'ами, созданными во время создания резервной копии и настройки нового узла, будут удалены.

Использованные материалы
------------------------

[Krunal Bauskar. Want IST Not SST for Node Rejoins? We Have a Solution!](https://www.percona.com/blog/2018/02/13/no-sst-node-rejoins/)
