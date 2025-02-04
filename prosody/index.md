Настройка mam в Prosody
=======================

mam - менеджер архивных сообщений (Message Archive Manager), позволяет хранить историю переписки на сервере. Если клиент поддерживает XEP-0313, то он сможет подгрузить с сервера переписку из архива, даже если эта переписка происходила через другой клиент.

Для настройки этой функции понадобится пакет - prosody-modules, т.к. нужный нам модуль находится в этом пакете. Модуль mam использует для хранения сообщений модуль storage, который, в свою очередь, может хранить информацию разных видов в разных хранилищах. Модуль storage позволяет хранить архив сообщений только в реляционной базе данных. Хранение архива сообщений возможно только в одной из баз данных SQL: SQLite3, MySQL, PostgreSQL. Однако, хранение архива сообщений в реляционной базе данных поддерживается только в Prosody версий 0.10 и выше. В дистрибутиве Debian Stretch имеется только Prosody версии 0.9. К счастью, в репозитории stretch-backports имеется готовый пакет с Prosody версии 0.11. К несчастью, когда я проделал все описанные ниже действия по установке Prosody версии 0.11.2, сломалась поддержка протокола BOSH. Что касается поддержки архива сообщений, то и она не заработала. Во всяком случае, в базе данных нет никаких намёков на это.

Подключим репозиторий, добавив в файл /etc/apt/sources.list одну строчку:

    deb http://mirror.yandex.ru/debian stretch-backports main contrib non-free
  
Теперь нужно обновить список пакетов, доступных для установки из репозитория. Сделаем это при помощи такой команды:

    # apt-get update
  
Теперь можно посмотреть варианты пакета prosody, доступные в репозиториях. Для этого можно воспользоваться следующей командой:

    # apt-cache policy prosody

В моём случае эта команда вывела следующую информацию:

    prosody:
      Установлен: 0.9.12-2+deb9u2
      Кандидат:   0.9.12-2+deb9u2
      Таблица версий:
         0.11.2-1~bpo9+1 100
            100 http://mirror.yandex.ru/debian stretch-backports/main amd64 Packages
     *** 0.9.12-2+deb9u2 500
            500 http://mirror.yandex.ru/debian stretch/main amd64 Packages
            500 http://mirror.yandex.ru/debian-security stretch/updates/main amd64 Packages
            100 /var/lib/dpkg/status</pre>

Установим пакет из репозитория stretch-backports:

    # apt-get install -t stretch-backports prosody
  
Вместе с новым пакетом prosody также будут обновлены пакеты с языком Lua с версии 5.1 до версии 5.2, т.к. Prosody версии 0.11 использует особенности Lua версии 5.2 (предыдущая версия 0.10 использует Lua 5.1).

При обновлении пакета мне было предложено обновить и файл конфигурации. Я запустил сравнение версий файлов конфигурации, скопировал внесённые мной изменения в отдельный файл, согласился на замену файла конфигурации, а затем снова внёс в него собственные правки. После этого я проверил правильность файла конфигурации при помощи следующей команды:

    # prosodyctl check config

Команда сообщила мне, что модули аутентификации, такие как `auth_dovecot`, не нужно включать явным образом, а достаточно лишь указать способ аутентификации в опции authentication.

Теперь можно установить пакет prosody-modules:

    # apt-get install prosody-modules

Модулю требуется база данных для сохранения архивных сообщений. В качестве примера приведу настройку базы данных под управлением MariaDB. Для начала, если сервер MariaDB ещё не установлен, его необходимо установить:

    # apt-get install mariadb-server

Подключимся к MariaDB:

    $ mysql -uroot -p mysql

И после ввода пароля, который был указан при инсталляции СУБД, выполним запрос на создание базы данных с именем prosody:

    MariaDB [mysql]>CREATE DATABASE prosody CHARSET 'UTF8';
    Query OK, 1 row affected (0.00 sec)

Теперь нужно создать пользователя, от имени которого Prosody будет подключаться к базе данных. Я назвал этого пользователя prosody, а пароль сгенерировал при помощи программы pwgen. Поскольку СУБД установлена на том же компьютере, что и сам сервер Prosody, то при создании пользователя укажем, что этот пароль действует только для локального сетевого узла localhost. Создадим пользователя:

    MariaDB [mysql]> INSERT INTO user(user, password, host) VALUES('prosody', PASSWORD('prosody_password'), 'localhost');
    Query OK, 1 row affected, 3 warnings (0.12 sec)
    MariaDB [mysql]>FLUSH PRIVILEGES;
    Query OK, 0 rows affected (0.07 sec)

Почти всё готово, осталось только выдать права доступа к базе данных созданному пользователю:

    MariaDB [mysql]>GRANT ALL ON prosody.* TO prosody@localhost;
    Query OK, 0 rows affected (0.04 sec)
    MariaDB [mysql]>FLUSH PRIVILEGES;
    Query OK, 0 rows affected (0.00 sec)

Выйдем из консольного SQL-клиента, нажав Ctrl-D.

Теперь приступим к настройке самого Prosody. Откроем файл /etc/prosody/prosody.cfg.lua и впишем в секцию `modules_enabled` модуль:

    "mam";

Ниже настроим сам модуль:

    max_archive_query_results = 50;
    default_archive_policy = true;
    archive_expires_after = "never";
    archive_cleanup_interval = 24 * 60 * 60;

Опции имеют следующий смысл:

* `max_archive_query_results` - задаёт количество сообщений, которое клиент может запросить у сервера за один раз. При необходимости получить больше сообщений клиент должен делать дополнительные запросы.
* `default_archive_policy` - позволяет выбрать, переписку с какими клиентами нужно хранить. Значение false означает, что хранить переписку не нужно. Значение true включает хранение всей переписки. Значение "roster" включает хранение переписки только с теми собеседниками, которые есть в списке собеседников.
* `archive_expires_after` - указывает, как долго нужно хранить сообщения на сервере. Можно указать числовое значение с одним из суффиксов: d - сутки, w - недели, m - месяцы, y - года. Если нужно указать более короткий интервал времени, то его можно указать числом без суффикса, в секундах. Если же сообщения из архива удалять не нужно, то можно указать значение "never". По умолчанию сообщения будут храниться одну неделю.
* `archive_cleanup_interval` - задаёт интервал в секундах, с которым сервер Prosody будет очищать базу данных от устаревших сообщений.

И, наконец, указываем, что в базе данных нужно хранить только архивные сообщения и указываем параметры подключения к базе данных:

    storage = {
      archive = "sql"
    }
    sql = {
      driver = "MySQL";
      database = "prosody";
      host = "localhost";
      port = 3306;
      username = "prosody";
      password = "prosody_password";
    }
    sql_manage_tables = true

Модулю mam для работы с MariaDB понадобится модуль для работы с базой данных MySQL. Перед перезапуском демона установим необходимые пакеты из репозитория stretch-backports:

    # apt-get install -t stretch-backports lua-dbi-common lua-dbi-mysql

Перезапустим Jabber-сервер Prosody, чтобы новые настройки вступили в силу:

    # systemctl restart prosody.service
