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

Первым делом установим пакет с плагином, который добавляет в MariaDB поддержку формата хранения таблиц TokuDB:

    # apt-get install percona-server-tokudb-5.7

Вместе с указанным пакетом из репозитория Percona будет установлен пакет `libjemalloc1`. После завершения установки нужно узнать путь к установленной библиотеке с помощью, например, такой команды:

    $ # dpkg -L libjemalloc1 | grep -E '\.so($|\.)'

Полученный путь нужно указать как значение опции `malloc_lib` в разделе `[mysqld_safe]` в файле конфигурации сервера `/etc/mysql/percona-server.conf.d/mysqld_safe.cnf`:

    [mysqld_safe]
    
    ...
    malloc_lib = /usr/lib/x86_64-linux-gnu/libjemalloc.so.1

Теперь отключим прозрачную поддержка огромных страниц (Transparent Hugepages). Для этого запускаем следующие команды:

    # echo never > /sys/kernel/mm/transparent_hugepage/enabled
    # echo never > /sys/kernel/mm/transparent_hugepage/defrag

Чтобы не нужно было выполнять эти действия после перезагрузки системы, передадим опцию ядру операционной системе при его загрузке. Для этого открываем файл `/etc/default/grub`, находим переменную `GRUB_CMDLINE_LINUX` и добавляем в список опций опцию `transparent_hugepage=never`. В результате должно получиться что-то такое:

    GRUB_CMDLINE_LINUX="ipv6.disable=1 transparent_hugepage=never"

Теперь нужно обновить конфигурацию загрузчика следующей командой:

    # update-grub

Теперь можно перезапустить Percona Server:

    # systemctl restart mysql

Все описанные выше действия, необходимые для включения плагина TokuDB, можно найти в официальной документации Percona, на странице [TokuDB installation](https://docs.percona.com/percona-server/8.0/tokudb/tokudb_installation.html).

Стоит отметить, что в Percona Server 8.0, начиная с версии 8.0.26 плагин TokuDB переведён в разряд устаревших и не включается по умолчанию, а начиная с версии 8.0.28 был удалён.

Дополнительные материалы
------------------------

* [TokuDB introduction](https://docs.percona.com/percona-server/8.0/tokudb/tokudb_intro.html)
* [TokuDB installation](https://docs.percona.com/percona-server/8.0/tokudb/tokudb_installation.html)
* [Fernando Laudares Camargos. Percona Server with TokuDB (beta): Installation, configuration](https://www.percona.com/blog/percona-server-with-tokudb-beta-installation-configuration/)
* [TokuDB configuration variables of interest](http://code.openark.org/blog/mysql/tokudb-configuration-variables-of-interest)
* [Use TokuDB](https://docs.percona.com/percona-server/8.0/tokudb/using_tokudb.html)
