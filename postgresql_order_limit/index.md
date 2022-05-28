Ускорение запросов с ORDER BY и LIMIT в плане выполнения в PostgreSQL
=====================================================================

Попался такой запрос, использующий временные файлы:

    SELECT "core_contractobject"."id",
           "core_contractobject"."contract_id",
           "core_contractobject"."house_id",
           "core_contract"."id",
           "core_contract"."user_id",
           "auth_user"."id",
           "auth_user"."username",
           "core_erphouse"."id",
           "core_erphouse"."external_id"
    FROM "core_contractobject"
    JOIN "core_contract" ON "core_contractobject"."contract_id" = "core_contract"."id"
    JOIN "auth_user" ON "core_contract"."user_id" = "auth_user"."id"
    JOIN "core_erphouse" ON "core_contractobject"."house_id" = "core_erphouse"."id"
    WHERE ("core_contract"."isp_org_id" IN (77, 310, 311)
           AND ("core_contract"."billing_id" = 'rb'
                OR "core_contract"."is_fake_flag" = true)
           AND "auth_user"."last_login" IS NOT NULL
           AND "core_erphouse"."external_id" IS NOT NULL
           AND "core_contractobject"."is_active" = true
           AND NOT ("core_erphouse"."external_id" = ''
                    AND "core_erphouse"."external_id" IS NOT NULL)
           AND NOT ("core_erphouse"."external_id" IS NULL))
    ORDER BY "core_contractobject"."date_created" DESC
    LIMIT 1000 OFFSET 122000;

План выполнения выглядит следующим образом:

    smart_house_prod=# EXPLAIN ANALYZE SELECT "core_contractobject"."id",
           "core_contractobject"."contract_id",
           "core_contractobject"."house_id",
           "core_contract"."id",
           "core_contract"."user_id",
           "auth_user"."id",
           "auth_user"."username",
           "core_erphouse"."id",
           "core_erphouse"."external_id"
    FROM "core_contractobject"
    JOIN "core_contract" ON "core_contractobject"."contract_id" = "core_contract"."id"
    JOIN "auth_user" ON "core_contract"."user_id" = "auth_user"."id"
    JOIN "core_erphouse" ON "core_contractobject"."house_id" = "core_erphouse"."id"
    WHERE ("core_contract"."isp_org_id" IN (77, 310, 311)
           AND ("core_contract"."billing_id" = 'rb'
                OR "core_contract"."is_fake_flag" = true)
           AND "auth_user"."last_login" IS NOT NULL
           AND "core_erphouse"."external_id" IS NOT NULL
           AND "core_contractobject"."is_active" = true
           AND NOT ("core_erphouse"."external_id" = ''
                    AND "core_erphouse"."external_id" IS NOT NULL)
           AND NOT ("core_erphouse"."external_id" IS NULL))
    ORDER BY "core_contractobject"."date_created" DESC
    LIMIT 1000 OFFSET 122000;
                                                                                        QUERY PLAN                                                                                    
    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     Limit  (cost=180999.91..181002.41 rows=1000 width=53) (actual time=4878.602..4878.774 rows=1000 loops=1)
       ->  Sort  (cost=180694.91..181335.71 rows=256320 width=53) (actual time=4860.597..4874.384 rows=123000 loops=1)
             Sort Key: core_contractobject.date_created DESC
             Sort Method: external merge  Disk: 19144kB
             ->  Gather  (cost=1000.43..157743.63 rows=256320 width=53) (actual time=0.679..4437.856 rows=293634 loops=1)
                   Workers Planned: 3
                   Workers Launched: 3
                   ->  Nested Loop  (cost=0.43..131111.63 rows=82684 width=53) (actual time=0.285..4492.743 rows=73408 loops=4)
                         ->  Nested Loop  (cost=0.00..77498.26 rows=82731 width=42) (actual time=0.182..3707.530 rows=73924 loops=4)
                               ->  Nested Loop  (cost=0.00..63072.75 rows=102028 width=28) (actual time=0.117..2423.461 rows=90565 loops=4)
                                     ->  Parallel Seq Scan on core_contractobject  (cost=0.00..25518.92 rows=154746 width=20) (actual time=0.025..658.361 rows=119931 loops=4)
                                           Filter: is_active
                                           Rows Removed by Filter: 112
                                     ->  Index Scan using dba_core_contract_hash_id on core_contract  (cost=0.00..0.24 rows=1 width=8) (actual time=0.011..0.011 rows=1 loops=479723)
                                           Index Cond: (id = core_contractobject.contract_id)
                                           Rows Removed by Index Recheck: 0
                                           Filter: ((((billing_id)::text = 'rb'::text) OR is_fake_flag) AND (isp_org_id = ANY ('{77,310,311}'::integer[])))
                                           Rows Removed by Filter: 0
                               ->  Index Scan using dba_auth_user_hash_id on auth_user  (cost=0.00..0.14 rows=1 width=14) (actual time=0.010..0.010 rows=1 loops=362260)
                                     Index Cond: (id = core_contract.user_id)
                                     Rows Removed by Index Recheck: 0
                                     Filter: (last_login IS NOT NULL)
                                     Rows Removed by Filter: 0
                         ->  Index Scan using core_erphouse_id_pkey on core_erphouse  (cost=0.43..0.65 rows=1 width=11) (actual time=0.010..0.010 rows=1 loops=295698)
                               Index Cond: (id = core_contractobject.house_id)
                               Filter: ((external_id IS NOT NULL) AND (external_id IS NOT NULL) AND (((external_id)::text <> ''::text) OR (external_id IS NULL)))
                               Rows Removed by Filter: 0
     Planning time: 1.408 ms
     Execution time: 4904.807 ms
    (29 rows)

Судя по строчке `Sort Method: external merge  Disk: 19144kB`, временные файлы создаются для сортировки данных.

Созданные ранее индесы типа HASH можно использовать только для присоединения таблиц в том порядке, в каком они соединялись до их создания. Подумал о том, что при наличии соответствующих индексов планировщик мог бы соединять таблицы в другом порядке. Создал соответствующие HASH-индексы, чтобы посмотреть, воспользуется ли планировщик какими-нибудь из них. И действительно, планировщик вместо индекса `dba_core_contract_hash_id` планировщик решил воспользоваться индексом `dba_core_contractobject_hash_contract_id` для соединения таблиц `core_contract` и `core_contractobject` в обратном порядке:

    smart_house_prod=# EXPLAIN ANALYZE SELECT "core_contractobject"."id",
           "core_contractobject"."contract_id",
           "core_contractobject"."house_id",
           "core_contract"."id",
           "core_contract"."user_id",
           "auth_user"."id",
           "auth_user"."username",
           "core_erphouse"."id",
           "core_erphouse"."external_id"
    FROM "core_contractobject"
    JOIN "core_contract" ON "core_contractobject"."contract_id" = "core_contract"."id"
    JOIN "auth_user" ON "core_contract"."user_id" = "auth_user"."id"
    JOIN "core_erphouse" ON "core_contractobject"."house_id" = "core_erphouse"."id"
    WHERE ("core_contract"."isp_org_id" IN (77, 310, 311)
           AND ("core_contract"."billing_id" = 'rb'
                OR "core_contract"."is_fake_flag" = true)
           AND "auth_user"."last_login" IS NOT NULL
           AND "core_erphouse"."external_id" IS NOT NULL
           AND "core_contractobject"."is_active" = true
           AND NOT ("core_erphouse"."external_id" = ''
                    AND "core_erphouse"."external_id" IS NOT NULL)
           AND NOT ("core_erphouse"."external_id" IS NULL))
    ORDER BY "core_contractobject"."date_created" DESC
    LIMIT 1000 OFFSET 122000;
                                                                                                QUERY PLAN                                                                                        
        
    --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     Limit  (cost=178654.29..178656.79 rows=1000 width=53) (actual time=2889.022..2889.443 rows=1000 loops=1)
       ->  Sort  (cost=178349.29..178990.09 rows=256321 width=53) (actual time=2850.817..2884.118 rows=123000 loops=1)
             Sort Key: core_contractobject.date_created DESC
             Sort Method: top-N heapsort  Memory: 21979kB
             ->  Gather  (cost=1000.43..155397.93 rows=256321 width=53) (actual time=0.569..2496.667 rows=293634 loops=1)
                   Workers Planned: 3
                   Workers Launched: 3
                   ->  Nested Loop  (cost=0.43..128765.83 rows=82684 width=53) (actual time=0.556..2588.157 rows=73408 loops=4)
                         ->  Nested Loop  (cost=0.00..75152.60 rows=82731 width=42) (actual time=0.490..2092.979 rows=73924 loops=4)
                               ->  Nested Loop  (cost=0.00..44863.52 rows=110887 width=22) (actual time=0.093..1216.599 rows=119858 loops=4)
                                     ->  Parallel Seq Scan on core_contract  (cost=0.00..25528.46 rows=136752 width=8) (actual time=0.027..145.599 rows=137579 loops=4)
                                           Filter: ((((billing_id)::text = 'rb'::text) OR is_fake_flag) AND (isp_org_id = ANY ('{77,310,311}'::integer[])))
                                           Rows Removed by Filter: 23166
                                     ->  Index Scan using dba_auth_user_hash_id on auth_user  (cost=0.00..0.14 rows=1 width=14) (actual time=0.006..0.006 rows=1 loops=550315)
                                           Index Cond: (id = core_contract.user_id)
                                           Rows Removed by Index Recheck: 0
                                           Filter: (last_login IS NOT NULL)
                                           Rows Removed by Filter: 0
                               ->  Index Scan using dba_core_contractobject_hash_contract_id on core_contractobject  (cost=0.00..0.26 rows=1 width=20) (actual time=0.006..0.006 rows=1 loops=479430)
                                     Index Cond: (contract_id = core_contract.id)
                                     Rows Removed by Index Recheck: 0
                                     Filter: is_active
                         ->  Index Scan using core_erphouse_id_pkey on core_erphouse  (cost=0.43..0.65 rows=1 width=11) (actual time=0.006..0.006 rows=1 loops=295698)
                               Index Cond: (id = core_contractobject.house_id)
                               Filter: ((external_id IS NOT NULL) AND (external_id IS NOT NULL) AND (((external_id)::text <> ''::text) OR (external_id IS NULL)))
                               Rows Removed by Filter: 0
     Planning time: 1.291 ms
     Execution time: 2893.337 ms
    (28 rows)

Что любопытно, при этом изменился и алгоритм сортировки результатов: `Sort Method: top-N heapsort  Memory: 21979kB`. Как видно, теперь сортировка происходит в оперативной памяти, без использования временных файлов. Не нашёл толкового описания этого алгоритма сортировки. Насколько я понимаю, из в процессе сканирования таблиц в оперативную память помещаются первые 123000 строчек, а последующие строчки либо вытесняют из оперативной памяти уже имеющиеся, либо отбрасываются, так что к концу сканирования в оперативной памяти остаются только последние 123000 строчек из выборки, упорядоченные по полю даты. Дале из этих результатов берутся только 1000 последних строчек и возвращаются в качестве результата.

Таким образом, из всех созданных пробных индексов можно оставить только один `dba_core_contractobject_hash_contract_id`:

    CREATE INDEX dba_core_contractobject_hash_contract_id ON core_contractobject USING HASH (contract_id);

А использовавшийся прежде индекс `dba_core_contract_hash_id` можно удалить:

    DROP INDEX dba_core_contract_hash_id;
