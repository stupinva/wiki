Установка Percona Server в Debian/Ubuntu
========================================

[[!tag mysql percona debian ubuntu]]

Заглядываем в файл `/etc/debian_version` или `/etc/lsb-release`, определяем кодовое имя релиза.

Открываем страницу [repo.percona.com/percona/apt/](http://repo.percona.com/percona/apt/) и находим там пакет `percona-release_latest.bionic_all.deb`, где bionic - кодовое имя релиза. Копируем ссылку на пакет и скачиваем в систему, где нужно установить Percona Server:

    $ wget http://repo.percona.com/percona/apt/percona-release_latest.bullseye_all.deb

Установим пакет в систему:

    # dpkg -i percona-release_latest.bullseye_all.deb

Подключаем репозитории с Percona Server 5.7, Percona XtraBackup 2.4 и Percona Toolkit:

    # percona-release enable ps-57
    # percona-release enable pxb-24
    # percona-release enable pt

Обновляем список пакетов, доступных через репозитории:

    # apt-get update

Устанавливаем необходимые пакеты:

    # apt-get install percona-server-server-5.7
    # apt-get install percona-server-client-5.7
    # apt-get install percona-xtrabackup-24
    # apt-get install percona-toolkit

В Debian Bullseye поставляется только Percona Server 8.0, соответствующий ему пакет Percona XtraBackup 8.0 и набор инструментов Percona Toolkit, работающий с любым вариантом сервера MySQL. Для этого случая включение репозиториев, обновление списка пакетов и их установка выполняются с помощью следующих команд:

    # percona-release enable ps-80
    # percona-release enable pxb-80
    # percona-release enable pt
    # apt-get update
    # apt-get install percona-server-server
    # apt-get install percona-server-client
    # apt-get install percona-xtrabackup-80
    # apt-get install percona-toolkit
