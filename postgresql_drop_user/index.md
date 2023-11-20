Ву Дао. Как удалить пользователя/роль PostgreSQL с привилегиями
===============================================================

[[!tag postgresql]]

Это перевод статьи [Vu Dao. How To Drop A Postgres Role/User With privileges](https://dev.to/vumdao/how-to-drop-a-postgres-role-user-with-privileges-2h1i).

Проблема
--------

Не удаётся удалить роль PostgreSQL. Ошибка: не может быть удалена, потому что некоторые объекты зависят от неё

    mydatabase=# DROP USER jack;
    ERROR: role "jack" cannot be dropped because some objects depend on it
    DETAIL: owner of view jacktest_view
    owner of table jacktest
    privileges for default privileges on new relations belonging to role postgres in schema public
    
    postgres=# DROP USER jack;
    ERROR: role "jack" cannot be dropped because some objects depend on it
    DETAIL: 3 objects in database mydatabase

Просмотр привилегий
-------------------

Прежде чем перейти к решению, посмотрим список всех привилегий роли:

    mydatabase=# SELECT grantor, grantee, table_schema, table_name, privilege_type FROM information_schema.table_privileges WHERE grantee = 'jack';
     grantor | grantee | table_schema |  table_name   | privilege_type 
    ---------+---------+--------------+---------------+----------------
     jack    | jack    | public       | jacktest      | TRUNCATE
     jack    | jack    | public       | jacktest      | REFERENCES
     jack    | jack    | public       | jacktest      | TRIGGER
     jack    | jack    | public       | jacktest_view | TRUNCATE
     jack    | jack    | public       | jacktest_view | REFERENCES
     jack    | jack    | public       | jacktest_view | TRIGGER
    (6 rows)
    
    mydatabase=# \ddp+ 
                Default access privileges
      Owner   | Schema | Type  | Access privileges 
    ----------+--------+-------+--------------------- 
     postgres | public | table | readonly=r/postgres+
              |        |       | jack=arwd/postgres
    (1 row)

Быстрый способ удалить пользователя
-----------------------------------

Подключившись к базе данных по умолчанию, выполнить команды:

    postgres=# REASSIGN OWNED BY jack TO postgres;
    postgres=# DROP OWNED BY jack;

Повторить приведённые выше команды, подключившись к базам данных, показанным в сообщении `DETAIL: 3 objects in database mydatabase`:

    mydatabase=# REASSIGN OWNED BY jack TO postgres;
    mydatabase=# DROP OWNED BY jack;
    mydatabase=# DROP USER jack;

Другой способ - отзыв привилегий
--------------------------------

Так же можно сначала отозвать все привилегии из списка `privilege_type` перед тем, как удалить пользователя:

    postgres=# REVOKE TRUNCATE, REFERENCES, TRIGGER ON ALL TABLES IN SCHEMA public FROM jack;
