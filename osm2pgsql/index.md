Исправление проблемы при импорте OSM с помощью osm2pgsql
========================================================

При переходе на Jessie применил ранее отработанную процедуру импорта данных в формате OSM командой:

    $ osm2pgsql -U osm -W -sd quarters -S style.style all-quarters2.osm

Однако процесс импорта завершился таким сообщением:

    Reading in file: all-quarters.osm
    node_changed_mark failed: ОШИБКА:  подготовленный оператор "node_changed_mark" не существует
    (7)
    Arguments were: -13692, 
    Error occurred, cleaning up

Результат поиска подобных проблем в интернете привёл меня на страницу [ERROR: prepared statement "node_changed_mark" does not exist](https://github.com/openstreetmap/osm2pgsql/issues/220)

Там я нашёл решение - нужно удалить из OSM-файла аттрибуты модификации данных:

    $ sed -e "s/ action='modify'//" all-quarters.osm > all-quarters2.osm

Получившийся файл all-quarters2.osm импортируется без проблем.
