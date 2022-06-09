Сборка pg_repack для Debian 8.11.1 LTS Jessie и PostgresPro 9.5.14.1
====================================================================

Настройка виртуальной машины
----------------------------

Для сборки pg_repack понадобится настроить виртуальную машину, аналогичную используемой на том сервере, где собираемся использовать утилиту. В рассматриваемом примере это система Debian 8.11.1 LTS с кодовым именем Jessie. Получить образ установочного диска можно по ссылке [debian-8.11.1-amd64-netinst.iso](http://cdimage.debian.org/cdimage/archive/8.11.1/amd64/iso-cd/debian-8.11.1-amd64-netinst.iso).

Настройка репозиториев
----------------------

Для настройки репозиториев поместим в файл `/etc/apt/sources.list` следующие строки:

    deb http://archive.debian.org/debian/ jessie main contrib non-free
    deb http://archive.debian.org/debian-security/ jessie/updates main contrib non-free
    deb http://repo.postgrespro.ru/pgpro-9.5/debian jessie main

Также нужно установить в систему публичный GPG-ключ, которым подписан репозиторий PostgresPro:

    # wget --quiet -O - http://repo.postgrespro.ru/keys/GPG-KEY-POSTGRESPRO | apt-key add -

Поскольу мы установили устаревший релиз, отключим проверку актуальности репозиториев, создав файл `/etc/apt/apt.conf.d/valid` со следующим содержимым:

    Acquire::Check-Valid-Until "false";

Отключаем установку предлагаемых зависимостей, создав файл `/etc/apt/apt.conf.d/suggests` со следующим содержимым:

    APT::Install-Suggests "false";

Отключаем установку рекомендуемых зависимостей, создав файл `/etc/apt/apt.conf.d/recommends` со следующим содержимым:

    APT::Install-Recommends "false";

Система apt сохраняет скачанные пакеты в каталоге `/var/cache/apt/archives/`, чтобы при необходимости не скачивать их снова. Файлы в этом каталоге по умолчанию не удаляются, что может привести к переполнению диска. Чтобы отключить размер файлов в этом каталоге 200 мегабайтами, создадим файл `/etc/apt/apt.conf.d/cache` со следующим содержимым:

    APT::Cache-Limit "209715200";

Создадим файл /etc/apt/apt.conf.d/timeouts с настройками таймаутов обращения к репозиториям:

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

    # apt-get install unzip postgrespro-server-dev-9.5 make gcc libicu-dev libreadline-dev checkinstall fakeroot

Т.к. пакет `postgrespro-server-dev-9.5` зависит от пакетов `libpq-dev` и `postgrespro-common`, в обоих из которых содержится файл `/usr/bin/pg_config`, то в процессе установки возникает ошибка следующего вида:

    Unpacking postgrespro-common (191-1.jessie) ...
    dpkg: error processing archive /var/cache/apt/archives/postgrespro-common_191-1.jessie_all.deb (--unpack):
     trying to overwrite '/usr/bin/pg_config', which is also in package libpq-dev 9.5.20.1-1.jessie.pro

То для её решения я воспользовался следующей последовательностью действий:

    # apt-get purge postgrespro-server-dev-9.5 postgrespro-common libpq-dev
    # rm /usr/bin/pg_config.libpq-dev
    # apt-get install postgrespro-common
    # dpkg-divert --remove /usr/bin/pg_config
    # dpkg -i --force-overwrite /var/cache/apt/archives/libpq-dev_9.5.20.1-1.jessie.pro_amd64.deb
    # apt-get install postgrespro-server-dev-9.5

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

    # mkdir -p /usr/share/postgresql/9.5


Создадим описание будущего deb-пакета:

    $ echo -n "Reorganize tables in PostgreSQL databases with minimal locks" > description-pak

Создадим каталог документации deb-пакета и поместим в него файлы документации:

    $ mkdir doc-pak
    $ cp COPYRIGHT README.rst doc/*.rst doc-pak/

Этап установки выполним через утилиты `fakeroot` для имитации прав пользователя `root` и `checkinstall` для сборки deb-пакета:

    $ fakeroot checkinstall --pkgname='postgrespro-9.5-repack' --pkgrelease='debian-jessie-1' --maintainer='vladimir@stupin.su' --requires='postgrespro-9.5' -y -D --install=no --fstrans=yes make install

Где дополнительные опции утилиты `checkinstall` имеют следующий смысл:

* `-D` - необходимо собрать deb-пакет,
* `-y` - отключение диалогового режима работы утилиты,
* `--install=no` - кроме сборки пакета выполнить установку в систему,
* `--pkgname='postgrespro-9.5-repack'` - имя пакета. В данном случае явным образом обозначаю для какой версии PostgreSQL собран пакет,
* `--pkgrelease='debian-jessie-1'` - релиз пакета. В релизе пакета явным образом обозначаю, для какой операционной системы был собран пакет,
* `--maintainer='vladimir@stupin.su'` - почтовый ящик ментейнера, сопровождающего этот deb-пакет,
* `--requires='postgrespro-9.5'` - список зависимостей deb-пакета. В данном случае указана зависимость только от одного пакета postgrespro-9.6,
* `--fstrans=yes` - использовать для сборки контейнер LXC.

Получившийся deb-пакет можно взять по ссылке [[postgrespro-9.5-repack 1.4.7-debian-jessie-1 amd64.deb]].

Использованные материалы
------------------------

* [[Где взять образы дисков устарешвих релизов Debian|debian_old_images]]
* [dpkg error: "trying to overwrite file, which is also in..."](https://askubuntu.com/questions/176121/dpkg-error-trying-to-overwrite-file-which-is-also-in)
* [dpkg-divert(8)](https://linux.die.net/man/8/dpkg-divert)
* [[Сборка pg_repack для Ubuntu 16.04 LTS Xenial и PostgresPro 9.6.21.1|pg_repack_ubuntu_xenial_postgrespro96]]
