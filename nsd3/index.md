Настройка NSD
=============

Поставим пакет с сервером:

    # apt-get install nsd3

Не мудрствуя лукаво, приведу сразу готовый файл конфигурации /etc/nsd3/nsd.conf для двух доменов со вторичными DNS-серверами на nic.ru:

    server:
            hide-version: yes
            ip4-only: yes
            database: "/var/lib/nsd3/nsd.db"
            identity: ""
            logfile: "/var/log/nsd.log"
            server-count: 1
            tcp-count: 100
            tcp-query-count: 0
            tcp-timeout: 120
            ipv4-edns-size: 4096
            pidfile: "/var/run/nsd3/nsd.pid"
            port: 53
            statistics: 3600
            zone-stats-file: "/var/log/nsd.stats"
            username: nsd
            zonesdir: "/etc/nsd3"
            difffile: "/var/lib/nsd3/ixfr.db"
            xfrdfile: "/var/lib/nsd3/xfrd.state"
            xfrd-reload-timeout: 10
            verbosity: 1
            rrl-size: 1000000
            rrl-ratelimit: 200
            rrl-whitelist-ratelimit: 2000
  
    zone:
            name: "stupin.su"
            zonefile: "./stupin.su.zone"
            provide-xfr: 91.217.20.0/26 NOKEY
            provide-xfr: 91.217.21.0/26 NOKEY
            provide-xfr: 194.226.96.192/28 NOKEY
            provide-xfr: 31.177.66.192/28 NOKEY
            #provide-xfr: 195.253.51.22 NOKEY
            #provide-xfr: 195.253.54.22 NOKEY
  
    zone:
            name: "mailover.ru"
            zonefile: "./mailover.ru.zone"
            provide-xfr: 91.217.20.0/26 NOKEY
            provide-xfr: 91.217.21.0/26 NOKEY
            provide-xfr: 194.226.96.192/28 NOKEY
            provide-xfr: 31.177.66.192/28 NOKEY
            #provide-xfr: 195.253.51.22 NOKEY
            #provide-xfr: 195.253.54.22 NOKEY

Закоментированные записи - это тестовые "облачные" серверы из новости: [RU-CENTER укрепляет DNS-инфраструктуру](http://www.nic.ru/news/2013/dns_anycast.html). Их можно использовать по желанию, без дополнительной платы всем клиентам, заказавшим хостинг DNS в этой компании.
