Настройка сборочного сервера NetBSD
===================================

[[!tag pkgsrc pkgsrc-wip sysbuild daemontools mathopd]]

Оглавление
----------

[[!toc startlevel=2 levels=4]]

Настройка сборочного сервера для локального обновления
------------------------------------------------------

### Подготовка pkgsrc

Для настройки сборочного сервера воспользуемся pkgsrc. Скачиваем и распакуем архив в каталог `/usr`:

    # cd /usr
    # ftp ftp://ftp.NetBSD.org/pub/pkgsrc/pkgsrc-2021Q3/pkgsrc.tar.xz
    # tar xJvf pkgsrc.tar.xz

После распаковки архив можно удалить:

    # rm pkgsrc.tar.xz

### Установка и настройка sysbuild-user

Для начала настроим регулярную сборку базовой системы NetBSD из свежих исходных текстов. Для обновления исходных текстов и сборки базовой системы NetBSD предназначена утилита sysbuild. Для этой утилиты существует удобная обёртка `sysbuild-user`. Установим её:

    # cd /usr/pkgsrc/sysutils/sysbuild-user
    # make install

При установке `sysbuild-user` происходит следующее:

* в систему устанавливается утилита `sysbuild`,
* настраивается пользователь sysbuild, от имени которого будет выполняться регулярная сборка,
* создаётся домашний каталог пользователя `/home/sysbuild`,
* настраивается задача в планировщике задач.

В каталоге `/home/sysbuild` уже имеется файл конфигурации `default.conf`, который можно подправить по своему вкусу. Мне, например, захотелось собирать собственное ядро NetBSD, на базе модульного и с изменённым планировщиком задач, поэтому я поменял в файле конфигурации опцию `BUILD_TARGETS` следующим образом:

    BUILD_TARGETS="tools kernel=${HOME}/MODULAR_M2 releasekernel=${HOME}/MODULAR_M2 release"

Файл конфигурации нужного мне ядра NetBSD я поместил в каталог `/home/sysbuild` под именем `MODULAR_M2`. На всякий случай приведу здесь его содержимое:

    # $NetBSD: MODULAR,v 1.5 2017/08/09 18:45:30 maxv Exp $
    #
    # MODULAR kernel
    # This kernel config prefers loading kernel drivers from file system.
    # Please see module(7) for more information.
    #
    include "arch/i386/conf/MODULAR"
    
    no options      SCHED_4BSD
    options         SCHED_M2

По умолчанию в файле конфигурации `/home/sysbuild/default.conf` имеется строчка, которая предписывает выполнять скачивание/обновление и сборку графической системы X11, если на компьютере уже установлена графическая система X11:

    [ ! -f /etc/mtree/set.xbase ] || XSRCDIR="${HOME}/xsrc"

Для того, чтобы отключить сборку системы X11, достаточно закомментировать эту строчку. Для того, чтобы выполнять сборку системы X11 на сборочном компьютере, где её нет, можно изменить эту строчку следующим образом:

    XSRCDIR="${HOME}/xsrc"    

Для того, чтобы не ждать, когда произойдёт скачивание исходных текстов и их сборка по планировщику задач, можно запустить `sysbuild` вручную:

    # su - sysbuild -c "sysbuild build"

### Установка и настройка pkg_comp-cron

Теперь займёмся сборкой пакетов. Для сборки пакетов из pkgsrc с нужными опциями предназначена утилита `pkg_comp`. Для этой утилиты тоже есть обёртка, которая называется `pkg_comp-cron`. Установим её:

    # cd /usr/pkgsrc/pkgtools/pkg_comp-cron
    # make install

Обёртка создаёт каталог `/var/pkg_comp`, в который помещает файлы конфигурации:

* файл конфигурации `pkg_comp.conf`,
* файл конфигурации сборочной песочницы `sandbox.conf`,
* файл `list.txt`, в котором указан список пакетов для периодической сборки,
* файл `extra.mk.conf` с опциями, которые будут использоваться при сборке пакетов.

Первым делом скопируем в этот каталог содержимое каталога `/usr/pkgsrc`:

    # cd /var/pkg_comp
    # cp -R /usr/pkgsrc .

И на всякий случай удалим все каталоги `work`, в которых происходила сборка пакетов:

    # find /var/pkg_comp/pkgsrc -maxdepth 3 -mindepth 3 -name work -exec rm -r {} +

По умолчанию `pkg_comp` настроен так, что программы, находящиеся в собранных пакетах, будут искать свои файлы конфигурации в каталоге `/etc`. Оставим этот каталог для файлов конфигурации базовой системы NetBSD, а файлы конфигурации для сторонних программ будем размещать в каталоге `/usr/pkg/etc`. Для этого отредактируем файл конфигурации `/var/pkg_comp/pkg_comp.conf` следующим образом:

    SYSCONFDIR="${LOCALBASE}/etc"

Теперь можно прописать в файл `/var/pkg_comp/list.txt` список пакетов для сборки, среди которых обязательно должны присутствовать как минимум сами `sysutils/sysbuild-user` и `pkgtools/pkg_comp-cron`. Если для обновления pkgsrc используется git, то в список собираемых пакетов также стоит добавить `devel/git-base`. Для того, чтобы можно было воспользоваться результатами сборки, стоит добавить в этот список ещё два пакета: `sysutils/sysupgrade` и `pkgtools/pkgin`.

Если при сборке пакетов нужно использовать какие-то специальные опции, то их можно прописать в файл `/var/pkg_comp/extra.mk.conf`.

Для регулярной пересборки обновлённых пакетов в планировщик добавляется задача, увидеть которую можно следующим образом:

    # crontab -lu root

Запустить полный цикл обновления pkgsrc и сборки пакетов можно с помощью следующей команды:

    # pkg_comp -c /var/pkg_comp/pkg_comp.conf auto

#### Настройка сборочной песочницы

Для сборки пакетов создаётся изолированное сборочное окружение, в которое распаковываются архивы с двоичными файлами NetBSD. Изолированное сборочное окружение создаётся с помощью утилиты `sandboxctl`. Конфигурация этой утилиты, используемая `pkg_comp`, находится в файле `/var/pkg_comp/sandbox.conf`.

Путь к каталогу, из которого берутся архивы с двоичными файлами NetBSD, указывается в опции `NETBSD_NATIVE_RELEASEDIR`. По умолчанию в этой переменной настроен путь к каталогу `/home/sysbuild/release/$(uname -m)`, а архивы берутся из подкаталога `binary/sets/`, находящегося в нём.

Список архивов двоичных файлов можно задать с помощью опции `NETBSD_RELEASE_SETS`. Если эта опция не задана, то в сборочное окружение распаковываются все найденные архивы двоичных файлов, а также ядро `GENERIC`. Для того, чтобы сборочное окружение было как можно меньшим, можно указать используемые архивы явным образом. Например, если не предполагается собирать пакеты, работающие с системой X11, то достаточно указать лишь архивы `base`, `comp` и `etc`:

    NETBSD_RELEASE_SETS="base comp etc"

Если же необходимо собирать пакеты, работающие с системой X11, причём будет использоваться система X11, идущая в комплекте с NetBSD, а не из системы pkgsrc, то нужно добавить в сборочное окружение содержимое архивов `xbase` и `xcomp`. В таком случае опция `NETBSD_RELEASE_SETS` примет следующий вид:

    NETBSD_RELEASE_SETS="base comp etc xbase xcomp"


#### Обновление pkgsrc через git

По умолчанию обновление каталога `/var/pkg_comp/pkgsrc` происходит через систему CVS. Утилита `cvs` уже имеется в базовой системе NetBSD, а содержимое каталога `pkgsrc` занимает сравнительно мало места на диске. Но обновление файлов при использовании `cvs` идёт довольно медленно.

`pkg_comp` также умеет обновлять содержимое каталога `/var/pkg_comp/pkgsrc` с помощью git, что работает быстрее, но требует больше места (вместе с репозиторием wip общий объём файлов увеличивается с 1,3 до 2,1 гигабайт). Если вы хотите достичь более высокой скорости обновления, пожертвовав местом на диске, то можно переключиться на использование git.

Для начала пропишем опции сборки утилиты `git` и её зависимостей в файл `/etc/mk.conf`:

    PKG_OPTIONS.git=                -apple-common-crypto
    PKG_OPTIONS.gmake=              nls
    PKG_OPTIONS.perl=               -debug -dtrace -mstats -threads -perl-64bitall perl-64bitauto -perl-64bitint -perl-64bitmore -perl-64bitnone
    PKG_OPTIONS.pcre2=              pcre2-jit
    PKG_OPTIONS.p5-Net-DNS=         -inet6
    PKG_OPTIONS.gtexinfo=           nls
    PKG_OPTIONS.p5-Authen-SASL=     -gssapi
    PKG_OPTIONS.curl=               -gssapi -http2 -idn -inet6 -ldap -libssh2 -rtmp

Установим в систему утилиту `git`:

    # cd /usr/pkgsrc/devel/git-base
    # make install

Поменяем в файле конфигурации `/var/pkg_comp/pkg_comp.conf` значение опции `FETCH_VCS` с `cvs` на `git` и попишем URL официального git-репозитория pkgsrc:

    FETCH_VCS=git
    GIT_URL=https://github.com/NetBSD/pkgsrc.git

Попоробовать обновление pkgsrc из git-репозитория можно с помощью следующей команды:

    # pkg_comp -c /var/pkg_comp/pkg_comp.conf fetch

##### Решение проблемы not a git repository

Если в каталоге `/var/pkg_comp` уже есть каталог pkgsrc, скачанный из CVS или распакованный из архива, то команда завершится неудачно, а в её выводе будут следующие строки:

    pkg_comp: I: Running 'git fetch https://github.com/NetBSD/pkgsrc.git trunk' in /var/pkg_comp/pkgsrc
    fatal: not a git repository (or any of the parent directories): .git

Нужно удалить имеющийся каталог `/var/pkg_comp/pkgsrc` вместе со всем содержимым:

    # rm -R /var/pkg_comp/pkgsrc

##### Решение проблемы unable to get local issuer certificate

Если в системе нет актуальных корневых сертификатов, то запуск команды завершится неудачно, а в её выводе будет следующая строка:

    fatal: unable to access 'https://github.com/NetBSD/pkgsrc.git/': SSL certificate problem: unable to get local issuer certificate

Для решения этой проблемы нужно установить в систему свежие корневые сертификаты следующим образом:

    # cd /usr/pkgsrc/security/mozilla-rootcerts
    # make install
    # mozilla-rootcerts install

##### Решение проблемы git: not found

При запуске задачи планировщиком обновление pkgsrc с помощью утилиты `git` может не сработать, в результате чего по электронной почте может прийти отчёт о проблеме, содержащий строки следующего вида:

    pkg_comp: I: Running 'git fetch https://github.com/NetBSD/pkgsrc.git trunk' in /var/pkg_comp/pkgsrc
    /usr/pkg/sbin/pkg_comp: git: not found

Для исправления этой проблемы нужно отредактировать файл с запланированными задачами пользователя `root`. Откроем его для редактирования с помощью следующей команды:

    # crontab -eu root

И отредактируем переменную окружения `PATH`, добавив в её начало пути `/usr/pkg/bin` и `/usr/pkg/sbin`. После редактирования строчка должна принять следующий вид:

    PATH=/usr/pkg/bin:/usr/pkg/sbin:/bin:/sbin:/usr/bin:/usr/sbin

#### Получение/обновление репозитория pkgsrc-wip

Кроме основного репозитория pkgsrc существует специальный репозиторий wip - work in progress. В этот репозиторий помещают ещё не готовые пакеты, находящиеся в разработке. Для скачивания этого репозитория пропишем в файл конфигурации `/var/pkg_comp/pkg_comp.conf` функцию, которая будет вызываться после получения обновлений из основного репозитория pkgsrc:

    post_fetch_hook()
    {
        if [ ! -d "$PKGSRCDIR" ] ; then
            echo "$PKGSRCDIR not exist"
            return
        fi
    
        _pwd=$(pwd)
        cd "$PKGSRCDIR"
    
        if [ ! -d wip ] ; then
            git clone git://wip.pkgsrc.org/pkgsrc-wip.git wip
        else
            cd wip
            git pull
        fi
    
        cd $_pwd
    }

#### Мой файл list.txt

На момет написания этой заметки файл `/var/pkg_comp/list.txt` на сборочной виртуальной машине содержит такой список пакетов:

    sysutils/sysbuild-user
    pkgtools/pkgin
    pkgtools/pkg_comp-cron
    editors/vim
    shells/bash
    mail/dovecot2
    mail/dovecot2-pigeonhole
    sysutils/zabbix50-agent
    devel/git-base
    www/gitea
    sysutils/daemontools
    net/openntpd
    mail/nullmailer
    pkgtools/pkg_leaves
    wip/mathopd
    sysutils/sysupgrade
    sysutils/pstree
    net/rsync
    mail/exim
    www/ikiwiki

#### Мой файл extra.mk.conf

Для сборки указанных выше пакетов используются следующие опции:

    PKG_OPTIONS.sysbuild=           -tests
    PKG_OPTIONS.sandboxctl=         -tests
    PKG_OPTIONS.pkg_comp=           -tests
    PKG_OPTIONS.libfetch=           -inet6 openssl
    PKG_OPTIONS.pkgin=              pkgin-prefer-gzip
    PKG_OPTIONS.vim=                -lua -luajit -perl -python -ruby
    PKG_OPTIONS.bash=               nls
    PKG_OPTIONS.bison=              nls
    PKG_OPTIONS.gmake=              nls
    PKG_OPTIONS.gtexinfo=           nls
    PKG_OPTIONS.perl=               -debug -dtrace -mstats -threads -perl-64bitall perl-64bitauto -perl-64bitint -perl-64bitmore -perl-64bitnone 
    PKG_OPTIONS.dovecot=            kqueue -pam ssl -tcpwrappers
    PKG_OPTIONS.zabbix50-agent=     -inet6
    PKG_OPTIONS.libxml2=            icu -inet6
    PKG_OPTIONS.python38=           -dtrace -pymalloc -x11
    PKG_OPTIONS.nghttp2=            -nghttp2-asio
    PKG_OPTIONS.curl=               -gssapi -http2 -idn -inet6 -ldap -libssh2 -rtmp
    PKG_OPTIONS.git=                -apple-common-crypto
    PKG_OPTIONS.pcre2=              pcre2-jit
    PKG_OPTIONS.p5-Net-DNS=         -inet6
    PKG_OPTIONS.p5-Authen-SASL=     -gssapi
    PKT_OPTIONS.gitea=              sqlite
    PKG_OPTIONS.ikiwiki=            cgi -cvs -git -ikiwiki-amazon-s3 -ikiwiki-highlight -ikiwiki-sudo -imagemagick -l10n -python -svn -w3m -p5-Text-Markdown-Discount -p5-Text-Markdown p5-Text-MultiMarkdown
    PKG_OPTIONS.glib2=              -fam
    PKG_OPTIONS.p5-Module-Build=    -p5-module-build-dist-authoring -p5-module-build-license-creation
    PKG_OPTIONS.libgcrypt=          -via-padlock
    PKG_OPTIONS.p5-libwww=          -libwww-aliases
    PKG_OPTIONS.freetype2=          -png
    PKG_OPTIONS.harfbuzz=           -doc -introspection
    PKG_OPTIONS.cairo=              -x11 -xcb
    PKG_OPTIONS.gmp=                gmp-fat -mmx -simd
    PKG_OPTIONS.tiff=               -lzw
    PKG_OPTIONS.ghostscript=        -cups -debug -disable-compile-inits -fontconfig utf8 -x11
    PKG_OPTIONS.gs_type=            ghostscript-agpl -ghostscript-gpl
    PKG_OPTIONS.p5-Net-DNS=         -inet6 -online-tests
    PKG_OPTIONS.daemontools=        daemontools-moresignals
    PKG_OPTIONS.nullmailer=         gnutls
    PKG_OPTIONS.gnutls=             -dane -guile
    PKG_OPTIONS.exim=               exim-tls exim-auth-dovecot exim-content-scan spf -exim-appendfile-maildir -exim-appendfile-mailstore -exim-appendfile-mbx -exim-lookup-dsearch -exim-old-demime -exim-tcp-wrappers -inet6

Локальное использование pkgin
-----------------------------

pkgin - это продвинутый менеджер пакетов NetBSD, умеющий работать с удалёнными репозиториями и похожий на такие пакетные менеджеры для Linux, как apt или yum. Для его установки выполним такую команду:

    # PKG_PATH=file:///var/pkg_comp/packages/All pkg_add pkgin

После установки pkgin пропишем в его файле конфигурации `/usr/pkg/etc/pkgin/repositories.conf` путь к локальному репозиторию пакетов:

    file:///var/pkg_comp/packages/All

Пропишем в файл `/etc/pkgpath.conf` пути к утилитам `pkg_admin` и `pkg_info`:

    pkg_admin=/usr/pkg/sbin/pkg_admin
    pkg_info=/usr/pkg/sbin/pkg_info

В файле `/root/.profile` переставим пути `/usr/pkg/bin` и `/usr/pkg/sbin` в начало значения переменной `PATH`, вот так:

    export PATH=/usr/pkg/sbin:/usr/pkg/bin:/sbin:/usr/sbin:/bin:/usr/bin
    export PATH=${PATH}:/usr/X11R7/bin:/usr/local/sbin:/usr/local/bin

Теперь нужно завершить сеанс пользователя `root` и начать новый, чтобы переменная окружения `PATH` приняла новые значения, прописанные в файле `/root/.profile`.

После этого можно обновить список пакетов, доступных для установки из репозитория:

    # pkgin update

Установить обновления пакетов:

    # pkgin upgrade

Локальное использование sysupgrade
----------------------------------

Теперь, когда у нас есть настроенный pkgin, с его помощью можно устанавливать из репозитория другие имеющиеся в нём пакеты. Установим утилиту `sysupgrade`:

    # pkgin install sysupgrade

Пропишем в файле конфигурации `/usr/pkg/etc/sysupgrade.conf` опции для обновления:

    RELEASEDIR="/home/sysbuild/release/$(uname -m)"
    KERNEL=MODULAR_M2
    SETS="base etc man modules"
    ETCUPDATE=yes
    AUTOCLEAN=yes
    ARCHIVE_EXTENSION=tgz

Смысл опций:

* `RELEASEDIR` - каталог, в котором находится собранный релиз операционной системы NetBSD,
* `KERNEL` - ядро NetBSD, которое нужно устанавливать при обновлении по умолчанию,
* `SETS` - части системы NetBSD, которые нужно устанавливать при обновлении: `base` - базовая система, `etc` - файлы конфигурации, `man` - страницы руководства, `modules` - загружаемые модули ядра,
* `ETCUPDATE` - опция, которая указывает, нужно ли обновлять файлы конфигурации в каталоге `/etc`. В процессе установки обновлений будет предложено заменить файлы из каталога `/etc`, отличающиеся от дистрибутивных. Можно будет посмотреть отличия, установить дистрибутивный или оставить имеющийся файл.
* `AUTOCLEAN` - опция, которая указывает, нужно ли после процедуры обновления удалить временный каталог, в который распаковывались новые файлы,
* `ARCHIVE_EXTENSION` - расширение, добавляемое к именам файлов частей системы NetBSD и именам файлов ядер NetBSD.

Для обновления системы нужно запустить команду:

    # sysupgrade auto

После обновления для загрузки нового ядра NetBSD нужно перезагрузить систему:

    # reboot

Настройка сборочного сервера для удалённого обновления
------------------------------------------------------

Для того, чтобы обновлять операционную систему NetBSD и пакеты на других серверах, нам понадобится настроить на сборочном сервере веб-сервер. Я воспользуюсь `mathopd`, который буду запускать с помощью `daemontools`.

### Установка daemontools

Установим в систему daemontools:

    # pkgin install daemontools

Создадим каталог `/service/`, в котором будут располагаться настройки сервисов, управляемых `daemontools`:

    # mkdir /service/

Пропишем запуск главного процесса daemontools в файл `/etc/rc.local`, чтобы он запускался при загрузке системы:

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

Создадим группу и пользователя `mulitlog`, которые будем использовать в качетсве группы доступа и владельца журналов, формируемых утилитой `multilog` из пакета `daemontools`:

    # groupadd multilog
    # useradd -g multilog -d /var/log/ multilog

### Настройка веб-сервера mathopd

Установим на сборочный сервер веб-сервер `mathopd`:

    # pkgin install mathopd

Для обслуживания результатов сборки веб-сервером `mathopd` я сформировал такой файл конфигурации `/usr/pkg/etc/mathopd.conf`:

    ErrorLog /dev/stderr
    Log /dev/stderr
    LogGMT Off
    
    StayRoot On
    User mathopd
    Umask 022
    
    Tuning {
            AcceptMulti On
            Clobber On
    
            NumConnections 64
            BufSize 12288
            InputBufSize 2048
            ScriptBufSize 4096
            NumHeaders 100
    
            ScriptTimeout 10
            Timeout 10
            Wait 10
    }
    
    LogFormat {
            #Ctime
            Method
            Uri
            QueryString
            Version
            Status
            BytesRead
            Referer
            UserAgent
    }
    
    Control {
            Admin vladimir@stupin.su
            
            AllowDotfiles Off
            SanitizePath On
            UserDirectory Off
    
            Types {
                    image/gif { .gif }
                    image/png {
                            .png
                            .ico
                    }
                    image/jpeg { .jpg }
                    text/css { .css }
                    text/html { .html }
                    "text/plain; charset=UTF-8" {
                            .sh
                            .txt
                            .diff
                            .patch
                            .c
                            .py
                            .pl
                            .conf
                    }
                    application/octet-stream { * }
            }
    
            ExtraHeaders {
                    "Cache-Control: max-age=3600"
            }
    
            IndexNames {
                    index.html
            }
    
            RunScriptsAsOwner Off
            ScriptUser mathopd-cgi
            AutoIndexCommand /usr/pkg/etc/index.cgi
    
            Specials {
                    CGI { .cgi }
            }
    }
    
    Server {
            Address 0.0.0.0
            Port 80
            Backlog 128
    
            Virtual {
                    AnyHost
    
                    Control {
                            Alias /release/
                            Location /home/sysbuild/release/
                    }
    
                    Control {
                            Alias /src/
                            Location /home/sysbuild/src/
                    }
    
                    Control {
                            Alias /packages/
                            Location /var/pkg_comp/packages/
                    }
            }
    }

Для работы веб-сервера понадобится вот такой файл `/usr/pkg/etc/index.cgi`, формирующий индексные страницы для каталогов, в которых их нет:

    #!/usr/bin/awk -f
    
    BEGIN {
            printf "Content-Type: text/html\n"
            printf "\n";
            printf "<html>\n";
            printf "<head><title>%s</title></head>\n", ENVIRON["REQUEST_URI"];
            printf "<body>\n";
            printf "<h1>Index of %s</h1><hr><pre><a href=\"..\">../</a>\n", ENVIRON["REQUEST_URI"];
    
            lscmd="/bin/ls -lT";
            nr = 0;
            while (lscmd | getline) {
                    nr++;
                    if (nr == 1) {
                            continue;
                    }
    
                    printf "<a href=\"%s\">%s</a>", $10, $10;
    
                    if (length($10) < 50) {
                            for(i = 0; i < 50 - length($10); i++) {
                                    printf " ";
                            }
                    }
    
                    split($8, t, /:/);
                    printf " %02d-%s-%04d %02d:%02d", $7, $6, $9, t[1], t[2];
    
                    if (substr($1, 1, 1) == "d") {
                            s = "-";
                    } else {
                            s = $5;
                    }
                    printf "%20s\n", s;
            }
    
            printf "</pre><hr></body>\n";
            printf "</html>";
    }

Проставим у созданного файла владельца, группу, права доступа:

    # chown root:wheel /usr/pkg/etc/index.cgi
    # chmod u=rwx,go=rx

Добавим в систему пользователя `mathopd-cgi`, от имени которого будет выполняться указанный выше скрипт, следующим образом:

    # useradd -c 'mathopd cgi user' -s /sbin/nologin -g mathopd -d /noexistent mathopd-cgi

### Настройка daemontools для запуска mathopd

Создадим каталог с настройками сервиса `mathopd`:

    # mkdir -p /service/.mathopd/

Пропишем в файл `/service/.mathopd/run` скрипт запуска `mathopd`:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -f /usr/pkg/etc/mathopd.conf ]
    then
            echo "Missing /usr/pkg/etc/mathopd.conf"
            exit 1
    fi
    
    exec \
    /usr/pkg/sbin/mathopd -nf /usr/pkg/etc/mathopd.conf

Добавим скрипту права на запуск:

    # chmod +x /service/.mathopd/run

Создадим каталог для сервиса сбора журналов от `mathopd`:

    # mkdir /service/.mathopd/log/

Создадим скрипт `/service/.mathopd/log/run` для запуска этого сервиса:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/mathopd/

Добавим скрипту права на запуск:

    # chmod +x /service/.mathopd/log/run

Создадим каталог для журнальных файлов `mathopd`:

    # mkdir /var/log/mathopd/

Каталог с журналами должен принадлежать сервису, управляющему журналами, поменяем владельца и группу:

    # chown multilog:multilog /var/log/mathopd/

Теперь можно запустить сервис:

    # mv /service/.mathopd /service/mathopd

Удалённое использование pkgin
-----------------------------

Теперь, когда у нас есть репозиторий пакетов, доступный через веб, для установки менеджера пакетов pkgin достаточно выполнить такую команду:

    # PKG_PATH=http://sysbuild.vm.stupin.su/packages/All pkg_add pkgin

Где `sysbuild.vm.stupin.su` - доменное имя сборочного сервера, на котором уже настроен веб-сервер для раздачи репозитория пакетов.

После установки pkgin пропишем в его файле конфигурации `/usr/pkg/etc/pkgin/repositories.conf` путь к удалённому репозиторию пакетов:

    http://sysbuild.vm.stupin.su/packages/All

Дальнейшие действия совпадают с действиями для локально доступного репозитория пакетов. Пропишем в файл `/etc/pkgpath.conf` пути к утилитам `pkg_admin` и `pkg_info`:

    pkg_admin=/usr/pkg/sbin/pkg_admin
    pkg_info=/usr/pkg/sbin/pkg_info

В файле `/root/.profile` переставим пути `/usr/pkg/bin` и `/usr/pkg/sbin` в начало значения переменной `PATH`, вот так:

    export PATH=/usr/pkg/sbin:/usr/pkg/bin:/sbin:/usr/sbin:/bin:/usr/bin
    export PATH=${PATH}:/usr/X11R7/bin:/usr/local/sbin:/usr/local/bin

Теперь нужно завершить сеанс пользователя `root` и начать новый, чтобы переменная окружения `PATH` приняла новые значения, прописанные в файле `/root/.profile`.

После этого можно обновить список пакетов, доступных для установки из репозитория:

    # pkgin update

Установить обновления пакетов:

    # pkgin upgrade

Удалённое использование sysupgrade
----------------------------------

Теперь, когда у нас есть настроенный pkgin, с его помощью можно устанавливать из репозитория другие имеющиеся в нём пакеты. Установим утилиту `sysupgrade`:

    # pkgin install sysupgrade

Пропишем в файле конфигурации `/usr/pkg/etc/sysupgrade.conf` опции для обновления:

    RELEASEDIR="http://sysbuild.vm.stupin.su/release/$(uname -m)"
    KERNEL=MODULAR_M2
    SETS="base etc man modules"
    ETCUPDATE=yes
    AUTOCLEAN=yes
    ARCHIVE_EXTENSION=tgz

Где `sysbuild.vm.stupin.su` - доменное имя сборочного сервера, на котором уже настроен веб-сервер для раздачи релиза системы NetBSD.

Смысл опций такой же, как и в случае с локально доступным репозиторием:

* `RELEASEDIR` - каталог, в котором находится собранный релиз операционной системы NetBSD,
* `KERNEL` - ядро NetBSD, которое нужно устанавливать при обновлении по умолчанию,
* `SETS` - части системы NetBSD, которые нужно устанавливать при обновлении: `base` - базовая система, `etc` - файлы конфигурации, `man` - страницы руководства, `modules` - загружаемые модули ядра,
* `ETCUPDATE` - опция, которая указывает, нужно ли обновлять файлы конфигурации в каталоге `/etc`. В процессе установки обновлений будет предложено заменить файлы из каталога `/etc`, отличающиеся от дистрибутивных. Можно будет посмотреть отличия, установить дистрибутивный или оставить имеющийся файл.
* `AUTOCLEAN` - опция, которая указывает, нужно ли после процедуры обновления удалить временный каталог, в который распаковывались новые файлы,
* `ARCHIVE_EXTENSION` - расширение, добавляемое к именам файлов частей системы NetBSD и именам файлов ядер NetBSD.

Для обновления системы нужно запустить команду:

    # sysupgrade auto

Утилита sysupgrade скачает с удалённого веб-сервера необходимые для обновления файлы, распакует их содержимое во временный каталог и выполнит процедуру обновления операционной системы.

После обновления для загрузки нового ядра NetBSD нужно перезагрузить систему:

    # reboot

Использованные материалы
------------------------

* [Хулио Мерино. Знакомство с sysbuild для NetBSD, 2012](http://netbsd.stupin.su/ru/sysbuild/)
* [Хулио Мерино. Знакомство с sysupgrade для NetBSD, 2012](http://netbsd.stupin.su/ru/sysupgrade/)
* [Хулио Мерино. Поддержание свежести NetBSD при помощи pkg_comp 2.0, 2017](http://netbsd.stupin.su/ru/pkg_comp/)
* [Frederic Cambus. Installing CA certificates on NetBSD](https://www.cambus.net/installing-ca-certificates-on-netbsd/)
* [[Использование daemontools в NetBSD. Настройка запуска mathopd|daemontools_netbsd/#mathopd]]
* [[Настройка mathopd в NetBSD|mathopd_netbsd]]
