Запуск dhcpd в NetBSD с помощью daemontools
===========================================

[[!tag netbsd daemontools dhcpd]]

Создаём каталог сервиса `/service/.dhcpd/`:

    # mkdir /service/.dhcpd

Создадим внутри каталога сервиса файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -f /etc/dhcpd.conf ]
    then
            echo "Missing /etc/dhcpd.conf"
            exit 1
    fi
    
    if [ ! -e /var/db/dhcpd.leases ]
    then
            echo "Creating /var/db/dhcpd.leases"
            touch /var/db/dhcpd.leases
    fi
    
    exec \
    /usr/sbin/dhcpd -f -d -q -4 --no-pid -lf /var/db/dhcpd.leases -cf /etc/dhcpd.conf vioif1 vioif2

И сделаем его исполняемым:

    # chmod +x /service/.dhcpd/run

Создадим каталог `/service/.dhcpd/log/`:

    # mkdir /service/.dhcpd/log

Создадим внутри него скрипт `run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/dhcpd/

И сделаем его исполняемым:

    # chmod +x /service/.dhcpd/log/run

Теперь создадим каталог `/var/log/dhcpd`, в котором `multilog` будет вести журналы работы сервиса:

    # mkdir /var/log/dhcpd

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/dhcpd/

Готовим файл `/etc/dhcpd.conf` и запускаем сервис:

    # mv /service/.dhcpd /service/dhcpd

Стоит учесть, что в каталог `/var/log/dhcpd` будут попадать только сообщения об ошибках запуска, т.к. сам `dhcpd` отправляет свои сообщения в `syslog`.

Совместимость с rc
------------------

Для совместимости с системой инициализации `/etc/rc` создадим скрипт `/etc/rc.d/dhcpd` со следующим содержимым:

    !/bin/sh
    #
    # $NetBSD: dhcpd,v 1.7 2014/07/17 07:17:03 spz Exp $
    #
    
    # PROVIDE: dhcpd
    # REQUIRE: DAEMON
    # BEFORE:  LOGIN
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=dhcpd
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

    # chmod +x /etc/rc.d/dhcpd

Теперь можно будет включать и выключать сервис `dhcpd` привычным образом через переменную `dhcpd` в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/dhcpd`.
