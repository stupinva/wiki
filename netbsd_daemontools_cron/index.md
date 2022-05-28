Запуск cron в NetBSD с помощью daemontools
==========================================

Создаём каталог сервиса /service/.cron/:

    # mkdir -p /service/.cron

Создадим внутри каталога сервиса файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    exec \
    /usr/sbin/cron -n

И сделаем его исполняемым:

    # chmod +x /service/.cron/run

Создадим каталог /service/.powerd/log/:

    # mkdir /service/.cron/log/

Создадим внутри него скрипт `run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/cron/

И сделаем его исполняемым:

    # chmod +x /service/.cron/log/run

Теперь создадим каталог `/var/log/cron`, в котором `multilog` будет вести журналы работы сервиса:

    # mkdir /var/log/cron/

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/cron/

Остановим `cron`, запущенный с помощью скрипта `/etc/rc.d/cron`:

    # /etc/rc.d/cron stop

Запустим сервис средствами `daemontools`, переименовав каталог сервиса:

    # mv /service/.cron /service/cron

Стоит учесть, что в каталог `/var/log/cron` будут попадать только сообщения об ошибках запуска, т.к. сам `cron` отправляет свои сообщения в `syslog`.

Совместимость с rc
------------------

Для совместимости с системой инициализации `/etc/rc` создадим скрипт `/etc/rc.d/cron` со следующим содержимым:

    #!/bin/sh
    #
    # $NetBSD: cron,v 1.6 2004/08/13 18:08:03 mycroft Exp $
    #
    
    # PROVIDE: cron
    # REQUIRE: LOGIN
    # KEYWORD: shutdown
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=cron
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

    # chmod +x /etc/rc.d/cron

Теперь можно будет включать и выключать сервис cron привычным образом через переменную `cron` в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/cron`.
