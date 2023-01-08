Запуск Gitea в NetBSD с помощью daemontools
===========================================

[[!tag netbsd daemontools gitea git]]

Оглавление
----------

[[!toc startlevel=2 levels=3]]

Введение
--------

Моё знакомство с `daemontools` началось с одной стороны случайно, а с другой стороны - с необходимости.

Случайные обстоятельства были следующими. При настройке `ikiwiki` я рассматривал различные приложения для обработки CGI-запросов и на странице руководства одного из них - spawn-fcgi - упоминались программы svc и supervise со ссылкой на страницу [http://cr.yp.to/daemontools.html](http://cr.yp.to/daemontools.html).

А вот необходимость возникла после того, как я установил Gitea в виртуальной машине с NetBSD. У Gitea есть одна интересная особенность: в ней не предусмотрен запуск в режиме демона, Gitea может работать только в интерактивном режиме. Это не проблема, если в системе есть systemd, но в NetBSD systemd нет. В скрипте инициализации, поставляющемся в составе pkgsrc, запуск Gitea в фоновом режиме реализован при помощи символа амерсанда, добавленного к списку аргументов:

    #!/bin/sh
    #
    # $NetBSD: gitea.sh,v 1.2 2019/08/04 12:26:59 nia Exp $
    #
    # REQUIRE: DAEMON
    # PROVIDE: gitea
    
    . /etc/rc.subr
    
    name="gitea"
    rcvar=${name}
    required_files="/usr/pkg/etc/gitea/conf/app.ini"
    command="/usr/pkg/sbin/gitea"
    command_args="--config /usr/pkg/etc/gitea/conf/app.ini 2>/dev/null >/dev/null &"
    
    gitea_env="GITEA_WORK_DIR=/usr/pkg/share/gitea"
    gitea_env="${gitea_env} GITEA_CUSTOM=/usr/pkg/etc/gitea"
    gitea_env="${gitea_env} HOME=/var/db/gitea"
    gitea_env="${gitea_env} USER=git"
    
    gitea_user="git"
    gitea_group="git"
    
    load_rc_config $name
    run_rc_command "$1"

Кроме того, т.к. Gitea выводит соообщения в процессе работы прямо на стандартный вывод и на стандартный поток диагностических сообщений, к опциям добавлены конструкции, перенаправляющие текст в устройство `/dev/null`. Мало того, что все эти конструкции для оболочки в списке аргументов кажутся чужеродными, по каким-то неведомым причинам Gitea не запускается при загрузке системы. После входа по SSH и ручного запуска Gitea запускается и работает нормально до следующего перезапуска системы.

Т.к. все эти конструкции на меня производят удручающее впечатление, то и разбираться в причинах проблемы мне не хотелось. В NetBSD нет systemd, при помощи которого можно было бы решить эту проблему, но зато в системе pkgsrc есть daemontools от Дэниела Бернштайна. Программы Дэниела Бернштайна большинству пользователей кажутся довольно неуклюжими, поэтому ими мало кто пользуется. Однако идеи, реализованные в этих программах, оказываются передовыми и часто перенимаются последователями. А по поводу кажущейся неуклюжести можно возразить, что при ближайшем рассмотрении эти программы оказываются написанными в соответствии с принципами Unix в их предельном выражении: каждая программа должна решать только одну задачу, но решать её хорошо.

Установка daemontools
---------------------

Воспользуемся готовым pkgsrc и установим daemontools:

    # cd /usr/pkgsrc/sysutils/daemontools
    # make install

Создадим каталог `/service/`, в котором будут располагаться настройки сервисов, управляемых daemontools:

    # mkdir /service/

Пропишем запуск главного процесса daemontools в файл /etc/rc.local, чтобы он запускался при загрузке системы:

    #       $NetBSD: rc.local,v 1.32 2008/06/11 17:14:52 perry Exp $
    #       originally from: @(#)rc.local   8.3 (Berkeley) 4/28/94
    #
    # This file is (nearly) the last thing invoked by /etc/rc during a
    # normal boot, via /etc/rc.d/local.
    #
    # It is intended to be edited locally to add site-specific boot-time
    # actions, such as starting locally installed daemons.
    #
    # An alternative option is to create site-specific /etc/rc.d scripts.
    #
    
    echo -n 'Starting local daemons:'
    
    # Add your local daemons here, eg:
    #
    #if [ -x /path/to/daemon ]; then
    #       /path/to/daemon args
    #fi
    
    if [ -x /usr/pkg/bin/svscanboot ]; then
            csh -cf '/usr/pkg/bin/svscanboot &'
    fi
        
    echo '.'

И запустим `svcscanboot` вручную прямо сейчас:

    # /usr/pkg/bin/svscanboot &

Создадим группу и пользователя mulitlog, которые будем использовать в качетсве группы доступа и владельца журналов, формируемых утилитой multilog из пакета daemontools:

    # groupadd multilog
    # useradd -g multilog -d /var/log/ multilog

Настройка запуска Gitea
-----------------------

Выставим в секции `[log]` файла `конфигурации /usr/pkg/etc/gitea/conf/app.ini` режим журналирования:

    MODE = console

Создадим каталог `/service/.gitea`:

    # mkdir /service/.gitea

Создадим внутри него файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    if [ -f /usr/pkg/etc/gitea/conf/app.ini ]
    then
            exec \
            envdir ./env \
            setuidgid git \
            /usr/pkg/sbin/gitea --config /usr/pkg/etc/gitea/conf/app.ini web
    else
            echo "Missing /usr/pkg/etc/gitea/conf/app.ini"
            exit 1
    fi

И сделаем его исполняемым:

    # chmod +x /service/.gitea/run

Теперь создадим каталог `/service/.gitea/env`, а в нём по файлу для каждой из переменных окружения, которые нужно передать сервису:

    # mkdir /service/.gitea/env/
    # cd /service/.gitea/env/
    # echo -n "/usr/pkg/etc/gitea" > GITEA_CUSTOM
    # echo -n "/usr/pkg/share/gitea" > GITEA_WORK_DIR
    # echo -n "/var/db/gitea" > HOME
    # echo -n "git" > USER

В принципе, этого уже достаточно для того, чтобы `daemontools` смог запустить Gitea, но при помощи этого пакета можно собирать в журнал сообщения, выводимые Gitea на консоль.

Создадим каталог `/service/.gitea/log`:

    # mkdir /service/.gitea/log

Создадим скрипт `/service/.gitea/log/run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/gitealog/

Сделаем файл `/service/.gitea/log/run` исполнимым:

    # chmod +x /service/.gitea/log/run

Создадим каталог `/var/log/gitealog/`, принадлежащий пользователю `multilog` и группе `multilog`:

    # mkdir -p /var/log/gitealog/
    # chown multilog:multilog /var/log/gitealog/

Существующий каталог `/var/log/gitea/` можно удалить:

    # rm -R /var/log/gitea/

Однако стоит учитывать, что этот каталог будет вновь создаваться при каждой переустановке или обновлении Gitea, а его владельцем будет пользователь `git` и группа `git`. Именно по этой причине я указал утилите `multilog` для ведения журналов другой каталог - `/var/log/gitealog/`.

Перед тем, как запустить сервис при помощи `daemontools`, остановим демон Gitea, запущенный при помощи стандартного скрипта инициализации `/etc/rc.d/gitea`:

    # /etc/rc.d/gitea stop

Для запуска сервиса переименуем каталог `/service/.gitea` в `/service/gitea`:

    # mv /service/.gitea /service/gitea


Теперь нужно отключить запуск Gitea скриптом инициализации `/etc/rc.d/gitea` при загрузки системы. Для этого нужно удалить из файла `/etc/rc.conf` строчку `gitea=YES`. Также можно удалить и сам сценарий инициализации `/etc/rc.d/gitea`, т.к. он не входит в состав базовой системы NetBSD и был помещён туда вручную при настройке Gitea.

Теперь при перезагрузке системы Gitea у меня запускается автоматически и без проблем.

Управление сервисом
-------------------

Чтобы проверить состояние сервиса, можно воспользоваться следующей командой:

    # svstat /service/gitea/
    /service/gitea/: up (pid 14327) 315 seconds

Чтобы остановить сервис, можно воспользоваться такой командой:

    # svc -d /service/gitea/

Если проверить состояние сервиса сейчас, то можно будет увидеть следующее:

    # svstat /service/gitea/
    /service/gitea/: down 1 seconds, normally up
 
Чтобы снова запустить сервис, можно воспользоваться такой командой:

    # svc -u /service/gitea/

Для перезапуска сервиса путём его остановки и повторного запуска, можно воспользоваться такой командой:

    # svc -du /service/gitea/

Некоторые сервисы умеют обрабатывать сигнал HUP, по которому они перечитывают и применяют изменения в файле конфигурации. Кроме того, подобные сервисы обычно также закрывают и повторно открывают файлы журналов, что не так важно, если журналами управляет `multilog`.

Просмотр журналов
-----------------

Один из плюсов программы `multilog` заключается в том, что она умеет выполнять автоматическую ротацию журналов: при достижении журналом размера более 99999 байт создаётся новый журнал, всего поддерживается не более 10 журналов. При необходимости эти настройки можно поменять, передав multilog соответствующие опции, о которых можно почитать на его странице руководства.

Для ротации журналов не требуется каким-либо образом извещать сервис о необходимости переоткрыть файлы журала, т.к. данные со стандартного вывода и стандартного потока диагностических сообщений попадают в канал, откуда их подхватывает `multilog`. Сам `multilog` следит за размером файла журнала, при необходимости создаёт новый файл, удаляет устаревшие журналы и продолжает запись в только что созданный журнальный файл.

В файле /var/log/gitea/current можно увидеть текст, который выводит Gitea в процессе работы:

    # tail -f /var/log/gitea/current 
    @40000000612f62c30620e2c4 2021/09/01 16:23:37 routers/init.go:134:GlobalInit() [T] Custom path: /usr/pkg/etc/gitea
    @40000000612f62c307bc7224 2021/09/01 16:23:37 routers/init.go:135:GlobalInit() [T] Log path: /var/log/gitea
    @40000000612f62c307bcc044 2021/09/01 16:23:37 routers/init.go:56:checkRunMode() [I] Run Mode: Production
    @40000000612f646a0c75720c 2021/09/01 16:30:40 cmd/web.go:108:runWeb() [I] Starting Gitea on PID: 14056
    @40000000612f646a0c8e707c 2021/09/01 16:30:40 ...dules/setting/git.go:91:newGit() [I] Git Version: 2.32.0, Wire Protocol Version 2 Enabled
    @40000000612f646a0d50bac4 2021/09/01 16:30:40 routers/init.go:132:GlobalInit() [T] AppPath: /usr/pkg/sbin/gitea
    @40000000612f646a0d515ed4 2021/09/01 16:30:40 routers/init.go:133:GlobalInit() [T] AppWorkPath: /usr/pkg/share/gitea
    @40000000612f646a0d527044 2021/09/01 16:30:40 routers/init.go:134:GlobalInit() [T] Custom path: /usr/pkg/etc/gitea
    @40000000612f646a100bb444 2021/09/01 16:30:40 routers/init.go:135:GlobalInit() [T] Log path: /var/log/gitea
    @40000000612f646a100c1dbc 2021/09/01 16:30:40 routers/init.go:56:checkRunMode() [I] Run Mode: Production

В начале каждой строки `multilog` добавляет закодированную отметку времени, о чём мы его попросили при помощи опции `t`. Посмотреть эти метки в раскодированном виде можно с помощюь утилиты `tai64nlocal`, например, следующим образом:

    # tail -f /var/log/gitea/current | tai64nlocal
    2021-09-01 16:23:37.102818500 2021/09/01 16:23:37 routers/init.go:134:GlobalInit() [T] Custom path: /usr/pkg/etc/gitea
    2021-09-01 16:23:37.129790500 2021/09/01 16:23:37 routers/init.go:135:GlobalInit() [T] Log path: /var/log/gitea
    2021-09-01 16:23:37.129810500 2021/09/01 16:23:37 routers/init.go:56:checkRunMode() [I] Run Mode: Production
    2021-09-01 16:30:40.209023500 2021/09/01 16:30:40 cmd/web.go:108:runWeb() [I] Starting Gitea on PID: 14056
    2021-09-01 16:30:40.210661500 2021/09/01 16:30:40 ...dules/setting/git.go:91:newGit() [I] Git Version: 2.32.0, Wire Protocol Version 2 Enabled
    2021-09-01 16:30:40.223394500 2021/09/01 16:30:40 routers/init.go:132:GlobalInit() [T] AppPath: /usr/pkg/sbin/gitea
    2021-09-01 16:30:40.223436500 2021/09/01 16:30:40 routers/init.go:133:GlobalInit() [T] AppWorkPath: /usr/pkg/share/gitea
    2021-09-01 16:30:40.223506500 2021/09/01 16:30:40 routers/init.go:134:GlobalInit() [T] Custom path: /usr/pkg/etc/gitea
    2021-09-01 16:30:40.269202500 2021/09/01 16:30:40 routers/init.go:135:GlobalInit() [T] Log path: /var/log/gitea
    2021-09-01 16:30:40.269229500 2021/09/01 16:30:40 routers/init.go:56:checkRunMode() [I] Run Mode: Production

Первыми отображаются отметки времени добавленные `multilog`, а далее следуют отметки времени от самой Gitea.

Среди прочих опций `multilog` можно указать программу-фильтр. Если в качестве программы-фильтра указать утилиту `tai64nlocal`, то в журналах на диске будут фигурировать не закодированные отметки времени, а пригодные для чтения человеком.

И кроме этого, можно настроить `multilog` так, чтобы он выделял из потока сообщений отдельные сообщения в соответствии с указанными критериями и помещал их в отдельные журналы. Кроме того, любой из журналов можно превратить в файл статуса, в котором будет храниться только последняя строчка, соответствующая указанным критериям фильтрации. Примеры подобной настройки `multilog` можно найти в статьях [[Запуск socklog в NetBSD с помощью daemontools|netbsd_daemontools_socklog]] и [[Мониторинг dnscache из djbdns в NetBSD через Zabbix-агента|netbsd_dnscache_zabbix_agent]].

Просмотр дерева процессов
-------------------------

Для просомтра дерева процессов можно воспользоваться стандартной системной командой `ps`, запустив её следующим образом:

    # ps -Ado pid,command 
      PID COMMAND
        0 [system]
        1 - init 
      277 |-- /bin/sh /usr/pkg/bin/svscanboot 
      326 | |-- readproctitle service errors: .................................................................................................................
      332 | `-- svscan /service 
      271 |   |-- supervise zabbix_agentd 
      439 |   | `-- /usr/pkg/sbin/zabbix_agentd -fc /usr/pkg/etc/zabbix_agentd.conf 
      367 |   |   |-- zabbix_agentd: listener #1 [waiting for connection] 
      430 |   |   |-- zabbix_agentd: collector [idle 1 sec] 
      432 |   |   `-- zabbix_agentd: active checks #1 [idle 1 sec] 
      295 |   |-- supervise powerd 
      383 |   | `-- /usr/sbin/powerd -d 
      308 |   |-- supervise sshd 
      389 |   | `-- /usr/pkg/bin/tcpserver -c10 -HRv -l0 0 22 /usr/sbin/sshd -Die -u0 -f /etc/ssh/sshd_config 
     9157 |   |   `-- sshd: stupin [priv] 
     8740 |   |     `-- sshd: stupin@pts/0 (sshd)
     9062 |   |       `-- -sh 
    14584 |   |         `-- su - 
     9067 |   |           `-- -sh 
     9183 |   |             `-- ps -Ado pid,command 
      314 |   |-- supervise log 
       96 |   | `-- multilog t /var/log/cron/ 
      330 |   |-- supervise log 
      427 |   | `-- multilog t /var/log/zabbix_agentd/ 
      334 |   |-- supervise openntpd 
    12204 |   | `-- /usr/pkg/sbin/ntpd -d -s -f /usr/pkg/etc/ntpd.conf 
     4760 |   |   `-- ntpd: ntp engine 
    12187 |   |     `-- ntpd: dns engine 
      336 |   |-- supervise log 
      547 |   | `-- multilog t /var/log/sshd/ 
      337 |   |-- supervise gitea 
      380 |   | `-- /usr/pkg/sbin/gitea --config /usr/pkg/etc/gitea/conf/app.ini web 
      338 |   |-- supervise log 
      516 |   | `-- multilog t /var/log/openntpd/ 
      339 |   |-- supervise log 
      472 |   | `-- multilog t /var/log/gitealog/ 
      345 |   |-- supervise log 
      484 |   | `-- multilog t /var/log/powerd/ 
      349 |   |-- supervise log 
       98 |   | `-- multilog t /var/log/socklog-unix/ 
      350 |   |-- supervise cron 
       41 |   | `-- /usr/sbin/cron -n 
      357 |   `-- supervise socklog-unix 
       97 |     `-- /usr/pkg/sbin/socklog nix /var/run/log 
      422 |-- /usr/libexec/getty Pc constty 
      327 |-- /usr/libexec/getty Pc ttyE1 
      104 |-- /usr/libexec/getty Pc ttyE2 
       73 `-- /usr/libexec/getty Pc ttyE3 

Если установить в систему утилиту `proctree` из pkgsrc `pstree`, то можно увидеть следующую иерархию процессов:

    # proctree -g3
    ─┬= 00001 root init 
     ├─┬= 00277 root /bin/sh /usr/pkg/bin/svscanboot 
     │ ├─── 00326 root readproctitle service errors: ................................................................................................
     │ └─┬─ 00332 root svscan /service 
     │   ├─┬─ 00271 root supervise zabbix_agentd 
     │   │ └─┬─ 00439 zabbix /usr/pkg/sbin/zabbix_agentd -fc /usr/pkg/etc/zabbix_agentd.conf 
     │   │   ├─── 00367 zabbix zabbix_agentd: listener #1 [waiting for connection] 
     │   │   ├─── 00430 zabbix zabbix_agentd: collector [idle 1 sec] 
     │   │   └─── 00432 zabbix zabbix_agentd: active checks #1 [idle 1 sec] 
     │   ├─┬─ 00295 root supervise powerd 
     │   │ └─── 00383 root /usr/sbin/powerd -d 
     │   ├─┬─ 00308 root supervise sshd 
     │   │ └─┬─ 00389 root /usr/pkg/bin/tcpserver -c10 -HRv -l0 0 22 /usr/sbin/sshd -Die -u0 -f /etc/ssh/sshd_config 
     │   │   └─┬─ 09157 root sshd: stupin [priv] 
     │   │     └─┬─ 08740 stupin sshd: stupin@pts/0 (sshd)
     │   │       └─┬= 09062 stupin -sh 
     │   │         └─┬= 14584 root su - 
     │   │           └─┬= 09067 root -sh 
     │   │             └─┬= 15672 root proctree -g3 
     │   │               └─── 08948 root ps -axwwo user,pid,ppid,pgid,command 
     │   ├─┬─ 00314 root supervise log 
     │   │ └─── 00096 multilog multilog t /var/log/cron/ 
     │   ├─┬─ 00330 root supervise log 
     │   │ └─── 00427 multilog multilog t /var/log/zabbix_agentd/ 
     │   ├─┬─ 00334 root supervise openntpd 
     │   │ └─┬─ 12204 root /usr/pkg/sbin/ntpd -d -s -f /usr/pkg/etc/ntpd.conf 
     │   │   └─┬─ 04760 _ntp ntpd: ntp engine 
     │   │     └─── 12187 _ntp ntpd: dns engine 
     │   ├─┬─ 00336 root supervise log 
     │   │ └─── 00547 multilog multilog t /var/log/sshd/ 
     │   ├─┬─ 00337 root supervise gitea 
     │   │ └─── 00380 git /usr/pkg/sbin/gitea --config /usr/pkg/etc/gitea/conf/app.ini web 
     │   ├─┬─ 00338 root supervise log 
     │   │ └─── 00516 multilog multilog t /var/log/openntpd/ 
     │   ├─┬─ 00339 root supervise log 
     │   │ └─── 00472 multilog multilog t /var/log/gitealog/ 
     │   ├─┬─ 00345 root supervise log 
     │   │ └─── 00484 multilog multilog t /var/log/powerd/ 
     │   ├─┬─ 00349 root supervise log 
     │   │ └─── 00098 multilog multilog t /var/log/socklog-unix/ 
     │   ├─┬─ 00350 root supervise cron 
     │   │ └─── 00041 root /usr/sbin/cron -n 
     │   └─┬─ 00357 root supervise socklog-unix 
     │     └─── 00097 root /usr/pkg/sbin/socklog nix /var/run/log 
     ├──= 00422 root /usr/libexec/getty Pc constty 
     ├──= 00327 root /usr/libexec/getty Pc ttyE1 
     ├──= 00104 root /usr/libexec/getty Pc ttyE2 
     └──= 00073 root /usr/libexec/getty Pc ttyE3 

В Linux для просмотра дерева процессов с помощью `ps` можно воспользоваться следующей командой:

    # ps -eHo pid,command

Чтобы убрать из вывода команды системные процессы, которых в Linux может быть довольно много, можно воспользоваться такой командой:

    # ps -eHo pid,command | grep -vE '^ *[0-9]+ +\['

Совместимость с rc
------------------

Для совместимости с системой инициализации `/etc/rc` создадим скрипт `/etc/rc.d/gitea` со следующим содержимым:

    #!/bin/sh
    #
    # REQUIRE: DAEMON
    # PROVIDE: gitea
    
    if [ -f /etc/rc.subr ]; then
            . /etc/rc.subr
    fi
    
    name=gitea
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

    # chmod +x /etc/rc.d/gitea

Теперь можно будет включать и выключать сервис Gitea привычным образом через переменную `gitea` в файле `/etc/rc.conf`, а также запускать, останавливать, перезапускать и проверять состояние сервиса с помощью скрипта `/etc/rc.d/gitea`. Для непосвящённого наблюдателя всё будет выглядеть привычным образом:

    git# /etc/rc.d/gitea rcvar
    # gitea
    $gitea=YES
    git# /etc/rc.d/gitea status
    gitea is running as pid 312.
    git# /etc/rc.d/gitea restart
    Restarting gitea.
    git# /etc/rc.d/gitea status
    gitea is running as pid 504.

В процессе загрузки системы первыми запускаются скрипты в каталоге `/etc/rc.d/` и только потом обрабатывается файл `/etc/rc.local`. Поскольку к моменту обработки файла `/etc/rc.local` в каталогах `/services/.../` уже будут созданы или удалены файлы `down` в соответствии с настройками из файла `/etc/rc.conf`, то `daemontools` запустит только сервисы, активированные через файл `/etc/rc.conf`.

Альтернативы
------------

Существуют аналогичные системы, развивающие идеи daemontools:

* [s6](https://skarnet.org/software/s6/) Лорента Беркота,
* [nosh](http://jdebp.info/Softwares/nosh/) Джонатана Поларда,
* [perp](http://b0llix.net/perp/) Уэйна Маршалла,
* [runit](http://smarden.org/runit/) Геррита Пейпа.
