Перенос базы данных ClickHouse
==============================

Для переноса базы данных с одного сервера ClickHouse на другой можно воспользоваться `rsync` и запросами `ATTACH TABLE`. Рассмотрим эту процедуру подробнее.

Настройка SSH
-------------

На приёмнике генерируем SSH-ключи, если их ещё нет:

    $ ssh-keygen

Берём содержимое файла `.ssh/id_rsa.pub` и добавляем в отдельную строку файла `.ssh/authorized_keys` на источнике.

Убеждаемся в возможности подключиться с приёмника на источник по SSH. При проблемах проверяем, что в файле /etc/passwd на источнике прописан домашний каталог пользователя и оболочка, что доступ по SSH не блокируется в /etc/hosts.allow или фаерволом.

Установка rsync
---------------

Устанавливаем на источнике и приёмнике rsync:

    # apt-get install rsync

Копирование базы данных
-----------------------

Запускаем на приёмнике копирование интересующей базы данных в локальный каталог для пользовательских файлов Clickhouse:

    $ rsync -avv user@source.domain.tld:/var/lib/clickhouse/data/db/ /var/lib/clickhouse/user_files/

При необходимости можно также сменить владельца, группу и права доступа к скопированным файлам:

    $ chown -R clickhouse:clickhouse /var/lib/clickhouse/user_files/
    $ chmod -R o= /var/lib/clickhouse/user_files/

Присоединение таблиц к базе данных
----------------------------------

Подключаемся к базе данных на исходном сервере:

    $ clickhouse-client -h source.domain.tld -d db -u user --ask-password

Смотрим на источнике список таблиц в базе данных и их структуру:

    SHOW TABLES;
    SHOW CREATE TABLE pagehit;

Например, структура таблицы `pagehit` выглядит следующим образом:

    CREATE TABLE db.pagehit
    (
        `date` DateTime,
        `user_agent` String,
        `browser` String,
        `brand` String,
        `device_type` String,
        `page_id` Int64,
        `contract` Nullable(String),
        `os` String
    )
    ENGINE = MergeTree
    PARTITION BY toYYYYMM(date)
    ORDER BY date
    SETTINGS index_granularity = 8192

Подключаемся к базе данных на целевом сервере:

    $ clickhouse-client -h destination.domain.tld -d db -u user --ask-password

На приёмнике выполняем подсоединение таблиц в нужную базу данных, указывая структуру таблицы:

    ATTACH TABLE pagehit FROM '/var/lib/clickhouse/user_files/pagehit'
    (
        `date` DateTime,
        `user_agent` String,
        `browser` String,
        `brand` String,
        `device_type` String,
        `page_id` Int64,
        `contract` Nullable(String),
        `os` String
    )
    ENGINE = MergeTree
    PARTITION BY toYYYYMM(date)
    ORDER BY date
    SETTINGS index_granularity = 8192;

Повторяем действия для каждой таблицы базы данных.

Эти действия можно автоматизировать с помощью скрипта, но написание такого скрипта оставим за рамками статьи.

Окончательный перенос
---------------------

После того, как выполнена подготовка, описанная выше, можно завершить перенос.

Закрываем доступ к исходной базе данных.

Запускаем на приёмнике синхронизацию содержимого интересующей базы данных:

    $ rsync -avv user@source.domain.tld:/var/lib/clickhouse/data/db/ /var/lib/clickhouse/data/db/

Если нужно, то меняем также владельца, группу и права доступа ко вновь появившимся файлам:

    $ chown -R clickhouse:clickhouse /var/lib/clickhouse/data/db
    $ chmod -R o= /var/lib/clickhouse/data/db

Переключаемся на копию базы данных.

Теперь можно удалить исходную базу данных:

    DROP DATABASE db;

Скрипт для резервного копирования и восстановления базы данных
--------------------------------------------------------------

Для резервного копирования и восстановления можно воспользоваться наколеночным скриптом [[chbr.sh]]. Прежде чем воспользоваться им, нужно создать в домашнем каталоге пользователя, от имени которого он будет запущен, файл конфигурации `~/.clickhouse-client/config.xml` для подключения к базе данных:

    <config>
            <host>127.0.0.1</host>
            <port>9000</port>
            <user>user</user>
            <password>password</password>
    </config>

Для снятия резервной копии нужно вызвать скрипт следующим образом:

    $ ./chbr.sh backup db

В текущем каталоге будет сформирован файл db.tar, содержащий внутри себя по два файла для каждой из таблиц:

* table.sql - файл с командой для создания таблицы,
* table.tsv.gz - файл со сжатыми данными таблицы в формате с колонками, разделёнными табуляциями.

Для восстановления резервной копии нужно создать пустую базу данных и запустить скрипт следующим образом:

    $ ./chbr.sh restore db

Работоспособность скрипта не гарантируется, скрипт сделан скорее в целях демострации концепции, а не как как готовое решение.
