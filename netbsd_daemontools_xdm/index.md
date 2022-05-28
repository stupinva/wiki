Запуск xdm в NetBSD с помощью daemontools
=========================================

Настройка сервера X
-------------------

Сначала настроим сервер X, для чего выполним его автоконфигурирование, запустив следующую команду от пользователя root:

    # /usr/X11R7/bin/X -configure

В текущем каталоге появится файл `xorg.conf.new`. Его можно отредактировать, после чего проверить правильность следующей командой:

    # /usr/X11R7/bin/X -config xorg.conf.new

Если всё в порядке, то файл конфигурации можно поместить в каталог `/etc/X11` под именем `xorg.conf`:

    # mv xorg.conf.new /etc/X11/xorg.conf

Настройка xdm для запуска сервера X
-----------------------------------

Создаём файл `/etc/X11/xdm/Xservers` со следующим содержимым:

    :0 local /usr/X11R7/bin/X :0 vt04

В файле `/etc/ttys` должна быть такая строка настройки 4 консоли (нумерация консолей ttyE* начинается с нуля):

    ttyE3   "/usr/libexec/getty Pc"         wsvt25   off secure

Для того, чтобы попасть на виртуальную консоль 4, в которой запущен сервер X, нужно будет нажать сочетание клавиш `Ctrl`+`Alt`+`F4'.

При необходимости запускать несколько серверов X, строчку можно повторить, меняя номер дисплея и виртуального терминала, например, следующим образом:

    :1 local /usr/X11R7/bin/X :1 vt05

Для второго сервера X нужно будет настроить ещё одну виртуальную консоль в файле `/etc/ttys` следующим образом:

    ttyE4   "/usr/libexec/getty Pc"         wsvt25   off secure

В таком случае, для переключения на виртуальную консоль 5, в которой запущен второй сервер X, нужно будет нажать сочетание клавиш `Ctrl`+`Alt`+`F5'.

Запуск xdm через daemontools
----------------------------

Создаём каталог сервиса `/service/.xdm/`:

    # mkdir /service/.xdm

Создадим внутри каталога сервиса файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -f /etc/X11/xdm/xdm-config ]
    then
            echo "Missing /etc/X11/xdm/xdm-config"
            exit 1
    fi
    
    exec \
    /usr/X11R7/bin/xdm -nodaemon -error /dev/stdout -config /etc/X11/xdm/xdm-config

И сделаем его исполняемым:

    # chmod +x /service/.xdm/run

Создадим каталог `/service/.xdm/log/`:

    # mkdir /service/.xdm/log

Создадим внутри него скрипт `run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/xdm/

И сделаем его исполняемым:

    # chmod +x /service/.xdm/log/run

Удалим имеющийся файл журнала `xdm`:

    # rm /var/log/xdm.log

Теперь создадим каталог `/var/log/xdm`, в котором `multilog` будет вести журналы работы сервиса:

    # mkdir /var/log/xdm

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/xdm/

Теперь можно запустить `xdm`:

    # mv /service/.xdm /service/xdm

Совместимость с rc
------------------

Для совместимости с системой инициализации `/etc/rc` создадим скрипт `/etc/rc.d/xdm` со следующим содержимым:

    #!/bin/sh
    #
    # $NetBSD: xdm.in,v 1.1 2008/12/05 18:55:22 cube Exp $
    #
    
    # PROVIDE: xdm
    # REQUIRE: DAEMON LOGIN wscons
    # KEYWORD: shutdown
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=xdm
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

    # chmod +x /etc/rc.d/xdm

Теперь можно будет включать и выключать сервис xdm привычным образом через переменную `xdm` в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/xdm`.
