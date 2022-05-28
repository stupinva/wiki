Установка ClickHouse
====================

Добавляем в файл /etc/apt/sources.list строку репозитория:

    deb http://repo.yandex.ru/clickhouse/deb/stable/ main/

Скачаем, установим и преобразуем GPG-ключ репозитория в новый формат:

    # cd /etc/apt/trusted.gpg.d/
    # wget http://repo.yandex.ru/clickhouse/CLICKHOUSE-KEY.GPG -O clickhouse-key.gpg
    # gpg --import clickhouse-key.gpg 
    # gpg --output clickhouse-key.gpg --export C8F1E19FE0C56BD4

Обновим список пакетов, доступных через репозиторий:

    # apt-get update

Установим сервер и клиент ClickHouse:

    # apt-get install clickhouse-server clickhouse-client

Использованные материалы
------------------------

* [convert PGP public key block Public-Key (old)](https://www.cubewerk.de/2020/06/02/convert-pgp-public-key-block-public-key-old/)
