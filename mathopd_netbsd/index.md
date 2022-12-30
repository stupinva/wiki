Настройка mathopd в NetBSD
==========================

[[!toc startlevel=2 levels=3]]

Установка и настройка mathopd
-----------------------------

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
    #RootDirectory
    #CoreDirectory
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
            #Ctime
            Method
            Uri
            QueryString
            Version
            Status
            BytesRead
            Referer
            UserAgent
    
            #RemoteUser
            #RemoteAddress
            #RemotePort
            #ServerName
            #ContentLength
            #BytesWritten
            #LocalAddress
            #LocalPort
            #TimeTaken
            #MicroTime
    }
    
    Control {
            Admin vladimir@stupin.su
            #Error401File
            #Error403File
            #Error404File
            
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
    }
    
    Server {
            Address 0.0.0.0
            Port 80
            Backlog 128
    
            Virtual {
                    NoHost
                    Host stupin.su
    
                    Control {
                            Alias /
                            Location /srv/stupin.su/
                    }
            }
    
            Virtual {
                    Host manpages.stupin.su
    
                    Control {
                            Alias /
                            Location /srv/manpages.stupin.su/
                    }
            }
    
            Virtual {
                    Host netbsd.stupin.su
    
                    Control {
                            Alias /
                            Location /srv/netbsd.stupin.su/
                    }
            }
    
            Virtual {
                    Host thedjbway.stupin.su
    
                    Control {
                            Alias /
                            Location /srv/thedjbway.stupin.su/
                    }
            }
    }

В приведённом файле конфигурации настроены 4 виртуальных узла. Если поступил запрос без заголовка `Host:`, то по умолчанию будет использоваться узел stupin.su.

Запускаем mathopd:

    # /etc/rc.d/mathopd start

Включаем запуск mathopd в файле /etc/rc.conf:

    mathopd=YES

Автоматическая генерация индексных страниц
------------------------------------------

mathopd не умеет самостоятельно генерировать индексные страницы для каталогов, в которых их нет.

Ниже приведён скрипт на языке AWK для генерации содержимого каталога, в котором нет страницы index.html. Я поместил его в файл /usr/pkg/etc/index.cgi:

    #!/usr/bin/awk -f
    
    # Function derived from https://gist.github.com/moyashi/4063894
    function escape(s) {
            r = "";
            for (i = 1; i <= length(s); i++) {
                    r = r esc[substr(s, i, 1)];
            }
            return r;
    }
    
    BEGIN {
            for(i = 0; i <= 255; i++) {
                    c = sprintf("%c", i);
                    if (c ~ /[0-9A-Za-z_.\-]/) {
                            esc[c] = c;
                    } else {
                            esc[c] = sprintf("%%%02X", i)
                    }
            }
            spaces = "                                                  ";
    
            printf "Content-Type: text/html\n"
            printf "\n";
            printf "<html>\n";
            printf "<head><title>%s</title></head>\n", ENVIRON["REQUEST_URI"];
            printf "<body>\n";
            printf "<h1>Index of %s</h1><hr><pre><a href=\"..\">../</a>\n", ENVIRON["REQUEST_URI"];
    
            lscmd="/bin/ls -lT";
            first = 1;
            while (lscmd | getline) {
                    if (first == 1) {
                            first = 0;
                            continue;
                    }
    
                    filename = $0;
                    for(i = 1; i < 10; i++) {
                            filename = substr(filename, index(filename, $i) + length($i));
                    }
                    filename = substr(filename, 2);
    
                    printf "<a href=\"%s\">%s</a>", escape(filename), filename;
                    if (length(filename) < 50) {
                            printf substr(spaces, 1, 50 - length(filename));
                    }
    
                    split($8, hms, /:/);
                    printf " %02d-%s-%04d %02d:%02d%20s\n", $7, $6, $9, hms[1], hms[2], (substr($1, 1, 1) == "d") ? "-" : $5;
            }
    
            printf "</pre><hr></body>\n";
            printf "</html>";
    }

Скрипт генерирует индексные страницы по тому же шаблону, по которому их генерирует nginx.

Этот скрипт будет запускаться как CGI-скрипт либо под одним из пользователей:

- если включена опция RunScriptsAsOwner, то скрипт будет запускаться от имени пользователя, который владеет файлом скрипта,
- если опция RunScriptsAsOwner выключена, то будет запускаться от имени пользователя, который указан в опции ScriptUser.

Есть одна маленькая тонкость: если используется второй вариант, то пользователь, указанный в опции ScriptUser должен отличаться от пользователя, указанного в опции User. В противном случае mathopd будет сообщать об ошибке:

    cannot run scripts without changing identity

У меня файлами веб-сервера владеет пользователь root, а в качестве группы владельца используется группа mathopd. Для запуска скрипта генерации индексных страниц я создал отдельного пользователя mathopd-cgi, включив его в группу mathopd, следующим образом:

    # useradd -c 'mathopd cgi user' -s /sbin/nologin -g mathopd -d /noexistent mathopd-cgi

Осталось добавить в общую секцию Control файла конфигурации следующие настройки, чтобы mathopd вызывал скрипт для генерации индексной страницы:

    RunScriptsAsOwner Off
    ScriptUser mathopd-cgi
    AutoIndexCommand /usr/pkg/etc/index.cgi
   
    Specials {
            CGI { .cgi }
    }

И перезапустить mathopd:

    # /etc/rc.d/mathopd restart

Ссылки
------

* [[Структурированная документация по конфигурации mathopd.conf|mathopd.conf]]
* [[Настройка ikiwkik в режиме CGI с использованием mathopd|ikiwiki_cgi_netbsd/#cgimathopd]]
* [[Настройка запуска mathopd через daemontools|netbsd_daemontools_mathopd]]
* [Обзор mathopd, 3proxy, sqlite и систем для учета трафика](https://www.opennet.ru/base/sys/misk_utils.txt.html)
* [Two-cent tip: Download whole directory as zip file](https://linuxgazette.net/155/lg_tips.html)
