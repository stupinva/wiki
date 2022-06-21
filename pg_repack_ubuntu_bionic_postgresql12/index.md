Сборка pg_repack для Ubuntu 18.04 LTS Bionic и PostgreSQL 12.11
===============================================================

[[!tag postgresql ubuntu bionic pg_repack]]

Настройка виртуальной машины
----------------------------

Для сборки pg_repack понадобится настроить виртуальную машину, аналогичную используемой на том сервере, где собираемся использовать утилиту. В рассматриваемом примере это система Ubuntu 18.04.5 LTS с кодовым именем Bionic Beaver. Получить образ установочного диска можно по ссылке [ubuntu-18.04.6-live-server-amd64.iso](http://www.releases.ubuntu.com/bionic/ubuntu-18.04.6-live-server-amd64.iso).

Настройка репозиториев
----------------------

Для настройки репозиториев поместим в файл `/etc/apt/sources.list` следующие строки:

    deb http://mirror.ufanet.ru/ubuntu/ bionic main restricted
    deb http://mirror.ufanet.ru/ubuntu/ bionic-updates main restricted
    deb http://mirror.ufanet.ru/ubuntu/ bionic-security main restricted
    deb http://mirror.ufanet.ru/ubuntu/ bionic universe
    deb http://mirror.ufanet.ru/ubuntu/ bionic-updates universe
    deb http://mirror.ufanet.ru/ubuntu/ bionic-security universe
    deb http://mirror.ufanet.ru/ubuntu/ bionic multiverse
    deb http://mirror.ufanet.ru/ubuntu/ bionic-updates multiverse
    deb http://mirror.ufanet.ru/ubuntu/ bionic-security multiverse
    deb http://mirror.ufanet.ru/ubuntu/ bionic-backports main restricted universe multiverse
    deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main
    #deb http://ppa.launchpad.net/timescale/timescaledb-ppa/ubuntu bionic main

Также нужно установить в систему публичный GPG-ключ, которым подписан репозиторий PostgreSQL:

    $ wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

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

Обновим список пакетов, доступных через репозиторий:

    # apt-get update

Обновим систему с использованием самых свежих пакетов, доступных через репозитории:

    # apt-get upgrade
    # apt-get dist-upgrade

Установка пакетов
-----------------

Установим пакеты, необходимые для сборки утилиты:

    # apt-get install unzip postgresql-server-dev-12 make gcc zlib1g-dev checkinstall fakeroot

Сборка утилиты pg_repack
------------------------

Находим на странице [pg_repack: PostgreSQL module for data reorganization / PostgreSQL Extension Network](https://pgxn.org/dist/pg_repack/) ссылку на скачивание утилиты и скачиваем утилиту по этой ссылке:

    $ wget https://api.pgxn.org/dist/pg_repack/1.4.7/pg_repack-1.4.7.zip

Распаковываем архив:

    $ unzip pg_repack-1.4.7.zip

Переходим в каталог с распакованными файлами и выполняем сборку:

    $ cd pg_repack-1.4.7
    $ make

Создадим каталог, который потребуется для сборки:

    # mkdir -p /usr/lib/postgresql/12/lib/bitcode

Создадим описание будущего deb-пакета:

    $ echo -n "Reorganize tables in PostgreSQL databases with minimal locks" > description-pak

Создадим каталог документации deb-пакета и поместим в него файлы документации:

    $ mkdir doc-pak
    $ cp COPYRIGHT README.rst doc/*.rst doc-pak/

Этап установки выполним через утилиты `fakeroot` для имитации прав пользователя `root` и `checkinstall` для сборки deb-пакета:

    $ fakeroot checkinstall --pkgname='postgresql-12-repack' --pkgrelease='ubuntu-bionic-1' --maintainer='vladimir@stupin.su' --requires='postgresql-12' -y -D --install=no --fstrans=yes make install

Где дополнительные опции утилиты `checkinstall` имеют следующий смысл:

* `-D` - необходимо собрать deb-пакет,
* `-y` - отключение диалогового режима работы утилиты,
* `--install=no` - кроме сборки пакета выполнить установку в систему,
* `--pkgname='postgresql12-repack'` - имя пакета. В данном случае явным образом обозначаю для какой версии PostgreSQL собран пакет,
* `--pkgrelease='ubuntu-bionic-1'` - релиз пакета. В релизе пакета явным образом обозначаю, для какой операционной системы был собран пакет,
* `--maintainer='vladimir@stupin.su'` - почтовый ящик ментейнера, сопровождающего этот deb-пакет,
* `--requires='postgrespro-12'` - список зависимостей deb-пакета. В данном случае указана зависимость только от одного пакета `postgrespro-12`,
* `--fstrans=yes` - использовать для сборки контейнер LXC.

Получившийся deb-пакет можно взять по ссылке [[postgresql-12-repack_1.4.7-ubuntu-bionic-1_amd64.deb]].

Использованные материалы
------------------------

* [[Сборка pg_repack для Ubuntu 16.04 LTS Xenial и PostgresPro 9.6.21.1|pg_repack_ubuntu_xenial_postgrespro96]]
