Запуск Zabbix-агента в NetBSD с помощью daemontools
===================================================

В этой статье предполагается, что в системе NetBSD уже установлен и настроен Zabbix-агент, который запускается с помощью скрипта `/etc/rc.d/zabbix_agentd`. Подробнее о настройке Zabbix-агента в NetBSD можно почитать в статье [[Установка и настройка агента Zabbix в NetBSD|netbsd_zabbix_agent]].

Также в этой статье предполагается, что в системе уже установлен и настроен пакет `daemontools`. Установка и настройка пакета описана в главе [[Установка daemontools|netbsd_daemontools_gitea#daemontools]] статьи [[Запуск Gitea в NetBSD с помощью daemontools|netbsd_daemontools_gitea]].

Прежде чем приступить к настройке сервиса, внесём изменения в конфигурацию Zabbix-агента, отредактировав файл `/usr/pkg/etc/zabbix_agentd.conf`. Отключим использование PID-файла и настроим вывод журнальных сообщений на стандартный вывод:

    PidFile=/dev/null
    LogType=console

Опцию `LogFile` можно закомментировать, т.к. её значение используется только при `LogType=file`.

Создаём каталог сервиса `/service/.zabbix_agentd/:

    # mkdir -p /service/.zabbix_agentd/

Создадим внутри него файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -f /usr/pkg/etc/zabbix_agentd.conf ]
    then
            echo "Missing /usr/pkg/etc/zabbix_agentd.conf"
            exit 1
    fi
    
    exec \
    /usr/pkg/sbin/zabbix_agentd -fc /usr/pkg/etc/zabbix_agentd.conf

И сделаем его исполняемым:

    # chmod +x /service/.zabbix_agentd/run

Создадим каталог `/service/.zabbix_agentd/log/`:

    # mkdir /service/.zabbix_agentd/log/

Создадим внутри него скрипт run со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/zabbix_agentd/

И сделаем его исполняемым:

    # chmod +x /service/.zabbix_agentd/log/run

Теперь создадим каталог `/var/log/zabbix_agentd`, в котором `multilog` будет вести журналы работы сервиса:

    # mkdir /var/log/zabbix_agentd/

Установим пользователя и группу multilog владельцами этого каталога:

    chown multilog:multilog /var/log/zabbix_agentd/

Остановим Zabbix-агент, запущенный с помощью скрипта `/etc/rc.d/zabbix_agentd`:

    # /etc/rc.d/zabbix_agentd stop

Удалим имеющиеся журналы Zabbix-агента:

    # rm /var/log/zabbix_agentd.log*

Запустим сервис средствами `daemontools`, переименовав каталог сервиса:

    mv /service/.zabbix_agentd /service/zabbix_agentd

Совместимость с rc
------------------

Для совместимости с системой инициализации `/etc/rc` создадим скрипт `/etc/rc.d/zabbix_agentd` со следующим содержимым:

    #!/bin/sh
    
    # REQUIRE: DAEMON
    # PROVIDE: zabbix_agentd
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=zabbix_agentd
    rcvar=$name
    
    load_rc_config $name
    if checkyesno $rcvar ; then
            rm -f /service/$name/down
    else
            touch /service/$name/down
    fi
    
    status_cmd="/usr/pkg/bin/svstat /service/$name/ | sed -e 's,^/service/\(.*\)/: up (\(pid .*\)).*$,\1 is running as \2.,g; s,^/service/\(.*\)/: down .*,\1 is not running.,g'"
    start_cmd="/usr/pkg/bin/svc -u /service/$name/ ; echo 'Starting $name.'"
    stop_cmd="/usr/pkg/bin/svc -d /service/$name/ ; echo 'Stopping $name.'"
    restart_cmd="/usr/pkg/bin/svc -du /service/$name/ ; echo 'Restarting $name.'"
    extra_commands="status"
    
    run_rc_command "$1"

После создания файла нужно добавить права на его выполнение:

    # chmod +x /etc/rc.d/zabbxi_agentd

Теперь можно будет включать и выключать сервис zabbix_agentd привычным образом через переменную `zabbix_agentd` в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/zabbix_agentd`.
