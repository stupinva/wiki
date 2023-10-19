Решение проблемы Could not increase number of max_open_files в MySQL
====================================================================

[[!tag mysql wsrep]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

Для настройки `large_pages` в Percona XtraDB Cluster Server понадобилось прописать в файл `mysql.service` строчку `AmbientCapabilities=CAP_IPC_LOCK`. Однако оказалось, что для Percona XtraDB Cluster Server 5.7 нет файла `mysql.service`, а используется скрипт `/etc/init.d/mysql`. В качестве прототипа был взят файл `mysql.servece` от Percona Server 5.7:

    #
    # Percona Server systemd service file
    #
    
    [Unit]
    Description=Percona Server
    After=network.target
    
    [Install]
    WantedBy=multi-user.target
    
    [Service]
    Type=forking
    User=mysql
    Group=mysql
    PermissionsStartOnly=true
    EnvironmentFile=-/etc/default/mysql
    ExecStartPre=/usr/share/mysql/mysql-systemd-start pre
    ExecStartPre=/usr/bin/ps_mysqld_helper
    ExecStart=/usr/sbin/mysqld --daemonize --pid-file=/var/run/mysqld/mysqld.pid $MYSQLD_OPTS
    TimeoutSec=0
    Restart=on-failure
    RestartPreventExitStatus=1

Для редактирования service-файла можно воспользоваться следующей командой:

    # systemctl edit --full mysql

Скрипт `/usr/bin/ps_mysqld_helper` предназначен для настройки плагина TokuDB и в Percona XtraDB Cluster Server отсутствует, т.к. этот плагин им не поддерживается. Нужно удалить из service-файла строчку с этим скриптом.

Кроме того, можно поправить описание сервиса в комментариях в начале файла и в строчке Description - вместо Percona Server прописать Percona XtraDB Cluster Server.

После этого можно добавить в файл желаемую строчку `AmbientCapabilities=CAP_IPC_LOCK`.

Для того, чтобы сообщить systemd о том, что service-файл изменился, воспользуемся такой командой:

    # systemctl daemon-reload

Проблема
--------

Если воспользоваться получившимся service-файлом, то можно столкнуться с проблемой: значение переменной `max_connections` может быть усечено по сравнению со значением, указанным в файле конфигурации. Если заглянуть в файл `/var/log/mysql/error.log`, то в нём можно найти предупреждения следующего вида:

    2023-10-19T05:48:08.615570Z 0 [Warning] Could not increase number of max_open_files to more than 1024 (request: 16000)
    2023-10-19T05:48:08.616141Z 0 [Warning] Changed limits: max_connections: 214 (requested 805)
    2023-10-19T05:48:08.616151Z 0 [Warning] Changed limits: table_open_cache: 400 (requested 2000)

Решение проблемы
----------------

Для решения проблемы нужно снять ограничение на максимальное количество файлов, открытых пользователем. Для этого снова отредактируем service-файл и добавим в него строчку следующего вида:

    LimitNOFILE=infinity

Итоговый service-файл
---------------------

После всех доработок у меня получился следующий service-файл:

    #
    # Percona XtraDB Cluster Server systemd service file
    #
    
    [Unit]
    Description=Percona XtraDB Cluster Server
    After=network.target
    
    [Install]
    WantedBy=multi-user.target
    
    [Service]
    Type=forking
    User=mysql
    Group=mysql
    PermissionsStartOnly=true
    EnvironmentFile=-/etc/default/mysql
    LimitNOFILE=infinity
    AmbientCapabilities=CAP_IPC_LOCK
    ExecStartPre=/usr/share/mysql/mysql-systemd-start pre
    ExecStart=/usr/sbin/mysqld --daemonize --pid-file=/var/run/mysqld/mysqld.pid $MYSQLD_OPTS
    TimeoutSec=0
    Restart=on-failure
    RestartPreventExitStatus=1
