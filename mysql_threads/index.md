Настройка количества потоков MySQL
==================================

[[!tag mysql]]

Оглавление
----------

[[!toc startlevel=2 levels=4]]

thread_cache_size
-----------------

Операции завершения и создания потоков достаточно дорогостоящие, с помощью опции `thread_cache_size` можно настроить количество неиспользуемых потоков, которые не будут завершаться для возможности их повторного использования.

Для подбора оптимального значения лучше обратить внимание на соотношение счётчиков `Threads_created` и `Threads_cached`. Эти счётчики увеличиваются на единицу при каждом создании нового потока и повторном использовании потока из кэша соответственно. Если это соотношение намного больше единицы, стоит увеличить значение опции `thread_cache_size`. Посмотреть эти значения можно, например, с помощью следующих запросов:

     SHOW GLOBAL STATUS WHERE Variable_name = 'Threads_created';
     SHOW GLOBAL STATUS WHERE Variable_name = 'Threads_cached';

Значение `thread_cache_size` не используется, если активирован алгоритм `pool-of-threads` (см. ниже описание опции [[thread_handling|mysql_threads#thread_handling]]) и не может превышать `max_connections`.

thread_handling
---------------

Опция настраивает метод назначения потоков клиентским подключениям и может принимать одно из следующих значений:

* `one-thread-per-connection` - метод, используемый по умолчанию, когда каждому клиентскому подключению выделяется по одному выделенному потоку,
* `pool-of-threads` (в MariaDB и Percona) или `loaded-dynamically` (в Oracle MySQL) - адаптивный метод, порождающий новые потоки, так чтобы на каждом процессорном ядре компьютера обрабатывался по меньшей мере один запрос,
* `no-threads` - используется только один поток для обслуживания всех клиентских подключений, этот режим предназначен только для разработчиков в целях отладки.

thread_pool_size
----------------

Опция `thread_pool_size` задаёт максимальное количество одновременно работающих потоков для алгоритма `pool-of-threads` (см. выше описание опции [[thread_handling|mysql_threads#thread_handling]]). По умолчанию равно количеству процессорных ядер в системе, может принимать значения от 1 до 128.

Для настройки значения этой опции можно воспользоваться переменными `Threadpool_threads` и `Threadpool_idle_threads`, первая из которых содержит количество потоков в пуле, а вторая содержит количество простаивающих потоков.

    SHOW GLOBAL STATUS WHERE Variable_name = 'Threadpool_threads';
    SHOW GLOBAL STATUS WHERE Variable_name = 'Threadpool_idle_threads';

innodb_read_io_threads и innodb_write_io_threads
------------------------------------------------

Чтением и записью данных на диск занимаются выделенные потоки MySQL. По умолчанию настроены 4 потока для чтения и 4 потока для записи. Можно настроить другое количество потоков в пределах от 1 до 64. Если файлы базы данных находятся на хранилище, состоящем из множества дисков, а компьютер обладает большим количеством процессорных ядер, то эти значения можно увеличить. Для одноплатных компьютеров, на которых в качестве хранилища используется SD-карта, можно наоборот уменьшить эти значения:

    innodb_read_io_threads = 16
    innodb_write_io_threads = 16

Для настройки можно воспользоваться переменными `Innodb_data_pending_reads` и `Innodb_data_pending_writes`, которые соответствуют количеству потоков, ожидающих выполнения операций чтения и записи соответственно. Понаблюдав за графиками их изменения, можно подобрать более обоснованные значения. Получить их можно, например, при помощи следующих запросов:

    SHOW GLOBAL STATUS WHERE Variable_name = 'Innodb_data_pending_reads';
    SHOW GLOBAL STATUS WHERE Variable_name = 'Innodb_data_pending_writes';

innodb_page_cleaners
--------------------

Количество потоков очистки страниц, по умолчанию 1, начиная с версии 5.7.8 - 4, но не более `innodb_buffer_pool_instances`. См. также `innodb_lru_scan_depth`.

innodb_lru_scan_depth
---------------------

Опция указывает, насколько глубоко нужно просматривать список последних изменений в буферном пуле InnoDB в поисках страниц для сброса на диск. По умолчанию просматривается 1024 изменения, минимальное значение равно 100. На системах с низкой интенсивностью изменения данных может оказаться полезным уменьшить значения этой опции.

innodb_thread_concurrency
-------------------------

Опция ограничивает количество одновременно работающих потоков. По умолчанию 0, то есть ограничений нет. Это приводит к деградации производительности. Рекомендуется подбирать значение, ориентируясь на сумму количества ядер и дисков в массиве. Можно попробовать удвоить одно из слагаемых.

Опция с похожим названием `thread_concurrency` имеет значение только для Solaris ниже 9 и не оказывает никакого влияния на Linux.

Использованные материалы
------------------------

* [MySQL 8.0 Reference Manual / Thread Pool Tuning](https://dev.mysql.com/doc/refman/8.0/en/thread-pool-tuning.html)
* [Percona Server 8.0 / Thread Pool](https://www.percona.com/doc/percona-server/8.0/performance/threadpool.html)
* [MariaDB Server Documentation / Thread Pool System and Status Variables](https://mariadb.com/kb/en/thread-pool-system-status-variables/)
* [MySQL 8.0 Reference Manual / Setting Account Resource Limits](https://dev.mysql.com/doc/refman/8.0/en/user-resources.html)
* [MySQL 8.0 Reference Manual / InnoDB Startup Options and System Variables](https://dev.mysql.com/doc/refman/8.0/en/innodb-parameters.html)
* [Vadim Tkachenko. kernel_mutex problem cont. Or triple your throughput](https://www.percona.com/blog/2011/12/02/kernel_mutex-problem-cont-or-triple-your-throughput/)
* [Miguel Angel Nieto. thread_concurrency doesn’t do what you expect](https://www.percona.com/blog/2012/06/04/thread_concurrency-doesnt-do-what-you-expect/)
* [Вячеслав Гапон. Как изменить innodb_thread_concurrency в MySQL](https://ixnfo.com/kak-izmenit-innodb_thread_concurrency-v-mysql.html)
