Запуск wpa supplicant в NetBSD с помощью daemontools
====================================================

Создаём каталог сервиса `/service/.wpa_supplicant/:

    # mkdir -p /service/.wpa_supplicant/

Создадим внутри него файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -f /etc/wpa_supplicant.conf ]
    then
            echo "Missing /etc/wpa_supplicant.conf"
            exit 1
    fi
    
    if [ ! -d /var/run/wpa_supplicant ]
    then
            mkdir -p -m 755 /var/run/wpa_supplicant
    fi
    
    exec \
    /usr/sbin/wpa_supplicant -i ath0 -c /etc/wpa_supplicant.conf

И сделаем его исполняемым:

    # chmod +x /service/.wpa_supplicant/run

Создадим каталог `/service/.wpa_supplicant/log/`:

    # mkdir /service/.wpa_supplicant/log/

Создадим внутри него скрипт `run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/wpa_supplicant/

И сделаем его исполняемым:

    # chmod +x /service/.wpa_supplicant/log/run

Теперь создадим каталог /var/log/wpa_supplicant, в котором multilog будет вести журналы работы сервиса:

    # mkdir /var/log/wpa_supplicant/

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/wpa_supplicant/

Остановим wpa_supplicant, запущенный с помощью скрипта `/etc/rc.d/wpa_supplicant`:

    # /etc/rc.d/wpa_supplicant stop

Запустим сервис средствами daemontools, переименовав каталог сервиса:

    # mv /service/.wpa_supplicant /service/wpa_supplicant

Совместимость с rc
------------------

Для совместимости wpa_supplicant с системой инициализации `/etc/rc` создадим скрипт `/etc/rc.d/wpa_supplicant` со следующим содержимым:

    #!/bin/sh
    #
    # $NetBSD: wpa_supplicant,v 1.7 2018/06/29 12:34:15 roy Exp $
    #
    
    # PROVIDE: wpa_supplicant
    # REQUIRE: network mountcritlocal
    # BEFORE:  NETWORKING dhcpcd
    #
    #       We need to run a command that resides in /usr/sbin, and the
    #       /usr file system is traditionally mounted by mountcritremote.
    #       However, we cannot depend on mountcritremote, because that
    #       would introduce a circular dependency.  Therefore, if you need
    #       wpa_supplicant to start during the boot process, you should
    #       ensure that the /usr file system is mounted by mountcritlocal,
    #       not by mountcritremote.
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=wpa_supplicant
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
    reload_cmd="/usr/sbin/wpa_cli reconfigure ; echo 'Reloading $name.'"
    extra_commands="status reload"
    
    run_rc_command "$1"
    
После создания файла нужно добавить права на его выполнение:

    # chmod +x /etc/rc.d/wpa_supplicant

Теперь можно будет включать и выключать сервис wpa_supplicant привычным образом через переменную `wpa_supplicant` в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/wpa_supplicant`.
