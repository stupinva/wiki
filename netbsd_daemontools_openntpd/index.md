Запуск OpenNTPd в NetBSD с помощью daemontools
==============================================

Создаём каталог сервиса `/service/.openntpd/:

    # mkdir -p /service/.openntpd/

Создадим внутри него файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -f /usr/pkg/etc/ntpd.conf ]
    then
            echo "Missing /usr/pkg/etc/ntpd.conf"
            exit 1
    fi
    
    exec \
    /usr/pkg/sbin/ntpd -d -s -f /usr/pkg/etc/ntpd.conf

И сделаем его исполняемым:

    # chmod +x /service/.openntpd/run

Создадим каталог `/service/.openntpd/log/`:

    # mkdir /service/.openntpd/log/

Создадим внутри него скрипт `run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/openntpd/

И сделаем его исполняемым:

    # chmod +x /service/.openntpd/log/run

Теперь создадим каталог `/var/log/openntpd`, в котором multilog будет вести журналы работы сервиса:

    # mkdir /var/log/openntpd/

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/openntpd/

Остановим OpenNTPd, запущенный с помощью скрипта `/etc/rc.d/openntpd`:

    # /etc/rc.d/openntpd stop

Запустим сервис средствами `daemontools`, переименовав каталог сервиса:

    # mv /service/.openntpd /service/openntpd

Совместимость с rc
------------------

Для совместимости с системой инициализации `/etc/rc` создадим скрипт `/etc/rc.d/openntpd` со следующим содержимым:

    #!/bin/sh
    
    # REQUIRE: DAEMON
    # PROVIDE: openntpd
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=openntpd
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

    # chmod +x /etc/rc.d/openntpd

Теперь можно будет включать и выключать сервис openntpd привычным образом через переменную `openntpd` в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/openntpd`.
