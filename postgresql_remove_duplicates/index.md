Удаление дубликатов строк в таблицах PostgreSQL
===============================================

[[!tag postgresql]]

Возникла задача перенести БД Sentry на другой сервер БД PostgreSQL. При восстановлении из резервной копии возникли такие ошибки:

    ERROR:  could not create unique index "sentry_eventuser_project_id_1a96e3b719e55f9a_uniq"
    DETAIL:  Key (project_id, hash)=(92, a7f5b9c8b2869a6c9dd293bdb720bffc) is duplicated.

После заливки данных в таблицу произошла неудачная попытка создать ключ уникальности `sentry_eventuser_project_id_1a96e3b719e55f9a_uniq` из-за наличия в таблице строк с повторяющимися значениями в колонках `project_id` и `hash`.

Посмотрим в исходной БД, к каой таблице относится этот индекс:

    sentry=# \di sentry_eventuser_project_id_1a96e3b719e55f9a_uniq
                                           List of relations
     Schema |                       Name                        | Type  | Owner  |      Table       
    --------+---------------------------------------------------+-------+--------+------------------
     public | sentry_eventuser_project_id_1a96e3b719e55f9a_uniq | index | sentry | sentry_eventuser

Этот индекс относится к таблице `sentry_eventuser`. Посмотрим на её структуру:

    sentry=# \d sentry_eventuser
                                           Table "public.sentry_eventuser"
       Column   |           Type           | Collation | Nullable |                   Default                    
    ------------+--------------------------+-----------+----------+----------------------------------------------
     id         | bigint                   |           | not null | nextval('sentry_eventuser_id_seq'::regclass)
     project_id | bigint                   |           | not null | 
     ident      | character varying(128)   |           |          | 
     email      | character varying(75)    |           |          | 
     username   | character varying(128)   |           |          | 
     ip_address | inet                     |           |          | 
     date_added | timestamp with time zone |           | not null | 
     hash       | character varying(32)    |           | not null | 
     name       | character varying(128)   |           |          | 
    Indexes:
        "sentry_eventuser_pkey" PRIMARY KEY, btree (id)
        "sentry_eventuser_project_id_1a96e3b719e55f9a_uniq" UNIQUE CONSTRAINT, btree (project_id, hash)
        "sentry_eventuser_project_id_1dcb94833e2de5cf_uniq" UNIQUE CONSTRAINT, btree (project_id, ident)
        "sentry_eventuser_date_added" btree (date_added)
        "sentry_eventuser_project_id" btree (project_id)
        "sentry_eventuser_project_id_58b4a7f2595290e6" btree (project_id, ip_address)
        "sentry_eventuser_project_id_7684267daffc292f" btree (project_id, email)
        "sentry_eventuser_project_id_8868307f60b6a92" btree (project_id, username)

Проверим, действительно ли в таблице есть строки со значениями, не удовлетворяющими ключу уникальности:

    sentry=# select project_id, hash, count(*) from sentry_eventuser group by project_id, hash having count(*) > 1;
     project_id |               hash               | count 
    ------------+----------------------------------+-------
             73 | 5c709665a7fb9bd42b8324a4ccd0353f |     2
             92 | a7f5b9c8b2869a6c9dd293bdb720bffc |     7
             92 | b0f15ffa6318493fdbda8424f99de818 |     2
    (3 rows)

Как видно, такие строки действительно есть. Одна из них не просто дублируется, а существует в 7 вариантах. Не знаю, как это произошло, но это нужно исправить. Для этого воспользуемся колонкой `id`, значения которой используются в качестве суррогатного ключа.  Оставим в таблице только строки с наибольшим значением суррогатного ключа. Сначала посмотрим на строки, которые собираемся удалять:

    sentry=# select a.id, a.project_id, a.hash from sentry_eventuser as a join sentry_eventuser as b on a.project_id = b.project_id and a.hash = b.hash and a.id < b.id;
       id    | project_id |               hash               
    ---------+------------+----------------------------------
     3767182 |         73 | 5c709665a7fb9bd42b8324a4ccd0353f
     7608719 |         92 | a7f5b9c8b2869a6c9dd293bdb720bffc
     7608718 |         92 | a7f5b9c8b2869a6c9dd293bdb720bffc
     7608720 |         92 | a7f5b9c8b2869a6c9dd293bdb720bffc
     7608722 |         92 | a7f5b9c8b2869a6c9dd293bdb720bffc
     7608721 |         92 | a7f5b9c8b2869a6c9dd293bdb720bffc
     7608724 |         92 | b0f15ffa6318493fdbda8424f99de818
     7525019 |         92 | a7f5b9c8b2869a6c9dd293bdb720bffc
    (8 rows)

Для удаления этих строк воспользуемся таким запросом:

    sentry=# delete from sentry_eventuser where id in (select a.id from sentry_eventuser as a join sentry_eventuser as b on a.project_id = b.project_id and a.hash = b.hash and a.id < b.id);
    DELETE 8

Снова проверим наличие дублирующихся строк:

    sentry=# select project_id, hash, count(*) from sentry_eventuser group by project_id, hash having count(*) > 1;
     project_id | hash | count 
    ------------+------+-------
    (0 rows)
    
    sentry=# select a.id, a.project_id, a.hash from sentry_eventuser as a join sentry_eventuser as b on a.project_id = b.project_id and a.hash = b.hash and a.id < b.id;
     id | project_id | hash 
    ----+------------+------
    (0 rows)

Дубликаты удалены. Можно попробовать снова сделать резервную копию базы данных и восстановить её.
