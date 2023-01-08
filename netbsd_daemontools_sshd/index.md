Запуск sshd в NetBSD с помощью daemontools
==========================================

[[!tag netbsd daemontools sshd]]

Содержание
----------

[[!toc levels=4 startlevel=2]]

Вариант без использования tcp-uscpi
-----------------------------------

Создаём каталог сервиса /service/.sshd/:

    # mkdir -p /service/.sshd/

Создадим внутри каталога сервиса файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -f /etc/ssh/sshd_config ]
    then
            echo "Missing /etc/ssh/sshd_config"
            exit 1
    fi
    
    /usr/bin/ssh-keygen -A

    exec \
    /usr/sbin/sshd -D -f /etc/ssh/sshd_config

И сделаем его исполняемым:

    # chmod +x /service/.sshd/run

Создадим каталог `/service/.sshd/log/`:

    # mkdir /service/.sshd/log/

Создадим внутри него скрипт `run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/sshd/

И сделаем его исполняемым:

    # chmod +x /service/.sshd/log/run

Теперь создадим каталог `/var/log/sshd`, в котором `multilog` будет вести журналы работы сервиса:

    # mkdir /var/log/sshd/

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/sshd/

Остановим `sshd`, запущенный с помощью скрипта `/etc/rc.d/sshd`:

    # /etc/rc.d/sshd stop

Запустим сервис средствами `daemontools`, переименовав каталог сервиса:

    # mv /service/.sshd /service/sshd

Вариант с использованием tcp-uscpi
----------------------------------

Обнаружил на [[просторах интернета|https://www.sanitarium.net/unix_stuff/supervise_run_scripts/sshd.txt]] такой вот скрипт для запуска `sshd` через `daemontools` с использованием утилиты `tcpserver` из пакета `tcp-uscpi`. 

Преимуществ у этого варианта запуска `sshd` всего два:

* этот способ больше соответствует подходу к разработке TCP-сервисов, принятому Дэниелом Бернштайном, автором пакетов `daemontools` и `tcp-ucspi`,
* с помощью `tcpserver` можно ограничивать количество одновременно установленных подключений.

Для использования этого способа настройки нужно установить в систему пакет `tcp-ucspi` и заменить содержимое файла `/service/sshd/run` на приведённое ниже:

    #!/bin/sh
    
    exec 2>&1

    if [ ! -f /etc/ssh/sshd_config ]
    then
            echo "Missing /etc/ssh/sshd_config"
            exit 1
    fi

    /usr/bin/ssh-keygen -A
    
    exec \
    /usr/pkg/bin/tcpserver -c10 -HRv -l0 0 22 \
    /usr/sbin/sshd -Die -u0 -f /etc/ssh/sshd_config

Совместимость с rc
------------------

Для совместимости с системой инициализации `/etc/rc` создадим скрипт `/etc/rc.d/sshd` со следующим содержимым:

    #!/bin/sh
    #
    # $NetBSD: sshd,v 1.29 2018/05/26 19:18:11 riastradh Exp $
    #
    
    # PROVIDE: sshd
    # REQUIRE: LOGIN
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=sshd
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

    # chmod +x /etc/rc.d/sshd

Теперь можно будет включать и выключать сервис sshd привычным образом через переменную `sshd` в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/sshd`.
