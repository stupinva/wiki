Использование MySQL
===================

Оглавление
----------

[[!toc startlevel=2 levels=3]]

Логин и пароль в консольном клиенте mysql
-----------------------------------------

### Явное указание логина и пароля

Клиент MySQL может подключаться с использованием явно указанного пароля:

    $ mysql -u username -p pass

### Использование файла с логином и паролем

Можно указать используемые по умолчанию настройки клиента в произвольном файле в следующем виде:

    [client]
    user = "whatever"
    password = "whatever"
    host = "whatever"

Для использования настроек по умолчанию из этого файла достаточно будет указать путь нему следующим образом:

    $ mysql --defaults-file=файл.cnf

### Использование файла `~/.mylogin.cnf`

Можно настроить иcпользумый по умолчанию пароль в файле `~/.mylogin.cnf` при помощи команды следующего вида:

    $ mysql_config_editor set --login-path=client --host=localhost --user=root --password

Где `client` - имя секции. Секция `client` используется клиентом `mysql` по умолчанию.

Посмотреть пароли из файла ~/.mylogin.cnf в расшифрованном виде можно следующим образом:

    $ my_print_defaults -s client

Для подключения клиентом MySQL с использованием другой секции, имя секции можно указать следующим образом:

    $ mysql --login-path=client

### Аутентификация через Unix-сокет

Имеется также возможность аутентификации без пароля при подключении через Unix-сокет. Для этого в настройках у клиента вместо традиционного плагина `mysql_native_password` должен быть выставлен плагин `auth_socket`. Для изменения способа аутентификации определённого пользователя можно воспользоваться одним из соотвествующих запросов:

    ALTER USER user@localhost IDENTIFIED WITH mysql_native_password BY 'password';
    ALTER USER user@localhost IDENTIFIED WITH auth_socket;

Просмотр списка активных транзакций
-----------------------------------

Просмотреть список активных транзакций можно выполнив в базе данных `information_schema` следующий запрос:

    SELECT innodb_trx.trx_started,
           innodb_trx.trx_mysql_thread_id,
           processlist.host,
           processlist.db,
           processlist.user
    FROM innodb_trx
    JOIN processlist ON processlist.id = innodb_trx.trx_mysql_thread_id
    ORDER BY innodb_trx.trx_started;

Просмотр количества записей в журнале откатов
---------------------------------------------

Просмотреть количество элементов можно выполнив в базе данных `information_schema` следующий запрос:

    SELECT count
    FROM innodb_metrics
    WHERE name = 'trx_rseg_history_len';

Или при помощи такого запроса:

    SHOW ENGINE InnoDB STATUS;

В строке следующего вида:

    History list length 2759

Просмотр объёма сегментов отката транзакций
-------------------------------------------

Узнать объём сегментов отката транзакций в мегабайтах можно из базы данных `information_schema` при помощи запроса:

    SELECT SUM(curr_size) * 16 / 1024 AS undo_space_mb
    FROM xtradb_rseg;

Объём сегментов отката в буферном пуле в мегабайтах можно узнать из той же базы данных с помощью такого запроса:

    SELECT COUNT(*) * 16 / 1024 AS size_mb
    FROM innodb_buffer_page
    WHERE page_type = 'UNDO_LOG';

Более полную информацию по остальным страницам можно получить следующим образом:

    SELECT COUNT(*) cnt,
           COUNT(*) * 16 / 1024 size_mb,
           page_type
    FROM innodb_buffer_page
    GROUP BY page_type;

Типы страниц:

* `BLOB` - несжатая страница BLOB,
* `EXTENT_DESCRIPTOR` - страница дескриптора экстентов,
* `FILE_SPACE_HEADER` - заголовок пространства файла,
* `IBUF_BITMAP` - битовая карта буфера вставки,
* `IBUF_INDEX` - индекс буфера вставки,
* `INDEX` - узел двоичного дерева,
* `INODE` - узел индекса,
* `SYSTEM` - системная страница,
* `TRX_SYSTEM` - данные транзакционной системы,
* `UNDO_LOG` - страница журнала отмены,
* `UNKNOWN` - неизвестно.

Источник:

* [Innodb transaction history often hides dangerous ‘debt’](https://www.percona.com/blog/2014/10/17/innodb-transaction-history-often-hides-dangerous-debt/).
* [24.4.2 The INFORMATION_SCHEMA INNODB_BUFFER_PAGE Table](https://dev.mysql.com/doc/refman/5.7/en/information-schema-innodb-buffer-page-table.html)

Просмотр неактивных пользователей
---------------------------------

Запрос для извлечения пользователей, которые никогда не подключались и не определили представление, подпрограмму, триггер или запись в планировщике задач:

    SELECT DISTINCT m.user,
                    m.host
    FROM mysql.user m
    LEFT JOIN performance_schema.accounts p ON m.user = p.user
      AND p.host LIKE m.host
    LEFT JOIN information_schema.views is_v ON is_v.security_type = 'DEFINER'
      AND is_v.definer LIKE CONCAT(m.user, '@', m.host)
    LEFT JOIN information_schema.routines is_r ON is_r.security_type = 'DEFINER'
      AND is_r.definer LIKE CONCAT(m.user, '@', m.host)
    LEFT JOIN information_schema.events is_e ON is_e.definer LIKE CONCAT(m.user, '@', m.host)
    LEFT JOIN information_schema.triggers is_t ON is_t.definer LIKE CONCAT(m.user, '@', m.host)
    WHERE p.user IS NULL
      AND is_v.DEFINER IS NULL
      AND is_r.DEFINER IS NULL
      AND is_e.DEFINER IS NULL
      AND is_t.DEFINER IS NULL
    ORDER BY user, host;

Источник:

* [How to find unused MariaDB/MySQL accounts](https://falseisnotnull.wordpress.com/2013/09/14/how-to-find-unused-mariadbmysql-accounts/)

Просмотр размеров таблиц и индексов
-----------------------------------

Для просмотра 10 самых крупных таблиц (вместе с индексами) можно воспользоваться запросом следующего вида, выполнив его в базе данных `information_schema`:

    SELECT table_name, data_length + index_length AS s
    FROM tables
    GROUP BY table_name
    ORDER BY s DESC
    LIMIT 10;

Просмотр необычных движков таблиц
---------------------------------

"Обычным" движком для таблиц считается InnoDB. Для получения списка таблиц, в которых используются другие движки, за исключением таблиц в системных базах данных, можно воспользоваться следующим запросом:

    SELECT engine,
           table_schema,
           table_name
    FROM information_schema.tables
    WHERE engine <> 'InnoDB'
      AND table_schema NOT IN ('mysql', 'performance_schema', 'information_schema');

Преобразование всех таблиц из MyISAM в InnoDB
---------------------------------------------

    $ mysql information_schema -BNe "SELECT CONCAT('ALTER TABLE \`', table_schema, '\`.\`', table_name, '\` ENGINE=InnoDB;') FROM tables WHERE engine = 'MyISAM' AND table_schema NOT IN ('mysql', 'performance_schema', 'information_schema');" | mysql

Выгрузка схемы базы данных
--------------------------

Для выгрузки схемы базы данных можно воспользоваться утилитой резервного копирования:

    $ mysqldump --single-transaction --skip-comments --skip-add-drop-table --no-data db > db_schema.sql

Дополнительные материалы
------------------------

* [Jeremy Cole. The MySQL “swap insanity” problem and the effects of the NUMA architecture](https://blog.jcole.us/2010/09/28/mysql-swap-insanity-and-the-numa-architecture/)
* [Jeremy Cole. A brief update on NUMA and MySQL](https://blog.jcole.us/2012/04/16/a-brief-update-on-numa-and-mysql/)
* [Memory part 4: NUMA support](https://lwn.net/Articles/254445/)
