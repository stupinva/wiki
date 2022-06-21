Ускорение запросов с Hash Join в плане выполнения в PostgreSQL
==============================================================

[[!tag postgresql]]

Попался такой запрос, использующий временные файлы:

    SELECT COUNT(*) AS "__count"
    FROM "core_contractobject"
    INNER JOIN "core_contract" ON ("core_contractobject"."contract_id" = "core_contract"."id")
    INNER JOIN "auth_user" ON ("core_contract"."user_id" = "auth_user"."id")
    INNER JOIN "core_erphouse" ON ("core_contractobject"."house_id" = "core_erphouse"."id")
    WHERE ("core_contract"."isp_org_id" IN (77, 310, 311)
           AND ("core_contract"."billing_id" = 'rb'
                OR "core_contract"."is_fake_flag" = true)
           AND "auth_user"."last_login" IS NOT NULL
           AND "core_erphouse"."external_id" IS NOT NULL
           AND "core_contractobject"."is_active" = true
           AND NOT ("core_erphouse"."external_id" = ''
                    AND "core_erphouse"."external_id" IS NOT NULL)
           AND NOT ("core_erphouse"."external_id" IS NULL)
           AND "core_contractobject"."ucams_sync" = false);

План выполнения запроса выглядит следующим образом:

    smart_house_prod=# EXPLAIN ANALYZE SELECT COUNT(*) AS "__count"
    FROM "core_contractobject"
    INNER JOIN "core_contract" ON ("core_contractobject"."contract_id" = "core_contract"."id")
    INNER JOIN "auth_user" ON ("core_contract"."user_id" = "auth_user"."id")
    INNER JOIN "core_erphouse" ON ("core_contractobject"."house_id" = "core_erphouse"."id")
    WHERE ("core_contract"."isp_org_id" IN (77, 310, 311)
           AND ("core_contract"."billing_id" = 'rb'
                OR "core_contract"."is_fake_flag" = true)
           AND "auth_user"."last_login" IS NOT NULL
           AND "core_erphouse"."external_id" IS NOT NULL
           AND "core_contractobject"."is_active" = true
           AND NOT ("core_erphouse"."external_id" = ''
                    AND "core_erphouse"."external_id" IS NOT NULL)
           AND NOT ("core_erphouse"."external_id" IS NULL)
           AND "core_contractobject"."ucams_sync" = false);
                                                                                   QUERY PLAN                                                                               
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     Finalize Aggregate  (cost=138157.46..138157.47 rows=1 width=8) (actual time=1140.386..1140.386 rows=1 loops=1)
       ->  Gather  (cost=138157.04..138157.45 rows=4 width=8) (actual time=1140.372..1151.151 rows=5 loops=1)
             Workers Planned: 4
             Workers Launched: 4
             ->  Partial Aggregate  (cost=137157.04..137157.05 rows=1 width=8) (actual time=1091.028..1091.029 rows=1 loops=5)
                   ->  Nested Loop  (cost=38681.58..137095.65 rows=24556 width=0) (actual time=1006.280..1091.025 rows=0 loops=5)
                         ->  Nested Loop  (cost=38681.15..101594.23 rows=24568 width=4) (actual time=680.063..1089.270 rows=244 loops=5)
                               ->  Hash Join  (cost=38680.73..84916.75 rows=30338 width=8) (actual time=676.084..978.456 rows=13409 loops=5)
                                     Hash Cond: (core_contractobject.contract_id = core_contract.id)
                                     ->  Parallel Seq Scan on core_contractobject  (cost=0.00..45654.46 rows=46064 width=8) (actual time=0.027..202.552 rows=36686 loops=5)
                                           Filter: (is_active AND (NOT ucams_sync))
                                           Rows Removed by Filter: 58555
                                     ->  Hash  (cost=33440.21..33440.21 rows=419241 width=8) (actual time=672.711..672.711 rows=544383 loops=5)
                                           Buckets: 1048576 (originally 524288)  Batches: 2 (originally 1)  Memory Usage: 20481kB
                                           ->  Seq Scan on core_contract  (cost=0.00..33440.21 rows=419241 width=8) (actual time=0.054..421.413 rows=544383 loops=5)
                                                 Filter: ((((billing_id)::text = 'rb'::text) OR is_fake_flag) AND (isp_org_id = ANY ('{77,310,311}'::integer[])))
                                                 Rows Removed by Filter: 92184
                               ->  Index Scan using auth_user_id_pkey on auth_user  (cost=0.42..0.55 rows=1 width=4) (actual time=0.008..0.008 rows=0 loops=67045)
                                     Index Cond: (id = core_contract.user_id)
                                     Filter: (last_login IS NOT NULL)
                                     Rows Removed by Filter: 1
                         ->  Index Scan using core_erphouse_id_pkey on core_erphouse  (cost=0.42..1.45 rows=1 width=4) (actual time=0.006..0.006 rows=0 loops=1219)
                               Index Cond: (id = core_contractobject.house_id)
                               Filter: ((external_id IS NOT NULL) AND (external_id IS NOT NULL) AND (((external_id)::text <> ''::text) OR (external_id IS NULL)))
                               Rows Removed by Filter: 0
     Planning time: 1.223 ms
     Execution time: 1151.360 ms
    (27 rows)

Внимание привлекает строчка с фрагментом `Memory Usage: 20481kB`. Попытки упросить запрос или создать дополнительные индексы для исключений последовательных сканирований успехом не увенчались - планировщик упрямо игнорировал создаваемые индексы и продолжал использовать последовательный перебор. Дело в том, что для соединения строк двух таблиц в данном случае используется созданный налету хэш-массив объёмом 20 мегабайт. Этот хэш-массив располагается в буфере `work_mem`, выделяемый для каждого установленного подключения. Размера этого буфера оказалось недостаточно для хранения хэш-массива, в результате чего PostgreSQL прибег к использованию временных файлов.

Ситуацию помог исправить дополнительный индекс типа HASH:

    CREATE INDEX core_contract_hash_id ON core_contract USING HASH (id);

После его создания план выполнения запроса изменился следующим образом:

    smart_house_prod=# EXPLAIN ANALYZE SELECT COUNT(*) AS "__count"
    FROM "core_contractobject"
    INNER JOIN "core_contract" ON ("core_contractobject"."contract_id" = "core_contract"."id")
    INNER JOIN "auth_user" ON ("core_contract"."user_id" = "auth_user"."id")
    INNER JOIN "core_erphouse" ON ("core_contractobject"."house_id" = "core_erphouse"."id")
    WHERE ("core_contract"."isp_org_id" IN (77, 310, 311)
           AND ("core_contract"."billing_id" = 'rb'
                OR "core_contract"."is_fake_flag" = true)
           AND "auth_user"."last_login" IS NOT NULL
           AND "core_erphouse"."external_id" IS NOT NULL
           AND "core_contractobject"."is_active" = true
           AND NOT ("core_erphouse"."external_id" = ''
                    AND "core_erphouse"."external_id" IS NOT NULL)
           AND NOT ("core_erphouse"."external_id" IS NULL)
           AND "core_contractobject"."ucams_sync" = false);
                                                                                      QUERY PLAN                                                                                  
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     Finalize Aggregate  (cost=127182.62..127182.63 rows=1 width=8) (actual time=608.546..608.546 rows=1 loops=1)
       ->  Gather  (cost=127182.20..127182.61 rows=4 width=8) (actual time=608.362..645.020 rows=5 loops=1)
             Workers Planned: 4
             Workers Launched: 4
             ->  Partial Aggregate  (cost=126182.20..126182.21 rows=1 width=8) (actual time=593.453..593.454 rows=1 loops=5)
                   ->  Nested Loop  (cost=0.85..126120.81 rows=24556 width=0) (actual time=593.450..593.450 rows=0 loops=5)
                         ->  Nested Loop  (cost=0.42..90620.32 rows=24568 width=4) (actual time=11.571..591.865 rows=244 loops=5)
                               ->  Nested Loop  (cost=0.00..73942.87 rows=30338 width=8) (actual time=0.166..472.952 rows=13409 loops=5)
                                     ->  Parallel Seq Scan on core_contractobject  (cost=0.00..45654.51 rows=46066 width=8) (actual time=0.027..82.091 rows=36686 loops=5)
                                           Filter: (is_active AND (NOT ucams_sync))
                                           Rows Removed by Filter: 58556
                                     ->  Index Scan using core_contract_hash_id on core_contract  (cost=0.00..0.61 rows=1 width=8) (actual time=0.009..0.009 rows=0 loops=183428)
                                           Index Cond: (id = core_contractobject.contract_id)
                                           Rows Removed by Index Recheck: 0
                                           Filter: ((((billing_id)::text = 'rb'::text) OR is_fake_flag) AND (isp_org_id = ANY ('{77,310,311}'::integer[])))
                                           Rows Removed by Filter: 1
                               ->  Index Scan using auth_user_id_pkey on auth_user  (cost=0.42..0.55 rows=1 width=4) (actual time=0.008..0.008 rows=0 loops=67043)
                                     Index Cond: (id = core_contract.user_id)
                                     Filter: (last_login IS NOT NULL)
                                     Rows Removed by Filter: 1
                         ->  Index Scan using core_erphouse_id_pkey on core_erphouse  (cost=0.42..1.44 rows=1 width=4) (actual time=0.005..0.005 rows=0 loops=1218)
                               Index Cond: (id = core_contractobject.house_id)
                               Filter: ((external_id IS NOT NULL) AND (external_id IS NOT NULL) AND (((external_id)::text <> ''::text) OR (external_id IS NULL)))
                               Rows Removed by Filter: 0
     Planning time: 1.692 ms
     Execution time: 645.172 ms
    (26 rows)

И дело не столько в том, что время выполнения уменьшилось в два раза, сколько в том, что теперь для соединения таблиц не используется созданный на лету хэш-массив. В результате удалось сэкономить пространство в буфере `work_mem` и переместить хэш-массив на диск, для работы с которым теперь будет использоваться гораздо более объёмный общий буфер `shared_buffer`. Часто используемые страницы этого индекса будут оседать в общём буфере `shared_buffer` и снижать интенсивность нагрузки на дисковую подсистему.
