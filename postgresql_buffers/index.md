Настройка буферов PostgreSQL
============================

[[!tag postgresql]]

Максимальный объём оперативной памяти, который может занять PostgreSQL, можно посчитать по одной из формул:

    shared_buffers + wal_buffer + (work_mem + temp_buffers) * max_connections + maintenance_work_mem * autovacuum_max_workers
    shared_buffers + wal_buffer + (work_mem + temp_buffers) * max_connections + autovacuum_work_mem

Общие буферы
------------

### shared_buffers

Кэш страниц таблиц и индексов. По умолчанию 128 мегабайт.

Если для PostgreSQL выделено менее 2 гигабайт, то `shared_buffers` выставляют равным 20% от максимального объёма.

Если для PostgreSQL выделено менее 32 гигабайт, то `shared_buffers` выставляют равным 25% от максимального объёма.

Если для PostgreSQL выделено более 32 гигабайт, то `shared_buffers` выставляют равным 8 гигабайтам.

### wal_buffer

Буферы подключений
------------------

### work_mem

Память для операций сортировки и слияния (ORDER BY, DISTINCT). По умолчанию 4 мегабайта.

Настройку начинают со значений 32-64 мегабайта.

Для уточнения значения нужно включить опцию `log_temp_files`. Опции указывается минимальный размер временного файла в килобайтах, запись о котором будет помещена в журнал. После этого нужно определить максимальный размер созданного временного файла и присвоить опции значение в 2-3 раза больше самого большого временного файла. Для отключения журналирования можно указать значение -1. 

### temp_buffers

Память для отслеживания временных таблиц. По умолчанию 8 мегабайт.

Буферы обслуживания
-------------------

### maintenance_work_mem, autovacuum_max_workers, autovacuum_work_mem

Память для операций `VACUUM`, `REINDEX` и `ALTER TABLE ADD FOREIGN KEY`. По умолчанию 64 мегабайта.

Рекомендуется настроить равным 10% (или от 12.5-25%) от общего объёма памяти компьютера, но не более 1 гигабайта.

Стоит учитывать значение опции `autovacuum_max_workers`, в которой указывается максимальное количество процессов, обрабатывающих операции `VACUUM`. Каждый из процессов может занять объём, указанный в `maintenance_work_mem`.

Для того, чтобы ограничить общий объём памяти для всех процессов, можно присвоить опции `maintenance_work_mem` значение -1 и указать общий объём в опции `autovacuum_work_mem`.

Оценочные значения
------------------

### effective_cache_size

Объём буферного кэша операционной системы. По умолчанию 4 гигабайта.

Рекомендуется либо оценить объём буферного кэша операционной системы, либо указать значение, равное 50% объёма оперативной памяти.

Использованные материалы
------------------------

* [Architecture and Tuning of Memory in PostgreSQL Databases](https://severalnines.com/database-blog/architecture-and-tuning-memory-postgresql-databases)
* [maintenance_work_mem](https://postgresqlco.nf/doc/en/param/maintenance_work_mem/)
* [autovacuum_max_workers](https://postgresqlco.nf/doc/en/param/autovacuum_max_workers/)
* [autovacuum_work_mem](https://postgresqlco.nf/doc/en/param/autovacuum_work_mem/)
* [log_temp_files](https://postgresqlco.nf/doc/en/param/log_temp_files/)
