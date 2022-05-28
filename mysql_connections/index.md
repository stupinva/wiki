Отслеживание подключений к MySQL
================================

В MySQL нет встроенных средств для отслеживания подключений, однако его легко реализовать самостоятельно с использованием опции `init_connect` и функций `NOW()`, `CURRENT_USER()`, `CONNECTION_ID()`.

Настройка
---------

Прежде всего создадим базу данных и таблицу, в которой будем отслеживать подключения:

    CREATE DATABASE admin;
    USE admin;
    CREATE TABLE connections (
            session_user VARCHAR(50) NOT NULL,
            user_grants VARCHAR(50) NOT NULL,
            connect_time DATETIME NOT NULL,
            PRIMARY KEY (session_user)
    );

Теперь предоставим всем пользователям права на вставку записей в эту таблицу, например, с помощью следующей команды:

    $ mysql mysql -BNe "SELECT CONCAT('GRANT INSERT, UPDATE ON admin.connections TO \'', user, '\'@\'', host, '\';') FROM user WHERE user <> 'root';" | mysql
    $ mysqladmin flush-privileges

Если на сервере включена опция `read_only`, то вставить данные в таблицу не получится, несмотря на наличие соответствующих прав. Поэтому если она включена, её нужно отключить:

    SET GLOBAL read_only = OFF;

Теперь можно выставить в опции `init_connect` запрос, который будет вставлять в эту таблицу информацию об установленных подключениях:

    SET GLOBAL init_connect = "INSERT INTO admin.connections (session_user, user_grants, connect_time) VALUES (SESSION_USER(), CURRENT_USER(), NOW()) ON DUPLICATE KEY UPDATE user_grants = CURRENT_USER(), connect_time = NOW();";

Для того, чтобы сделанные настройки не терялись при перезагрузке, их нужно внести в файл конфигурации:

    read_only = OFF
    init_connect = INSERT INTO admin.connections (session_user, user_grants, connect_time) VALUES (SESSION_USER(), CURRENT_USER(), NOW()) ON DUPLICATE KEY UPDATE user_grants = CURRENT_USER(), connect_time = NOW();

Отмена настроек
---------------

Если отслеживать подключения более не требуется, то вернуть всё к начальному состоянию можно в обратном порядке следующим образом:

Удаляем из файла конфигурации опцию `init_connect` и включаем опцию `read_only`, если ранее она была включена.

Меняем настройки работающего сервера:

    SET GLOBAL init_connect = '';
    SET GLOBAL read_only = ON;

Отнимаем у пользователей права доступа к таблице `connections` в базе данных `admin`:

    $ mysql mysql -BNe "SELECT CONCAT('REVOKE INSERT, UPDATE ON admin.connections FROM \'', user, '\'@\'', host, '\';') FROM user WHERE user <> 'root';" | mysql
    $ mysqladmin flush-privileges

Удаляем базу данных вместе с таблицей:

    DROP DATABASE admin;

Использованные материалы
------------------------

* [How to Log User Connections in MySQL](https://mysqlhints.blogspot.com/2011/01/how-to-log-user-connections-in-mysql.html)
