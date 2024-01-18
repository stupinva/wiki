Zabbix-агент в Debian Bullseye и Zabbix-сервер 3.4
==================================================

[[!tag debian bullseye zabbix_agent]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

В Zabbix-агенте и сервере после версии 4.4 изменилась структура JSON, используемая элементами данных низкоуровневого обнаружения. Теперь возвращаемые данные больше не помещаются вовнутрь структуры `{"data": [...]}`, а возвращаются как есть, в виде массива `[...]`.

В документации [Руководство по Zabbix / Низкоуровневое обнаружение (LLD) / Низкоуровневое обнаружение (LLD)](https://www.zabbix.com/documentation/current/ru/manual/discovery/low_level_discovery) об этом написано следующее:

>Обратите внимание, что начиная с Zabbix 4.2 формат JSON, возвращаемого правилами низкоуровневого обнаружения, изменился. Более не ожидается, что JSON будет содержать объект "data". Чтобы поддерживать новые возможности - такие как предобработку значений элементов данных и пользовательские пути к значениям LLD-макросов в документе JSON, - правила LLD теперь будут воспринимать обычный JSON, содержащий массив.

Поиск узлов с более свежим пакетом
----------------------------------

В официальных репозиториях Debian Bullseye поставляется Zabbix-агент версии 5.0.8, который не совместим с серверами Zabbix версии 3.4. Для поиска проблемных узлов можно воспользоваться следующим запросом:

    SELECT hosts.host, items.key_
    FROM items
    JOIN hosts ON hosts.hostid = items.hostid
      AND hosts.status = 0
    WHERE items.status = 0
      AND items.error = 'Cannot find the "data" array in the received JSON object.';

Установка старого Zabbix-агента
-------------------------------

Для решения проблемы можно, например, установить в Debian Bullseye Zabbix-агент 4.0.4 из официальных репозиториев Debian Buster: [zabbix-agent_4.0.4+dfsg-1_amd64.deb](https://ftp.debian.org/debian/pool/main/z/zabbix/zabbix-agent_4.0.4+dfsg-1_amd64.deb):

    # wget https://ftp.debian.org/debian/pool/main/z/zabbix/zabbix-agent_4.0.4+dfsg-1_amd64.deb
    # dpkg -i zabbix-agent_4.0.4+dfsg-1_amd64.deb
    # apt-get install -f

Фиксация старого Zabbix-агента
------------------------------

Для того, чтобы установленный вручную пакет с Zabbix-агентом при обновлении системы из репозиториев не заменился более новым пакетом, можно создать файл `/etc/apt/preferences.d/zabbix` со следующим содержимым:

    Package: zabbix-agent
    Pin: version 1:4.0.4+dfsg-1+deb10u1
    Pin-Priority: 1003
