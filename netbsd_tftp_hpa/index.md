Настройка tftp-hpa в NetBSD
===========================

Установка tftp-hpa
------------------

Впишем в файл `/etc/mk.conf` опции сборки пакета `tftp-hpa` и требуемых им зависимостей:

    PKG_OPTIONS.tftp-hpa=           -inet6 -remap -tcpwrappers
    PKG_OPTIONS.gmake=              nls
    PKG_OPTIONS.perl=               -debug -dtrace -mstats -threads -perl-64bitall perl-64bitauto -perl-64bitint -perl-64bitmore -perl-64bitnone

Соберём и установим `tftp-hpa`:

    # cd /usr/pkgsrc/wip/tftp-hpa
    # make install

Создадим группу и пользователя, от имени которых будет работать `tftpd`:

    # groupadd tftp
    # useradd -g tftp -d /srv/tftp -m tftp

Настройка запуска через daemontools
-----------------------------------

Создаём каталог сервиса /service/.tftpd/:

    # mkdir /service/.tftpd

Создадим внутри каталога сервиса файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -d /srv/tftp ]
    then
            echo "No /srv/tftp"
            exit 1
    fi
    
    exec \
    setuidgid tftp \
    /usr/pkg/sbin/in.tftpd -4Lscpa 0.0.0.0:69 -u tftp -U 027 /srv/tftp

И сделаем его исполняемым:

    # chmod +x /service/.tftpd/run

Создадим каталог `/service/.tftpd/log/`:

    # mkdir /service/.tftpd/log

Создадим внутри него скрипт `run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/tftpd/

И сделаем его исполняемым:

    # chmod +x /service/.tftpd/log/run

Теперь создадим каталог `/var/log/tftpd`, в котором `multilog` будет вести журналы работы сервиса:

    # mkdir /var/log/tftpd/

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/tftpd/

Запустим сервис:

    # mv /servcie/.tftpd /service/tftpd

Проверить, что он действительно запустился, можно с помощью команды следующего вида:

    # netstat -anf inet | fgrep .69
    udp        0      0  *.69                   *.*  

Совместимость с rc
------------------

Для совместимости с системой инициализации `/etc/rc` создадим скрипт `/etc/rc.d/tftpd` со следующим содержимым:

    #!/bin/sh
    
    # REQUIRE: DAEMON
    # PROVIDE: tftpd
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=tftpd
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

    # chmod +x /etc/rc.d/tftpd

Теперь можно будет включать и выключать сервис `tftpd` привычным образом через переменную `tftpd` в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/tftpd`.
