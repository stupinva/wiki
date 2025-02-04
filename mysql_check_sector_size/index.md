Устранение предупреждения MySQL об отстутствии прав доступа к файлу check sector size
-------------------------------------------------------------------------------------

[[!tag mysql]]

Если в конфигурации MySQL опции `innodb_flush_method` присвоено значение `O_DIRECT`, то при перезапуске MySQL можно увидеть в журналах сообщение об ошибке:

    [ERROR] InnoDB: Failed to create check sector file, errno:13 Please confirm O_DIRECT is supported and remove the file /var/lib/check_sector_size if it exists.

К счастью, это сообщение об ошибке фактически является предупреждением, т.к. не приводит к остановке MySQL. Однако, если в файле конфигурации MySQL имеются другие ошибки, то это сообщение может сбивать с толку, т.к. может быть воспринято как причина остановки MySQL.

Для исправления ошибки нужно поменять значение другой опции - `innodb_data_home_dir`. Значение этой опции должно оканчиваться символом-разделителем каталогов, вот так:

    innodb_data_home_dir = /var/lib/mysql/

При отсутствии косой черты MySQL откусывает из пути последнюю часть и пытается создать/удалить файл `/var/lib/check_sector_size` в каталоге, находящемся выше. Как правило у MySQL нет доступа к этому каталогу, из-за чего при запуске MySQL выводит указанное сообщение об ошибке. Если просто добавить в конец пути косую черту, то указанное сообщение об ошибке при перезапусках MySQL больше не выводится.

Использованние материалы
------------------------

[Bug #84488 - InnoDB: Failed to create check sector file](https://bugs.mysql.com/bug.php?id=84488)
