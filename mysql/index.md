Использование MySQL
===================

Оглавление
----------

[[!toc startlevel=2 levels=3]]

Пользователи
------------

### Логин и пароль в консольном клиенте mysql

#### Явное указание логина и пароля

Клиент MySQL может подключаться с использованием явно указанного пароля:

    $ mysql -u username -p pass

#### Использование файла с логином и паролем

Можно указать используемые по умолчанию настройки клиента в произвольном файле в следующем виде:

    [client]
    user = "whatever"
    password = "whatever"
    host = "whatever"

Для использования настроек по умолчанию из этого файла достаточно будет указать путь нему следующим образом:

    $ mysql --defaults-file=файл.cnf

#### Использование файла `~/.mylogin.cnf`

Можно настроить используемый по умолчанию пароль в файле `~/.mylogin.cnf` при помощи команды следующего вида:

    $ mysql_config_editor set --login-path=client --host=localhost --user=root --password

Где `client` - имя секции. Секция `client` используется клиентом `mysql` по умолчанию.

Посмотреть пароли из файла ~/.mylogin.cnf в расшифрованном виде можно следующим образом:

    $ my_print_defaults -s client

Для подключения клиентом MySQL с использованием другой секции, имя секции можно указать следующим образом:

    $ mysql --login-path=client

#### Аутентификация через Unix-сокет

Имеется также возможность аутентификации без пароля при подключении через Unix-сокет. Для этого в настройках у клиента вместо традиционного плагина `mysql_native_password` должен быть выставлен плагин `auth_socket`. Для изменения способа аутентификации определённого пользователя можно воспользоваться одним из соответствующих запросов:

    ALTER USER user@localhost IDENTIFIED WITH mysql_native_password BY 'password';
    ALTER USER user@localhost IDENTIFIED WITH auth_socket;

### Просмотр пользователей-определителей

В базах данных могут быть определены представления, подпрограммы, события и триггеры, исполняемые с правами пользователя, который их определил. Для получения списка таких пользователей можно воспользоваться следующим запросом:

    SELECT DISTINCT m.user,
                    m.host,
                    CASE WHEN is_v.DEFINER IS NULL THEN 'N' ELSE 'Y' END AS view_definer,
                    CASE WHEN is_r.DEFINER IS NULL THEN 'N' ELSE 'Y' END AS routine_definer,
                    CASE WHEN is_e.DEFINER IS NULL THEN 'N' ELSE 'Y' END AS event_definer,
                    CASE WHEN is_t.DEFINER IS NULL THEN 'N' ELSE 'Y' END AS trigger_definer
    FROM mysql.user m
    LEFT JOIN information_schema.views is_v ON is_v.security_type = 'DEFINER'
      AND is_v.definer LIKE CONCAT(m.user, '@', m.host)
    LEFT JOIN information_schema.routines is_r ON is_r.security_type = 'DEFINER'
      AND is_r.definer LIKE CONCAT(m.user, '@', m.host)
    LEFT JOIN information_schema.events is_e ON is_e.definer LIKE CONCAT(m.user, '@', m.host)
    LEFT JOIN information_schema.triggers is_t ON is_t.definer LIKE CONCAT(m.user, '@', m.host)
    WHERE is_v.DEFINER IS NOT NULL
      OR is_r.DEFINER IS NOT NULL
      OR is_e.DEFINER IS NOT NULL
      OR is_t.DEFINER IS NOT NULL
    GROUP BY m.user, m.host
    ORDER BY user, host

### Просмотр неактивных пользователей

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

Просмотр информации
-------------------

### Просмотр списка активных транзакций

Просмотреть список активных транзакций можно выполнив в базе данных `information_schema` следующий запрос:

    SELECT innodb_trx.trx_started,
           innodb_trx.trx_mysql_thread_id,
           processlist.host,
           processlist.db,
           processlist.user
    FROM innodb_trx
    JOIN processlist ON processlist.id = innodb_trx.trx_mysql_thread_id
    ORDER BY innodb_trx.trx_started;

Для завершения зависшей транзакции нужно выполнить команду `KILL` с идентификатором потока MySQL, в котором открыта транзакция:

    KILL <trx_mysql_thread_id>;

### Просмотр количества записей в журнале откатов

Просмотреть количество элементов можно выполнив в базе данных `information_schema` следующий запрос:

    SELECT count
    FROM innodb_metrics
    WHERE name = 'trx_rseg_history_len';

Или при помощи такого запроса:

    SHOW ENGINE InnoDB STATUS;

В строке следующего вида:

    History list length 2759

### Просмотр объёма сегментов отката транзакций

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

### Выгрузка схемы базы данных

Для выгрузки схемы базы данных можно воспользоваться утилитой резервного копирования:

    $ mysqldump --single-transaction --skip-comments --skip-add-drop-table --no-data db > db_schema.sql

### Просмотр размеров таблиц и индексов

Для просмотра 10 самых крупных таблиц (вместе с индексами) можно воспользоваться запросом следующего вида, выполнив его в базе данных `information_schema`:

    SELECT table_name, data_length + index_length AS s
    FROM tables
    GROUP BY table_name
    ORDER BY s DESC
    LIMIT 10;

### Просмотр количества таблиц в базах данных

Для просмотра количества таблиц в каждой из баз данных, имеющихся на сервере, кроме системых, можно воспользоваться таким запросом:

    SELECT table_schema, COUNT(*)
    FROM tables
    WHERE table_schema NOT IN ('mysql', 'sys', 'information_schema', 'performance_schema', 'admin')
    GROUP BY table_schema;

Из выборки исключена также база данных `admin`, которая используется для [[отслеживания подключений к MySQL|mysql_connections]].

### Просмотр количества колонок в таблицах баз данных

Для просмотра количества колонок в таблицах в каждой из баз данных, имеющихся на сервере, кроме системых, можно воспользоваться таким запросом:

    SELECT table_schema, COUNT(*)
    FROM columns
    WHERE table_schema NOT IN ('mysql', 'sys', 'information_schema', 'performance_schema', 'admin')
    GROUP BY table_schema;

Из выборки исключена также база данных `admin`, которая используется для [[отслеживания подключений к MySQL|mysql_connections]].

### Просмотр объёмов баз данных

Для просмотра объёма в гигабайтах каждой из баз данных, имеющихся на сервере, кроме системых, можно воспользоваться таким запросом:

    SELECT table_schema, SUM(data_length + index_length) / (1024 * 1024 * 1024)
    FROM tables
    WHERE table_schema NOT IN ('mysql', 'sys', 'information_schema', 'performance_schema', 'admin')
    GROUP BY table_schema;

Из выборки исключена также база данных `admin`, которая используется для [[отслеживания подключений к MySQL|mysql_connections]].

### Просмотр объёма данных за месяц в периодических таблицах баз данных

Если в базе данных создаются таблицы с суффиксами вида `_ГГГГММ` и/или `_ГГГГММДД`, то оценить объём данных в гигабайтах за прошлый (полный) месяц в таких таблицах каждой из баз данных можно с помощью следующего запроса:

    SELECT table_schema,
           SUM(data_length + index_length) / (1024 * 1024 * 1024)
    FROM tables
    WHERE table_schema NOT IN ('mysql', 'sys', 'information_schema', 'performance_schema')
      AND (table_name LIKE CONCAT('%\_', DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 1 MONTH), '%Y%m'))
        OR table_name LIKE CONCAT('%\_', DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 1 MONTH), '%Y%m'), '__'))
    GROUP BY table_schema;

### Поиск таблиц без первичного ключа и ключа уникальности

Для поиска таблиц, не имеющих первичного ключа, можно воспользоваться следующим запросом к базе данных `information_schema`:

    SELECT tables.table_schema,
           tables.table_name
    FROM tables
    LEFT JOIN table_constraints ON tables.table_schema = table_constraints.table_schema
      AND tables.table_name = table_constraints.table_name
      AND table_constraints.constraint_type = 'PRIMARY KEY'
    WHERE table_constraints.constraint_type IS NULL
      AND tables.table_schema NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys')
      AND tables.table_type = 'BASE TABLE'
    ORDER BY tables.table_schema,
             tables.table_name;

Бывают таблицы, у которых нет первичного ключа, но вместо него создан ключ уникальности. Чтобы найти таблицы, у которых нет ни первичного ключа, ни ключа уникальности, можно воспользоваться таким запросом:

    SELECT tables.table_schema,
           tables.table_name
    FROM tables
    LEFT JOIN table_constraints ON tables.table_schema = table_constraints.table_schema
      AND tables.table_name = table_constraints.table_name
      AND table_constraints.constraint_type ('PRIMARY KEY', 'UNIQUE')
    WHERE table_constraints.constraint_type IS NULL
      AND tables.table_schema NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys')
      AND tables.table_type = 'BASE TABLE'
    ORDER BY tables.table_schema,
             tables.table_name;

Источник: [Bart Gawrych. Find tables without primary keys (PKs) in MySQL database](https://dataedo.com/kb/query/mysql/find-tables-without-primary-keys)

### Поиск таблиц с необычными форматами

"Обычным" форматом для таблиц считается InnoDB. Для получения списка таблиц, в которых используются другие форматы, за исключением таблиц в системных базах данных, можно воспользоваться следующим запросом:

    SELECT engine,
           table_schema,
           table_name
    FROM information_schema.tables
    WHERE engine <> 'InnoDB'
      AND table_schema NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys');

### Поиск таблиц с секциями

Для вывода списка таблиц, поделённых на секции или подсекции, можно выполнить в базе данных `information_schema` следующий запрос:

    SELECT DISTINCT table_schema, table_name
    FROM partitions
    WHERE partition_name IS NOT NULL
      OR subpartition_name IS NOT NULL;

Преобразование таблиц
---------------------

### Преобразование всех таблиц из MyISAM в InnoDB

"В лоб" эту задачу можно решить следующим образом:

    $ mysql information_schema -BN <<END | mysql
    SELECT CONCAT('ALTER TABLE \`',
                  table_schema,
                  '\`.\`',
                  table_name,
                  '\` ENGINE=InnoDB;')
    FROM tables
    WHERE engine = 'MyISAM'
      AND table_schema NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys');"
    END

Однако во время выполнения команд преобразования таблицы будут заблокированы для операций записи, что в большинстве случаев неприемлемо. Для того, чтобы преобразовать к InnoDB только таблицы с первичным ключом или ключом уникальности, можно воспользоваться такой конструкцией:

    $ mysql information_schema -BN <<END | sh
    SELECT CONCAT('pt-online-schema-change --alter engine=InnoDB --execute D=',
           tables.table_schema,
           ',t=',
           tables.table_name,
           ' # ',
           (tables.data_length + tables.index_length) / (1024 * 1024),
           ' MB'))
    FROM tables
    JOIN table_constraints ON tables.table_schema = table_constraints.table_schema
      AND tables.table_name = table_constraints.table_name
      AND table_constraints.constraint_type IN ('PRIMARY KEY', 'UNIQUE')
    WHERE tables.engine = 'MyISAM'
      AND tables.table_schema NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys')
      AND tables.table_type = 'BASE TABLE'
    ORDER BY tables.data_length + tables.index_length DESC,
             tables.table_schema,
             tables.table_name;
    END

Таблицы сразу сортируются в порядке убывания размеров. Т.к. таблицы InnoDB занимают больше места, чем таблицы MyISAM, лучше преобразовывать их начиная с самых больших, пока на диске ещё есть достаточно места. Если преобразовывать таблицы в обратном порядке, то на некотором этапе можно столкнуться с тем, что на диске нет места для размещения копии очередной таблицы, поскольку всё свободное место уже было истрачено на увеличение размеров мелких таблиц.

Для остальных таблиц конструкция по-прежнему придётся воспользоваться запросами `ALTER TABLE`, т.к. `pt-online-schema-change` не умеет преобразовывать таблицы, у которых нет первичного ключа или ключа уникальности:

    $ mysql information_schema -BN <<END | mysql
    SELECT CONCAT('ALTER TABLE \`',
           tables.table_schema,
           '\`.\`',
           tables.table_name,
           '\` ENGINE=InnoDB; -- ',
           (tables.data_length + tables.index_length) / (1024 * 1024),
           ' MB')
    FROM tables
    LEFT JOIN table_constraints ON tables.table_schema = table_constraints.table_schema
      AND tables.table_name = table_constraints.table_name
      AND table_constraints.constraint_type IN ('PRIMARY KEY', 'UNIQUE')
    WHERE table_constraints.constraint_type IS NULL
      AND tables.engine = 'MyISAM'
      AND tables.table_schema NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys')
      AND tables.table_type = 'BASE TABLE'
    ORDER BY tables.data_length + tables.index_length DESC,
             tables.table_schema ASC,
             tables.table_name ASC;
    END

### Неблокирующее преобразование журнальных таблиц без первичного и уникального ключей

Для неблокирующего преобразования любых таблиц, имеющих первичный или уникальный ключ, лучше всего использовать утилиту `pt-online-schema-change`. Если же в таблице нет ни первичного ключа, ни уникального ключа, то утилита `pt-online-schema-change` откажется работать. Если таблица используется в качестве журнала и в неё только вставляются новые записи, но записи никогда не удаляются и не изменяются, то можно воспользоваться комбинацией нескольких запросов. Например, для смены типа таблицы на `InnoDB` можно воспользоваться такой последовательностью запросов:

    CREATE TABLE <таблица>_new LIKE <таблица>;
    ALTER TABLE <таблица>_new ENGINE=InnoDB;
    ALTER TABLE <таблица> RENAME TO <таблица>_old;
    ALTER TABLE <таблица>_new RENAME TO <таблица>;
    INSERT INTO <таблица> SELECT * FROM <таблица>_old;
    DROP TABLE <таблица>_old;

Стоит учитывать, что во время выполнения этих операций запросы `SELECT` будут возвращать только новые записи, а уже имеющиеся на время не будут попадать в выборку, т.к. будут находиться в таблице `<таблица>_old`. Если это недопустимо, то стоит поискать другие способы.

### Преобразование секционированных таблиц

Для вывода списка таблиц, поделённых на секции или подсекции, можно выполнить в базе данных `information_schema` следующий запрос:

    $ mysql information_schema -BN <<END | mysql
    SELECT DISTINCT CONCAT('ALTER TABLE \`',
                           table_schema,
                           '\`.\`',
                           table_name,
                           '\` REMOVE PARTITIONING;')
    FROM partitions
    WHERE partition_name IS NOT NULL
      OR subpartition_name IS NOT NULL;
    END

### Преобразование формата строк таблиц InnoDB

Строки таблиц InnoDB могут храниться в форматах `Redundant`, `Compact`, `Dynamic` и `Compressed`. Форматы `Redundant` и `Compact` поддерживают индексы шириной не более 768 байт, в результате чего индексы по текстовым полям, у которых в начале часто встречается определённый длинный текст, могут оказаться неэффективными. Форматы `Dynamic` и `Compressed` поддерживают индексы шириной до 3072 байт и в подобных ситуациях могут оказаться эффективнее. Для преобразования всех таблиц InnoDB к формату строк `Dynamic` можно воспользоваться решением "в лоб":

    $ mysql information_schema -BN <<END | mysql
    SELECT CONCAT('ALTER TABLE \`',
                  table_schema,
                  '\`.\`',
                  table_name,
                  '\` ROW_FORMAT=Dynamic;')
    FROM tables
    WHERE engine = 'InnoDB'
      AND row_format <> 'Dynamic'
      AND table_schema NOT IN ('mysql', 'performance_schema', 'information_schema', 'sys');"
    END

Преобразовать формат строк в таблицах без их блокировки с помощью утилиты `pt-online-schema-change` можно, например, вот так:

    $ mysql information_schema -BN <<END | sh
    SELECT CONCAT('pt-online-schema-change --alter row_format=Dynamic --execute D=',
                  tables.table_schema,
                  ',t=',
                  tables.table_name,
                  ' # ',
                  (tables.data_length + tables.index_length) / (1024 * 1024),
                  ' MB'))
    FROM tables
    JOIN table_constraints ON tables.table_schema = table_constraints.table_schema
      AND tables.table_name = table_constraints.table_name
      AND table_constraints.constraint_type IN ('PRIMARY KEY', 'UNIQUE')
    WHERE tables.engine = 'InnoDB'
      AND tables.row_format <> 'Dynamic'
      AND tables.table_schema NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys')
      AND tables.table_type = 'BASE TABLE'
    ORDER BY tables.data_length + tables.index_length DESC,
             tables.table_schema,
             tables.table_name;
    END

Таблицы без первичного ключа и ключа уникальности утилита `pt-online-schema-change` обрабатывать не умеет, поэтому их придётся обрабатывать прежним образом:

    $ mysql information_schema -BN <<END
    SELECT CONCAT('ALTER TABLE \`',
                  tables.table_schema,
                  '\`.\`',
                  tables.table_name,
                  '\` ROW_FORMAT=Dynamic; -- ',
                  (tables.data_length + tables.index_length) / (1024 * 1024),
                  ' MB')
    FROM tables
    LEFT JOIN table_constraints ON tables.table_schema = table_constraints.table_schema
      AND tables.table_name = table_constraints.table_name
      AND table_constraints.constraint_type IN ('PRIMARY KEY', 'UNIQUE')
    WHERE table_constraints.constraint_type IS NULL
      AND tables.engine = 'InnoDB'
      AND talbes.row_format <> 'Dynamic'
      AND tables.table_schema NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys')
      AND tables.table_type = 'BASE TABLE'
    ORDER BY tables.data_length + tables.index_length DESC,
             tables.table_schema ASC,
             tables.table_name ASC;
    END

### Удаление осиротевших табличных пространств

Иногда можно столкнуться с ситуациями, когда таблицы нет, но от неё осталось табличное пространство. Такая проблема может возникнуть из-за некорректной обработки сервером MySQL команд `ALTER TABLE ... DISCARD TABLESPACE` и `ALTER TABLE ... IMPORT TABLESPACE`. У отсутствующей таблицы нельзя посмотреть структуру и её нельзя удалить, потому что её нет:

    mysql> show create table log_session_20_201506;
    ERROR 1146 (42S02): Table 'neftekamsk.log_session_20_201506' doesn't exist
    mysql> drop table log_session_20_201506;
    ERROR 1051 (42S02): Unknown table 'neftekamsk.log_session_20_201506'

Но и создать на её месте новую таблицу с таким же именем тоже нельзя, потому что существует табличное пространство, которое сервер MySQL не хочет затирать:

    mysql> create table log_session_20_201506 (id int);
    ERROR 1813 (HY000): Tablespace '`neftekamsk`.`log_session_20_201506`' exists.

Решается эта проблема просто: нужно удалить (переместить, переименовать) существующий ibd-файл из каталога, в котором находятся файлы базы данных:

    # cd /var/lib/mysql/neftekamsk
    # rm log_session_20_201506.ibd

Репликация
----------

### Переключение реплики на другой IP-адрес источника

Понадобилось поменять IP-адрес на источнике. Для того, чтобы не сломать репликацию, сделать это можно в три этапа:

* Добавляем на сервер-источник дополнительный IP-адрес, который станет его новым IP-адресом,
* Перенастраиваем реплику на новый IP-адрес источника (остальных клиентов тоже можно перенастроить на использование нового IP-адреса),
* Удаляем на сервере-источнике прежний IP-адрес, оставляем только новый.

Останавливаем репликацию:

    $ mysql mysql -BNe 'STOP SLAVE;'

Запоминаем в файле `pos` позицию, на которой остановились в виде готового запроса для настройки репликации:

    $ mysql -Be 'SHOW SLAVE STATUS\G' \
        | awk '/Relay_Master_Log_File:/ {
                   printf "CHANGE MASTER TO MASTER_HOST = '\''192.168.169.115'\'', ";
                   printf "MASTER_USER = '\''repl'\'', ";
                   printf "MASTER_PASSWORD = '\''xxx'\'', ";
                   printf "MASTER_LOG_FILE = '\''" $2 "'\'', ";
                   printf "MASTER_LOG_POS = ";
               }
               /Exec_Master_Log_Pos:/ {
                   print $2 ";";
               }' > pos

Удаляем настройки репликации:

    $ mysql mysql -BNe 'RESET SLAVE ALL;'

Настраиваем репликацию на новый IP-адрес, воспользовавшись запросом, сохранённым в файле `pos`:

    $ mysql mysql < pos

Возобновляем репликацию:

    $ mysql mysql -BNe 'START SLAVE;'

Удаляем файл с сохранёнными настройками репликации `pos`:

    $ rm pos

Для того, чтобы перерыв в репликации был минимальным, все команды можно поместить в скрипт и выполнить разом.

### Игнорирование ошибок репликации MySQL

Пропустить одну запись из журнала репликации можно следующим образом:

    STOP SLAVE; SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1; START SLAVE;

Игнорировать ошибки репликации небезопасно. Однажды пропущенная запись из журнала репликации приводит к появлению различий в таблицах на источнике и реплике. Даже если база данных содержит лишь таблицы, содержимое которых используется как кэш или журнал событий, и небольшая разница в данных не критична, однажды появившееся расхождение может приводить к возникновению новых ошибок репликации. Поэтому стоит использовать пропуск записей из журнала репликации лишь как временную меру до тех пор, пока не будет развёрнута новая реплика.

Источник:

* [Another reason why SQL_SLAVE_SKIP_COUNTER is bad in MySQL](https://www.percona.com/blog/2013/07/23/another-reason-why-sql_slave_skip_counter-is-bad-in-mysql/)

Дополнительные материалы
------------------------

* [Jeremy Cole. The MySQL “swap insanity” problem and the effects of the NUMA architecture](https://blog.jcole.us/2010/09/28/mysql-swap-insanity-and-the-numa-architecture/)
* [Jeremy Cole. A brief update on NUMA and MySQL](https://blog.jcole.us/2012/04/16/a-brief-update-on-numa-and-mysql/)
* [Memory part 4: NUMA support](https://lwn.net/Articles/254445/)
* [Syncing MySQL Slave Table with pt-online-schema-change](https://dzone.com/articles/syncing-mysql-slave-table-pt)
* [Sveta Smirnova. How to Update InnoDB Table Statistics Manually](https://www.percona.com/blog/updating-innodb-table-statistics-manually/)
* [Peter Zaitsev. Examining MySQL InnoDB Persistent Statistics](https://www.percona.com/blog/examining-mysql-innodb-persistent-statistics/)
