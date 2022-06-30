Настройка PostgreSQL для миграции базы данных на новую версию TimescaleDB
=========================================================================

[[!tag postgresql timescaledb]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Постановка задачи
-----------------

Имеется база данных в PostgreSQL 12, использующая TimescaleDB версии 1.7.4. Нужно перенести её в PostgreSQL 13 с обновлением TimescaleDB до версии 2.7.0. Версии TimescaleDB 1.x и 2.x несовместимы между собой, так что при установке расширения версии 2.x перестают работать расширения версий 1.x. На сервере имеются другие базы данных, зависящие от расширения TimescaleDB, в которых нужно оставить расширение версии 1.x.

Для переноса базы данных с обновлением воспользуемся промежуточной виртуальной машиной с PostgreSQL версии 12, как на исходной СУБД. Восстановим на неё резервную копию базы данных, после чего обновим расширение и снимем резервную копию для переноса в целевую СУБД PostgreSQL версии 13.

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

Установка PostgreSQL и TimescaleDB
----------------------------------

Установим PostgreSQL версии 12:

    # apt-get install postgresql-12

Установим TimescaleDB версии 1.7.4:

    # apt-get install timescaledb-1.7.4-postgresql-12

Пропишем расширение `timescaledb` в опцию `shared_preload_libraries` в файле конфигурации `/etc/postgresql/13/main/postgresql.conf`:

    shared_preload_libraries = 'timescaledb'

Чтобы расширение стало доступным, нужно перезапустить PostgreSQL:

    # systemctl restart postgresql

Снятие резервной копии
----------------------

Для снятия резервной копии с исходной базы данных воспользуемся такой командой, запущенной от имени пользователя `postgres`:

    $ pg_dump -Fc -d db | gzip -c > db.bak.gz

Восстановление резервной копии
------------------------------

Создадим владельца базы данных:

    $ createuser owner

Создадим пустую базу данных `db`, которой будет владеть пользователь `owner`:

    $ createdb db -O owner

Установим в пустую базу расширение TimescaleDB той версии, которое было установлено в базе данных перед снятием резервной копии:

    $ psql -d db -c "CREATE EXTENSION IF NOT EXISTS timescaledb VERSION '1.7.4';"

Вызовем функцию подготовки к восстановлению базы данных из резервной копии:

    $ psql -d db -c "SELECT timescaledb_pre_restore();"

Восстановим содержимое базы данных из резервной копии:

    $ zcat db.bak.gz | pg_restore -Fc -d db

И вызовем функцию для завершения восстановления базы данных из резервной копии:

    $ psql -d db -c "SELECT timescaledb_post_restore();"

Обновление TimescaleDB
----------------------

Установим из репозитория свежую версию расширения timescaledb:

    # apt-get install timescaledb-2-loader-postgresql-12 timescaledb-2-2.7.0-postgresql-12

И выполним обновление расширения до версии 2.7.0:

    $ psql -d ucams_office -c "ALTER EXTENSION timescaledb UPDATE TO '2.7.0';"

Перенос обновлённой базы данных
-------------------------------

Теперь можно снять резервную копию снова и восстановить её в целевой базе данных PostgreSQL 12 с установленным расширением 2.7.0, повторив описанные выше действия по резервному копированию и восстановлению в пустую базу данных на PostgreSQL 13, в которой на этот раз будет установлено расширение TimescaleDB версии 2.7.0.
