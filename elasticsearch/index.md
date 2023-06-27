Установка и настройка Elasticsearch для хранения данных Zabbix
==============================================================

[[!tag debian zabbix elasticsearch]]

Подключение репозитория
-----------------------

Elasticsearch нет в официальных репозиториях Debian Stretch, поэтому для его установки воспользуемся репозиторием от авторов Elasticsearch. Пропишем в файл /etc/apt/sources.list строчку с репозиторием:

    deb https://artifacts.elastic.co/packages/7.x/apt stable main

Добавим PGP-ключ репозитория:

    # wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

Обновим список пакетов, доступных для установки через репозитории:

    # apt-get update

Если вы получили сообщение об ошибке, похожее на это:

    E: Драйвер для метода /usr/lib/apt/methods/https не найден.
    N: Проверьте, установлен ли пакет apt-transport-https?
    E: Не удалось получить https://artifacts.elastic.co/packages/7.x/apt/dists/stable/InRelease  
    E: Некоторые индексные файлы не скачались. Они были проигнорированы или вместо них были использованы старые версии.

Это значит, что необходимо установить дополнение к менеджеру репозиторев apt, которое позволит ему работать с репозиториями, доступными через протокол HTTPS:

    # apt-get install apt-transport-https

После установки дополнения попробуйте снова выполнить команду apt-get update.

Установка и запуск сервиса
--------------------------

Установим пакет elasticsearch из добавленных репозиториев:

    # apt-get install elasticsearch

Пакет довольно большой, после установки на диске он займёт примерно половину гигабайта. 320 мегабайт из этого объёма занимает JDK, который зачем-то встроен в пакет.

В пакете с elasticsearch поставляется service-файл для systemd. Попросим systemd перечитать service-файлы:

    # systemctl daemon-reload

Включим и запустим сервис elasticsearch:

    # systemctl enable elasticsearch.service
    # systemctl start elasticsearch.service

Проверить, запустился ли Elasticsearch, можно, например, при помощи команды:

    # systemctl status elasticsearch.service

В моём случае сервис выводил предупреждение:

    OpenJDK 64-Bit Server VM warning: Option UseConcMarkSweepGC was deprecated in version 9.0 and will likely be removed in a future release.

Чтобы избавиться от предупреждения, можно закомментировать соответствующую строчку в файле /etc/elasticsearch/jvm.options
