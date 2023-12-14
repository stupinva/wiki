Настройка tinydns из djbdns в NetBSD
====================================

[[!tag djbdns dns]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

`tinydns` - это авторитетный UDP-сервер DNS из пакета `djbdns` авторства небезызвестного Дэниела Бернштайна.

Для запуска `tinydns` будем использовать пакет `daemontools`, а для ведения журналов - утилиту `multilog` из этого пакета. Подробнее об установке и использовании пакета и утилиты можно прочитать в статье [[Использование daemontools в NetBSD|daemontools_netbsd]].

Сборка и установка djbdns
-------------------------

Пропишем в файл `/etc/mk.conf` опции сборки:

    PKG_OPTIONS.djbdns=             -djbdns-cachestats -djbdns-ignoreip2 -djbdns-listenmultiple -djbdns-mergequeries -djbdns-tinydns64

Установим пакет:

    # cd /usr/pkgsrc/net/djbdns
    # make install

Создание пользователя и группы для tinydns
------------------------------------------

Создадим группу и пользователя, от имени которых будет работать `tinydns`:

    # groupadd djbdns
    # useradd -g djbdns tinydns

Настройка tinydns
-----------------

Создадим каталог `/usr/pkg/etc/tinydns`, в котором будут храниться файлы конфигурации `tinydns`:

    # mkdir /usr/pkg/etc/tinydns
    # chmod +st /usr/pkg/etc/tinydns

Создадим пустой файл базы данных DNS, скрипты для добавления новых записей в этот файл и `Makefile` для преобразования базы данных в двоичный вид:

    # touch /usr/pkg/etc/tinydns/data
    # printf "#!/bin/sh\n\nexec /usr/pkg/bin/tinydns-edit data data.new add alias \${1+\"\$@\"}\n" > /usr/pkg/etc/tinydns/add-alias
    # printf "#!/bin/sh\n\nexec /usr/pkg/bin/tinydns-edit data data.new add childns \${1+\"\$@\"}\n" > /usr/pkg/etc/tinydns/add-childns
    # printf "#!/bin/sh\n\nexec /usr/pkg/bin/tinydns-edit data data.new add host \${1+\"\$@\"}\n" > /usr/pkg/etc/tinydns/add-host
    # printf "#!/bin/sh\n\nexec /usr/pkg/bin/tinydns-edit data data.new add mx \${1+\"\$@\"}\n" > /usr/pkg/etc/tinydns/add-mx
    # printf "#!/bin/sh\n\nexec /usr/pkg/bin/tinydns-edit data data.new add ns \${1+\"\$@\"}\n" > /usr/pkg/etc/tinydns/add-ns
    # printf "data.cdb: data\n\t/usr/pkg/bin/tinydns-data\n" > /usr/pkg/etc/tinydns/Makefile
    # chmod +x /usr/pkg/etc/tinydns/add-*

Настроим запуск `tinydns` через `daemontools`:

    # mkdir /service/.tinydns
    # cat > /service/.tinydns/run <<END
    #!/bin/sh
    
    exec 2>&1
    
    exec \
    envdir ./env \
    envuidgid tinydns \
    softlimit -d 3000000 \
    /usr/pkg/bin/tinydns
    END
    # chmod +x /service/.tinydns/run

Зададим переменные окружения для `tinydns`:

    # mkdir /service/.tinydns/env
    # echo -n "0.0.0.0" > /service/.tinydns/env/IP
    # echo -n "/usr/pkg/etc/tinydns" > /service/.tinydns/env/ROOT

Назначение переменных окружения:

* IP - IP-адрес, на котором `tinydns` будет ожидать поступления входящих запросов,
* ROOT - каталог, который `tinydns` будет использовать в качестве корневого.

Настроим ведение журналов `tinydns` с помощью утилиты `multilog` из пакета `daemontools`:

    # mkdir /service/.tinydns/log
    # cat > /service/.tinydns/log/run <<END
    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/tinydns/
    END
    # chmod +x /service/.tinydns/log/run

Создадим каталог `/var/log/tinydns/` для журналов `tinydns`:

    # mkdir /var/log/tinydns/
    # chown multilog:multilog /var/log/tinydns/

Дополнительные материалы
------------------------

Настройка авторитетного TCP-сервера DNS, который называется `axfrdns`, описана в статье [[Настройка axfrdns из djbdns в NetBSD|netbsd_axfrdns]].

Настройка файлов зон для обоих серверов описана в статье [[Настройка файлов зон для tinydns и axfrdns из djbdns|djbdns_zones]].
