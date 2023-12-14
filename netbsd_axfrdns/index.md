Настройка axfrdns из djbdns в NetBSD
====================================

[[!tag djbdns dns]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

`axfrdns` - это авторитетный TCP-сервер DNS из пакета `djbdns` авторства небезызвестного Дэниела Бернштайна.

Для запуска `axfrdns` будем использовать пакет `daemontools`, а для ведения журналов - утилиту `multilog` из этого пакета. Подробнее об установке и использовании пакета и утилиты можно прочитать в статье [[Использование daemontools в NetBSD|daemontools_netbsd]].

Сборка и установка djbdns
-------------------------

Пропишем в файл `/etc/mk.conf` опции сборки:

    PKG_OPTIONS.djbdns=             -djbdns-cachestats -djbdns-ignoreip2 -djbdns-listenmultiple -djbdns-mergequeries -djbdns-tinydns64

Установим пакет:

    # cd /usr/pkgsrc/net/djbdns
    # make install

Создание пользователя и группы для axfrdns
------------------------------------------

Создадим группу и пользователя, от имени которых будет работать `tinydns`:

    # groupadd djbdns
    # useradd -g djbdns axfrdns

Настройка axfrdns
-----------------

Создадим файл `/usr/pkg/etc/axfrdns/tcp`, содержащий правила ограничения доступа к `axfrdns` по IP-адресу клиента, и файл `/usr/pkg/etc/tinydns/Makefile` для компиляции этих правил в двоичный вид в файл `/usr/pkg/etc/axfrdns/tcp.cdb`:

    # mkdir /usr/pkg/etc/axfrdns
    # printf "# sample line:  1.2.3.4:allow,AXFR=\"heaven.af.mil/3.2.1.in-addr.arpa\"\n:deny\n" > /usr/pkg/etc/axfrdns/tcp
    # printf "tcp.cdb: tcp\n\ttcprules tcp.cdb tcp.tmp < tcp" > /usr/pkg/etc/axfrdns/Makefile

Настроим запуск `axfrdns` через `daemontools`:

    # mkdir /service/.axfrdns
    # cat > /service/.axfrdns/run <<END
    #!/bin/sh
    
    exec 2>&1
    
    exec \
    envdir ./env \
    envuidgid axfrdns \
    softlimit -d 300000 \
    tcpserver -vDRHl0 -x /usr/pkg/etc/axfrdns/tcp.cdb -- 0.0.0.0 53 \
    /usr/pkg/bin/axfrdns
    END
    # chmod +x /service/.axrfdns/run

Обратите внимание, что IP-адрес, на котором `axfrdns` будет ожидать входящих подключений, указывается в скрипте `/service/.axfrdns/run`. В примере выше это адрес `0.0.0.0`, то есть входящие подключения будут ожидаться на всех локальных IP-адресах.

Зададим переменную окружения `ROOT`, в которой поместим путь к каталогу, который `axfrdns` будет использовать в качестве корневого:

    # mkdir /service/.axfrdns/env
    # echo -n "/usr/pkg/etc/tinydns" > /service/.axfrdns/env/ROOT

Настроим ведение журналов `axfrdns` с помощью утилиты `multilog` из пакета `daemontools`:

    # mkdir /service/.axfrdns/log
    # cat > /service/.axfrdns/log/run <<END
    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/axfrdns/
    END
    # chmod +x /service/.axfrdns/log/run

Создадим каталог `/var/log/axfrdns/` для журналов `axfrdns`:

    # mkdir /var/log/axfrdns/
    # chown multilog:multilog /var/log/axfrdns/

### Настройка разрешений на передачу зон

Для того, чтобы с любого IP-адреса можно было выполнять запросы единичных записей по протоколу TCP, нужно поместить в файл `/usr/pkg/etc/axfrdns/tcp` такую строчку:

    :allow,AXFR=""

Для того, чтобы позволить IP-адресу `192.168.252.1` полное копирование зоны `stupin.su`, нужно добавить в файл `/usr/pkg/etc/axfrdns/tcp` такую строчку:

    192.168.252.1:allow,AXFR="stupin.su"

Для разрешения передачи нескольких зон их можно перечислить через косую черту, вот так:

    192.168.252.1:allow,AXFR="stupin.su/kuramshin.me/252.168.192.in-addr.arpa/253.168.192.in-addr.arpa/254.168.192.in-addr-arpa"

Для того, чтобы разрешить передавать указанному IP-адресу любую имеющуюся зону, нужно опустить атрибут AXFR полностью:

    192.168.252.1:allow

После редактирования файла не забудьте выполнить в каталоге `/usr/pkg/etc/axfrdns` команду `make`:

    # make

Изменения вступаю в силу немедленно, перезапуск сервиса `axfrdns` при этом не требуется.

Запуск и проверка axfrdns
-------------------------

Запустим сервис:

    # mv /service/.axfrdns /service/axfrdns

Проверить, что он действительно запустился, можно с помощью команды следующего вида:

    # netstat -anf inet | fgrep .53
    tcp        0      0  *.53                   *.*                    LISTEN
    udp        0      0  *.53                   *.*                   

Как видно, теперь кроме UDP-сокета прослушивается ещё и TCP-сокет.

Проверить, что `axfrdns` отвечает на TCP-запросы, можно, например, с помощью утилиты `dig`:

    $ dig stupin.su @192.168.252.5 +tcp -t MX

Проверить передачу зоны можно следующим образом:

    $ dig stupin.su @192.168.252.5 +tcp -t AXFR

Дополнительные материалы
------------------------

Настройка авторитетного UDP-сервера DNS, который называется `tinydns`, описана в статье [[Настройка tinydns из djbdns в NetBSD|netbsd_tinydns]].

Настройка файлов зон для обоих серверов описана в статье [[Настройка файлов зон для tinydns и axfrdns из djbdns|djbdns_zones]].
