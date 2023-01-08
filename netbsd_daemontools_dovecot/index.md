Запуск dovecot в NetBSD с помощью daemontools
=============================================

[[!tag netbsd daemontools dovecot]]

Создаём каталог сервиса `/service/.dovecot/`:

    # mkdir -p /service/.dovecot/

Создадим внутри каталога сервиса файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -f /usr/pkg/etc/dovecot/dovecot.conf ]
    then
            echo "Missing /usr/pkg/etc/dovecot/dovecot.conf"
            exit 1
    fi
    
    exec \
    softlimit -o 1024 \
    /usr/pkg/sbin/dovecot -F -c /usr/pkg/etc/dovecot/dovecot.conf

И сделаем его исполняемым:

    # chmod +x /service/.dovecot/run

Создадим каталог `/service/.dovecot/log/`:

    # mkdir /service/.dovecot/log/

Создадим внутри него скрипт `run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/dovecot/

И сделаем его исполняемым:

    # chmod +x /service/.dovecot/log/run

Теперь создадим каталог `/var/log/dovecot`, в котором `multilog` будет вести журналы работы сервиса:

    # mkdir /var/log/dovecot/

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/dovecot/

Остановим `dovecot`, если он уже запущен с помощью скрипта `/etc/rc.d/dovecot`:

    # /etc/rc.d/dovecot stop

Запустим сервис средствами `daemontools`, переименовав каталог сервиса:

    # mv /service/.dovecot /service/dovecot

Стоит учесть, что в каталог `/var/log/dovecot` будут попадать только сообщения об ошибках запуска, т.к. сам `dovecot` отправляет свои сообщения в `syslog`.

Совместимость с rc
------------------

Для совместимости с системой инициализации `/etc/rc` создадим скрипт `/etc/rc.d/dovecot` со следующим содержимым:

    #!/bin/sh
    
    # REQUIRE: DAEMON
    # PROVIDE: dovecot
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=dovecot
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

    # chmod +x /etc/rc.d/dovecot

Теперь можно будет включать и выключать сервис `dovecot` привычным образом через переменную `dovecot` в файле /etc/rc.conf, а также запускать, останавливать, перезапускать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/dovecot`.
