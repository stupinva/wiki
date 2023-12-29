Пример настройки файлов зон для tinydns и axfrdns из djbdns
===========================================================

[[!tag djbdns dns]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Прежде всего, стоит учесть, что в одном файле описываются записи всех зон. Во-вторых, стоит учитывать, что порядок указания записей не имеет значения.

Простой пример
--------------

Первым рассмотрим пример настройки самой маленькой и простой зоны:

    .kuramshin.me::ns1.stupin.su.:10800
    &kuramshin.me::c.ns.buddyns.com.:10800
    &kuramshin.me::e.ns.buddyns.com.:10800
    &kuramshin.me::j.ns.buddyns.com.:10800
    +kuramshin.me:188.234.148.179:10800
    +www.kuramshin.me:188.234.148.179:10800

В первой строчке фигурирует SOA-запись для домена `kuramshin.me`, основным DNS-сервером для которого является узел с доменным именем `ns1.stupin.su`.

В следующих трёх строчках указаны дополнительные DNS-серверы.

В последних двух строчках указаны две A-записи с именами `kuramshin.me` и `www.kuramshin.me`, указывающие на IP-адрес 188.234.148.179.

Пример посложнее
----------------

Рассмотрим более сложный пример с почтовым сервером и XMPP-сервером. Первый фрагмент в целом похож на предыдущую зону:

    .stupin.su:188.234.148.179:ns1.stupin.su.:10800
    &stupin.su::c.ns.buddyns.com.:10800
    &stupin.su::e.ns.buddyns.com.:10800
    &stupin.su::j.ns.buddyns.com.:10800
    +stupin.su:188.234.148.179:10800
    +manpages.stupin.su:188.234.148.179:10800
    +netbsd.stupin.su:188.234.148.179:10800
    +thedjbway.stupin.su:188.234.148.179:10800
    +vladimir.stupin.su:188.234.148.179:10800

Отличие от предыдущего случая тут лишь в первой строчке - в ней указан IP-адрес `188.234.148.179` DNS-сервера `ns1.stupin.su.`, ответственного за доменную зону `stupin.su`. Поскольку тут указан IP-адрес, вместе с SOA- и NS-записями будет создана ещё и A-запись для DNS-сервера.

Рассмотрим настройку записей, соответствующих почтовому серверу:

    =mail.stupin.su:188.234.148.179:10800
    @stupin.su::mail.stupin.su.:10:10800
    'stupin.su:v=spf1 +mx ~all:10800
    'mail._domainkey.stupin.su:v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDG4ffUuNzbN1yko8SanKL0i/n38KQgJOk6SxElyU95fbiK2gBGg1tMnPM1q4wlyAGDbsdFst++F803rUh/6BhN5/dfwcwvHC0RTaBgRRFiy5M2N7Jb79hc2TEC5JAPW6j5F8A3UaebgW0jYvvDFUzA2t3eHbFDQRlB9DU86FewbwIDAQAB:10800

Первой строчкой настраиваются A- и PTR-записи, связывающие между собой доменное имя `mail.stupin.su` и IP-адрес `188.234.148.179`.

Второй строчкой настраивается MX-запись для домена `stupin.su` - она соответствует почтовому серверу с доменным именем `mail.stupin.su` и приоритетом 10.

Третьей и четвёртой строчкой создаются TXT-записи с политикой SPF и с ключами для проверки подписей DKIM.

Далее рассмотрим настройку записей, соответствующих XMPP-серверу:

    +jabber.stupin.su:188.234.148.179:10800
    S_xmpp-client._tcp.stupin.su::jabber.stupin.su.:0:0:5222:10800
    S_xmpp-server._tcp.stupin.su::jabber.stupin.su.:0:0:5269:10800
    S_xmpp-server._tcp.conference.stupin.su::jabber.stupin.su.:0:0:5269:10800
    S_xmpp-server._tcp.pubsub.stupin.su::jabber.stupin.su.:0:0:5269:10800
    S_xmpp-server._tcp.proxy.stupin.su::jabber.stupin.su.:0:0:5269:10800
    S_xmpp-server._tcp.vjud.stupin.su::jabber.stupin.su.:0:0:5269:10800
    '_xmppconnect.stupin.su:_xmpp-client-xbosh=https\072//stupin.su/bosh:10800

Первой строчкой создаётся A-запись, последней строчкой создаётся TXT-запись. Обратите внимание, что двоеточие в текстовой строке заменено на последовательность `\072`. Все остальные строчки настраивают SRV-записи с приоритетами 0, весами 0, и портами: для клиентов - 5222, для серверов - 5269.

Локальные зоны и PTR-записи
---------------------------

Прежде всего настроим классификацию клиентов:

    %wan
    %lo:192.168

По умолчанию клиент причисляется к классу `wan`, а клиенты с префиксом `192.168` причисляются к классу `lo`. Указать маску подсети при классификации клиентов нельзя.

Теперь определим A- и PTR-записи с указанием класса `lo`, которые будут отдаваться только клиентам этого класса:
    
    =eeepc.lo.stupin.su:192.168.254.3:10800::lo
    =eeepc.wi.stupin.su:192.168.253.3:10800::lo
    =asus.lo.stupin.su:192.168.254.4:10800::lo
    =asus.wi.stupin.su:192.168.253.4:10800::lo
    =duos.wi.stupin.su:192.168.253.5:10800::lo
    =dlink.lo.stupin.su:192.168.254.6:10800::lo
    =usr.lo.stupin.su:192.168.254.7:10800::lo
    =usr.lo.stupin.su:192.168.254.7:10800::lo
    =ata1.lo.stupin.su:192.168.254.8:10800::lo
    =ata2.lo.stupin.su:192.168.254.9:10800::lo
    =digma.wi.stupin.su:192.168.253.10:10800::lo
    =wileyfox.wi.stupin.su:192.168.253.11:10800::lo
    =bbk1.lo.stupin.su:192.168.254.12:10800::lo
    =win7.lo.stupin.su:192.168.254.14:10800::lo
    =mi10t.wi.stupin.su:192.168.253.18:10800::lo
    =alcatel.wi.stupin.su:192.168.253.19:10800::lo
    =bbk2.lo.stupin.su:192.168.254.20:10800::lo
    =tcl.lo.stupin.su:192.168.254.21:10800::lo
    =redmi10c.wi.stupin.su:192.168.253.22:10800::lo
    =snr.lo.stupin.su:192.168.254.24:10800::lo
    =motorola.wi.stupin.su:192.168.253.25:10800::lo
    =leeco.wi.stupin.su:192.168.253.26:10800::lo
    =acer.lo.stupin.su:192.168.254.27:10800::lo
    =acer.wi.stupin.su:192.168.253.27:10800::lo
    =huawei.lo.stupin.su:192.168.254.28:10800::lo
    =hp.lo.stupin.su:192.168.254.29:10800::lo
    =ubiquiti.lo.stupin.su:192.168.253.31:10800::lo
    =ubiquiti.wi.stupin.su:192.168.253.31:10800::lo
    =apc1500.lo.stupin.su:192.168.254.32:10800::lo
    =lenovo.wi.stupin.su:192.168.253.33:10800::lo
    
    =dnscache.vm.stupin.su:192.168.252.2:10800::lo
    =mon.vm.stupin.su:192.168.252.3:10800::lo
    =kuramshin.vm.stupin.su:192.168.252.4:10800::lo
    =tinydns.vm.stupin.su:192.168.252.5:10800::lo
    =win7.vm.stupin.su:192.168.252.6:10800::lo
    =minecraft.vm.stupin.su:192.168.252.7:10800::lo
    =winxp-2.vm.stupin.su:192.168.252.11:10800::lo
    =mda.vm.stupin.su:192.168.252.12:10800::lo
    =mta.vm.stupin.su:192.168.252.13:10800::lo
    =www.vm.stupin.su:192.168.252.14:10800::lo
    =git.vm.stupin.su:192.168.252.15:10800::lo
    =wiki.vm.stupin.su:192.168.252.16:10800::lo
    =win10.vm.stupin.su:192.168.252.17:10800::lo
    =sysbuild.vm.stupin.su:192.168.252.18:10800::lo

Для того, чтобы сервер начал отвечать на запросы PTR-записей, нужно определить SOA-записи для обратной зоны и ответственные за них DNS-серверы:

    .253.168.192.in-addr.arpa:192.168.253.5:tinydns.wi.stupin.su.:10800::lo
    .254.168.192.in-addr.arpa:192.168.254.5:tinydns.lo.stupin.su.:10800::lo
    .252.168.192.in-addr.arpa::tinydns.vm.stupin.su.:10800::lo
    .179.148.234.188.in-addr.arpa::ns1.stupin.su.:10800::lo

В первых записях определены так же A-записи для DNS-серверов, т.к. указаны их IP-адреса.

Дополнительные материалы
------------------------

* [[Настройка файлов зон для tinydns и axfrdns из djbdns|djbdns_zones]]
