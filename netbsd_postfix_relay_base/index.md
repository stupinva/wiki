Postfix из базовой системы NetBSD как локальный SMTP-ретранслятор
=================================================================

[[!tag postfix]]

Ранее я уже настраивал Postfix в Debian: [Postfix как локальный SMTP-ретранслятор](http://vladimir-stupin.blogspot.ru/2014/06/postfix-smtp.html) и во FreeBSD: [Postfix как локальный SMTP-ретранслятор во FreeBSD](https://vladimir-stupin.blogspot.com/2016/03/postfix-smtp-freebsd.html). Здесь я выложу ту же заметку, адаптированную применительно к NetBSD.

В целом настройка Postfix в NetBSD похожа на таковую во FreeBSD. Первое отличие заключается в том, что в NetBSD Postfix уже имеется в составе базовой системы. В Postfix из базовой системы NetBSD нет одной полезной для меня функции: поддержки словарей типа `pcre`. Убедиться в этом можно при помощи следующей команды:

    # postconf -m | grep pcre

Словари `pcre` я использую для добавления к заголовкам писем имени сервера. Если вам не требуется такая функция, можете воспользоваться этой статьёй. Если же вам, как и мне, хочется чтобы к теме письма добавлялось имя сервера, с которого это письмо было отправлено, то рекомендую воспользоваться Postfix из pksrc. Его настройка описана в статье [[Postfix из pkgsrc как локальный SMTP-ретранслятор в NetBSD|netbsd_postfix_relay_pkgsrc]].

Настройка Postfix
-----------------

Настроим Postfix для отправки почты с подменой отправителя и аутентификацией на сервере провайдера. Настроим в файле `/etc/postfix/main.cf` следующую конфигурацию:

    # Имя сервера и его почтового домена
    myhostname = server.domain.tld
    mydomain = server.domain.tld
    
    # Откуда и для кого принимать почту к доставке
    inet_protocols = ipv4
    inet_interfaces = 127.0.0.1
    mydestination = $myhostname, localhost.$mydomain, localhost
    mynetworks = 127.0.0.0/8
    
    # Карта соответствия локальных получателей адресам на почтовом сервере ISP
    alias_maps = hash:/etc/mail/aliases
    alias_database = hash:/etc/mail/aliases
    
    # Использовать защищённые подключения при отправке писем
    smtp_use_tls = yes
    
    # Включаем выбор учётных данных на сервере провайдера в зависимости от отправителя
    smtp_sender_dependent_authentication = yes
    sender_dependent_relayhost_maps = hash:/etc/postfix/sender_relays
    
    # Включаем использование аутентификации на сервере провайдера
    smtp_sasl_auth_enable = yes
    smtp_sasl_password_maps = hash:/etc/postfix/passwords
    
    # Разрешаем использовать механизмы аутентификации PLAIN и LOGIN
    smtp_sasl_security_options = noanonymous
    smtp_sasl_tls_security_options = noanonymous
    smtp_sasl_mechanism_filter = plain, login
    
    # Карта соответствия локальных отправителей ящикам на почтовом сервере ISP
    sender_canonical_maps = regexp:/etc/postfix/sender_maps
    
    # Устанавливаем не более одного исходящего подключения на каждый домен
    default_destination_concurrency_limit = 1
    
    # Отключение опций совместимости с предыдущими версиями Postfix
    compatibility_level = 2
    
    # Отключение использования UTF-8 по умолчанию в адресах и темах писем
    smtputf8_enable = no

Теперь создадим необходимые карты. Укажем в файле `/etc/mail/aliases`, на какие ящики на сервере провайдера перенаправлять почту для локальных пользователей. Я отредактировал уже имеющийся файл и вписал настоящие адреса получателей писем, адресованных `root` и `operator`:

    # Well-known aliases -- these should be filled in!
    root: recipient@domain.tld
    operator: recipient@domain.tld

Почта для пользователя `root` будет перенаправляться в ящик `recipient@domain.tld`.

Укажем в файле `/etc/postfix/sender_maps`, какой ящик на сервере провайдера использовать для отправки почты от локального отправителя:

    /^.*$/ sender@domain.tld

Когда пользователь root попытается отправить письмо, то на сервер провайдера оно уйдёт от отправителя sender@domain.tld.

Укажем в файле `/etc/postfix/sender_relays`, какой сервер следует использовать для отправки писем от определённого отправителя:

    sender@domain.tld [mailserver.domain.tld]:587

Когда пользователь `root` попытается отправить почту, письмо, в соответствии с настройками в файле `/etc/postfix/sender_maps`, будет отправлено с адреса `sender@domain.tld`. Письмо от этого отправителя нужно отправить через порт 587 сервера `mailserver.domain.tld`.

Укажем в файле `/etc/postfix/passwords` учётные данные каждого из ящиков на сервере провайдера:

    sender@domain.tld sender@domain.tld:password

Когда локальный пользователь попытается отправить почту, письмо, в соответствии с настройками в файле `/etc/postfix/sender_maps`, будет отправлено с адреса `sender@domain.tld`. Письмо от этого отправителя, в соответствии с настройками в файле `/etc/postfix/sender_relays`, нужно отправить через порт 587 сервера `mailserver.domain.tld`. В соответствии с настройками в этом файле для аутентификации на сервере провайдера нужно будет использовать имя пользователя `sender@domain.tld` и пароль `password`.

Для файла `/etc/postfix/passwords` стоит задать разрешения, ограничивающие возможность подсмотреть пароли локальными пользователями системы:

    # chown root:wheel /etc/postfix/passwords
    # chmod u=rw,g=r,o= /etc/postfix/passwords

При каждом обновлении файлов карт нужно не забывать обновлять их двоичные копии одной из следующих команд:

    # postalias /etc/mail/aliases
    # postmap /etc/postfix/sender_maps
    # postmap /etc/postfix/sender_relays
    # postmap /etc/postfix/passwords

Двоичные копии имеют то же имя, но с расширением `.db`. Права доступа к оригинальному файлу полностью переносятся и на его двоичную копию.

Включение Postfix
-----------------

По умолчанию Postfix должен быть уже включен. Убедимся, что в файле `/etc/rc.conf` прописана следующая опция:

    postfix=YES

Исторически сложилось так, что первой почтовой системой был Sendmail и в течение некоторого времени не существовало никаких других систем. Поэтому многие программы, взаимодействующие с почтовой системой, были написаны в расчёте только на Sendmail. Возникшие позже почтовые системы в целях совместимости как правило поставляются вместе с некоторыми утилитами, имитирующими таковые из состава Sendmail. Чтобы безболезненно менять почтовую систему в NetBSD предусмотрен файл `/etc/mailer.conf`, в котором прописаны полные пути к утилитам, имитирующим Sendmail. Именно при помощи этого файла можно заменить Postfix из базовой системы NetBSD на Postfix (или другую почтовую систему) из pkgsrc.

Убедимся, что файл `/etc/mailer.conf` указывает на утилиты из базовой системы. Содержимое файла должно быть таким:

    #       $NetBSD: mailer.conf,v 1.18 2011/07/24 08:28:11 mbalmer Exp $
    #
    # This file configures /usr/sbin/mailwrapper, which selects the MTA
    # (Mail Transport Agent) that is invoked when programs like
    # /usr/sbin/sendmail are executed.
    # 
    # See mailwrapper(8) and mailer.conf(5) for an explanation of how this works.
    # See also rc.conf(5) and afterboot(8) for more details on setting up an MTA.
    #
    # The following configuration is correct for Postfix.
    #
    # Notes for running postfix:
    #  - postfix configuration requires either 
    #    hostname to be a FQDN, or for $mydomain 
    #    to be set in /etc/postfix/main.cf
    #  - postfix does not listen on the network
    #    by default; to enable inbound mail reception,
    #    configure /etc/postfix/main.cf and then uncomment
    #    the smtp service in /etc/postfix/master.cf
    #
    sendmail        /usr/libexec/postfix/sendmail
    mailq           /usr/libexec/postfix/sendmail
    newaliases      /usr/libexec/postfix/sendmail

Теперь, когда с настройкой покончено, настало время перезапустить Postfix. Для этого выполним следующую команду:

    # /etc/rc.d/postfix restart

Проверка отправки почты
-----------------------

Осталось проверить правильность работы системы. Попробуем отправить тестовое письмо от имени пользователя `root` пользователю `root`:

    # mail -s test root
    test
    .

На ящик `recipient@domain.tld` должно прийти письмо от ящика `sender@domain.tld`.
