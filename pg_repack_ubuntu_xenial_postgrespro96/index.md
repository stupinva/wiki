Сборка pg_repack для Ubuntu 16.04 LTS Xenial и PostgresPro 9.6.21.1
===================================================================

Настройка виртуальной машины
----------------------------

Для сборки pg_repack понадобится настроить виртуальную машину, аналогичную используемой на том сервере, где собираемся использовать утилиту. В рассматриваемом примере это система Ubuntu 16.04 LTS с кодовым именем Xenial. Получить образ установочного диска можно по ссылке [ubuntu-16.04.7-server-amd64.iso](http://www.releases.ubuntu.com/16.04/ubuntu-16.04.7-server-amd64.iso).

Настройка репозиториев
----------------------

Для настройки репозиториев поместим в файл `/etc/apt/sources.list` следующие строки:

    deb http://mirror.ufanet.ru/ubuntu/ xenial main restricted
    deb http://mirror.ufanet.ru/ubuntu/ xenial-updates main restricted
    deb http://mirror.ufanet.ru/ubuntu/ xenial-security main restricted
    deb http://mirror.ufanet.ru/ubuntu/ xenial universe
    deb http://mirror.ufanet.ru/ubuntu/ xenial-updates universe
    deb http://mirror.ufanet.ru/ubuntu/ xenial-security universe
    deb http://mirror.ufanet.ru/ubuntu/ xenial multiverse
    deb http://mirror.ufanet.ru/ubuntu/ xenial-updates multiverse
    deb http://mirror.ufanet.ru/ubuntu/ xenial-security multiverse
    deb http://mirror.ufanet.ru/ubuntu/ xenial-backports main restricted universe multiverse
    deb http://repo.postgrespro.ru/pgpro-archive/pgpro-9.6.21.1/ubuntu/ xenial main

Также нужно установить в систему публичный GPG-ключ, которым подписан репозиторий PostgresPro:

    # wget --quiet -O - http://repo.postgrespro.ru/keys/GPG-KEY-POSTGRESPRO | apt-key add -

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

    # apt-get install unzip postgrespro-server-dev-9.6 make gcc lib64readline6-dev checkinstall fakeroot

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

    # mkdir -p /usr/share/postgresql/9.6/extension

Создадим описание будущего deb-пакета:

    $ echo -n "Reorganize tables in PostgreSQL databases with minimal locks" > description-pak

Создадим каталог документации deb-пакета и поместим в него файлы документации:

    $ mkdir doc-pak
    $ cp COPYRIGHT README.rst doc/*.rst doc-pak/

Этап установки выполним через утилиты `fakeroot` для имитации прав пользователя `root` и `checkinstall` для сборки deb-пакета:

    $ fakeroot checkinstall --pkgname='postgrespro-9.6-repack' --pkgrelease='ubuntu-xenial-1' --maintainer='vladimir@stupin.su' --requires='postgrespro-9.6' -y -D --install=no --fstrans=yes make install

Где дополнительные опции утилиты `checkinstall` имеют следующий смысл:

* `-D` - необходимо собрать deb-пакет,
* `-y` - отключение диалогового режима работы утилиты,
* `--install=no` - кроме сборки пакета выполнить установку в систему,
* `--pkgname='postgrespro-9.6-repack'` - имя пакета. В данном случае явным образом обозначаю для какой версии PostgreSQL собран пакет,
* `--pkgrelease='ubuntu-xenial-1'` - релиз пакета. В релизе пакета явным образом обозначаю, для какой операционной системы был собран пакет,
* `--maintainer='vladimir@stupin.su'` - почтовый ящик ментейнера, сопровождающего этот deb-пакет,
* `--requires='postgrespro-9.6'` - список зависимостей deb-пакета. В данном случае указана зависимость только от одного пакета `postgrespro-9.6`,
* `--fstrans=yes` - использовать для сборки контейнер LXC.

Получившийся deb-пакет можно взять по ссылке [[postgrespro-9.6-repack_1.4.7-ubuntu-xenial-1_amd64.deb]].

Использованные материалы
------------------------

* [pg_repack 1.4.6 -- Reorganize tables in PostgreSQL databases with minimal locks](https://reorg.github.io/pg_repack/)
* [Установка Postgres Pro 10 для 1С:Предприятие на Debian / Ubuntu](https://interface31.ru/tech_it/2018/10/ustanovka-postgresql-10-dlya-1spredpriyatie-na-debian-ubuntu.html)
* [Создание RPM или DEB пакетов с Checkinstall в Linux](https://linux-notes.org/sozdanie-rpm-ili-deb-paketov-s-checkinstall-v-linux/)
* [Create .deb package from revision tag for a git url](https://stackoverflow.com/questions/20129788/create-deb-package-from-revision-tag-for-a-git-url)
* [checkinstall/README](https://github.com/cntrump/checkinstall/blob/master/README)
