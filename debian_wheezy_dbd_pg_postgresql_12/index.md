Исправление DBD::Pg из Debian Wheezy для поддержки PostgreSQL 12 и выше
=======================================================================

Постановка задачи
-----------------

После обновления PostgreSQL 9.6 до PostgreSQL 12 появились ошибки следующего вида:

    column d.adsrc does not exist at character 333

Ошибки порождались запросами следующего вида:

    SELECT a.attname, i.indisprimary, pg_catalog.pg_get_expr(adbin,adrelid)
    FROM pg_catalog.pg_index i, pg_catalog.pg_attribute a, pg_catalog.pg_attrdef d
     WHERE i.indrelid = 719060 AND d.adrelid=a.attrelid AND d.adnum=a.attnum
      AND a.attrelid = 719060 AND i.indisunique IS TRUE
      AND a.atthasdef IS TRUE AND i.indkey[0]=a.attnum
     AND d.adsrc ~ '^nextval'

Эти запросы порождал модуль `DBD::Pg` из приложения, работающего в Debian Wheezy.

Аналогичная проблема описана по ссылке: [Autodoc fails on PostgreSQL 12 #19](https://github.com/cbbrowne/autodoc/issues/19).

Там же можно найти выдержку из официальной документации к выпуску PostgreSQL 12:

>Remove obsolete pg_attrdef.adsrc column (Peter Eisentraut)
>    
>This column has been deprecated for a long time, because it did not update in response to other catalog changes (such as column renamings). The recommended way to get a text version of a default-value expression from pg_attrdef is pg_get_expr(adbin, adrelid).

Суть решения сводится к замене поля `adsrc` в запросах к таблице `pg_attrdef` на выражение `pg_get_expr(adbin, adrelid)`. Если обратить внимание на проблемный запрос, то можно увидеть, что первая строчка запроса уже исправлена, но не исправлена последняя строчка.

Итак, нужно собрать пакет с модулем `DBD::Pg` для Debian Wheezy, в котором проблемный запрос будет исправлен так, чтобы модуль работал с PostgreSQL версий 12 и выше.

Настройка виртуальной машины
----------------------------

Для сборки настроим виртуальную машину, аналогичную используемой на том сервере, где установлено проблемное приложение. В рассматриваемом примере это система Debian 7.11.0 с кодовым именем Wheezy. Получить образ установочного диска можно по ссылке [debian-7.11.0-amd64-netinst.iso](http://cdimage.debian.org/cdimage/archive/7.11.0/amd64/iso-cd/debian-7.11.0-amd64-netinst.iso).

Настройка репозиториев
----------------------

Для настройки репозиториев поместим в файл `/etc/apt/sources.list` следующие строки:

    deb http://archive.debian.org/debian/ wheezy main contrib non-free
    deb http://archive.debian.org/debian-security/ wheezy/updates main contrib non-free
    deb http://archive.debian.org/debian/ wheezy-backports main contrib non-free
    
    deb-src http://archive.debian.org/debian/ wheezy main contrib non-free
    deb-src http://archive.debian.org/debian-security/ wheezy/updates main contrib non-free
    deb-src http://archive.debian.org/debian/ wheezy-backports main contrib non-free

Поскольку мы установили устаревший релиз, отключим проверку актуальности репозиториев, создав файл `/etc/apt/apt.conf.d/valid` со следующим содержимым:

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
