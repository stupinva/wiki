Запуск powerd в NetBSD с помощью daemontools
============================================

[[!tag netbsd daemontools powerd]]

Демон `powerd` входит в штатную поставку NetBSD и отвечает за обработку событий управления электропитанием. Например, он выполняет скрипт при нажатии кнопки выключения компьютера.

Создаём каталог сервиса `/service/.powerd/`:

    # mkdir -p /service/.powerd/

Создадим внутри каталога сервиса файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -d /etc/powerd/scripts/ ]
    then
            echo "Missing /etc/powerd/scripts/"
            exit 1
    fi
    
    exec \
    /usr/sbin/powerd -d

И сделаем его исполняемым:

    # chmod +x /service/.powerd/run

Создадим каталог `/service/.powerd/log/`:

    # mkdir /service/.powerd/log/

Создадим внутри него скрипт `run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/powerd/

И сделаем его исполняемым:

    # chmod +x /service/.powerd/log/run

Теперь создадим каталог `/var/log/powerd`, в котором `multilog` будет вести журналы работы сервиса:

    # mkdir /var/log/powerd/

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/powerd/

Остановим `powerd`, запущенный с помощью скрипта `/etc/rc.d/powerd`:

    # /etc/rc.d/powerd stop

Запустим сервис средствами `daemontools`, переименовав каталог сервиса:

    # mv /service/.powerd /service/powerd

Совместимость с rc
------------------

Для совместимости с системой инициализации `/etc/rc` создадим скрипт `/etc/rc.d/powerd` со следующим содержимым:

    #!/bin/sh
    #
    # $NetBSD: powerd,v 1.2 2004/08/13 18:08:03 mycroft Exp $
    #
    
    # PROVIDE: powerd
    # REQUIRE: DAEMON
    # BEFORE:  LOGIN
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=powerd
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

    # chmod +x /etc/rc.d/powerd

Теперь можно будет включать и выключать сервис powerd привычным образом через переменную `powerd` в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/powerd`.
