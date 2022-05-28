Настройка общих буферов MySQL
=============================

innodb_buffer_pool_size
-----------------------

Буферный пул используется для работы с таблицами и индексами InnoDB. Если объём имеющейся оперативной памяти превышает размер таблиц и индексов InnoDB, то лучшим вариантом будет указать значение чуть больше их суммарного объёма.

Оценить объём таблиц и индексов можно в гигабайтах с помощью следующего запроса:

    SELECT SUM(data_length + index_length) / (1024 * 1024 * 1024) size_gb
    FROM information_schema.tables
    WHERE engine = 'InnoDB';

Или в мегабайтах:

    SELECT SUM(data_length + index_length) / (1024 * 1024) size_mb
    FROM information_schema.tables
    WHERE engine = 'InnoDB';

Если же объём оперативной памяти не позволяет вместить все таблицы и индексы, то стоит выделить 70-80% объёма доступной оперативной памяти. При этом стоит учитывать, что объём буферного пула вместе с объёмом клиентских буферов не должен превышать общий объём оперативной памяти. Для расчёта можно воспользоваться формулой `innodb_buffer_pool_size + max_connections * (join_buffer_size + sort_buffer_size + read_buffer_size read_rnd_buffer_size)`.

Пример:

    innodb_buffer_pool_size = 512M

Объём буферного пула можно изменять без остановки сервера MySQL при помощи запросов следующего вида:

    SET GLOBAL innodb_buffer_pool_size = 512M;

Отслеживать процесс изменения размера буферного пула можно с помощью следующего запроса:

    SHOW STATUS WHERE Variable_name = 'InnoDB_buffer_pool_resize_status';

Оценить достаточность размера буферного пула можно при помощи команды следующего вида:

    $ mysql -e 'SHOW ENGINE InnoDB STATUS\G' | grep 'Buffer pool hit rate'

Если в выводе преобладают строчки с соотношением 1000 / 1000 или близко к нему, то размер буферного пула достаточен.

innodb_buffer_pool_instances
----------------------------

В системах, где несколько клиентов создают интенсивную нагрузку на систему, можно поделить буферный пул на несколько экземпляров. Это позволит распределить блокировки буферного пула по отдельным экземплярам и тем самым снизить вероятность того, что один поток будет ожидать снятия блокировки другим потоком:

    innodb_buffer_pool_size = 10G
    innodb_buffer_pool_instances = 10

Принято делить буферный пул на экземпляры размером в 1 гигабайт, однако стоит учитывать, что максимальное количество экземпляров - 64. Поэтому для объёмов буферного пула больше 64 гигабайт можно округлить объём, приходящийся на один экземпляр, до большего целого числа гигабайт.

innodb_buffer_pool_dump_at_shutdown и innodb_buffer_pool_load_at_startup
------------------------------------------------------------------------

Опция `innodb_buffer_pool_dump_at_shutdown` предписывает записывать содержимое буферного пула в файл перед завершением работы, а опция `innodb_buffer_pool_load_at_startup` предписывает загружать из этого файла содержимое буферного пула. Позволяет ускорить наполнение буферного пула актуальными данными при перезапусках сервера MySQL.

    innodb_buffer_pool_dump_at_shutdown = 1
    innodb_buffer_pool_load_at_startup = 1

innodb_flush_method
-------------------

Рекомендуется не использовать дисковый кэш операционной системы, т.к. у сервера MySQL есть собственные буферы, а двойная буферизация замедляет работу и повышает вероятность повреждения данных. Для этого стоит настроить следующее значение:

    innodb_flush_method = O_DIRECT

key_buffer_size
---------------

Размер буфера для индексов таблиц MyISAM. При использовании только таблиц InnoDB таблицы MyISAM продолжают использоваться в качестве временных, поэтому для этого буфера в любом случае стоит выделить 32-64 мегабайт. При настройке следует ориентироваться на соотношение `Кey_read_requests` и `Кey_reads`, узанть которые можно, например, с помощью следующих запросов:

    SHOW GLOBAL STATUS WHERE Variable_name = 'Key_read_requests';
    SHOW GLOBAL STATUS WHERE Variable_name = 'Key_reads';

tmp_table_size
--------------

Максимальный размер таблицы внутри памяти. При превышении этого размера временная таблица помещается на диск (с полями типа text и blob). При настройке можно ориентироваться на соотношение `Created_tmp_disk_tables` и `Created_tmp_tables`, но стоит учитывать что некоторые временные таблицы всегда создаются на диске. Если временные таблицы создаются, то стоит искать решение в другом месте, например, создать индексы, которые позволят избежать сортировки данных на диске.

Посмотреть значения `Created_tmp_disk_tables` и `Created_tmp_tables` можно, например, при помощи следующих запросов:

    SHOW GLOBAL STATUS WHERE Variable_name = 'Created_tmp_disk_tables';
    SHOW GLOBAL STATUS WHERE Variable_name = 'Created_tmp_tables';

Использованные материалы
------------------------

* [Muhammad Irfan. InnoDB Performance Optimization Basics](https://www.percona.com/blog/2013/09/20/innodb-performance-optimization-basics-updated/) - обновлённая статья 2013 года
* [Peter Zaitsev. InnoDB Performance Optimization Basics](https://www.percona.com/blog/2007/11/01/innodb-performance-optimization-basics/) - оригинальная статья 2007 года
* [Вячеслав Гапон. Изменение InnoDB buffer pool в MySQL](https://ixnfo.com/innodb-buffer-pool-size.html)
* [MySQL 8.0 Reference Manual / Configuring InnoDB Buffer Pool Size](https://dev.mysql.com/doc/refman/8.0/en/innodb-buffer-pool-resize.html)
