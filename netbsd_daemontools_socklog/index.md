Запуск socklog в NetBSD с помощью daemontools
=============================================

Оглавление
----------

[[!toc startlevel=2 levels=2]]

`socklog` - это сервис из одноимённого пакета, которым можно заменить стандартный `syslogd`. Он умеет принимать сообщения по протоколу `syslogd`, но вместо того, чтобы записывать их в разные файлы в соответствии со сложными правилами, он просто выводит их в текстовом виде на стандартный вывод. Эта программа предназначена быть прослойкой между теми программами, которые не умеют выводить свои журнальные сообщения на стандартный вывод (или стандартный поток диагностики) и утилитой `multilog` из пакета `daemontools`. Её можно запускать для приёма сообщений на Unix-сокете, на UDP-сокете или для приёма сообщений по протоколу TCP с помощью программы `tcpserver` из пакета `ucspi-tcp`.

Настройка socklog на Unix-сокете
--------------------------------

Рассмотрим настройку `socklogd` для приёма сообщений на Unix-сокете.

Создаём каталог сервиса `/service/.socklog_unix/`:

    # mkdir /service/.socklog_unix

Внутри создаём подкаталог `env` для настройки переменных окружения демона:

    # mkdir /service/.socklog_unix/env

И создадим файлы со значениями переменных окружения `UID` и `GID`, внутри которых укажем имя пользователя и группу, от имени которых должен работать демон:

    # echo -n "multilog" > /service/.socklog_unix/env/UID
    # echo -n "multilog" > /service/.socklog_unix/env/GID

Создадим внутри каталога сервиса файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    exec \
    /usr/pkg/sbin/socklog unix /var/run/log

И сделаем его исполняемым:

    # chmod +x /service/.socklog_unix/run

Создадим каталог `/service/.socklog_unix/log/`:

    # mkdir /service/.socklog_unix/log/

Создадим внутри него скрипт `run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/socklog-unix/

И сделаем его исполняемым:

    # chmod +x /service/.socklog_unix/log/run

Теперь создадим каталог `/var/log/socklog-unix`, в котором `multilog` будет вести журналы работы сервиса:

    # mkdir /var/log/socklog-unix/

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/socklog-unix/

Остановим `syslogd`, запущенный с помощью скрипта `/etc/rc.d/syslogd`:

    # /etc/rc.d/syslogd stop

Запустим сервис средствами `daemontools`, переименовав каталог сервиса:

    # mv /service/.socklog_unix /service/socklog_unix

После того, как все сообщения, ранее принимавшиеся `syslogd`, начнут собираться `socklog`, отпадает надобность в некоторых журнальных файлах, список которых можно посмотреть в файле конфигурации `/etc/syslogd.conf`. Удалим их:

    # rm /var/log/messages /var/log/messages.*
    # rm /var/log/authlog /var/log/authlog.*
    # rm /var/log/cron /var/log/cron.*
    # rm /var/log/xferlog /var/log/xferlog.*
    # rm /var/log/lpd-errs /var/log/lpd-errs.*
    # rm /var/log/maillog /var/log/maillog.*

Настройка socklog на UDP-порту
------------------------------

Теперь настроим `socklog` для приёма сообщений на 514 порту UDP.

Создаём каталог сервиса `/service/.socklog_inet/`:

    # mkdir /service/.socklog_inet

Внутри создаём подкаталог `env` для настройки переменных окружения демона:

    # mkdir /service/.socklog_inet/env

И создадим файлы со значениями переменных окружения `UID` и `GID`, внутри которых укажем имя пользователя и группу, от имени которых должен работать демон:

    # echo -n "multilog" > /service/.socklog_inet/env/UID
    # echo -n "multilog" > /service/.socklog_inet/env/GID

Создадим внутри каталога сервиса файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    exec \
    /usr/pkg/sbin/socklog inet 0 514

И сделаем его исполняемым:

    # chmod +x /service/.socklog_inet/run

Создадим каталог `/service/.socklog_inet/log/`:

    # mkdir /service/.socklog_inet/log/

Создадим внутри него скрипт `run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/socklog-inet/

И сделаем его исполняемым:

    # chmod +x /service/.socklog_inet/log/run

Теперь создадим каталог `/var/log/socklog-inet`, в котором multilog будет вести журналы работы сервиса:

    # mkdir /var/log/socklog-inet/

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/socklog-inet/

Запустим сервис средствами `daemontools`, переименовав каталог сервиса:

    # mv /service/.socklog_inet /service/socklog_inet

Для проверки работы UDP-сервера `socklog` можно воспользоваться, например, утилитой `logger` из Linux:

    $ logger -n 192.168.254.2 -d -P 514 "test"

Настройка socklog на TCP-порту
------------------------------

Ну и наконец, для полного комплекта можно настроить `socklog` для приёма сообщений на 514 порту TCP (для этого понадобится установить пакет `ucspi-tcp`).

Создаём каталог сервиса /service/.socklog_ucspi/:

    # mkdir /service/.socklog_ucspi

Внутри создаём подкаталог `env` для настройки переменных окружения демона:

    # mkdir /service/.socklog_ucspi/env

И создадим файлы со значениями переменных окружения `UID` и `GID`, внутри которых укажем имя пользователя и группу, от имени которых должен работать демон:

    # echo -n "multilog" > /service/.socklog_ucspi/env/UID
    # echo -n "multilog" > /service/.socklog_ucspi/env/GID

Создадим внутри каталога сервиса файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    exec \
    /usr/pkg/bin/tcpserver -c10 -HRv -l0 0 514 \
    /usr/pkg/sbin/socklog ucspi TCPREMOTEHOST

И сделаем его исполняемым:

    # chmod +x /service/.socklog_ucspi/run

Создадим каталог `/service/.socklog_ucspi/log/`:

    # mkdir /service/.socklog_ucspi/log/

Создадим внутри него скрипт `run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/socklog-ucspi/

И сделаем его исполняемым:

    # chmod +x /service/.socklog_ucspi/log/run

Теперь создадим каталог `/var/log/socklog-ucspi`, в котором `multilog` будет вести журналы работы сервиса:

    # mkdir /var/log/socklog-ucspi/

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/socklog-ucspi/

Запустим сервис средствами `daemontools`, переименовав каталог сервиса:

    # mv /service/.socklog_ucspi /service/socklog_ucspi

Для проверки из Linux можно воспользоваться командой `logger` следующего вида:

    $ logger -n 192.168.254.2 -T -P 514 "test"

Совместимость socklog на Unix-сокете с rc
-----------------------------------------

Для совместимости socklog на Unix-сокете с системой инициализации `/etc/rc` создадим скрипт `/etc/rc.d/socklog_unix` со следующим содержимым:

    #!/bin/sh
    
    # REQUIRE: DAEMON
    # PROVIDE: socklog_unix
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=socklog_unix
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

    # chmod +x /etc/rc.d/socklog_unix

Теперь можно будет включать и выключать сервис socklog на Unix-сокете привычным образом через переменную `socklog_unix` в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/socklog_unix`.

Совместимость socklog на UDP-порту с rc
---------------------------------------

Для совместимости socklog на UDP-порту с системой инициализации `/etc/rc` создадим скрипт `/etc/rc.d/socklog_inet` со следующим содержимым:

    #!/bin/sh
    
    # REQUIRE: DAEMON
    # PROVIDE: socklog_inet
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=socklog_inet
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

    # chmod +x /etc/rc.d/socklog_inet

Теперь можно будет включать и выключать сервис socklog на UDP-порту привычным образом через переменную `socklog_inet` в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/socklog_inet`.

Совместимость socklog на TCP-порту с rc
---------------------------------------

Для совместимости socklog на TCP-порту с системой инициализации `/etc/rc` создадим скрипт `/etc/rc.d/socklog_ucspi` со следующим содержимым:

    #!/bin/sh
    
    # REQUIRE: DAEMON
    # PROVIDE: socklog_ucspi
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=socklog_ucpsi
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

    # chmod +x /etc/rc.d/socklog_ucspi

Теперь можно будет включать и выключать сервис socklog на UDP-порту привычным образом через переменную `socklog_ucspi` в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/socklog_ucspi`.

Распределение сообщений по отдельным журналам
---------------------------------------------

У меня есть несколько сетевых устройств, которые отправляют сообщения по сети на 514 порт UDP. Мне было бы удобнее, чтобы эти сообщения попадали в отдельные журналы. К счастью, настроить это допольно просто. Для этого можно воспользоваться штатными возможностями `multilog`. Достаточно добавить в командную строку запуска `multilog` дополнительные опции. Опции, начинающиеся со знака `+` указывают фильтр сообщений, которые должны попасть в указанный за ними журнал. Опции, начинающиеся со знака `-` наоборот, позволяют исключить из журнала соответствующие им сообщения. Например, следующим образом я настроил фильтрацию сообщений по IP-адресам устройств:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t \
            '+*' \
            '-* 192.168.254.6:*' \
            '-* 192.168.254.24:*' \
            '-* 192.168.254.28:*' \
            '-* 192.168.254.8:*' \
            '-* 192.168.254.9:*' /var/log/socklog-inet/ \
            '-*' '+* 192.168.254.6:*' /var/log/socklog-inet-dlink/ \
            '-*' '+* 192.168.254.24:*' /var/log/socklog-inet-snr/ \
            '-*' '+* 192.168.254.28:*' /var/log/socklog-inet-huawei/ \
            '-*' '+* 192.168.254.8:*' /var/log/socklog-inet-ata1/ \
            '-*' '+* 192.168.254.9:*' /var/log/socklog-inet-ata2/ \
            '-*' '+* 192.168.253.31:*' /var/log/socklog-inet-ubiquiti/

Сообщения от коммутаторов D-Link, SNR и Huawei, от двух голосовых шлюзов Cisco ATA и от точки доступа Ubiquiti будут попадать в отдельные журналы. Все остальные сообщения, если таковые вдруг откуда-то появятся, будут попадать в общий журнал для всех остальных устройств.
