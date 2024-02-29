Запуск clamd и freshclamd в NetBSD с помощью daemontools
========================================================

[[!tag netbsd daemontools clamav]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

`clamd` и `freshclamd` - это два компонента бесплатного антивируса. Первый компонент представляет собой службу, которая выполняет проверки указанных файлов на наличие зловредного кода по запросу. Второй компонент представляет собой службу для обновления баз данных антивируса. Оба компонента доступны в одном пакете с именем `clamav`, который можно установить через систему pkgsrc или из репозиториев двоичных пакетов. В статье рассматривается настройка обоих компонентов, их запуск средствами системы инициализации `daemontools` и настройка скриптов системы инициализации `rc` для совместимости с `daemontools`.

Установка clamav
----------------

Для установки готового пакета `clamav` воспользуемся командой:

     # pkgin install clamav

Настройка freshclamd
--------------------

Для настройки компонента `freshclamd` предназаначен файл конфигурации `/usr/pkg/etc/freshclamd.conf`. Права на антивирус принадлежат компании Cisco, которая ограничила доступ к антивирусным базам данных с российских IP-адресов. Тем не менее существуют зеркала этих баз данных, которые получают обновления через прокси-серверы. Одно из таких зеркал доступно по протоколу HTTP по адресу `clamav.ufanet.ru`. Для настройки зеркала воспользуемся опцией `DatabaseMirror`. Поскольку по умолчанию `freshclamd` использует подключение по протоколу HTTPS, то протокол HTTP нужно указывать явным образом.

Пропишем зеркало в файл конфигурации:

    DatabaseMirror http://clamav.ufanet.ru

Остальные настройки, на мой взгляд, имеют разумные значения по умолчанию.

### Настройка запуска freshclamd

Создаём каталог будущего сервиса:

    # mkdir /service/.freshclamd

Создаём скрипт запуска сервиса `/service/.freshclamd/run`:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -f /usr/pkg/etc/freshclam.conf ] ; then
            echo "Missing /usr/pkg/etc/freshclam.conf"
            exit 1
    fi
    
    exec \
    /usr/pkg/bin/setuidgid clamav \
    /usr/pkg/bin/freshclam --checks 2 --stdout --daemon --foreground

Создаём подкаталог для сервиса сбора журналов:

    # mkdir /service/.freshclamd/log

Создаём скрипт запуска сервиса для сбора журналов `/service/.freshclamd/log/run`:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/freshclamd/

Создаём каталог для журналов и выставляем права доступа к нему:

    # mkdir /var/log/freshclamd/
    # chown multilog:multilog /var/log/freshclamd/

Сделаем скрипты выполняемыми:

    # chmod +x /service/.freshclamd/run /service/.freshclamd/log/run

Переименовываем каталог сервиса для его запуска:

    # mv /service/.freshclamd /service/freshclamd

### Совместимость с rc

Создадим в каталоге `/etc/rc.d/` скрипт `freshclamd` следующего вида:

    #!/bin/sh
    
    # REQUIRE: DAEMON
    # PROVIDE: freshclamd
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=freshclamd
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

Сделаем скрипт выполняемым:

    # chmod +x /etc/rc.d/freshclamd

Включим сервис в файле `/etc/rc.conf`, прописав в него строчку:

    freshclamd=YES

Теперь можно будет включать и выключать сервис `freshclamd` привычным образом через переменную `freshclamd` в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать, перезагружать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/freshclamd`.

Настройка clamd
---------------

### Настройка запуска clamd

Создаём каталог будущего сервиса:

    # mkdir /service/.clamd

Создаём скрипт запуска сервиса `/service/.clamd/run`:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -f /usr/pkg/etc/clamd.conf ] ; then
            echo "Missing /usr/pkg/etc/clamd.conf"
            exit 1
    fi
    
    exec \
    /usr/pkg/bin/setuidgid clamav \
    /usr/pkg/sbin/clamd --foreground

Создаём подкаталог для сервиса сбора журналов:

    # mkdir /service/.clamd/log

Создаём скрипт запуска сервиса для сбора журналов `/service/.clamd/log/run`:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/clamd/

Создаём каталог для журналов и выставляем права доступа к нему:

    # mkdir /var/log/clamd/
    # chown multilog:multilog /var/log/clamd/

Сделаем скрипты выполняемыми:

    # chmod +x /service/.clamd/run /service/.clamd/log/run

Переименовываем каталог сервиса для его запуска:

    # mv /service/.clamd /service/clamd

### Совместимость с rc

Создадим в каталоге `/etc/rc.d/` скрипт `clamd` следующего вида:

    #!/bin/sh
    
    # REQUIRE: DAEMON
    # PROVIDE: clamd
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=clamd
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

Сделаем скрипт выполняемым:

    # chmod +x /etc/rc.d/clamd

Включим сервис в файле `/etc/rc.conf`, прописав в него строчку:

    clamd=YES

Теперь можно будет включать и выключать сервис `clamd` привычным образом через переменную `clamd` в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать, перезагружать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/clamd`.
