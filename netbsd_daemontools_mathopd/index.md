Запуск mathopd в NetBSD с помощью daemontools
=============================================

[[!tag netbsd daemontools mathopd]]

Перед тем, как приступить к настройке сервиса `daemontools`, изменим настройки журналирования в файле конфигурации `/usr/pkg/etc/mathopd.conf` самого веб-сервера `mathopd` следующим образом:

    ErrorLog /dev/stderr
    Log /dev/stderr
    #PIDFile /var/run/mathopd.pid

Создаём каталог сервиса `/service/.mathopd/`:

    # mkdir -p /service/.mathopd/

Создадим внутри каталога сервиса файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -f /usr/pkg/etc/mathopd.conf ]
    then
            echo "Missing /usr/pkg/etc/mathopd.conf"
            exit 1
    fi
    
    exec \
    /usr/pkg/sbin/mathopd -nf /usr/pkg/etc/mathopd.conf

И сделаем его исполняемым:

    # chmod +x /service/.mathopd/run

Создадим каталог `/service/.mathopd/log/`:

    # mkdir /service/.mathopd/log/

Создадим внутри него скрипт `run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/mathopd/

И сделаем его исполняемым:

    # chmod +x /service/.mathopd/log/run

Теперь создадим каталог `/var/log/mathopd`, в котором `multilog` будет вести журналы работы сервиса:

    # mkdir /var/log/mathopd/

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/mathopd/

Остановим `mathopd`, если он уже запущен с помощью скрипта `/etc/rc.d/mathopd`:

    # /etc/rc.d/mathopd stop

Запустим сервис средствами `daemontools`, переименовав каталог сервиса:

    # mv /service/.mathopd /service/mathopd

Совместимость с rc
------------------

Для совместимости с системой инициализации `/etc/rc` создадим скрипт `/etc/rc.d/mathopd` со следующим содержимым:

    #!/bin/sh
    
    # REQUIRE: DAEMON
    # PROVIDE: mathopd
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=mathopd
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

    # chmod +x /etc/rc.d/mathopd

Теперь можно будет включать и выключать сервис `mathopd` привычным образом через переменную `mathopd` в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/mathopd`.
