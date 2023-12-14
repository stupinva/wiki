Настройка dnscache из djbdns в NetBSD
=====================================

[[!tag djbdns]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

`dnscache` - это кэширующий сервер DNS из пакета программ `djbdns` авторства небезызвестного Дэниела Бернштайна.

Для запуска `dnscache` будем использовать пакет `daemontools`, а для ведения журналов - утилиту `multilog` из этого пакета. Подробнее об установке и использовании пакета и утилиты можно прочитать в статье [[Использование daemontools в NetBSD|daemontools_netbsd]].

Сборка и установка djbdns
-------------------------

Пропишем в файл `/etc/mk.conf` опции сборки:

    PKG_OPTIONS.djbdns=             -djbdns-cachestats -djbdns-ignoreip2 -djbdns-listenmultiple djbdns-mergequeries djbdns-tinydns64

Установим пакет:

    # cd /usr/pkgsrc/net/djbdns
    # make install

Создание пользователя и группы
-------------------------------

Создадим группу и пользователя, от имени которых будет работать `dnscache`:

    # groupadd dnscache
    # useradd -g dnscache dnscache

Настройка
---------

Создадим каталог `/usr/pkg/etc/dnscache`, в котором будут храниться файлы конфигурации `dnscache`:

    # mkdir /usr/pkg/etc/dnscache
    # chmod +s /usr/pkg/etc/dnscache

Создадим файл `/usr/pkg/etc/dnscache/seed` со случайными 128 байтами:

    # dd if=/dev/urandom of=/usr/pkg/etc/dnscache/seed bs=128 count=1
    # chmod go= /usr/pkg/etc/dnscache/seed

Создадим каталог `/usr/pkg/etc/dnscache/root`, который будет исполнять роль корневого каталога для сервера `dnscache` во время его работы:

    # mkdir /usr/pkg/etc/dnscache/root
    # chmod +s /usr/pkg/etc/dnscache/root

Создадим каталог `/usr/pkg/etc/dnscache/root/ip`, в который поместим пустые файлы с именами, образованными из IP-адресов узлов и сетей, которые будет обслуживать наш DNS-сервер:

    # mkdir /usr/pkg/etc/dnscache/root/ip
    # chmod +s /usr/pkg/etc/dnscache/root/ip
    # touch /usr/pkg/etc/dnscache/root/ip/127.0.0.1
    # chmod go= /usr/pkg/etc/dnscache/root/ip/127.0.0.1
    # touch /usr/pkg/etc/dnscache/root/ip/192.168.252
    # chmod go= /usr/pkg/etc/dnscache/root/ip/192.168.252
    # touch /usr/pkg/etc/dnscache/root/ip/192.168.253
    # chmod go= /usr/pkg/etc/dnscache/root/ip/192.168.253
    # touch /usr/pkg/etc/dnscache/root/ip/192.168.254
    # chmod go= /usr/pkg/etc/dnscache/root/ip/192.168.254

Как видно из примера выше, для сетей класса C нужно создавать пустые файлы, имена которых содержат три октета адреса сети.

Создадим каталог `/usr/pkg/etc/dnscache/root/servers`, внутри которого разместим файл `@`, содержащий IP-адреса корневых серверов DNS:

    # mkdir /usr/pkg/etc/dnscache/root/servers
    # chmod +s /usr/pkg/etc/dnscache/root/servers
    # cp /usr/pkg/share/examples/djbdns/dnsroots.global /usr/pkg/etc/dnscache/root/servers/\@

В этот же каталог можно поместить IP-адреса авторитетных серверов, отвечающих за определённые доменные зоны. Например, для сервера DNS с IP-адресом 192.168.252.5, авторитетного для доменов `stupin.su` и `kuramshin.me` можно создать такие файлы:

    # echo "192.168.252.5" > /usr/pkg/etc/dnscache/root/servers/stupin.su
    # echo "192.168.252.5" > /usr/pkg/etc/dnscache/root/servers/kuramshin.me

Таким же способом можно указать IP-адреса авторитетных серверов для обратных зон:

    # echo "192.168.252.5" > /usr/pkg/etc/dnscache/root/servers/252.168.192.in-addr.arpa
    # echo "192.168.252.5" > /usr/pkg/etc/dnscache/root/servers/253.168.192.in-addr.arpa
    # echo "192.168.252.5" > /usr/pkg/etc/dnscache/root/servers/254.168.192.in-addr.arpa

Настроим запуск `dnscache` через `daemontools`:

    # mkdir /service/.dnscache
    # cat > /service/.dnscache/run <<END
    #!/bin/sh
    
    exec 2>&1
    
    exec </usr/pkg/etc/dnscache/seed
    
    exec \
    envdir ./env \
    envuidgid dnscache \
    softlimit -o 250 -d 3000000 \
    /usr/pkg/bin/dnscache
    END
    # chmod +x /service/.dnscache/run

Зададим переменные окружения для `dnscache`:

    # mkdir /service/.dnscache/env
    # echo -n "1000000" > /service/.dnscache/env/CACHESIZE
    # echo -n "192.168.252.3" > /service/.dnscache/env/IP
    # echo -n "0.0.0.0" > /service/.dnscache/env/IPSEND
    # echo -n "/usr/pkg/etc/dnscache/root" > /service/.dnscache/env/ROOT

Назначение переменных окружения:

* `CACHESIZE` - максимальный объём оперативной памяти в байтах, который `dnscache` может использовать для кэширования DNS-записей,
* `IP` - IP-адрес, на котором `dnscache` будет ожидать поступления входящих запросов,
* `IPSEND` - IP-адрес, с которого `dnscache` будет отправлять исходящие запросы,
* `ROOT` - каталог, который `dnscache` будет использовать в качестве корневого.

Настроим ведение журналов `dnscache` с помощью утилиты `multilog` из пакета `daemontools`:

    # mkdir /service/.dnscache/log
    # cat > /service/.dnscache/log/run <<END
    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/dnscache/
    END
    # chmod +x /service/.dnscache/log/run

Создадим каталог `/var/log/dnscache/` для журналов `dnscache`:

    # mkdir /var/log/dnscache/
    # chown multilog:multilog /var/log/dnscache/

Запуск
------

Запустим сервис:

    # mv /service/.dnscache /service/dnscache

Проверить, что он действительно запустился, можно с помощью команды следующего вида:

    # netstat -anf inet | fgrep .53
    tcp        0      0  *.53                   *.*                    LISTEN
    udp        0      0  *.53                   *.*  

Пропишем в файл `/etc/resolv.conf` IP-адрес 127.0.0.1:

    nameserver 127.0.0.1

И попробуем выполнить запросы для проверки работы сервера `dnscache`:

    # dnsip ya.ru
    87.250.250.242
    # dnsmx stupin.su
    10 mail.stupin.su

Как видно, всё работает.

Дополнительные материалы
------------------------

* [Kevin Day. djbdns patches](http://www.your.org/dnscache/)
* [djbdns: установка и настройка dnscache](https://opennet.ru/docs/RUS/dnscache/)
