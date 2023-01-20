Установка и настройка Exim в NetBSD
===================================

Установка пакета
----------------

Перед установкой пакета exim, содержащего SMTP-сервер, пропишем в файле /etc/mk.conf опции пакета, которые нам понадобятся и отключим ненужные:

    PKG_OPTIONS.exim=       exim-tls exim-auth-dovecot exim-content-scan spf -exim-appendfile-maildir -exim-appendfile-mailstore -exim-appendfile-mbx -exim-lookup-dsearch -exim-old-demime -exim-tcp-wrappers -inet6

Установим пакет exim, содержащий SMTP-сервер:

    # cd /usr/pkgsrc/mail/exim
    # make install

Первоначальная настройка
------------------------

Прежде чем приступить к настройке, переименуем имеющийся файл /usr/pkg/etc/exim/configure:

    # cd /usr/pkg/etc/exim/
    # mv configure configure.example

Создадим на месте переименованного файла новый файл конфигурации со следующим содержимым:

    # Имя нашей почтовой системы
    primary_hostname = mail.stupin.su
    
    # Список доменов нашей почтовой системы
    domainlist local_domains = /usr/pkg/etc/exim/local_domains
    
    # Список доменов, для которых наша почтовая система является резервной
    domainlist relay_domains = /usr/pkg/etc/exim/relay_domains
    
    # Список узлов, почту от которых будем принимать без проверок
    hostlist relay_from_hosts = localhost
    
    # Список почтовых ящиков, использующихся только для отправки писем
    addresslist noreply_addresses = /usr/pkg/etc/exim/noreply_addresses
    
    # Список узлов, письма от которых не принимаем
    hostlist spammers_hosts = /usr/pkg/etc/exim/spammers_hosts
    
    # Правила для проверок
    acl_not_smtp = acl_check_not_smtp
    acl_smtp_rcpt = acl_check_rcpt
    acl_smtp_data = acl_check_data
    
    # Отключаем IPv6, слушаем порты 25 и 587
    disable_ipv6
    daemon_smtp_ports = 25 : 587
    
    # Дописываем домены отправителя и получателя, если они не указаны
    qualify_domain = stupin.su
    qualify_recipient = stupin.su
    
    # Exim никогда не должен запускать процессы от имени пользователя root
    never_users = root
    
    # Проверять прямую и обратную записи узла отправителя по DNS
    host_lookup = *
    
    # Отключаем проверку пользователей узла отправителя по протоколу ident
    rfc1413_hosts = *
    rfc1413_query_timeout = 0s
    
    # Только эти узлы могут не указывать домен отправителя или получателя
    sender_unqualified_hosts = +relay_from_hosts
    recipient_unqualified_hosts = +relay_from_hosts
    
    # Лимит размера сообщения, 30 мегабайт
    message_size_limit = 30M
    
    # Запрещаем использовать знак % для явной маршрутизации почты
    percent_hack_domains =
    
    # Настройки обработки ошибок доставки, используются значения по умолчанию
    ignore_bounce_errors_after = 2d
    timeout_frozen_after = 7d
    
    # Включить расширение SMTP 8BITMIME для приёма 8-битных писем, не кодированных в
    # 7-битную кодировку Quoted Printable (используется по умолчанию)
    accept_8bitmime = yes
    
    # Возвращать в рикошете тело сообщения (используется по умолчанию)
    bounce_return_body = yes
    # Ограничить размер тела сообщения в рикошете 100 килобайтами (используется по умолчанию)
    bounce_return_size_limit = 100K
    # Задаёт адрес отправителя рикошетов (по умолчанию - пусто)
    bounce_sender_authentication = mailer-daemon@stupin.su
    # Если получатель рикошета попытается на него ответить, ответ уйдёт на этот адрес
    errors_reply_to = postmaster@stupin.su
    
    begin acl
    
      # Проверки для локальных отправителей
      acl_check_not_smtp:
    
        accept
    
      # Проверки на этапе RCPT
      acl_check_rcpt:
    
        accept hosts = :
    
        # Отклоняем неправильные адреса почтовых ящиков  
        deny message = Restricted characters in address
             domains = +local_domains
             local_parts = ^[.] : ^.*[@%!/|]
    
        # Отклоняем неправильные адреса почтовых ящиков  
        deny message = Restricted characters in address
             domains = !+local_domains
             local_parts = ^[./|] : ^.*[@%!] : ^.*/\\.\\./
    
        # В локальные ящики postmaster и abuse принимает почту всегда
        accept local_parts = postmaster : abuse
               domains = +local_domains
    
        # Проверяем существование домена отправителя
        require verify = sender
    
        # Не принимаем письма от узлов, замеченных в отправке только спама
        deny message = Your IP was blocked due spam. You may contact with postmaster anyway
             hosts = +spammers_hosts
    
        # Не принимаем письма для почтовых ящиков, предназначенных только для отправки писем
        deny message = No reply mailbox
             recipients = +noreply_addresses
    
        # Принимаем почту от доверенных узлов, попутно исправляя заголовки письма
        accept hosts = +relay_from_hosts
               control = submission
    
        # Принимаем почту от аутентифицированных узлов, попутно исправляя заголовки письма
        accept authenticated = *
               control = submission/domain=
    
        # Принимаем почту для доменов, для которых наш сервер является запасным
        accept domains = +relay_domains
    
        # Проверяем почту для существующих получателей из обслуживаемых нами доменов
        accept domains = +local_domains
               verify = recipient/callout=no_cache
    
        # Всю остальную почту отклоняем
        deny message = Relay not permitted
    
      acl_check_data:
    
        accept
    
    begin routers
    
      # Поиск транспорта для удалённых получателей
      dnslookup:
        driver = dnslookup
        domains = ! +local_domains
        transport = remote_smtp
        ignore_target_hosts = 0.0.0.0 : 127.0.0.0/8
        no_more
    
      # Пересылки для локальных получателей из файла /etc/mail/aliases
      system_aliases:
        driver = redirect
        allow_fail
        allow_defer
        domains = stupin.su
        data = ${lookup{$local_part}lsearch{/etc/mail/aliases}}
    
      # Пересылки для получателей в разных доменах
      aliases:
        driver = redirect
        allow_fail
        allow_defer
        data = ${lookup{$local_part@$domain}lsearch{/usr/pkg/etc/exim/aliases}}
    
      # Получение почты на локальный ящик
      mailbox:
        driver = manualroute
        route_list = "* mda.vm.stupin.su byname"
        domains = +local_domains
        transport = dovecot_lmtp
    
    begin transports
    
      # Транспорт для удалённых получателей
      remote_smtp:
        driver = smtp
    
      # Транспорт для локальных получателей из Dovecot
      dovecot_lmtp:
        driver = smtp
        rcpt_include_affixes
        protocol = lmtp
        port = 24
    
    begin retry
    
      *   *   F,2h,15m; G,16h,1h,1.5; F,4d,6h
    
    begin rewrite
    
    begin authenticators

В этом файле настроена базовая почтовая система, которая:

  * умеет принимать почту для почтовых ящиков своих доменов и передавать её LMTP-серверу,
  * пересылать почту для получаетелей из доменов, для которых наш сервер является запасным,
  * отправлять почту, принятую без аутентификации с адреса localhost.

Пока что эта почтовая система не умеет принимать письма от аутентифицированных пользователей, проверять письма на вирусы, проверять и добавлять DKIM-подписи, проверять отправителей по SPF-записям, временно отказывать в приёме писем от узлов-отправителей, замеченных в публичных чёрных списках. Все эти настройки мы добавим позже.

Использованные материалы:

  * [LMTP/Exim](https://wiki2.dovecot.org/LMTP/Exim)
  * [Exim и Dovecot без SQL](https://vladimir-stupin.blogspot.com/2014/05/exim-dovecot-sql.html)

Списки доменов, узлов, адресов
------------------------------

В каталоге конфигурации сервера /etc/pkg/etc/exim есть несколько файлов со списками доменов, узлов и адресов.

Список локальных доменов, для получателей в которых наш сервер будет принимать письма:

    mta# cat local_domains
    stupin.su
    kuramshin.me

Список доменов, для которых наш сервер будет выступать в роли запасного и будет принимать письма для передачи основному серверу, когда тот снова появится в сети:

    mta# cat relay_domains

Список профессиональных рассыльщиков спама, которые обходят все проверки:

    mta# cat spammers_hosts
    91.235.233.0/24
    91.239.215.0/24
    91.247.220.0/24
    193.105.174.0/24
    37.187.19.13

Список почтовых ящиков, которые используются только для отправки писем:

    mta# cat noreply_addresses
    zabbix@stupin.su
    rss@stupin.su
    redmine@stupin.su
    wordpress@kuramshin.me

Первый запуск сервера
---------------------

Копируем пример скрипта управления Exim в соответствующий каталог:

    mta# cp /usr/pkg/share/examples/rc.d/exim /etc/rc.d/

Заменяем файл с настройками используемых почтовых программ:

    mta# mv /etc/mailer.conf /etc/mailer.conf.bak
    mta# cp /usr/pkg/share/examples/exim/mailer.conf /etc/

Отключаем в файле /etc/rc.conf установленный по умолчанию почтовый сервер Postfix, включаем установленный нами Exim:

    postfix=NO
    exim=YES

Запускаем Exim:

    mta# /etc/rc.d/exim start
    Starting exim.

Смотрим список открытых на прослушивание портов:

    mta# netstat -anf inet
    Active Internet connections (including servers)
    Proto Recv-Q Send-Q  Local Address          Foreign Address        State
    tcp        0      0  *.587                  *.*                    LISTEN
    tcp        0      0  *.25                   *.*                    LISTEN
    tcp        0      0  169.254.252.13.22      169.254.252.1.40224    ESTABLISHED
    tcp        0      0  *.22                   *.*                    LISTEN

Видим, что порты 25 и 587 прослушиваются.

Проверка доставки писем
-----------------------

Попробуем проверить доставку писем, попытавшись отправить его с самого SMTP-сервера. Для этого воспользуемся telnet. Подключимся локально к 25 порту TCP:

    mta# telnet 127.0.0.1 25
    Trying 127.0.0.1...
    Connected to localhost.
    Escape character is '^]'.
    220 mail.stupin.su ESMTP Exim 4.94 Wed, 09 Dec 2020 16:03:29 +0500

Отправим серверу приветственное сообщение:

    EHLO mail.stupin.su
    250-mail.stupin.su Hello localhost [127.0.0.1]
    250-SIZE 31457280
    250-8BITMIME
    250-PIPELINING
    250-X_PIPE_CONNECT
    250-CHUNKING
    250-STARTTLS
    250 HELP

Сообщим адрес отправителя, от имени которого собираемся отправить письмо:

    MAIL FROM: vladimir@stupin.su
    250 OK

Сообщим адрес получателя, которому хотим отправить письмо:

    RCPT TO: vladimir@stupin.su
    250 Accepted

Передаём команду DATA, сообщающую о нашем намерении передать заголовки и тело самого письма:

    DATA
    354 Enter message, ending with "." on a line by itself

Вводим заголовки и текст письма, завершив их строкой с одной точкой:

    test
    
    TEST
    .
    250 OK id=1kmxG9-0000ue-87

Сервер сообщил, что принял письмо к доставке. Передаём серверу команду QUIT для отключения:

    QUIT
    221 mail.stupin.su closing connection
    Connection closed by foreign host.

Теперь можно зайти на виртуальную машину с Dovecot, перейти в каталог с новыми письмами:

    mda# cd /var/vmail/stupin.su/vladimir/new

Смотрим список имеющихся писем:

    mda# ls
    1607509268.M720210P776.mda.vm.stupin.su,S=287,W=299
    1607511835.M488752P1244.mda.vm.stupin.su,S=678,W=698

Первое письмо осталось после проверки работоспособности LMTP-сервера, посмотрим содержимое второго:

    mda# less 1607511835.M488752P1244.mda.vm.stupin.su,S\=678,W\=698 

Убеждаемся, что это только что отправленное нами письмо:

    Return-Path: <vladimir@stupin.su>
    Delivered-To: vladimir@stupin.su
    Received: from mail.stupin.su ([169.254.252.13])
            (using TLSv1.3 with cipher TLS_AES_256_GCM_SHA384 (256/256 bits))
            by mda.vm.stupin.su with LMTPS
            id 71KlGhuv0F/cBAAAfuT4vQ
            (envelope-from <vladimir@stupin.su>)
            for <vladimir@stupin.su>; Wed, 09 Dec 2020 16:03:55 +0500
    Received: from localhost ([127.0.0.1] helo=mail.stupin.su)
            by mail.stupin.su with esmtp (Exim 4.94)
            (envelope-from <vladimir@stupin.su>)
            id 1kmxG9-0000ue-87
            for vladimir@stupin.su; Wed, 09 Dec 2020 16:03:54 +0500
    Message-Id: <E1kmxG9-0000ue-87@mail.stupin.su>
    From: vladimir@stupin.su
    Date: Wed, 09 Dec 2020 16:03:52 +0500
    
    test
    
    TEST

Очистка очереди доставки
------------------------

Смотрим список писем, застрявших в очереди:

    $ mailq

Размораживаем все замороженные письма:

    $ exiqgrep -i | xargs exim -Mt

Пытаемся доставить письма из очереди прямо сейчас:

    $ exim -q

Удаляем все письма из очереди:

    $ exiqgrep -i | xargs exim -Mrm

При наличии заблокированных сообщений можно узнать идентификаторы процессов, пытающихся доставить их:

    $ exiwhat

Затем можно принудительно завершить выполнение этих процессов, указав их идентификаторы команде `kill`, после чего можно попробовать снова удалить сообщения из очереди.

Настройка грейлистинга
----------------------

Для грейлистинга воспользуемся демоном `greylistd`, написанном на Python. Этот демон не настолько сложен, как `milter-greylist`, которым я воспользовался для настройки грейлистинга в Postfix, однако его простота с лихвой компенсируется возможностями Exim. К сожалению, в pkgsrc нет greylistd, поэтому пришлось [[подготовить его самостоятельно|netbsd_greylistd]].

Установим пакет greylistd:

    # cd /usr/pkgsrc/mail/greylistd
    # make install

Для запуска greylistd я воспользовался daemontools так, как это описано в статье [[Запуск greylistd в NetBSD с помощью daemontools|netbsd_daemontools_greylistd]].

greylistd предоставляет механизм, а политику можно определить в конфигурации Exim. Я придерживаюсь политики подвергать грейлистингу те узлы, которые оказались в чёрном списке. Для того, чтобы включить грейлистинг, нужно в самый конец списка управления доступом `acl_check_rcpt` до финального правила `deny` добавить следующую проверку:

    defer message = Greylisting in action, try later
          !senders = :
          !hosts = ${if exists{/usr/pkg/etc/greylistd/whitelist-hosts}\
                              {/usr/pkg/etc/greylistd/whitelist-hosts}{}} : \
                   ${if exists{/var/db/greylistd/whitelist-hosts}\
                              {/var/db/greylistd/whitelist-hosts}{}}
          dnslists = zen.spamhaus.org
          condition = ${readsocket{/var/run/greylistd.sock}\
                                  {--grey $sender_host_address $sender_address $local_part@$domain}\
                                  {5s}{}{false}}

В поле `!senders` можно прописать адреса тех отправителей, которые не должны подвергаться грейлистингу. Соответственно, чтобы узел с определённым IP-адресом не подвергался грейлистингу, его можно добавить в файл `/usr/pkg/etc/greylistd/whitelist-hosts`.

Включим пользователя mail в группу greylist, чтобы Exim имел доступ к сокету и файлам `greylistd`:

    # usermod -G greylist mail

Осталось попросить Exim перезагрузить файл конфигурации, чтобы новые настройки вступили в силу:

    # /etc/rc.d/exim4 reload

Другие материалы
----------------

  * [SRS](https://en.wikipedia.org/wiki/Sender_Rewriting_Scheme)
  * [MTA-STS](https://www.hardenize.com/blog/mta-sts)
  * [DMARC](https://habr.com/ru/company/mailru/blog/170957/)
  * [Ещё про DMARC](https://www.unisender.com/ru/blog/sovety/putevoditel-po-dmarc-chto-eto-zachem-nuzhno-i-kak-propisat/)
