Сборка ProxySQL для Debian 10.12 Buster
=======================================

[[!tag proxysql debian buster percona]]

Настройка виртуальной машины
----------------------------

Для сборки ProxySQL понадобится настроить виртуальную машину, аналогичную используемой на том сервере, где собираемся его использовать. В рассматриваемом примере это система Debian 10.12 с кодовым именем Buster. Получить образ установочного диска можно по ссылке [debian-10.12.0-amd64-netinst.iso](http://cdimage.debian.org/cdimage/archive/10.12.0/amd64/iso-cd/debian-10.12.0-amd64-netinst.iso).

Настройка репозиториев
----------------------

Для настройки репозиториев поместим в файл `/etc/apt/sources.list` следующие строки:

    deb http://mirror.ufanet.ru/debian/ buster main contrib non-free
    deb http://mirror.ufanet.ru/debian/ buster-updates main contrib non-free
    deb http://mirror.ufanet.ru/debian/ buster-proposed-updates main contrib non-free
    deb http://mirror.ufanet.ru/debian-security/ buster/updates main contrib non-free

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

Обновляем список пакетов, доступных через репозитории:

    # apt-get update

Обновим систему с использованием самых свежих пакетов, доступных через репозитории:

    # apt-get upgrade
    # apt-get dist-upgrade

Настройка репозиториев Percona
------------------------------

Установим пакеты, необходимые для работы пакета настройки репозиториев:

    # apt-get install curl lsb-release gnupg

Заглядываем в файл `/etc/debian_version` или `/etc/lsb-release`, определяем кодовое имя релиза.

Открываем страницу [repo.percona.com/percona/apt/](http://repo.percona.com/percona/apt/) и находим там пакет `percona-release_latest.buster_all.deb`, где `buster` - кодовое имя релиза. Копируем ссылку на пакет и скачиваем в систему, где нужно установить ProxySQL:

    $ curl http://repo.percona.com/percona/apt/percona-release_latest.buster_all.deb > percona-release_latest.buster_all.deb

Установим пакет в систему:

    # dpkg -i percona-release_latest.buster_all.deb

Подключаем репозитории с ProxySQL:

    # percona-release enable proxysql

Обновляем список пакетов, доступных через репозитории:

    # apt-get update

Сборка пакета
-------------

Установим пакеты, которые понадобятся дальнейших действий:

    # apt-get install dpkg-dev git ca-certificates devscripts build-essential debhelper pkg-config g++ cmake quilt libgnutls28-dev zlib1g-dev uuid-dev gawk

Получим исходный пакет, который на момент написания статьи соответствует версии 2.3.2:

    $ apt-get source proxysql2

Клонируем из репозитория ветку с нужной нам версией 2.4.1:

    $ git clone --single-branch -b v2.4.1 https://github.com/sysown/proxysql/ proxysql2-2.4.1

Скопируем каталог `debian` в каталог со скачанными исходными текстами и удалим служебный каталог `.git`:

    $ cp -R proxysql2-2.3.2/debian proxysql2-2.4.1/
    $ rm -fR proxysql2-2.4.1/.git

Перейдём в каталог с новыми исходными текстами и запустим утилиту для редактирования журнала изменений пакета:

    $ cd proxysql2-2.4.1
    $ dch -i

Вводим в качестве описания последних изменений такой текст:

    proxysql2 (2.4.1~buster) unstable; urgency=medium
    
      * Update to new upstream release ProxySQL 2.4.1
    
     -- Vladimir Stupin <vladimir@stupin.su>  Thu, 09 Jun 2022 11:03:26 +0500

Добавляем в файл `debian/control` зависимость от библиотек `libgnutls`, `zlib`, `uuid` и утилиты `gawk`:

    Build-Depends: debhelper (>= 9), debconf, pkg-config, g++, cmake, libgnutls28-dev, zlib1g-dev, uuid-dev, gawk

Удаляем из файла `debian/control` следующую строчку:

    Version: @@VERSION@@

Добавляем в заплатку `percona-utilities` файлы, добавленные авторами исходного пакета:

    $ quilt new percona-utilities
    $ quilt add etc/proxysql-admin.cnf
    $ quilt add tools/proxysql-admin
    $ quilt add tools/proxysql-admin-common
    $ quilt add tools/proxysql-logrotate
    $ quilt add tools/proxysql-status
    $ quilt add tools/proxysql-login-file
    $ quilt add tools/tools/enable_scheduler
    $ quilt add tools/tools/mysql_exec
    $ quilt add tools/tools/proxysql_exec
    $ quilt add tools/tools/run_galera_checker
    $ quilt add tools/tests/bad-login-file2.clear.cnf
    $ quilt add tools/tests/bad-login-file2.cnf
    $ quilt add tools/tests/bad-login-file.clear.cnf
    $ quilt add tools/tests/bad-login-file.cnf
    $ quilt add tools/tests/generic-test.bats
    $ quilt add tools/tests/login-file2.clear.cnf
    $ quilt add tools/tests/login-file2.cnf
    $ quilt add tools/tests/login-file.clear.cnf
    $ quilt add tools/tests/login-file.cnf
    $ quilt add tools/tests/proxysql-admin-testsuite.bats
    $ quilt add tools/tests/proxysql-admin-testsuite.sh
    $ quilt add tools/tests/setup_workdir.sh
    $ quilt add tools/tests/test-common.bash
    $ quilt add doc/internal/command_line_options.txt
    $ quilt add doc/internal/debug_filters.md
    $ quilt add doc/internal/global_variables.txt
    $ quilt add doc/internal/PROXYSQLTEST.md
    $ quilt add doc/internal/query_parser.txt
    $ quilt add doc/internal/Standard_ProxySQL_Admin.txt
    $ quilt add doc/internal/Stats_API.txt
    $ quilt add doc/release_notes/ProxySQL_v1.2.2.md
    $ quilt add doc/release_notes/ProxySQL_v1.2.3.md
    $ quilt add doc/release_notes/ProxySQL_v1.2.4.md
    $ quilt add doc/release_notes/ProxySQL_v1.3.0g.md
    $ quilt add doc/release_notes/ProxySQL_v1.3.0.md
    $ quilt add doc/release_notes/ProxySQL_v1.3.2.md
    $ quilt add doc/release_notes/ProxySQL_v1.3.3.md
    $ quilt add doc/release_notes/ProxySQL_v1.4.4.md
    $ quilt add tools/README.md
    $ cp ../proxysql2-2.3.2/etc/proxysql-admin.cnf etc/
    $ cp ../proxysql2-2.3.2/tools/proxysql-admin tools/
    $ cp ../proxysql2-2.3.2/tools/proxysql-admin-common tools/
    $ cp ../proxysql2-2.3.2/tools/proxysql-logrotate tools/
    $ cp ../proxysql2-2.3.2/tools/proxysql-status tools/
    $ cp ../proxysql2-2.3.2/tools/proxysql-login-file tools/
    $ cp -r ../proxysql2-2.3.2/tools/tools tools/
    $ cp -r ../proxysql2-2.3.2/tools/tests tools/
    $ cp -r ../proxysql2-2.3.2/doc .
    $ cp ../proxysql2-2.3.2/tools/README.md tools/
    $ quilt refresh

В файл `debian/rules.systemd` добавим правило, удаляющее файлы, отмечающие выполненные этапы сборки пакета:

    override_dh_clean:
            @echo "RULES.$@"
            dh_clean
            rm -f override_dh_auto_build override_dh_auto_configure

Скопируем содержимое файла `debian/rules.systemd` в файл `debian/rules`:

    $ cat debian/rules.systemd > debian/rules

Запускаем сборку пакета:

    $ GIT_VERSION=2.4.1 dpkg-buildpackage -us -uc -rfakeroot

Использованные материалы
------------------------

* [[Сборка pg_repack для Debian 8.11.1 LTS Jessie и PostgresPro 9.5.14.1|pg_repack_debian_jessie_postgrespro95]]
* [joey/ blog/ entry/ debhelper dh overrides](https://joeyh.name/blog/entry/debhelper_dh_overrides/)
