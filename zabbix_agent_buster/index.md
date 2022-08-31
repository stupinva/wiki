Zabbix-агент в Debian Bullseye и Zabbix-сервер 3.4
==================================================

В Zabbix-агенте и сервере после версии 4.4 изменилась структура JSON, используемая элементами данных низкоуровневого обнаружения. Теперь возвращаемые данные больше не помещаются вовнутрь структуры `{"data": [...]}`, а возвращаются как есть, в виде массива `[...]`.

В официальных репозиториях Debian Bullseye поставляется Zabbix-агент версии 5.0.8, который не совместим с серверами Zabbix версии 3.4. Для поиска проблемных узлов можно воспользоваться следующим запросом:

    SELECT hosts.host, items.key_
    FROM items
    JOIN hosts ON hosts.hostid = items.hostid
      AND hosts.status = 0
    WHERE items.status = 0
      AND items.error = 'Cannot find the "data" array in the received JSON object.';

Для решения проблемы можно, например, установить в Debian Bullseye Zabbix-агент 4.0.4 из официальных репозиториев Debian Buster.
