Установка Percona Server в Debian/Ubuntu
========================================

[[!tag mysql percona debian ubuntu tokudb]]

Настройка репозитория
---------------------

Заглядываем в файл `/etc/debian_version` или `/etc/lsb-release`, определяем кодовое имя релиза.

Открываем страницу [repo.percona.com/percona/apt/](http://repo.percona.com/percona/apt/) и находим там пакет `percona-release_latest.bionic_all.deb`, где bionic - кодовое имя релиза. Копируем ссылку на пакет и скачиваем в систему, где нужно установить Percona Server:

    $ wget http://repo.percona.com/percona/apt/percona-release_latest.bullseye_all.deb

Установим пакет в систему:

    # dpkg -i percona-release_latest.bullseye_all.deb

Подключаем репозитории с Percona Server 5.7, Percona XtraBackup 2.4 и Percona Toolkit:

    # percona-release enable ps-57
    # percona-release enable pxb-24
    # percona-release enable pt

В случае Debian Bullseye вместо этого можно подключить репозитории с Percona Server 8.0 и соответствующим ему пакетом Percona XtraBackup 8.0 (утилиты Percona Toolkit работают с любой версией сервера):

    # percona-release enable ps-80
    # percona-release enable pxb-80
    # percona-release enable pt

Обновляем список пакетов, доступных через репозитории:

    # apt-get update

Установка сервера и утилит
--------------------------

Устанавливаем пакеты с Percona Server 5.7, Percona XtraBackup 2.4 и утилиты Percona Toolkit:

    # apt-get install percona-server-server-5.7
    # apt-get install percona-server-client-5.7
    # apt-get install percona-xtrabackup-24
    # apt-get install percona-toolkit

Если же были выбраны репозитории с Percona Server 8.0 и Percona XtraBackup 8.0, то вместе с утилитами Percona Toolkit установить пакеты можно так:

    # apt-get install percona-server-server
    # apt-get install percona-server-client
    # apt-get install percona-xtrabackup-80
    # apt-get install percona-toolkit

Установка TokuDB
----------------

Плагину TokuDB для работы потребуется библиотека `libjemalloc`. В репозитории Percona есть собственный пакет `libjemalloc1` с этой библиотекой, но можно использовать и пакет `libjemalloc2`, имеющийся в официальном репозитории Debian. Необходимо лишь убедиться, что версия libjemalloc не ниже 3.3.0. В случае с Debian Bullseye в пакете `libjemalloc2` находится библиотека версии 5.2.1. Установим пакет:

    # apt-get install libjemalloc2

После завершения установки нужно узнать путь к установленной библиотеке с помощью, например, такой команды:

    $ dpkg -L libjemalloc2 | grep -E '\.so($|\.)'

Полученный путь нужно указать как значение переменной `LD_PRELOAD` в файле конфигурации сервера `/etc/default/mysql`:

    LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

Теперь отключим прозрачную поддержку огромных страниц (Transparent Hugepages). Для этого выполним следующие команды:

    # echo never > /sys/kernel/mm/transparent_hugepage/enabled
    # echo never > /sys/kernel/mm/transparent_hugepage/defrag

Чтобы не нужно было выполнять эти действия после перезагрузки системы, передадим опцию ядру операционной системе при его загрузке. Для этого открываем файл `/etc/default/grub`, находим переменную `GRUB_CMDLINE_LINUX` и добавляем в список опций опцию `transparent_hugepage=never`. В результате должно получиться что-то такое:

    GRUB_CMDLINE_LINUX="ipv6.disable=1 transparent_hugepage=never"

Обновим конфигурацию загрузчика следующей командой:

    # update-grub

Теперь можно установить пакет с плагином TokuDB:

    # apt-get install percona-server-tokudb-5.7

Перезапустим Percona Server, чтобы применить изменения в файле `/etc/default/mysql`:

    # systemctl restart mysql

Включим TokuDB:

    # ps-admin -e

По умолчанию плагин TokuDB использует половину оперативной памяти для собственного кэша. Нужно следить за тем, чтобы суммарное потребление оперативной памяти кэшем InnoDB, буферами клиентских подключений и операционной системой не превышало объём оперативной памяти. Задать объём оперативной памяти, используемый TokuDB, можно с помощью опции `tokudb_cache_size`, которую нужно прописать в секции `[mysqld]` в файле конфигурации сервера `/etc/mysql/percona-server.conf.d/mysqld_safe.cnf`:

    tokudb_cache_size = 64G

Теперь можно перезапустить Percona Server ещё раз для включения TokuDB:

    # systemctl restart mysql

Все описанные выше действия, необходимые для включения плагина TokuDB, можно найти в официальной документации Percona, на странице [TokuDB installation](https://docs.percona.com/percona-server/8.0/tokudb/tokudb_installation.html).

Стоит отметить, что в Percona Server 8.0, начиная с версии 8.0.26 плагин TokuDB переведён в разряд устаревших и не включается по умолчанию, а начиная с версии 8.0.28 был удалён.

Настройка TokuDB
----------------

Кроме уже упомянутой опции `tokudb_cache_size`, указывающей размер кэша для таблиц TokuDB, можно отметить следующие полезные опции:

* `tokudb_directio` - принимает значения `ON` - не использовать кэш операционной системы и `OFF` - использовать кэш операционной системы.
* `tokudb_row_format` - используемый алгоритм для сжатия строк:
    * `tokudb_default`, `tokudb_zlib` - среднее сжатие при средней нагрузке на процессор.
    * `tokudb_snappy` - хорошее сжатие при низкой нагрузке на процессор.
    * `tokudb_fast`, `tokudb_quicklz` - слабое сжатие при низкой нагрузке на процессор.
    * `tokudb_small`, `tokudb_lzma` - лучшее сжатие при высокой нагрузке на процессор.
    * `tokudb_uncompressed` - сжатие не используется.
* `tokudb_empty_scan` - направление сканирования индекса для проверки уникальности строки при вставке/обновлении:
    * `disabled` - проверка отключена,
    * `rl` - значение по умолчанию, "справа налево", то есть проверка от больших значений к меньшим,
    * `lr` - "слева направо", то есть проверка от меньших значений к большим.

Пример настроек приведён ниже:

    tokudb_cache_size = 64G
    tokudb_directio = ON
    tokudb_row_format = tokudb_lzma
    tokudb_empty_scan = disabled

Дополнительные материалы
------------------------

* [TokuDB introduction](https://docs.percona.com/percona-server/8.0/tokudb/tokudb_intro.html)
* [TokuDB installation](https://docs.percona.com/percona-server/8.0/tokudb/tokudb_installation.html)
* [Fernando Laudares Camargos. Percona Server with TokuDB (beta): Installation, configuration](https://www.percona.com/blog/percona-server-with-tokudb-beta-installation-configuration/)
* [TokuDB configuration variables of interest](http://code.openark.org/blog/mysql/tokudb-configuration-variables-of-interest)
* [Use TokuDB](https://docs.percona.com/percona-server/8.0/tokudb/using_tokudb.html)
