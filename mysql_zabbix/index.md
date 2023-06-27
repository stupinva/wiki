Мониторинг MySQL с помощью Zabbix
=================================

[[!tag mysql zabbix zabbix_agent]]

Для мониторинга используется сценарий [[mysql.sh]], который нужно положить в каталог `/etc/zabbix`, где находится конфигурация Zabbix-агента. Его владельцем можно сделать пользователя `root` и дать права читать и выполнять его всем:

    # chown root:root /etc/zabbix/mysql.sh
    # chmod u=rwx,go=rx /etc/zabbix/mysql.sh

Сценарий использует для работы файл `/etc/zabbix/my.cnf`, в котором должны быть указаны логин и пароль для подключения к MySQL. Файл имеет следующий формат:

    [client]
    user = zabbix
    password = zabbix_p4$$w0rd

Для того, чтобы файл смог изменять только пользователь `root`, а читать смог только пользователь `zabbix`, от имени которого работает Zabbbix-агент, можно выставить права доступа к этому файлу следующим образом:

    # chown root:zabbix /etc/zabbix/my.cnf
    # chmod u=rw,g=r,o= /etc/zabbix/my.cnf

Для мониторинга пользователю MySQL понадобится право `PROCESS`. Для мониторинга состояния репликации также нужно право `REPLICATION CLIENT`. Нужно создать пользователя с соответствующими правами, логин и пароль которого были указаны в файле `/etc/zabbix/my.cnf`. Для этого нужно выполнить от имени пользователя root SQL-запрос следующего вида:

    > GRANT PROCESS, REPLICATION CLIENT ON *.* TO zabbix@localhost IDENTIFIED BY 'zabbix_p4$$w0rd';

Для того, чтобы изменения прав пользователей вступили в силу, нужно выполнить также следующий SQL-запрос:

    > FLUSH PRIVILEGES;

Для проверки правильности настроек можно вызвать скрипт, одним из указанных ниже способов:

    $ /etc/zabbix/mysql.sh global_status connections
    $ /etc/zabbix/mysql.sh trx_rseg_history_len 

Если настройки верны, скрипт должен вывести число и его можно прописать в файл конфигурации Zabbix-агента `/etc/zabbix/zabbix_agentd.conf` следующим образом:

    UserParameter=mysql[*],/etc/zabbix/mysql.sh $1 $2 $3

Как вариант, указанную выше строчку можно прописать в один из файлов в каталоге `/etc/zabbix/zabbix_agentd.d` или `/etc/zabbix/zabbix_agentd.conf.d` или создать новый файл с такой строчкой.

Для применения настроек Zabbix-агента нужно перезапустить при помощи одной из следующих команд:

    # systemctl restart zabbix-agent
    # /etc/init.d/zabbix-agent restart

Если у вас есть доступ к Zabbix-серверу или Zabbix-прокси, который осуществляет опрос Zabbix-агента, то проверить правильность настройки Zabbix-агента можно с помощью команд следующего вида:

    $ zabbix_get -s mysql.domain.tld -k mysql[trx_rseg_history_len]
    $ zabbix_get -s mysql-cluster.domain.tld -k mysql[global_status,connections]

После этого можно назначить наблюдаемому узлу шаблон [[Template_App_MySQL_Active.xml]] для контроля общих показателей производительности и исправности.

Если сервер MySQL состоит в кластере Galera, то можно добавить дополнительный шаблон [[Template_App_wsrep_Active.xml]] для контроля состояния сервера внутри кластера.

Если следить за показателями производительности не требуется, то можно ограничиться шаблоном [[Template_App_MySQL_process_Active.xml]]. Для использования этого шаблона описанная выше процедура настройки Zabbix-агента не требуется.

При необходимости вместо этих шаблонов можно воспользоваться одним из двух других, в которых вместо активного Zabbix-агента используется пассивный: [[Template_App_MySQL.xml]], [[Template_App_wsrep.xml]], [[Template_App_MySQL_process.xml]].
