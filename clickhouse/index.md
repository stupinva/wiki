Шпаргалка по ClickHouse
=======================

Просмотр текущих запросов
-------------------------

Посмотреть текущие выполняемые запросы, отсортировав их по убыванию времени выполнения и количества участвующих в запросе строк, можно при помощи следующего запроса в базе данных `system`:

    SELECT elapsed,
           total_rows_approx,
           client_name,
           client_hostname,
           user,
           query
    FROM processes
    ORDER BY elapsed, total_rows_approx DESC;
