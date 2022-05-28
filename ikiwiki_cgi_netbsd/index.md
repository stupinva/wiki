ikiwiki в режиме CGI
====================

Оглавление
----------

[[!toc startlevel=2 levels=3]]

Введение
--------

В прошлой статье была рассмотрена настройка [[Ikiwiki в качестве генератора статических сайтов|ikiwiki_static_netbsd]].

Ikiwiki можно настроить для работы в режиме CGI, который позволяет редактировать содержимое страниц из веб-браузера. CGI-скрипт используется только для обновления содержимого страниц, поэтому не влияет на скорость отдачи HTML-страниц. Для достижения максимальной скорости отдачи страниц можно воспользоваться каким-нибудь мультиплексирующим веб-сервером, поддерживающим системные вызовы kqueue, epoll и sendfile: nginx, lighttpd, thttpd, mathopd, boa.

Донастройка ikiwiki
-------------------

Для редактирования страниц через веб-браузер при сборке ikiwiki из pkgsrc нужно включить опцию cgi, прописав опции в файле /etc/mk.conf:

    PKG_OPTIONS.ikiwiki=            cgi -cvs -git -ikiwiki-amazon-s3 -ikiwiki-highlight -ikiwiki-search -ikiwiki-sudo -imagemagick -l10n -python -svn -w3m -p5-Text-Markdown-Discount -p5-Text-Markdown p5-Text-MultiMarkdown

Если ikiwiki уже установлена, то можно переустановить её с новыми опциями следующим образом:

    # cd /usr/pkgsrc/www/ikiwiki
    # make clean
    # make
    # pkg_delete ikiwiki
    # make install

Если ikiwiki ещё не установлена, то собрать и установить можно следующим образом:

    # cd /usr/pkgsrc/www/ikiwiki
    # make install

Рассмотрим опции, влияющие на работу ikiwiki в режиме CGI.

|Опция                    |Значение по умолчанию|Описание|
|:-----------------------:|:-------------------:|:-------|
|adminuser                |[]                   |Список пользователей-администраторов. Администратор может редактировать заблокированную страницу, которую уже открыл на редактирование обычный пользователь. Если включен плагин websetup, то администраоры будут иметь доступ к его функциям, а обычные пользователи - нет.|
|cgiurl                   |Пустая строка        |Ссылка на CGI-скрипт ikiwiki. Я выставил ссылку https://stupin.su/wiki/index.cgi|
|reverse_proxy            |0                    |По умолчанию ссылка на CGI-скрипт прописывается в HTML-страницах полностью. Если выставлено значение 1, то в HTML-страницах прописывается относительная ссылка. У меня ikiwki работает в виртуальной машине, а доступ снаружи осуществляется через обратный прокси, поэтому я выставил значение 1.|
|cgi_wrapper              |Пустая строка        |Путь к CGI-скрипту. Стоит прописать сюда полный путь к файлу. Я задал имя файла /home/wiki/dst/index.cgi|
|cgi_wrappermode          |06755                |Права доступа к CGI-скрипту. Я выставил значение 0700: без SUID-бита, читать, писать и исполнять скрипт имеет право только его владелец.|
|account_creation_password|s3cr1t               |Пароль, который необходимо ввести новому пользователю для регистрации. Стоит поменять этот пароль, чтобы заблокировать возможность регистрации новых пользователей. При необходимости этот пароль можно сообщить человеку, желающему зарегистрироваться, а затем снова поменять.|

После изменения настроек нужно вызвать ikiwiki с указанием имени файла конфигурации:

     $ ikiwiki --setup src/.ikiwiki/ikiwiki.setup

ikiwiki сгенерирует CGI-скрипт, в который будут вшиты эти настройки. При последующем изменении настроек не забывайте снова выполнять эту команду, чтобы новые настройки вступали в силу.

CGI с использованием uwsgi
--------------------------

### Установка и настройка uwsgi

Для запуска ikiwiki в режиме CGI я решил воспользоваться сервером приложений uwsgi. Пропишем в файл /etc/mk.conf опции для его сборки:

    PKG_OPTIONS.py-uwsgi=           -debug -openssl -pcre -uuid -uwsgi-sse_offload -yaml -jansson -yajl -expat -libxml2

Установим uwsgi:

    # cd /usr/pkgsrc/www/py-uwsgi
    # make install

В pkgsrc нет примера rc-файла, но это не проблема. За основу можно взять любой уже существующий rc-файл. Я взял за основу rc-файл openntpd. Создадим файл /etc/rc.d/uwsgi для запуска uwsgi:

    #!/bin/sh
    
    # PROVIDE: uwsgi
    # REQUIRE: DAEMON
    # BEFORE:  LOGIN
    
    . /etc/rc.subr
    
    name="uwsgi"
    rcvar="uwsgi"
    command="/usr/pkg/bin/uwsgi-3.8"
    required_files="/usr/pkg/etc/uwsgi.ini"
    
    load_rc_config $name
    run_rc_command "$1"

Создадим файл конфигурации /usr/pkg/etc/uwsgi.ini:

    [uwsgi]
    
    procname = uwsgi-cgi
    procname-master = uwsgi-cgi-master
    
    master-as-root = yes
    uid = wiki
    gid = users
    chdir = /home/wiki/
    
    cgi-mode = yes
    plugins = cgi
    cgi = /home/wiki/dst/index.cgi
    cgi-timeout = 120
    socket = /var/run/uwsgi.sock
    pidfile = /var/run/uwsgi.pid
    
    processes = 1

Включим uwsgi и пропишем опции для его запуска в файле /etc/rc.conf:

    uwsgi=YES
    uwsgi_flags="-d /var/log/uwsgi.log --ini /usr/pkg/etc/uwsgi.ini"

Осталось запустить uwsgi:

    # /etc/rc.d/uwsgi start
    Starting uwsgi.
    [uWSGI] getting INI configuration from /usr/pkg/etc/uwsgi.ini
    !!! UNABLE to load uWSGI plugin: Cannot open "./cgi_plugin.so" !!!

Несмотря на предупреждение uwsgi о невозможности открыть плагин CGI, плагин CGI работает, т.к. скомпонован с uwsgi статически.

### Донастройка nginx

Если nginx уже установлен, то нужно включить опцию uwsgi, пересобрать и переустановить его. Пропишем в файл /etc/mk.conf нужные нам опции сборки nginx:

    PKG_OPTIONS.nginx=              -array-var -auth-request -cache-purge -dav -debug -echo -encrypted-session -flv -form-input -geoip -gtools -gzip -headers-more -http2 -image-filter -luajit -mail-proxy -memcache -naxsi -njs -pcre -perl -push -realip -rtmp -secure-link -set-misc -slice -ssl -status -stream-ssl-preread -sub uwsgi

Пересобрать и переустановить nginx можно следующим образом:

    # cd /usr/pkgsrc/www/nginx
    # make clean
    # make
    # pkg_delete nginx
    # make install

Если nginx ещё не установлен, то установить его можно вот так:

    # cd /usr/pkgsrc/www/nginx
    # make install

Добавим в секцию server файла /usr/pkg/etc/nginx/nginx.conf к уже имеющимся настройкам дополнительную секцию с правилами обработки CGI-скрипта:

    location /wiki/ {
      alias /home/wiki/dst/;
      index index.html;
    }
    
    location = /wiki/index.cgi {
      uwsgi_pass unix:/var/run/uwsgi.sock;
      include uwsgi_params;
    
      uwsgi_modifier1 9;
      uwsgi_param SCRIPT_FILENAME /home/wiki/dst/index.cgi;
    }

Включим nginx в файле /etc/rc.conf, если это ещё не было сделано:

    nginx=YES

Осталось перезапустить nginx, чтобы запустить новый двоичный файл nginx и задействовать новый файл конфигурации:

    # /etc/rc.d/nginx restart

uwsgi из pkgsrc тянет с собой не нужную нам зависимость - язык Python. Интересно, что в этом проекте для сборки программы на языке Си используются не привычная утилита make и Makefile'ы, а скрипты, написанные на Python. Несмотря на то, что язык Python мне знаком, скрипты сборки показались мне довольно запутанными и я не смог доработать pkgsrc так, чтобы uwsgi собирался без Python и множества плагинов, не нужных для работы ikiwiki.

CGI с использованием spawn-fcgi и fcgiwrap
------------------------------------------

fcgiwrap - это программа, которая принимает запросы через Unix-сокет по протоколу FastCGI и вызывает для их обслуживания CGI-скрипт. Она может как открывать Unix-сокет с указанным именем сама, так и принимать идентификатор Unix-сокета через стандартный ввод.

spawn-fcgi - это программа, которая создаёт Unix-сокет, принимает через него запросы по протоколу FastCGI, а для их обслуживания порождает указанные FastCGI-процессы. Для Unix-сокета можно указать владельца, группу и права доступа. Для FastCGI-процессов можно указать пользователя и группу, от имени которых они будут работать. FastCGI-процессы можно запускать в указанном рабочем каталоге и/или указанной chroot-среде.

### Установка и настройка spawn-fcgi и fcgiwrap

Установить обе программы можно из системы pkgsrc:

    # cd /usr/pkgsrc/www/fcgiwrap
    # make install
    # cd /usr/pkgsrc/www/spawn-fcgi
    # make install

Скрипт инициализации spawnfcgi из пакета spawn-fcgi не позволяет указать для процесса spawn-fcgi все возможные настройки и не умеет корректно работать в случаях, когда для обслуживания запросов из Unix-сокета используется несколько процессов. Я практически полностью переписал этот скрипт, так что он принял следующий вид:

    #!/bin/sh
    #
    # $NetBSD: spawnfcgi.sh,v 1.4 2011/07/25 11:36:29 imil Exp $
    #
    # PROVIDE: spawnfcgi
    # REQUIRE: DAEMON
    
    . /etc/rc.subr
    
    name="spawnfcgi"
    rcvar=$name
    command="/usr/pkg/bin/spawn-fcgi"
    start_cmd="spawnfcgi_start"
    stop_cmd="spawnfcgi_stop"
    status_cmd="spawnfcgi_status"
    pidfile_base="/var/run/spawnfcgi-"
    
    spawnfcgi_start()
    {
            rv=0
            for job in "" $spawnfcgi_jobs; do
                    pidfile=${pidfile_base}${job}.pid
                    [ -z $job ] && continue
                    if [ -f $pidfile ] ; then
                            (cat $pidfile ; echo) | while read pid ; do
                                    kill -0 $pid
                                    if $! ; then
                                            echo "${name}/${job} at PID $pid is already running"
                                            rv=1
                                            continue
                                    fi
                            done
                    fi
                    job_command=$(eval echo \$${name}_${job}_command)
                    job_args=$(eval echo \$${name}_${job}_args)
                    echo "Starting ${name}/$job."
                    $command ${job_args} -P $pidfile -- ${job_command}
            done
            return $rv
    }
    
    spawnfcgi_stop()
    {
            rv=0
            for job in "" $spawnfcgi_jobs; do
                    pidfile=${pidfile_base}${job}.pid
                    [ -z $job ] && continue
                    if [ ! -f $pidfile ] ; then
                            echo "${name}/${job} is not running"
                            continue
                    fi
                    (cat $pidfile ; echo) | while read pid ; do
                            echo -n "${name}/${job} at PID $pid"
                            kill -TERM $pid
                            if $! ; then
                                    wait_for_pids $pid
                                    echo " is stopped"
                            else
                                    echo " is not running"
                                    rv=1
                            fi
                    done
                    rm $pidfile
            done
            return $rv
    }
    
    spawnfcgi_status()
    {
            rv=0
            for job in "" $spawnfcgi_jobs; do
                    pidfile=${pidfile_base}${job}.pid
                    [ -z $job ] && continue
                    if [ ! -f $pidfile ] ; then
                            echo "${name}/${job} is not running"
                            continue
                    fi
                    (cat $pidfile ; echo) | while read pid ; do
                            echo -n "${name}/${job} at PID $pid"
                            kill -0 $pid
                            if $! ; then
                                    echo " is running"
                            else
                                    echo " is not running"
                                    rv=1
                            fi
                    done
            done
            return $rv
    }
    
    load_rc_config $name
    run_rc_command $1

Настроим запуск spawn-fcgi, вписав в файл /etc/rc.conf следующие настройки:

    spawnfcgi=YES
    spawnfcgi_jobs="ikiwiki"
    spawnfcgi_ikiwiki_args="-u wiki -g users -s /var/run/ikiwiki.sock -U nginx -G nginx -M 0600 -d /home/wiki/dst/ -F 4"
    spawnfcgi_ikiwiki_command="/usr/pkg/sbin/fcgiwrap"

Запустим spawn-fcgi при помощи следующей команды:

    # /etc/rc.d/spawnfcgi start

Для ослуживания запросов будет запущено 4 процесса fcgiwrap под пользователем wiki и группой users, которые будут ослуживать запросы на Unix-сокете /var/run/ikiwiki.sock. Владельцем сокета будет пользователь nginx и группа nginx, правами чтения и записи в сокет будет обладать только сам пользователь nginx. Текущим каталогом для процессов будет каталог /home/wiki/dst/

### Донастройка nginx

В отличие от конфигурации с использованием uwsgi, в случае со spawn-fcgi пересобирать nginx не требуется, т.к. поддержка протокола FastCGI в nginx уже имеется.

Добавим в секцию server файла /usr/pkg/etc/nginx/nginx.conf к уже имеющимся настройкам дополнительную секцию с правилами обработки CGI-скрипта:

    location /wiki/ {
      alias /home/wiki/dst/;
      index index.html;
    }
    
    location = /wiki/index.cgi {
      fastcgi_pass unix:/var/run/ikiwiki.sock;
      include /usr/pkg/etc/nginx/fastcgi_params;
      fastcgi_param SCRIPT_FILENAME /home/wiki/dst/index.cgi;
    }

Осталось перезагрузить nginx, чтобы задействовать новый файл конфигурации:

    # /etc/rc.d/nginx restart

Автор spawn-fcgi, похоже, расчитывал на то, что эта программа будет запускаться программой multiwatch, которая умеет изменять количество запущенных процессов spawn-fcgi без их предварительной остановки, как это происходит при использовании скрипта spawncgi, а также умеет перезапускать внезапно завершившиеся процессы. К сожалению, в pkgsrc нет программы mulitwatch. Впрочем, она зависит от библиотеки glib и мне кажется, что в такой программе можно было обойтись и без неё.

CGI с использованием thttpd
---------------------------

Настроим Ikiwiki под управлением веб-сервера thttpd. В отличие от nginx, thttpd умеет самостоятельно запускать CGI-скрипты. Из недостатков можно назвать лишь, пожалуй, отсутствие поддержки протокола HTTPS.

Устанавилваем thttpd из pkgsrc:

    # cd /usr/pkgsrc/www/thttpd
    # make install

Копируем скрипт инициализации:

    # cp /usr/pkg/share/examples/rc.d/thttpd /etc/rc.d/

Прописываем настройки в файл конфигурации /usr/pkg/etc/thttpd.conf:

    logfile=/var/log/thttpd.log
    pidfile=/var/run/thttpd.pid
    port=8080
    dir=/home/wiki/dst/
    cgipat=index.cgi
    user=wiki

Запускаем thttpd:

    # /etc/rc.d/thttpd start

Включаем запуск thttpd в файле /etc/rc.conf:

    thttpd=YES

CGI с использованием mathopd
----------------------------

Mathopd тоже имеет встроенную поддержку CGI, но тоже не имеет поддержки HTTPS. Существенный плюс по сравнению с thttpd - поддержка авторизации и псевдонимов.

Для установки mathopd понадобится pkgsrc-wip. Его развёртывание описано на странице [[Система pkgsrc|pkgsrc]].

Устанавилваем mathopd из pkgsrc:

    # cd /usr/pkgsrc/wip/mathopd
    # make install

Копируем скрипт инициализации:

    # cp /usr/pkg/share/examples/rc.d/mathopd /etc/rc.d/

Прописываем настройки в файл конфигурации /usr/pkg/etc/mathopd.conf:

    ErrorLog /var/log/mathopd/mathopd/error_log
    Log /var/log/mathopd/mathopd/access_log.%Y%m%d
    LogGMT Off
    
    StayRoot On
    User mathopd
    Umask 022
    PIDFile /var/run/mathopd.pid
    
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
            Ctime
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
                    text/plain { .sh }
                    application/octet-stream { * }
            }
    
            Specials {
                    CGI { .cgi }
            }
    
            ExtraHeaders {
                    "Cache-Control: max-age=3600"
            }
    
            IndexNames {
                    index.html
            }
    }
    
    Server {
            Address 0.0.0.0
            Port 80
            Backlog 128
    
            Virtual {
                    AnyHost
    
                    Control {
                            Alias /wiki/
                            Location /home/wiki/dst/
                    }
    
                    Control {
                            Alias /wiki/private/
                            Location /home/wiki/dst/private/
    
                            Realm "private content"
                            EncryptedUserFile On
                            UserFile /home/wiki/src/.ikiwiki/private_users
                    }
            
                    Control {
                            Alias /wiki/ufanet/
                            Location /home/wiki/dst/ufanet/
            
                            Realm "limited access"
                            EncryptedUserFile On
                            UserFile /home/wiki/src/.ikiwiki/ufanet_users
                    }
            
                    Control {
                            Alias /wiki/index.cgi
                            Location /home/wiki/dst/index.cgi
                            PathArgs On
            
                            RunScriptsAsOwner Off
                            ScriptUser wiki
                    }
            }
    }

Секции Control одного уровня просматриваются веб-сервером снизу вверх, так что более специфичные секции нужно помещать ниже. В противном случае сработает более общая секция, которая при просмотре снизу вверх встретится веб-серверу первой.

Запускаем mathopd:

    # /etc/rc.d/mathopd start

Включаем запуск mathopd в файле /etc/rc.conf:

    mathopd=YES
