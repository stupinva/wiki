Запуск exim в NetBSD с помощью daemontools
==========================================

[[!tag netbsd daemontools exim]]

exim может вести журналы только в файлы, указанные шаблоном в опции `log_file_path` и/или в `syslog`. Использование в качестве журнала стандартного вывода или стандартного потока диагностических сообщений не предусмотрено. Поскольку журналы `main` и `panic` используются для формирования отчётов для системного администратора, будем продолжать использовать их.

Создаём каталог сервиса `/service/.exim/`:

    # mkdir -p /service/.exim

Создадим внутри каталога сервиса файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -f /usr/pkg/etc/exim/configure ]
    then
            echo "Missing /usr/pkg/etc/exim/configure"
            exit 1
    fi
    
    exec \
    /usr/pkg/sbin/exim -bdf -oY -oP /dev/null -q30m -C /usr/pkg/etc/exim/configure

И сделаем его исполняемым:

    # chmod +x /service/.exim/run

Остановим `exim`, если он уже запущен с помощью скрипта `/etc/rc.d/exim`:

    # /etc/rc.d/exim stop

Запустим сервис средствами `daemontools`, переименовав каталог сервиса:

    # mv /service/.exim /service/exim

Совместимость с rc
------------------

Для совместимости с системой инициализации `/etc/rc` создадим скрипт `/etc/rc.d/exim` со следующим содержимым:

    #!/bin/sh
    #
    #       $NetBSD: exim.sh,v 1.7 2004/11/26 10:17:40 grant Exp $
    #
    # PROVIDE: mail
    # REQUIRE: LOGIN
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=exim
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

    # chmod +x /etc/rc.d/exim

Теперь можно будет включать и выключать сервис `exim` привычным образом через переменную `exim` в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/exim`.
