Настройка PostgreSQL для миграции базы данных на новую версию TimescaleDB
=========================================================================

Постановка задачи
-----------------

Имеется база данных в PostgreSQL 12, использующая TimescaleDB версии 1.7.4. Нужно перенести её в PostgreSQL 13 с обновлением TimescaleDB до версии 2.7.0.

Настройка виртуальной машины
----------------------------

Для сборки pg_repack понадобится настроить виртуальную машину, аналогичную используемой на том сервере, где собираемся использовать утилиту. В рассматриваемом примере это система Debian 8.11.1 LTS с кодовым именем Jessie. Получить образ установочного диска можно по ссылке [debian-9.13.0-amd64-netinst.iso](http://cdimage.debian.org/cdimage/archive/9.13.0/amd64/iso-cd/debian-9.13.0-amd64-netinst.iso).

Настройка репозиториев
----------------------

Для настройки репозиториев поместим в файл `/etc/apt/sources.list` следующие строки:

    deb http://mirror.ufanet.ru/debian/ stretch main contrib non-free
    deb http://mirror.ufanet.ru/debian/ stretch-updates main contrib non-free
    deb http://mirror.ufanet.ru/debian/ stretch-proposed-updates main contrib non-free
    deb http://mirror.ufanet.ru/debian-security stretch/updates main contrib non-free

Отключаем установку предлагаемых зависимостей, создав файл `/etc/apt/apt.conf.d/suggests` со следующим содержимым:

    APT::Install-Suggests "false";

Отключаем установку рекомендуемых зависимостей, создав файл `/etc/apt/apt.conf.d/recommends` со следующим содержимым:

    APT::Install-Recommends "false";

Система apt сохраняет скачанные пакеты в каталоге `/var/cache/apt/archives/`, чтобы при необходимости не скачивать их снова. Файлы в этом каталоге по умолчанию не удаляются, что может привести к переполнению диска. Чтобы отключить размер файлов в этом каталоге 200 мегабайтами, создадим файл `/etc/apt/apt.conf.d/cache` со следующим содержимым:

    APT::Cache-Limit "209715200";

Создадим файл `/etc/apt/apt.conf.d/timeouts` с настройками таймаутов обращения к репозиториям:

    Acquire::http::Timeout "5";
    Acquire::https::Timeout "5";
    Acquire::ftp::Timeout "5";

При необходимости, если репозитории доступны через веб-прокси, можно создать файл `/etc/apt/apt.conf.d/proxy`, прописав в него прокси-серверы для протоколов HTTP, HTTPS и FTP:

    Acquire::http::Proxy "http://10.0.25.3:8080";
    Acquire::https::Proxy "http://10.0.25.3:8080";
    Acquire::ftp::Proxy "http://10.0.25.3:8080";

Обновим список пакетов, доступных через репозитории:

    # apt-get update

Обновим систему с использованием самых свежих пакетов, доступных через репозитории:

    # apt-get upgrade
    # apt-get dist-upgrade

Установим пакеты, необходимые для установки GPG-ключей и для использования репозиториев TimescaleDB:

    # apt-get install apt-transport-https ca-certificates

Добавим в файл `/etc/apt/sources.list` репозитории PostgresPro и TimescaleDB:

    deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main
    deb https://packagecloud.io/timescale/timescaledb/debian/ stretch main

Также нужно установить в систему публичные GPG-ключи, которыми подписаны репозитории PostgresPro и TimescaleDB:

    # wget --quiet -O - http://repo.postgrespro.ru/keys/GPG-KEY-POSTGRESPRO | apt-key add -
    # wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | apt-key add -

Обновим список пакетов, доступных через репозитории:

    # apt-get update
