Postfix из pkgsrc как локальный SMTP-ретранслятор в NetBSD
==========================================================

Ранее я уже настраивал Postfix в Debian: [Postfix как локальный SMTP-ретранслятор](http://vladimir-stupin.blogspot.ru/2014/06/postfix-smtp.html) и во FreeBSD: [Postfix как локальный SMTP-ретранслятор во FreeBSD](https://vladimir-stupin.blogspot.com/2016/03/postfix-smtp-freebsd.html). Здесь я выложу ту же заметку, адаптированную применительно к NetBSD.

В целом настройка Postfix в NetBSD похожа на таковую во FreeBSD. Первое отличие заключается в том, что в NetBSD Postfix уже имеется в составе базовой системы. В Postfix из базовой системы NetBSD нет одной полезной для меня функции: поддержки словарей типа pcre. Убедиться в этом можно при помощи следующей команды:

    # postconf -m | grep pcre

Словари pcre я использую для добавления к заголовкам писем имени сервера. Если вам, как и мне, хочется чтобы к теме письма добавлялось имя сервера, с которого это письмо было отправлено, то можете воспользоваться этой статьёй. Если же вам не требуется такая функция, можете воспользоваться статьёй [[Postfix из базовой системы NetBSD как локальный SMTP-ретранслятор|netbsd_postfix_relay_base]].

Установка Postfix с PCRE
------------------------

Перейдём в каталог postfix в pkgsrc:

    # cd /usr/pkgsrc/mail/postfix

У Postix есть всего три опции сборки: tls, sasl и eai. По умолчанию включена только опция tls. Увидеть это можно при помощи следующей команды:

    # make show-options

Нам понадобятся опции tls и sasl, а eai - нет. Включим нужные опции и явным образом отключим не нужные, добавив в файл /etc/mk.conf такую строчку:

    PKG_OPTIONS.postfix=    -eai sasl tls

У Postfix нет зависимостей, необходимых для работы, но есть зависимости для сборки. Убедиться в этом можно при помощи таких команд:

    # make show-depends
    # make print-build-depends-list
    # make print-run-depends-list

Для сборки postfix понадобятся следующие зависимости: cwrappers cyrus-sasl digest cyrus-sasl libtool-base m4 perl5 pkgconf

Опции настройки есть только у gmake, perl5 и cyrus-sasl. Пропишем нужные нам и отключим ненужные в файле /etc/mk.conf следующим образом:

    PKG_OPTIONS.gmake=      -nls
    PKG_OPTIONS.perl=       -debug -dtrace -mstats -threads 64bitauto
    PKG_OPTIONS.cyrus-sasl= -bdb -gdbm -ndbm ndbm

Можно приступать к сборке и установке Postfix:

    # make install

Для аутентификации Postfix на внешнем SMTP-сервере нам также понадобятся модули Cyrus SASL с поддержкой аутентификации LOGIN и PLAIN. Установим их:

    # cd /usr/pkgsrc/security/cy2-login
    # make install
    # cd /usr/pkgsrc/security/cy2-plain
    # make install

Для изменения темы письма нам также понадобится модуль PCRE к Postfix. У него него самого и его зависимостей нет опций настройки, поэтому можно просто перейти в соответствующий каталог pkgsrc и выполнить установку:

    # cd /usr/pkgsrc/mail/postfix-pcre
    # make install

Настройка Postfix
-----------------

Настроим Postfix для отправки почты с подменой отправителя и аутентификацией на сервере провайдера. Настроим в файле /usr/pkg/etc/postfix/main.cf следующую конфигурацию:

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
    sender_dependent_relayhost_maps = hash:/usr/pkg/etc/postfix/sender_relays
    
    # Включаем использование аутентификации на сервере провайдера
    smtp_sasl_auth_enable = yes
    smtp_sasl_password_maps = hash:/usr/pkg/etc/postfix/passwords
    
    # Разрешаем использовать механизмы аутентификации PLAIN и LOGIN
    smtp_sasl_security_options = noanonymous
    smtp_sasl_tls_security_options = noanonymous
    smtp_sasl_mechanism_filter = plain, login
    
    # Карта соответствия локальных отправителей ящикам на почтовом сервере ISP
    sender_canonical_maps = regexp:/usr/pkg/etc/postfix/sender_maps
    
    # Устанавливаем не более одного исходящего подключения на каждый домен
    default_destination_concurrency_limit = 1
    
    # Изменение темы письма (не поддерживается Postfix из базовой системы)
    header_checks = pcre:/usr/pkg/etc/postfix/rewrite_subject
    
    # Отключение опций совместимости с предыдущими версиями Postfix
    compatibility_level = 2
    
    # Отключение использования UTF-8 по умолчанию в адресах и темах писем
    smtputf8_enable = no

Теперь создадим необходимые карты. Укажем в файле /etc/mail/aliases, на какие ящики на сервере провайдера перенаправлять почту для локальных пользователей. Я отредактировал уже имеющийся файл и вписал настоящие адреса получателей писем, адресованных root и operator:

    # Well-known aliases -- these should be filled in!
    root: recipient@domain.tld
    operator: recipient@domain.tld

Почта для пользователя root будет перенаправляться в ящик recipient@domain.tld.

Укажем в файле /usr/pkg/etc/postfix/sender_maps, какой ящик на сервере провайдера использовать для отправки почты от локального отправителя:

    /^.*$/ sender@domain.tld

Когда пользователь root попытается отправить письмо, то на сервер провайдера оно уйдёт от отправителя sender@domain.tld.

Укажем в файле /usr/pkg/etc/postfix/sender_relays, какой сервер следует использовать для отправки писем от определённого отправителя:

    sender@domain.tld [mailserver.domain.tld]:587

Когда пользователь root попытается отправить почту, письмо, в соответствии с настройками в файле /etc/postfix/sender_maps, будет отправлено с адреса sender@domain.tld. Письмо от этого отправителя нужно отправить через порт 587 сервера mailserver.domain.tld.

Укажем в файле /usr/pkg/etc/postfix/passwords учётные данные каждого из ящиков на сервере провайдера:

    sender@domain.tld sender@domain.tld:password

Когда локальный пользователь попытается отправить почту, письмо, в соответствии с настройками в файле /etc/postfix/sender_maps, будет отправлено с адреса sender@domain.tld. Письмо от этого отправителя, в соответствии с настройками в файле /usr/pkg/etc/postfix/sender_relays, нужно отправить через порт 587 сервера mailserver.domain.tld. В соответствии с настройками в этом файле для аутентификации на сервере провайдера нужно будет использовать имя пользователя sender@domain.tld и пароль password.

Для файла /usr/pkg/etc/postfix/passwords стоит задать разрешения, ограничивающие возможность подсмотреть пароли локальными пользователями системы:

    # chown root:wheel /usr/pkg/etc/postfix/passwords
    # chmod u=rw,g=r,o= /usr/pkg/etc/postfix/passwords

При каждом обновлении файлов карт нужно не забывать обновлять их двоичные копии одной из следующих команд:

    # /usr/pkg/sbin/postalias /etc/mail/aliases
    # /usr/pkg/sbin/postmap /usr/pkg/etc/postfix/sender_maps
    # /usr/pkg/sbin/postmap /usr/pkg/etc/postfix/sender_relays
    # /usr/pkg/sbin/postmap /usr/pkg/etc/postfix/passwords

Двоичные копиии имеют то же имя, но с расширением .db. Права доступа к оригинальному файлу полностью переносятся и на его двоичную копию.

Создадим файл /usr/pkg/etc/postfix/rewrite_subject для добавления к теме письма имени сервера, с которого оно было отправлено:

    /^Subject: (.*)$/ REPLACE Subject: [server.domain.tld] $1

Настройка переменной PATH
-------------------------

Т.к. в базовой системе NetBSD уже имеется Postfix, команды postalias и postmap в ней уже имеются. По умолчанию в профиле пользователя root в файле /root/.profile настроена переменная PATH со следующим списком каталогов для поиска команд:

* /sbin
* /usr/sbin
* /bin
* /usr/bin
* /usr/pkg/sbin
* /usr/pkg/bin
* /usr/X11R7/bin
* /usr/local/sbin
* /usr/local/bin

Используется программа из первого каталога, в котором она обнаружена. Как видно, предпочтение отдаётся командам, имеющимся в базовой системе. Чтобы изменить это поведение, можно переопределить переменную PATH так, чтобы предпочтение отдавалось утилитам, установленным из pkgsrc. Отредактируем файл /root/.profile, изменив в нём переменную PATH следующим образом:

    export PATH=/usr/pkg/sbin:/usr/pkg/bin:/sbin:/usr/sbin:/bin:/usr/bin
    export PATH=${PATH}:/usr/X11R7/bin:/usr/local/sbin:/usr/local/bin

Теперь в новых сеансах пользователя root будет действовать новая переменная PATH и необходимость вводить полный путь к программам postalias и postmap отпадёт.

Включение Postfix
-----------------

По умолчанию postfix должен быть уже включен. Убедимся, что в файле /etc/rc.conf прописана следующая опция:

    postfix=YES

В базовой системе NetBSD уже имеется Postfix. Чтобы скрипт /etc/rc.d/postfix работал с Postfix не в базовой системе, а с установленным из pkgsrc, нужно создать файл /etc/rc.conf.d/postfix со следующим содержимым:

    postfix_command='/usr/pkg/sbin/postfix'
    required_files='/usr/pkg/etc/postfix/main.cf'
    postconf='/usr/pkg/sbin/postconf'

Исторически сложилось так, что первой почтовой системой был sendmail и в течение некоторого времени не существовало никаких других систем. Поэтому многие программы, взаимодействующие с почтовой системой, были написаны в расчёте только на sendmail. Возникшие позже почтовые системы в целях совместимости как правило поставляются вместе с некоторыми утилитами, имитирующими таковые из состава sendmail. Чтобы безболезненно менять почтовую систему в NetBSD предусмотрен файл /etc/mailer.conf, в котором прописаны полные пути к утилитам, имитирующим sendmail. Именно при помощи этого файла можно заменить postfix из базовой системы NetBSD на postfix (или другую почтовую систему) из pkgsrc. Установленный нами Postfix поставляется с примером такого файла /usr/pkg/share/examples/postfix/mailer.conf.

Скопируем его содержимое в файл /etc/mailer.conf при помощи следующей команды:

    # cat /usr/pkg/share/examples/postfix/mailer.conf > /etc/mailer.conf

Теперь, когда с настройкой покончено, настало время перезапустить postfix. Для этого выполним следующую команду:

    # /etc/rc.d/postfix restart

Проверка отправки почты
-----------------------

Осталось проверить правильность работы системы. Попробуем отправить тестовое письмо от имени пользователя root пользователю root:

    # mail -s test root
    test
    .

На ящик recipient@domain.tld должно прийти письмо от ящика sender@domain.tld.
