Запуск chronyd в NetBSD с помощью daemontools
=============================================

[[!tag netbsd daemontools chronyd]]

Создаём каталог сервиса `/service/.chronyd/:

    # mkdir -p /service/.chronyd/

Создадим внутри него файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -f /usr/pkg/etc/chrony.conf ] ; then
            echo "Missing /usr/pkg/etc/chrony.conf"
            exit 1
    fi
    
    if [ ! -d /var/run/chronyd ] ; then
            mkdir /var/run/chronyd
    fi
    chown ntpd:ntpd /var/run/chronyd
    
    exec \
    /usr/pkg/sbin/chronyd -d -f /usr/pkg/etc/chrony.conf

И сделаем его исполняемым:

    # chmod +x /service/.chronyd/run

Создадим каталог `/service/.chronyd/log/`:

    # mkdir /service/.chronyd/log/

Создадим внутри него скрипт `run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/chronyd/

И сделаем его исполняемым:

    # chmod +x /service/.chronyd/log/run

Теперь создадим каталог `/var/log/chronyd`, в котором multilog будет вести журналы работы сервиса:

    # mkdir /var/log/chronyd/

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/chronyd/

Запустим сервис средствами `daemontools`, переименовав каталог сервиса:

    # mv /service/.chronyd /service/chronyd

Совместимость с rc
------------------

Для совместимости с системой инициализации `/etc/rc` создадим скрипт `/etc/rc.d/chronyd` со следующим содержимым:

    #!/bin/sh
    
    # REQUIRE: DAEMON
    # PROVIDE: chronyd
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=chronyd
    rcvar=$name
    
    load_rc_config $name
    if checkyesno $rcvar ; then
            rm -f /service/$name/down
    else
            touch /service/$name/down
    fi
    
    status_cmd="/usr/pkg/bin/svstat /service/$name/ | sed -e 's,^/service/\(.*\)/: up (\(pid .*\)).*$,\1 is running as \2.,g; s,^/service/\(.*\)/: down .*,\1 is not running.,g'"
    online_cmd="/usr/pkg/bin/chronyc online"
    offline_cmd="/usr/pkg/bin/chronyc offline"
    start_cmd="/usr/pkg/bin/svc -u /service/$name/ ; echo 'Starting $name.'"
    stop_cmd="/usr/pkg/bin/svc -d /service/$name/ ; echo 'Stopping $name.'"
    restart_cmd="/usr/pkg/bin/svc -du /service/$name/ ; echo 'Restarting $name.'"
    extra_commands="status online offline"
    
    run_rc_command "$1"

После создания файла нужно добавить права на его выполнение:

    # chmod +x /etc/rc.d/chroynd

Теперь можно будет включать и выключать сервис chronyd привычным образом через переменную `chronyd` в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/chronyd`.
