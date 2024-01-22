Zabbix-агент в Debian Bookworm и Zabbix-сервер 3.4
==================================================

[[!tag debian bookworm zabbix_agent]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

В Zabbix-агенте и сервере, начиная с версии 4.2, изменилась структура JSON, используемая элементами данных низкоуровневого обнаружения. Теперь возвращаемые данные больше не помещаются вовнутрь структуры `{"data": [...]}`, а возвращаются как есть, в виде массива `[...]`.

В документации [Руководство по Zabbix / Низкоуровневое обнаружение (LLD) / Низкоуровневое обнаружение (LLD)](https://www.zabbix.com/documentation/current/ru/manual/discovery/low_level_discovery) об этом написано следующее:

>Обратите внимание, что начиная с Zabbix 4.2 формат JSON, возвращаемого правилами низкоуровневого обнаружения, изменился. Более не ожидается, что JSON будет содержать объект "data". Чтобы поддерживать новые возможности - такие как предобработку значений элементов данных и пользовательские пути к значениям LLD-макросов в документе JSON, - правила LLD теперь будут воспринимать обычный JSON, содержащий массив.

Поиск узлов с более свежим пакетом
----------------------------------

В официальных репозиториях Debian Bookworm поставляется Zabbix-агент версии 6.0.14, который не совместим с серверами Zabbix версии 3.4. Для поиска проблемных узлов можно воспользоваться следующим запросом:

    SELECT hosts.host, items.key_
    FROM items
    JOIN hosts ON hosts.hostid = items.hostid
      AND hosts.status = 0
    WHERE items.status = 0
      AND items.error = 'Cannot find the "data" array in the received JSON object.';

Сборка старого Zabbix-агента
-------------------------------

Для решения проблемы можно, например, установить в Debian Bookworm Zabbix-агент 4.0.4 из официальных репозиториев Debian Buster, однако он требует в качестве зависимостей пакеты `libldap-2.4-2` и `multiarch-support`, которых в репозиториях Debian Bookworm. Чтобы выйти из ситуации, пересоберём этот пакет с использованием зависимостей, доступных через официальные репозитории Debian Bookworm.

Установим пакеты, которые нам понадобятся для выполнения сборки:

    # apt-get install wget dpkg-dev devscripts build-essential automake dh-linktree apache2-dev libcurl4-gnutls-dev libevent-dev gnutls-dev libiksemel-dev libldap2-dev default-libmysqlclient-dev libopenipmi-dev libpcre3-dev libpq-dev libsnmp-dev libsqlite3-dev libssh2-1-dev libxml2-dev pkg-config unixodbc-dev zlib1g-dev libjs-prototype libjs-jquery-ui javahelper default-jdk libandroid-json-java liblogback-java libslf4j-java junit4 gettext ruby-sass

Скачаем файлы, необходимые для сборки пакета из исходных текстов:

    $ wget http://mirror.ufanet.ru/debian/pool/main/z/zabbix/zabbix_4.0.4%2Bdfsg-1.dsc
    $ wget http://mirror.ufanet.ru/debian/pool/main/z/zabbix/zabbix_4.0.4%2Bdfsg.orig.tar.xz
    $ wget http://mirror.ufanet.ru/debian/pool/main/z/zabbix/zabbix_4.0.4%2Bdfsg-1.debian.tar.xz

Распакуем скачанные файлы в каталог, внутри которого будет выполняться сборка:

    $ dpkg-source --no-check -x zabbix_4.0.4+dfsg-1.dsc

Переименуем один из файлов так, чтобы его имя соответствовало версии пакета, которую мы будем собирать:

    $ mv zabbix_4.0.4+dfsg.orig.tar.xz zabbix_4.0.4+dfsg-1-debian-bookworm.orig.tar.xz

Войдём в каталог с распакованными файлами:

    $ cd zabbix-4.0.4+dfsg

Отредактируем журнал изменений пакета:

    $ EMAIL=stupin_v@ufanet.ru dch -i

В журнале изменений добавим сверху описание новой версии пакета:

    zabbix (1:4.0.4+dfsg-1-debian-bookworm-1) UNRELEASED; urgency=medium
    
      * Non-maintainer upload.
      * Build old package for Debian 12 Bookworm.
    
     -- Vladimir Stupin <stupin_v@ufanet.ru>  Tue, 19 Sep 2023 11:55:40 +0500

Запустим сборку двоичных пакетов и обновлённого исходного пакета:

    $ dpkg-buildpackage -us -uc -rfakeroot

Установка старого Zabbix-агента
-------------------------------

В результате описанной выше процедуры сборки в выше появится пакет, который можно скачать по ссылке [[zabbix-agent_4.0.4+dfsg-1-debian-bookworm-1_amd64.deb]].

Установить его в систему можно следующим образом:

    # dpkg -i zabbix-agent_4.0.4+dfsg-1-debian-bookworm-1_amd64.deb
    # apt-get install -f

Фиксация старого Zabbix-агента
------------------------------

Для того, чтобы установленный вручную пакет с Zabbix-агентом при обновлении системы из репозиториев не заменился более новым пакетом, можно создать файл `/etc/apt/preferences.d/zabbix` со следующим содержимым:

    Package: zabbix-agent
    Pin: version 1:4.0.4+dfsg-1-debian-bookworm-1
    Pin-Priority: 1003
