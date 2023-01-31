Пример изменения настроек оптимизатора запросов MySQL
=====================================================

После обновления Percona Server 5.6 до версии Percona Server 5.7 появились жалобы на медленную работу сервера. Т.к. обновлённый сервер был репликой другого, оставшегося не обновлённым, имелась возможность сравнивать планы выполнения запроса на серверах разных версий. Было обнаружено различие в плане выполнения запроса.

В версии 5.6 план выполнения запроса имел следующий вид:

    +----+--------------------+------------------------------+--------+-----------------------------------------------------+----------------------+---------+-----------------------------------------------------+-------+------------------------------+
    | id | select_type        | table                        | type   | possible_keys                                       | key                  | key_len | ref                                                 | rows  | Extra                        |
    +----+--------------------+------------------------------+--------+-----------------------------------------------------+----------------------+---------+-----------------------------------------------------+-------+------------------------------+
    |  1 | PRIMARY            | ig                           | ref    | pgr,group_id                                        | group_id             | 4       | const                                               | 90440 | Using where; Using temporary |
    |  1 | PRIMARY            | process                      | eq_ref | PRIMARY,status,type,process_type_id_status_id_index | PRIMARY              | 4       | bgcrm_v21.ig.process_id                             |     1 | Using where                  |
    |  1 | PRIMARY            | param_1372                   | eq_ref | PRIMARY,param_id                                    | PRIMARY              | 8       | bgcrm_v21.ig.process_id,const                       |     1 | NULL                         |
    |  1 | PRIMARY            | param_2395                   | eq_ref | PRIMARY,param_id                                    | PRIMARY              | 8       | bgcrm_v21.ig.process_id,const                       |     1 | NULL                         |
    |  1 | PRIMARY            | type_process                 | eq_ref | PRIMARY                                             | PRIMARY              | 4       | bgcrm_v21.process.type_id                           |     1 | NULL                         |
    |  1 | PRIMARY            | ps_process_data              | ref    | process_id_status_id,process_id                     | process_id_status_id | 8       | bgcrm_v21.process.status_id,bgcrm_v21.ig.process_id |     1 | Using where                  |
    |  1 | PRIMARY            | process_status_title_process | eq_ref | PRIMARY                                             | PRIMARY              | 4       | bgcrm_v21.process.status_id                         |     1 | NULL                         |
    |  1 | PRIMARY            | param_90                     | ref    | PRIMARY                                             | PRIMARY              | 8       | bgcrm_v21.ig.process_id,const                       |     1 | NULL                         |
    |  1 | PRIMARY            | ps_9_process                 | ref    | process_id_status_id,process_id                     | process_id_status_id | 8       | const,bgcrm_v21.ig.process_id                       |     1 | Using where                  |
    |  1 | PRIMARY            | ps_8_process                 | ref    | process_id_status_id,process_id                     | process_id_status_id | 8       | const,bgcrm_v21.ig.process_id                       |     1 | Using where                  |
    |  1 | PRIMARY            | param_1611                   | eq_ref | PRIMARY,param_id                                    | PRIMARY              | 8       | bgcrm_v21.ig.process_id,const                       |     1 | NULL                         |
    |  1 | PRIMARY            | param_2380                   | eq_ref | PRIMARY,param_id                                    | PRIMARY              | 8       | bgcrm_v21.ig.process_id,const                       |     1 | NULL                         |
    |  3 | DEPENDENT SUBQUERY | param                        | ref    | ipv,id                                              | ipv                  | 8       | bgcrm_v21.process.id,const                          |     1 | Using where; Using index     |
    |  3 | DEPENDENT SUBQUERY | val                          | ref    | param_id                                            | param_id             | 4       | const                                               |   492 | Using where                  |
    |  2 | DEPENDENT SUBQUERY | link                         | ref    | PRIMARY,object_id                                   | PRIMARY              | 4       | bgcrm_v21.process.id                                |     1 | Using where                  |
    +----+--------------------+------------------------------+--------+-----------------------------------------------------+----------------------+---------+-----------------------------------------------------+-------+------------------------------+

В версии 5.7 план выполнения запроса имел такой вид:

    +----+--------------------+------------------------------+------------+--------+-----------------------------------------------------+---------------------------------+---------+--------------------------------------------------+--------+----------+----------------------------------------+
    | id | select_type        | table                        | partitions | type   | possible_keys                                       | key                             | key_len | ref                                              | rows   | filtered | Extra                                  |
    +----+--------------------+------------------------------+------------+--------+-----------------------------------------------------+---------------------------------+---------+--------------------------------------------------+--------+----------+----------------------------------------+
    |  1 | PRIMARY            | process                      | NULL       | range  | PRIMARY,status,type,process_type_id_status_id_index | process_type_id_status_id_index | 12      | NULL                                             | 417412 |   100.00 | Using index condition; Using temporary |
    |  1 | PRIMARY            | param_1372                   | NULL       | eq_ref | PRIMARY,param_id                                    | PRIMARY                         | 8       | bgcrm_v21.process.id,const                       |      1 |   100.00 | NULL                                   |
    |  1 | PRIMARY            | ig                           | NULL       | ref    | pgr,group_id                                        | pgr                             | 8       | bgcrm_v21.process.id,const                       |      1 |   100.00 | Using index                            |
    |  1 | PRIMARY            | param_2395                   | NULL       | eq_ref | PRIMARY,param_id                                    | PRIMARY                         | 8       | bgcrm_v21.process.id,const                       |      1 |   100.00 | NULL                                   |
    |  1 | PRIMARY            | type_process                 | NULL       | eq_ref | PRIMARY                                             | PRIMARY                         | 4       | bgcrm_v21.process.type_id                        |      1 |   100.00 | NULL                                   |
    |  1 | PRIMARY            | ps_process_data              | NULL       | ref    | process_id_status_id,process_id                     | process_id_status_id            | 8       | bgcrm_v21.process.status_id,bgcrm_v21.process.id |      1 |   100.00 | Using where                            |
    |  1 | PRIMARY            | process_status_title_process | NULL       | eq_ref | PRIMARY                                             | PRIMARY                         | 4       | bgcrm_v21.process.status_id                      |      1 |   100.00 | NULL                                   |
    |  1 | PRIMARY            | param_90                     | NULL       | ref    | PRIMARY                                             | PRIMARY                         | 8       | bgcrm_v21.process.id,const                       |      1 |   100.00 | NULL                                   |
    |  1 | PRIMARY            | ps_9_process                 | NULL       | ref    | process_id_status_id,process_id                     | process_id_status_id            | 8       | const,bgcrm_v21.process.id                       |      1 |   100.00 | Using where                            |
    |  1 | PRIMARY            | ps_8_process                 | NULL       | ref    | process_id_status_id,process_id                     | process_id_status_id            | 8       | const,bgcrm_v21.process.id                       |      1 |   100.00 | Using where                            |
    |  1 | PRIMARY            | param_1611                   | NULL       | eq_ref | PRIMARY,param_id                                    | PRIMARY                         | 8       | bgcrm_v21.process.id,const                       |      1 |   100.00 | NULL                                   |
    |  1 | PRIMARY            | param_2380                   | NULL       | eq_ref | PRIMARY,param_id                                    | PRIMARY                         | 8       | bgcrm_v21.process.id,const                       |      1 |   100.00 | NULL                                   |
    |  3 | DEPENDENT SUBQUERY | param                        | NULL       | ref    | ipv,id                                              | ipv                             | 8       | bgcrm_v21.process.id,const                       |      1 |   100.00 | Using where; Using index               |
    |  3 | DEPENDENT SUBQUERY | val                          | NULL       | ref    | param_id                                            | param_id                        | 4       | const                                            |    492 |   100.00 | Using where                            |
    |  2 | DEPENDENT SUBQUERY | link                         | NULL       | ref    | PRIMARY,object_id                                   | PRIMARY                         | 4       | bgcrm_v21.process.id                             |      2 |   100.00 | Using where                            |
    +----+--------------------+------------------------------+------------+--------+-----------------------------------------------------+---------------------------------+---------+--------------------------------------------------+--------+----------+----------------------------------------+

Наткнулся на интересный материал [MySQL join has drastically worse performance after upgrading from 5.6 to 5.7](https://dba.stackexchange.com/questions/235351/mysql-join-has-drastically-worse-performance-after-upgrading-from-5-6-to-5-7), который дал пищу для размышлений. Сверил настройки optimizer_switch на двух серверах при помощи такого запроса:

    SHOW GLOBAL VARIABLES WHERE Variable_name = 'optimizer_switch';

В Percona Server 5.7 появились дополнительные настройки со следующими значениями:

    duplicateweedout=on
    condition_fanout_filter=on
    derived_merge=on
    prefer_ordering_index=on
    favor_range_scan=off

Попробовал изменять значения новых настроек и в итоге обнаружил, что изменений одной из них позволяет вернуться к прежнему плану выполнения:

    SET GLOBAL optimizer_switch='condition_fanout_filter=off';

Сам план выполнения запроса при этом стал выглядеть следующим образом:

    +----+--------------------+------------------------------+------------+--------+-----------------------------------------------------+----------------------+---------+-----------------------------------------------------+-------+----------+------------------------------+
    | id | select_type        | table                        | partitions | type   | possible_keys                                       | key                  | key_len | ref                                                 | rows  | filtered | Extra                        |
    +----+--------------------+------------------------------+------------+--------+-----------------------------------------------------+----------------------+---------+-----------------------------------------------------+-------+----------+------------------------------+
    |  1 | PRIMARY            | ig                           | NULL       | ref    | pgr,group_id                                        | group_id             | 4       | const                                               | 88140 |    50.00 | Using where; Using temporary |
    |  1 | PRIMARY            | process                      | NULL       | eq_ref | PRIMARY,status,type,process_type_id_status_id_index | PRIMARY              | 4       | bgcrm_v21.ig.process_id                             |     1 |    20.00 | Using where                  |
    |  1 | PRIMARY            | param_1372                   | NULL       | eq_ref | PRIMARY,param_id                                    | PRIMARY              | 8       | bgcrm_v21.ig.process_id,const                       |     1 |   100.00 | NULL                         |
    |  1 | PRIMARY            | param_2395                   | NULL       | eq_ref | PRIMARY,param_id                                    | PRIMARY              | 8       | bgcrm_v21.ig.process_id,const                       |     1 |   100.00 | NULL                         |
    |  1 | PRIMARY            | type_process                 | NULL       | eq_ref | PRIMARY                                             | PRIMARY              | 4       | bgcrm_v21.process.type_id                           |     1 |   100.00 | NULL                         |
    |  1 | PRIMARY            | ps_process_data              | NULL       | ref    | process_id_status_id,process_id                     | process_id_status_id | 8       | bgcrm_v21.process.status_id,bgcrm_v21.ig.process_id |     1 |   100.00 | Using where                  |
    |  1 | PRIMARY            | process_status_title_process | NULL       | eq_ref | PRIMARY                                             | PRIMARY              | 4       | bgcrm_v21.process.status_id                         |     1 |   100.00 | NULL                         |
    |  1 | PRIMARY            | param_90                     | NULL       | ref    | PRIMARY                                             | PRIMARY              | 8       | bgcrm_v21.ig.process_id,const                       |     1 |   100.00 | NULL                         |
    |  1 | PRIMARY            | ps_9_process                 | NULL       | ref    | process_id_status_id,process_id                     | process_id_status_id | 8       | const,bgcrm_v21.ig.process_id                       |     1 |   100.00 | Using where                  |
    |  1 | PRIMARY            | ps_8_process                 | NULL       | ref    | process_id_status_id,process_id                     | process_id_status_id | 8       | const,bgcrm_v21.ig.process_id                       |     1 |   100.00 | Using where                  |
    |  1 | PRIMARY            | param_1611                   | NULL       | eq_ref | PRIMARY,param_id                                    | PRIMARY              | 8       | bgcrm_v21.ig.process_id,const                       |     1 |   100.00 | NULL                         |
    |  1 | PRIMARY            | param_2380                   | NULL       | eq_ref | PRIMARY,param_id                                    | PRIMARY              | 8       | bgcrm_v21.ig.process_id,const                       |     1 |   100.00 | NULL                         |
    |  3 | DEPENDENT SUBQUERY | param                        | NULL       | ref    | ipv,id                                              | ipv                  | 8       | bgcrm_v21.process.id,const                          |     1 |   100.00 | Using where; Using index     |
    |  3 | DEPENDENT SUBQUERY | val                          | NULL       | ref    | param_id                                            | param_id             | 4       | const                                               |   492 |   100.00 | Using where                  |
    |  2 | DEPENDENT SUBQUERY | link                         | NULL       | ref    | PRIMARY,object_id                                   | PRIMARY              | 4       | bgcrm_v21.process.id                                |     2 |    11.11 | Using where                  |
    +----+--------------------+------------------------------+------------+--------+-----------------------------------------------------+----------------------+---------+-----------------------------------------------------+-------+----------+------------------------------+

Второй пример:

    +----+--------------------+------------------------------+------------+-------------+-----------------------------------------------------+----------------------+---------+---------- -----------------------------------------------+-------+----------+-------------------------------------------------------------------------------+
    | id | select_type        | table                        | partitions | type        | possible_keys                                       | key                  | key_len | ref                                                     | rows  | filtered | Extra                                                                         |
    +----+--------------------+------------------------------+------------+-------------+-----------------------------------------------------+----------------------+---------+---------------------------------------------------------+-------+----------+-------------------------------------------------------------------------------+
    |  1 | PRIMARY            | param_list_236               | NULL       | index_merge | ipv,value,id_param,id,param_id                      | value,param_id       | 4,4     | NULL                                                    | 87167 |    50.00 | Using intersect(value,param_id); Using where; Using temporary; Using filesort |
    |  1 | PRIMARY            | process                      | NULL       | eq_ref      | PRIMARY,status,type,process_type_id_status_id_index | PRIMARY              | 4       | bgcrm_v21.param_list_236.id                             |     1 |    25.00 | Using where                                                                   |
    |  1 | PRIMARY            | ps_process_data              | NULL       | ref         | process_id_status_id,process_id                     | process_id_status_id | 8       | bgcrm_v21.process.status_id,bgcrm_v21.param_list_236.id |     1 |   100.00 | Using where                                                                   |
    |  1 | PRIMARY            | process_status_title_process | NULL       | eq_ref      | PRIMARY                                             | PRIMARY              | 4       | bgcrm_v21.process.status_id                             |     1 |   100.00 | NULL                                                                          |
    |  1 | PRIMARY            | type_process                 | NULL       | eq_ref      | PRIMARY                                             | PRIMARY              | 4       | bgcrm_v21.process.type_id                               |     1 |   100.00 | NULL                                                                          |
    |  1 | PRIMARY            | param_342                    | NULL       | eq_ref      | PRIMARY,param_id                                    | PRIMARY              | 8       | bgcrm_v21.param_list_236.id,const                       |     1 |   100.00 | NULL                                                                          |
    |  1 | PRIMARY            | param_392                    | NULL       | eq_ref      | PRIMARY,param_id                                    | PRIMARY              | 8       | bgcrm_v21.param_list_236.id,const                       |     1 |   100.00 | NULL                                                                          |
    |  3 | DEPENDENT SUBQUERY | param                        | NULL       | ref         | ipv                                                 | ipv                  | 8       | bgcrm_v21.process.id,const                              |     1 |   100.00 | Using where; Using index                                                      |
    |  3 | DEPENDENT SUBQUERY | val                          | NULL       | ref         | param_id_id                                         | param_id_id          | 156     | const,bgcrm_v21.param.value                             |     1 |   100.00 | NULL                                                                          |
    |  2 | DEPENDENT SUBQUERY | param                        | NULL       | ref         | ipv,id_param,id,param_id                            | ipv                  | 8       | bgcrm_v21.process.id,const                              |     1 |   100.00 | Using where; Using index                                                      |
    |  2 | DEPENDENT SUBQUERY | val                          | NULL       | eq_ref      | PRIMARY                                             | PRIMARY              | 4       | bgcrm_v21.param.value                                   |     1 |   100.00 | NULL                                                                          |
    +----+--------------------+------------------------------+------------+-------------+-----------------------------------------------------+----------------------+---------+---------------------------------------------------------+-------+----------+-------------------------------------------------------------------------------+

Как видно из плана выполнения запроса, в первой строчке используется пересечение двух индексов - "Using intersect(value,param_id)". Попробовал отключить использование этой оптимизации следующим образом:

    SET GLOBAL optimizer_switch='index_merge_intersection=off';

И обнаружил, что план выполнения запроса изменился следующим образом:

    +----+--------------------+------------------------------+------------+--------+-----------------------------------------------------+---------------------------------+---------+--------------------------------------------------+-------+----------+--------------------------------------------------------+
    | id | select_type        | table                        | partitions | type   | possible_keys                                       | key                             | key_len | ref                                              | rows  | filtered | Extra                                                  |
    +----+--------------------+------------------------------+------------+--------+-----------------------------------------------------+---------------------------------+---------+--------------------------------------------------+-------+----------+--------------------------------------------------------+
    |  1 | PRIMARY            | process                      | NULL       | range  | PRIMARY,status,type,process_type_id_status_id_index | process_type_id_status_id_index | 12      | NULL                                             | 31263 |   100.00 | Using index condition; Using temporary; Using filesort |
    |  1 | PRIMARY            | param_list_236               | NULL       | eq_ref | ipv,value,id_param,id,param_id                      | ipv                             | 12      | bgcrm_v21.process.id,const,const                 |     1 |   100.00 | Using index                                            |
    |  1 | PRIMARY            | ps_process_data              | NULL       | ref    | process_id_status_id,process_id                     | process_id_status_id            | 8       | bgcrm_v21.process.status_id,bgcrm_v21.process.id |     1 |   100.00 | Using where                                            |
    |  1 | PRIMARY            | process_status_title_process | NULL       | eq_ref | PRIMARY                                             | PRIMARY                         | 4       | bgcrm_v21.process.status_id                      |     1 |   100.00 | NULL                                                   |
    |  1 | PRIMARY            | type_process                 | NULL       | eq_ref | PRIMARY                                             | PRIMARY                         | 4       | bgcrm_v21.process.type_id                        |     1 |   100.00 | NULL                                                   |
    |  1 | PRIMARY            | param_342                    | NULL       | eq_ref | PRIMARY,param_id                                    | PRIMARY                         | 8       | bgcrm_v21.process.id,const                       |     1 |   100.00 | NULL                                                   |
    |  1 | PRIMARY            | param_392                    | NULL       | eq_ref | PRIMARY,param_id                                    | PRIMARY                         | 8       | bgcrm_v21.process.id,const                       |     1 |   100.00 | NULL                                                   |
    |  3 | DEPENDENT SUBQUERY | param                        | NULL       | ref    | ipv                                                 | ipv                             | 8       | bgcrm_v21.process.id,const                       |     1 |   100.00 | Using where; Using index                               |
    |  3 | DEPENDENT SUBQUERY | val                          | NULL       | ref    | param_id_id                                         | param_id_id                     | 156     | const,bgcrm_v21.param.value                      |     1 |   100.00 | NULL                                                   |
    |  2 | DEPENDENT SUBQUERY | param                        | NULL       | ref    | ipv,id_param,id,param_id                            | ipv                             | 8       | bgcrm_v21.process.id,const                       |     1 |   100.00 | Using where; Using index                               |
    |  2 | DEPENDENT SUBQUERY | val                          | NULL       | eq_ref | PRIMARY                                             | PRIMARY                         | 4       | bgcrm_v21.param.value                            |     1 |   100.00 | NULL                                                   |
    +----+--------------------+------------------------------+------------+--------+-----------------------------------------------------+---------------------------------+---------+--------------------------------------------------+-------+----------+--------------------------------------------------------+

Как видно, отключение опции положительным образом повлияло на план выполнения запроса: теперь выполнение запроса начинается со сканирования таблицы process, из которой с помощью составного индекса process_type_id_status_id_index извлекается меньшее количество строк - 31263 против 87176 строк в предыдущем варианте, а таблица param_list_236 присоединяется к таблице process с помощью составного индекса ipv.

Третий пример:

    +----+-------------+-------+------------+-------+-----------------------------------------------------+------------+---------+----------------+-------+----------+-------------+
    | id | select_type | table | partitions | type  | possible_keys                                       | key        | key_len | ref            | rows  | filtered | Extra       |
    +----+-------------+-------+------------+-------+-----------------------------------------------------+------------+---------+----------------+-------+----------+-------------+
    |  1 | SIMPLE      | p     | NULL       | index | PRIMARY,status,type,process_type_id_status_id_index | close_dt   | 6       | NULL           | 23667 |     0.04 | Using where |
    |  1 | SIMPLE      | pe    | NULL       | ref   | process_id,user_id                                  | process_id | 4       | bgcrm_v21.p.id |     1 |     4.01 | Using where |
    +----+-------------+-------+------------+-------+-----------------------------------------------------+------------+---------+----------------+-------+----------+-------------+

Он не столь очевиден без текста самого запроса:

    SELECT p.* 
    FROM process p 
    JOIN process_executor pe on pe.process_id = p.id
      AND pe.user_id = 1523
    WHERE p.type_id in (10822, 10665) AND p.status_id = 8
    ORDER BY p.close_dt DESC
    LIMIT 1;

Как видно, вместо того, чтобы выбирать из таблиц подходящие результаты во временную таблицу и только потом сортировать её и выбрать строчку с наибольшим значением close_dt, планировщик решил перебрать все строки из таблицы processes, в порядке убывания поля close_dt, в надежде найти первую подходящую запись без создания временных таблиц. На практике эта оптимизация не всегда оказывается удачной. Если в таблице process_executor нет подходящих строк, то это приводит к полному перебору всех строк из таблицы processes. Время выполнения запроса при этом вырастает от долей секунд до сотен секунд.

За оптимизацию запросов с ORDER BY и LIMIT отвечает опция prefer_ordering_index, появившаяся в MySQL 5.7. Отключим её:

    SET GLOBAL optimizer_switch = 'prefer_ordering_index=OFF';

После отключения план выполнения запроса приобретает тот вид, который он имел до этого:

    +----+-------------+-------+------------+-------+-----------------------------------------------------+---------------------------------+---------+----------------+-------+----------+---------------------------------------+
    | id | select_type | table | partitions | type  | possible_keys                                       | key                             | key_len | ref            | rows  | filtered | Extra                                 |
    +----+-------------+-------+------------+-------+-----------------------------------------------------+---------------------------------+---------+----------------+-------+----------+---------------------------------------+
    |  1 | SIMPLE      | p     | NULL       | range | PRIMARY,status,type,process_type_id_status_id_index | process_type_id_status_id_index | 8       | NULL           | 75200 |   100.00 | Using index condition; Using filesort |
    |  1 | SIMPLE      | pe    | NULL       | ref   | process_id,user_id                                  | process_id                      | 4       | bgcrm_v21.p.id |     1 |     4.01 | Using where                           |
    +----+-------------+-------+------------+-------+-----------------------------------------------------+---------------------------------+---------+----------------+-------+----------+---------------------------------------+

Для того, чтобы не нужно было менять опцию оптимизатора, добавил составной индекс по полям user_id и process_id в таблицу process_executor и переписал запрос следующим образом:

    SELECT p.* 
    FROM process_executor pe
    STRAIGHT_JOIN process p ON pe.process_id = p.id
      AND p.type_id in (10822, 10665)
      AND p.status_id = 8
    WHERE pe.user_id = 1523
    ORDER BY p.close_dt DESC
    LIMIT 1;

В таком виде запрос стал работать менее секунды, а его план выполнения приобрёл следующий вид:

    +----+-------------+-------+------------+--------+-----------------------------------------------------+--------------------+---------+-------------------------+--------+----------+----------------------------------------------+
    | id | select_type | table | partitions | type   | possible_keys                                       | key                | key_len | ref                     | rows   | filtered | Extra                                        |
    +----+-------------+-------+------------+--------+-----------------------------------------------------+--------------------+---------+-------------------------+--------+----------+----------------------------------------------+
    |  1 | SIMPLE      | pe    | NULL       | ref    | process_id,user_id_process_id                       | user_id_process_id | 4       | const                   | 163862 |   100.00 | Using index; Using temporary; Using filesort |
    |  1 | SIMPLE      | p     | NULL       | eq_ref | PRIMARY,status,type,process_type_id_status_id_index | PRIMARY            | 4       | bgcrm_v21.pe.process_id |      1 |     5.00 | Using where                                  |
    +----+-------------+-------+------------+--------+-----------------------------------------------------+--------------------+---------+-------------------------+--------+----------+----------------------------------------------+

Дополнительные материалы
------------------------

* [How To Prepare For Your MySQL 5.7 Upgrade](https://www.digitalocean.com/community/tutorials/how-to-prepare-for-your-mysql-5-7-upgrade) - как подготовиться к обновлению с версии 5.6 до 5.7
* [Sergey Glukhov. New optimizer hint for changing the session system variable](https://dev.mysql.com/blog-archive/new-optimizer-hint-for-changing-the-session-system-variable/)
