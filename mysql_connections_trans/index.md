Как вести журнал подключений пользователей к MySQL
==================================================

[[!tag mysql]]

Это перевод статьи: [How to Log User Connections in MySQL](https://mysqlhints.blogspot.com/2011/01/how-to-log-user-connections-in-mysql.html)

В MySQL 5.1 нет встроенных средств для ведения журнала подключений пользователей, но сочетание нескольких команд MySQL позволяет вести журнал подключений пользователей без необходимости включать общий журнал запросов. Я повторяю: вам не нужно включать общий журнал запросов для того, чтобы сделать это!

Вы бы хотели узнать, как это сделать?

С помощью статьи Бэрона Шварца (Baron Schwartz) по ссылке [http://www.xaprb.com/blog/2006/07/23/how-to-track-what-owns-a-mysql-connection/](http://www.xaprb.com/blog/2006/07/23/how-to-track-what-owns-a-mysql-connection/) мне удалось найти подходящий способ. Однако, я захотел сделать это немного проще, потому что мне нужно было отслеживать подключения к MySQL. Возможно впоследствии я собираюсь дополнить этот способ, но пока что сохраню его простым.

Ингридиенты:

* `init-connect`
* `NOW()`
* `CURRENT_USER()`
* `CONNECTION_ID()`

Хотите увидеть, как их объединить?

Итак, вот рецепт...

Подразумевается, что информация будет сохраняться в базу данных admin.

1. Создадим таблицу для сохранения информации о подключениях.

        CREATE TABLE admin.connections (
            id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            connect_time DATETIME NOT NULL,
            user_host VARCHAR(50) NOT NULL,
            connection_id INT UNSIGNED NOT NULL
        );

2. Настроим значение переменной `init-connect`. Это запрос или команда, которая будет выполняться при каждом подключении клиента. [Подробности здесь](http://dev.mysql.com/doc/refman/5.0/en/server-system-variables.html#sysvar_init_connect).

        SET GLOBAL init_connect = "INSERT INTO admin.connections (connect_time, user, connection_id) VALUES (NOW(), CURRENT_USER(), CONNECTION_ID());";

3. Убедитесь, что у всех пользователей есть права для вставки записей в таблицу `admin.connections`.

4. При входе пользователя без глобальных прав в таблицу `admin.connections` должна вставиться строка. Отметим, что системная переменная `init-connect` не влияет на пользователей с глобальными правами. Все администраторы баз данных более-менее понимают, о чём речь.

5. Наблюдайте, как растёт и расцветает таблица подключений. Вы только что начали новый хобби-проект.
