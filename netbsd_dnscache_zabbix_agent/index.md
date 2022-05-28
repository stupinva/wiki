Мониторинг dnscache из djbdns в NetBSD через Zabbix-агента
==========================================================

Для мониторинга через Zabbix-агента нужно привести файл `/service/dnscache/log/run` к следующему виду:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/dnscache/ \
            '-*' '+* stats *' =/var/log/dnscache/stats

Далее нужно создать файл `/var/log/dnscache/stats`, разрешить его чтение Zabbix-агенту и перезапустить `multilog`:

    touch /var/log/dnscache/stats
    chown multilog:multilog /var/log/dnscache/stats
    chmod u=rw,go=r /var/log/dnscache/stats
    svc -t /service/dnscache/log/

В соответствии с рекомендациями по настройке размера кэша, которые можно найти по ссылке [djbdns: установка и настройка dnscache / Размер кэша](https://opennet.ru/docs/RUS/dnscache/#cachesize), идеальный объём кэша позволяет хранить записи в течение недели. Однако на практике значение этого элемента данных колеблется в зависимости от срока годности записей, находящихся в кэше. Я настроил триггеры так, что они срабатывают при значениях менее 3 или более 10. Триггеры не срабатывают, если значение глубины кэша находится в интервале от 4 до 8 суток.

Дополнительные материалы
------------------------

* [Rob Mayoff. dnscache Log File Format](http://www.dqd.com/~mayoff/notes/djbdns/dnscache-log.html)
* [dnscache log processor](http://mikebabcock.ca/code/dnscacheproc/)
