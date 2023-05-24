Мониторинг ClickHouse с помощью Zabbix
======================================

[[!tag clickhouse zabbix]]

Для мониторинга используется сценарий [[clickhouse.sh]], который нужно положить в каталог `/etc/zabbix`, где находится конфигурация Zabbix-агента. Его владельцем можно сделать пользователя root и дать права читать и выполнять его всем:

    # chown root:root /etc/zabbix/clickhouse.sh
    # chmod u=rwx,go=rx /etc/zabbix/clickhouse.sh

Сценарий использует для работы файл `/etc/zabbix/clickhouse.xml`, в котором должны быть указаны настройки для подключения к ClickHouse. Файл имеет следующий формат:

    <config>
            <host>127.0.0.1</host>
            <port>9000</port>
            <user>zabbix</user>
            <password>zabbix_p4$$w0rd</password>
            <database>system</database>
    </config>

Для того, чтобы файл смог изменять только пользователь `root`, а читать смог только пользователь `zabbix`, от имени которого работает Zabbbix-агент, можно выставить права доступа к этому файлу следующим образом:

    # chown root:zabbix /etc/zabbix/clickhouse.xml
    # chmod u=rw,g=r,o= /etc/zabbix/clickhouse.xml

Для мониторинга пользователю ClickHouse понадобятся права доступа к нескольким таблицам в базе данных `system`. Нужно создать пользователя с соответствующими правами, логин и пароль которого были указаны в файле `/etc/zabbix/clickhouse.xml`. Для этого нужно выполнить от имени администратора ClickHouse SQL-запросы следующего вида:

    CREATE USER zabbix IDENTIFIED BY 'zabbix_p4$$w0rd';
    GRANT SELECT ON system.metrics TO zabbix;
    GRANT SELECT ON system.asynchronous_metrics TO zabbix;
    GRANT SELECT ON system.events TO zabbix;
    GRANT SELECT ON system.processes TO zabbix;

Для проверки правильности настроек можно вызвать скрипт, одним из указанных ниже способов:

    $ /etc/zabbix/clickhouse.sh Version
    $ /etc/zabbix/clickhouse.sh Query

Если настройки верны, скрипт должен вывести версию сервера или количество выполняемых в настоящее время запросов. В таком случае можно продолжить и прописать в файл конфигурации Zabbix-агента `/etc/zabbix/zabbix_agentd.conf` следующим образом:

    UserParameter=clickhouse[*],/etc/zabbix/clickhouse.sh "$1"

Как вариант, указанную выше строчку можно прописать в один из файлов в каталоге `/etc/zabbix/zabbix_agentd.d` или `/etc/zabbix/zabbix_agentd.conf.d` или создать новый файл с такой строчкой.

Для применения настроек Zabbix-агента нужно перезапустить при помощи одной из следующих команд:

    # systemctl restart zabbix-agent
    # /etc/init.d/zabbix-agent restart

Если у вас есть доступ к Zabbix-серверу или Zabbix-прокси, который осуществляет опрос Zabbix-агента, то проверить правильность настройки Zabbix-агента можно с помощью команд следующего вида:

    $ zabbix_get -s clickhouse.domain.tld -k clickhouse[Version]
    $ zabbix_get -s clickhouse-server.domain.tld -k clickhouse[Query]

После этого можно назначить наблюдаемому узлу шаблон [[Template_App_ClickHouse_Active.xml]] для контроля общих показателей производительности и исправности.

При необходимости вместо этого шаблона можно воспользоваться другим, в котором вместо активного Zabbix-агента используется пассивный: [[Template_App_ClickHouse.xml]].

Дополнительные материалы
------------------------

* [Setup & maintenance / ClickHouse Monitoring](https://kb.altinity.com/altinity-kb-setup-and-maintenance/altinity-kb-monitoring/)
* [Altinity / clickhouse-zabbix-template](https://github.com/Altinity/clickhouse-zabbix-template)
