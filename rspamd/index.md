Настройка rspamd
================

Разработчики не рекомендуют использовать версию из официальных репозиториев дистрибутива, а рекомендуют воспользоваться официальными репозиториями самих разработчиков. Заходим на страницу [Downloads](https://rspamd.com/downloads.html). Мне нужны репозитории для Debian.

Первым делом ставим GPG-ключ репозитория:

    # wget -O- https://rspamd.com/apt-stable/gpg.key | apt-key add -

Теперь добавляем репозитории в файл /etc/apt/sources.list:

    deb http://rspamd.com/apt-stable/ jessie main
    deb-src http://rspamd.com/apt-stable/ jessie main

Выполним обновление списков пакетов, имеющихся в подключенных репозиториях:

    # apt-get update

Посмотрим, какие версии rspamd доступны:

    # apt-cache policy rspamd
    rspamd:
      Установлен: 0.6.10
      Кандидат:   0.6.10
      Таблица версий:
         1.4.0-2~jessie 0
            500 http://rspamd.com/apt-stable/ jessie/main amd64 Packages
     *** 0.6.10 0
           1001 http://mirror.yandex.ru/debian/ jessie/main amd64 Packages
            100 /var/lib/dpkg/status

Нужно установить версию 1.4.0-2~jessie. Для этого воспользуемся такой командой:

    # apt-get --no-install-recommends install rspamd=1.4.0-2~jessie

Идём на страницу [MTA integration](https://rspamd.com/doc/integration.html). У меня установлен Exim версии 4.84, поэтому мне нужен патч для того, чтобы Exim мог работать с Rspamd. На странице патча нет, поэтому ищем патч через Google. Я нашёл патч по следующей ссылке: [patch-exim-src_spam.c.diff](https://raw.githubusercontent.com/vstakhov/rspamd/master/contrib/exim/patch-exim-src_spam.c.diff). После подгонки патча под Exim версии 4.84 у меня получился собственный, более точно подходящий патч [patch-exim-src_spam.c.diff4](здесь должна быть ссылка)

    # cd /root
    ...
    # wget ссылка/patch-exim-src_spam.c.diff4
    # cd exim4-4.84/
    # patch -Nlp1 < ../patch-exim-src_spam.c.diff4

Далее открываем файл src/EDITME в текстовом редакторе и раскомментируем строчки, включающие поддержку SPF (см. :

    EXPERIMENTAL_SPF=yes
    CFLAGS  += -I/usr/local/include
    LDFLAGS += -lspf2

Теперь добавляем в журнал изменений пакета описание сделанных изменений. Запускаем команду редактирования изменений:

    # dch -i

Добавляем в самый верх журнала следующее описание:

    exim4 (4.84-8.1) UNRELEASED; urgency=medium
  
      * Non-maintainer upload.
      * Enabled experimental SPF support.
      * Added patch for integration with rspamd.
  
     -- Vladimir Stupin <vladimir@stupin.ru>  Tue, 22 Nov 2016 22:58:13 +0500

Создадим патч к пакету с исходниками:

    # dpkg-source --commit
  
В ответ на запрос имени патча введём patch-exim-src, а в открывшемся окне редактирования введём следующее описание патча:

    Description: SFP and rspamd support
     exim4 (4.84-8.1) UNRELEASED; urgency=medium
     .
       * Non-maintainer upload.
       * Enabled experimental SPF support.
       * Added patch for integration with rspamd.
    Author: Vladimir Stupin <vladimir@stupin.ru>

Установим пакеты, необходимые для сборки Exim:

    # apt-get build-dep exim4

Установились пакеты libdb5.3-dev libident libident-dev libpam0g-dev libpcre3-dev libperl-dev libxaw7-dev libxext-dev libxmu-dev libxmu-headers lynx-cur x11proto-xext-dev

Установим ещё пакет для поддержки SPF, который не указан в сборочных зависимостях:

    # apt-get install libspf2-dev

Осталось собрать и установить пакет:

    # dpkg-buildpackage -us -uc -rfakeroot
