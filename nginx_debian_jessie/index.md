Сборка deb-пакета nginx из Debian 11 Bullseye для Debian 8.11 Jessie
====================================================================

Настройка виртуальной машины
----------------------------

Для сборки nginx понадобится настроить виртуальную машину с Debian 8.11.1 LTS с кодовым именем Jessie. Получить образ установочного диска можно по ссылке [debian-8.11.1-amd64-netinst.iso](http://cdimage.debian.org/cdimage/archive/8.11.1/amd64/iso-cd/debian-8.11.1-amd64-netinst.iso).

Настройка репозиториев
----------------------

Для настройки репозиториев поместим в файл `/etc/apt/sources.list` следующие строки:

    deb http://archive.debian.org/debian/ jessie main contrib non-free
    deb http://archive.debian.org/debian-security/ jessie/updates main contrib non-free
    deb-src http://nginx.org/packages/mainline/debian/ bullseye nginx

Также нужно установить в систему публиынй GPG-ключ, которым подписан репозиторий `nginx`:

    # wget --quiet -O - http://nginx.org/keys/nginx_signing.key | apt-key add -

Поскольу мы установили устаревший релиз, отключим проверку актуальности репозиториев, создав файл `/etc/apt/apt.conf.d/valid` со следующим содержимым:

    Acquire::Check-Valid-Until "false";

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

Устанавливаем пакеты, которые потребуются для сборки 

    # apt-get install devscripts libparse-debcontrol-perl fakeroot gcc build-essential:native debhelper quilt lsb-release libpcre3-dev

Обратный перенос и сборка
-------------------------

Скачиваем исходники deb-пакета `nginx`, они автоматически распакуются в каталог `nginx-1.21.6`:

    $ apt-get source nginx

Переходим в каталог с распакованными исходниками для сборки deb-пакета:

    $ cd nginx-1.21.6

Запускаем утилиту `dch` для обновления журнала изменений пакета:

    $ dch -i

Вводим описание доработанной нами версии пакета:

    nginx (1.21.6-1~jessie-backport) jessie; urgency=low
    
      * Package backport for Debian 8.11 Jessie
    
     -- Vladimir Stupin <vladimir@stupin.su>  Wed, 18 May 2022 10:31:17 +0500

Редактируем файл `debian/control`, меняем зависимость от `libpcre2-dev` на зависимость от `libpcre3-dev` и меняем требуемую минимальную версию `debhelper` с 11 на 8:

    Build-Depends: debhelper (>= 8),
                   dpkg-dev (>= 1.16.1~),
                   quilt (>= 0.46-7~),
                   lsb-release,
                   libpcre3-dev,
                   libssl-dev (>= 0.9.7),
                   zlib1g-dev

Редактируем файл `debian/compat`, меняем содержащуюся в нём цифру 11 на 8.

Редактируем файлы `debian/nginx.rules.in` и `debian/rules`, удаляем опцию `--no-stop-on-upgrade` в следующих строчках:

    dh_installinit -i -pnginx --no-stop-on-upgrade --no-start --name=nginx
    dh_installinit -i -pnginx --no-stop-on-upgrade --no-start --noscripts --name=nginx-debug

Из этих же файлов удаляем следующие строчки:

    dh_installsystemd -i -pnginx --name=nginx nginx.service
    dh_installsystemd -i -pnginx --name=nginx-debug --no-enable nginx-debug.service

Запускаем сборку deb-пакета и доработанного исходного deb-пакета:

    $ dpkg-buildpackage -rfakeroot -us -uc

В каталоге выше кроме появятся следующие файлы:

* [[nginx_1.21.6-1~jessie_amd64.changes]]
* [[nginx_1.21.6-1~jessie_amd64.deb]]
* [[nginx_1.21.6-1~jessie.debian.tar.xz]]
* [[nginx_1.21.6-1~jessie.dsc]]
* [[nginx-dbg_1.21.6-1~jessie_amd64.deb]]

Эти файлы вместе с файлом [[nginx_1.21.6.orig.tar.gz]] можно поместить в репозиторий, например, с помощью утилиты `aptly`.

Использованные материалы
------------------------

* [nginx: Linux packages](https://nginx.org/en/linux_packages.html)
* [nginx: PGP public keys](https://nginx.org/en/pgp_keys.html)
