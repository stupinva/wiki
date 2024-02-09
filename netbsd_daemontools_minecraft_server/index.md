Запуск сервера Minecraft в NetBSD с помощью daemontools
=======================================================

[[!tag minecraft daemontools netbsd]]

Сборка пакета pkgsrc описана в статье [[Делаем pkgsrc для сервера Minecraft|pkgsrc_minecraft_server]]. Сборка пакета у меня автоматизирована в соответствии со статьёй [[Настройка сборочного сервера NetBSD|netbsd_sysbuild]], поэтому для установки пакета с сервером Minecraft в моём случае достаточно одной команды:

    # pkgin install minecraft-server

Для работы сервера создадим выделенного пользователя и группу:

    # groupadd minecraft
    # useradd -G minecraft minecraft

Сервер при запуске помещает в текущий каталог свои рабочие файлы. В качестве рабочего каталога сервера будем использовать каталог `/var/games/minecraft-server`, владельцем которого сделаем пользователя `minecraft`.

Создадим каталоги с файлами сервиса daemontools:

    # mkdir -p /service/.minecraft-server/log/

Для запуска сервера Minecraft создадим скрипт `/service/.minecraft-server/run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -d /var/games/minecraft-server ] ; then
            mkdir -p /var/games/minecraft-server
            chown minecraft:minecraft /var/games/minecraft-server
    fi
    
    cd /var/games/minecraft-server
    
    if [ -f eula.txt ] ; then
            sed -i 's/eula=false/eula=true/' eula.txt
    fi
    
    exec \
    setuidgid minecraft \
    /usr/pkg/java/openjdk17/bin/java -Xmx1024M -Xms1024M -jar /usr/pkg/lib/minecraft-server/minecraft-server.jar nogui

Скрипт запуска создаёт каталог для размещения файлов сервера Minecraft, если его ещё нет, выставляет права доступа к нему и меняет текущий каталог на каталог с файлами игры. При первом запуске сервер Minecraft распакует в этот каталог свои файлы и создаст в нём файл `eula.txt`, после чего завершит работу.

Для того, чтобы сервер Minecraft не завершал работу, нужно принять лицензионное соглашение. Для этого в скрипте запуска сервера Minecraft предусмотрена команда, которая редактирует файл `eula.txt` так, чтобы отразить в нём согласие с лицензией. Поскольку при завершении скрипта daemontools повторно запустит его, то второй запуск сервера Minecraft окажется успешным.

Для ведения журналов работы сервера Minecraft создадим скрипт `/service/.minecraft-server/log/run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/minecraft-server/

Создадим каталог для журналов сервера Minecraft и выставим права доступа к ним:

    # mkdir /var/log/minecraft-server
    # chown multilog:multilog /var/log/minecraft-server

Выставим права выполнения у скриптов запуска сервера Minecraft и сервиса ведения журналов работы сервера Minecraft:

    # chmod +x /service/.minecraft-server/run /service/.minecraft-server/log/run

Для запуска сервера остаётся переименовать каталог сервиса:

    # mv /service/.minecraft-server /service/minecraft-server

Совместимость с rc
------------------

Для совместимости с системой инициализации `/etc/rc` создадим скрипт `/etc/rc.d/minecraft_server` со следующим содержимым:

    #!/bin/sh
    
    # REQUIRE: DAEMON
    # PROVIDE: minecraft_server
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=minecraft_server
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

    # chmod +x /etc/rc.d/minecraft_server

Теперь можно будет включать и выключать сервис `minecraft_server` привычным образом через переменную `minecraft_server` в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/minecraft_server`.

Использованные материалы
------------------------

* [Скачивание сервера Minecraft: Java Edition](https://www.minecraft.net/ru-ru/download/server)
* [Ruben Schade. NetBSD can also run a Minecraft server](https://rubenerd.com/netbsd-can-also-run-a-minecraft-server/)
