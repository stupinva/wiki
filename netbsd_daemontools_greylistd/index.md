Запуск greylistd в NetBSD с помощью daemontools
===============================================

Создаём каталог сервиса `/service/.greylistd/`:

    # mkdir -p /service/.greylistd/

Создадим внутри него файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -f /usr/pkg/etc/greylistd/config ]
    then
            echo "Missing /usr/pkg/etc/greylistd/config"
            exit 1
    fi
    
    exec \
    /usr/pkg/bin/setuidgid greylist \
    /usr/pkg/sbin/greylistd

И сделаем его исполняемым:

    # chmod +x /service/.greylistd/run

Создадим каталог `/service/.greylistd/log/`:

    # mkdir /service/.greylistd/log/

Создадим внутри него скрипт run со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/greylistd/

И сделаем его исполняемым:

    # chmod +x /service/.greylistd/log/run

Теперь создадим каталог `/var/log/greylistd`, в котором `multilog` будет вести журналы работы сервиса:

    # mkdir /var/log/greylistd/

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/greylistd/

Запустим сервис средствами daemontools, переименовав каталог сервиса:

    # mv /service/.greylistd /service/greylistd

Совместимость с rc
------------------

Для совместимости с системой инициализации `/etc/rc` создадим скрипт `/etc/rc.d/greylistd` со следующим содержимым:

    #!/bin/sh
    
    # REQUIRE: DAEMON
    # PROVIDE: greylistd
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=greylistd
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
    reload_cmd="/usr/pkg/bin/svc -h /service/$name/ ; echo 'Reloading $name.'"
    extra_commands="status reload"
    
    run_rc_command "$1"

После создания файла нужно добавить права на его выполнение:

    # chmod +x /etc/rc.d/greylistd

Теперь можно будет включать и выключать сервис `greylistd` привычным образом через переменную greylistd в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать, перезагружать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/greylistd`.
