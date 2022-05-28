Ускорение запросов LIKE с % в начале шаблона в PostgreSQL
=========================================================

Для ускорения обработки запросов воспользуемся расширением `pg_trgm` и индексами GIN или GiST.

Включение расширения trgm
-------------------------

Для начала подключимся к базе данных:

    $ psql -d db

И проверим, какие расширения в ней включены:

    \dx

Проверить наличие необходимого расширения можно также с помощью следующего запроса:

    SELECT *
    FROM pg_available_extensions
    WHERE name LIKE '%trgm%';

Включаем расширение `pg_trgm`:

    CREATE EXTENSION pg_trgm IF NOT EXISTS pg_trgm;

Добавление индекса
------------------

В моём случае проблемный запрос выглядел следующим образом:

    SELECT "content_material"."id"
    FROM "content_material"
    WHERE "content_material"."is_active" = true AND
          "content_material"."status" = 3 AND
          "content_material"."actual_date" <= '2022-04-18T09:05:07.470754+00:00'::timestamptz AND
         (UPPER("content_material"."name"::text) LIKE UPPER('%погода%') OR
          UPPER("content_material"."name"::text) LIKE UPPER('%телеверсия%') OR
          UPPER("content_material"."name"::text) LIKE UPPER('%обзор%'))
    ORDER BY "content_material"."actual_date" DESC

Для ускорения выполнения запроса добавим индекс:

    CREATE INDEX content_material_name_trgm ON content_material USING GIN (UPPER(name) gin_trgm_ops);

Проверить, что запрос будет использоваться при выполнении запроса, можно с помощью ключевого слова EXPLAIN, отображающего план выполнения запроса:

    EXPLAIN SELECT "content_material"."id" FROM "content_material" WHERE ("content_material"."is_active" = true AND "content_material"."status" = 3 AND "content_material"."actual_date" <= '2022-04-18T09:05:07.470754+00:00'::timestamptz AND (UPPER("content_material"."name"::text) LIKE UPPER('%погода%') OR UPPER("content_material"."name"::text) LIKE UPPER('%телеверсия%') OR UPPER("content_material"."name"::text) LIKE UPPER('%обзор%'))) ORDER BY "content_material"."actual_date" DESC;
                                                                               QUERY PLAN                                                                           
    ----------------------------------------------------------------------------------------------------------------------------------------------------------------
     Sort  (cost=343.30..343.34 rows=14 width=12)
       Sort Key: actual_date DESC
       ->  Bitmap Heap Scan on content_material  (cost=288.11..343.03 rows=14 width=12)
             Recheck Cond: ((upper((name)::text) ~~ '%ПОГОДА%'::text) OR (upper((name)::text) ~~ '%ТЕЛЕВЕРСИЯ%'::text) OR (upper((name)::text) ~~ '%ОБЗОР%'::text))
             Filter: (is_active AND (actual_date <= '2022-04-18 14:05:07.470754+05'::timestamp with time zone) AND (status = 3))
             ->  BitmapOr  (cost=288.11..288.11 rows=14 width=0)
                   ->  Bitmap Index Scan on content_material_name_trgm  (cost=0.00..84.03 rows=5 width=0)
                         Index Cond: (upper((name)::text) ~~ '%ПОГОДА%'::text)
                   ->  Bitmap Index Scan on content_material_name_trgm  (cost=0.00..132.03 rows=5 width=0)
                         Index Cond: (upper((name)::text) ~~ '%ТЕЛЕВЕРСИЯ%'::text)
                   ->  Bitmap Index Scan on content_material_name_trgm  (cost=0.00..72.03 rows=5 width=0)
                         Index Cond: (upper((name)::text) ~~ '%ОБЗОР%'::text)
    (12 rows)

Как видно по строчкам `Bitmap Index Scan on content_material_name_trgm`, индекс используется трижды. Затем битовые карты страниц, содержащих интересующие слова, объединяются с помощью операции `BitmapOr`, после чего происходит фильтрация искомых данных из страниц, отобранных в соответствии с итоговой битовой картой.

Использованные материалы
------------------------

* [PostgreSQL LIKE query performance variations](https://stackoverflow.com/questions/1566717/postgresql-like-query-performance-variations/13452528#13452528)
* [PostgreSQL 14 / Appendix F. Additional Supplied Modules / F.33. pg_trgm](https://www.postgresql.org/docs/current/pgtrgm.html)
