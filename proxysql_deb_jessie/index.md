Сборка ProxySQL для Debian 8.11.1 LTS Jessie
============================================

Настройка виртуальной машины
----------------------------

Для сборки ProxySQL понадобится настроить виртуальную машину, аналогичную используемой на том сервере, где собираемся его использовать. В рассматриваемом примере это система Debian 8.11.1 LTS с кодовым именем Jessie. Получить образ установочного диска можно по ссылке [debian-8.11.1-amd64-netinst.iso](http://cdimage.debian.org/cdimage/archive/8.11.1/amd64/iso-cd/debian-8.11.1-amd64-netinst.iso).

Настройка репозиториев
----------------------

Для настройки репозиториев поместим в файл `/etc/apt/sources.list` следующие строки:

    deb http://archive.debian.org/debian/ jessie main contrib non-free
    deb http://archive.debian.org/debian-security/ jessie/updates main contrib non-free

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

    # apt-get install curl

Заглядываем в файл `/etc/debian_version` или `/etc/lsb-release`, определяем кодовое имя релиза.

Открываем страницу [repo.percona.com/percona/apt/](http://repo.percona.com/percona/apt/) и находим там пакет `percona-release_latest.jessie_all.deb`, где `jessie` - кодовое имя релиза. Копируем ссылку на пакет и скачиваем в систему, где нужно установить ProxySQL:

    $ curl http://repo.percona.com/percona/apt/percona-release_latest.jessie_all.deb > percona-release_latest.jessie_all.deb

Установим пакет в систему:

    # dpkg -i percona-release_latest.jessie_all.deb

Подключаем репозитории с ProxySQL:

    # percona-release enable proxysql

Обновляем список пакетов, доступных через репозитории:

    # apt-get update
