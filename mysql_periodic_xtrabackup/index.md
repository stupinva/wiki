Периодическое резервное копирование MySQL с помощью xtrabackup
==============================================================

[[!tag mysql xtrabackup backup restore]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

Периодическое резервное копирования баз данных позволяет восстановить данные в случае сбоя аппаратного или программного обеспечения, а также в случае ошибок системного администратора. В подобных случаях удобно иметь свежую резервную копию баз данных, готовую к немедленному использованию.

Подобную резервную копию можно сделать при помощи мгновенных снимков файловой системы, обновляя изменившиеся файлы с помощью утилиты `rsync`. Этот метод резервного копирования в целом совпадает с процедурой настройки реплики MySQL, описанной в статье [[Настройка реплики MySQL с помощью снимков LVM и rysnc|mysql_slave_lvm_rsync]].

Также подобную резервную копию можно подготовить с помощью утилиты `xtrabackup`. 

Полное резервное копирование
----------------------------

Создаём полную резервную копию:

    # xtrabackup --backup --open-files-limit=100000 --target-dir=/backup/db

Готовим полную резервную копию:

    # xtrabackup --prepare --apply-log-only --target-dir=/backup/db

К сожалению, подготовка полной резервной копии с помощью утилиты `xtrabackup` занимает больше времени, чем обновление резервной копии описанным выше способом.

Обновление полной резервной копии
---------------------------------

Утилита `xtrabackup` позволяет создавать не только полную резервную копию, но и инкрементную, в которую будут помещены только те страницы, которые изменились в текущих файлах баз данных по сравнению с резервной копией. Затем эту инкрементную резервную копию можно использовать для обновления полной резервной копии. Подробнее создание инкрементных резервных копий описано в статье [Incremental Backup](https://docs.percona.com/percona-xtrabackup/2.4/backup_scenarios/incremental_backup.html).

Делаем инкрементальную резервную копию в отдельный каталог:

    # xtrabackup --backup --open-files-limit=100000 --target-dir=/backup/inc --incremental-basedir=/backup/db

Применяем инкрементальную резервную копию к полной подготовленной:

    # xtrabackup --prepare --apply-log-only --target-dir=/backup/db --incremental-dir=/backup/inc

Однако проблема в том, что для создания инкрементной резервной копии `xtrabackup` фактически выполняет сравнение файлов в существующей резервной копии с текущими файлами баз данных, что занимает почти столько же времени, сколько требуется для создания полной резервной копии.

Ускорение обновления полной резервной копии
-------------------------------------------

К счастью, для ускорения периодического резервного копирования можно воспользоваться битовыми картами для отслеживания изменённых страниц, которые описаны в статьях [XtraDB changed page tracking](https://www.percona.com/doc/percona-server/5.6/management/changed_page_tracking.html) и [XtraDB changed page tracking](https://docs.percona.com/percona-server/5.7/management/changed_page_tracking.html).

Для этого нужно прописать в файл конфигурации Percona Server опцию:

    innodb_track_changed_pages = ON

Для вступления настроек в силу потребуется перезапустить сервер MySQL:

    # systemctl restart mysql

При включении этой опции в каталоге с данными начнут создаваться файлы с именами вида `ib_modified_log_<seq>_<startlsn>.xdb`, где `seq` - порядковый номер файла, а `startlsn` соответствует номеру транзакции в журнале изменений. По умолчанию эти файлы будут иметь размер до 100 мегабайт. Чтобы уменьшить их количество, я прописал в файл конфигурации дополнительную опцию:

    innodb_max_bitmap_file_size = 512M

К сожалению файлы битовых карт изменённых страниц не удаляются автоматически. Чтобы не засорять диск, нужно периодически удалять файлы, ставшие ненужными.

Удаление устаревших файлов битовых карт
---------------------------------------

В каталоге с резервной копией имеется файл `xtrabackup_checkpoints`, в котором имеются строка следующего вида:

    to_lsn = 1291135

Число в этой строке соответствует номеру последней транзакции в журнале изменений, которая была зафиксирована в резервной копии. Все файлы битовых карт до этого номера можно удалить без ущерба для создания последующих инкрементных резервных копий.

Для этого после выполнения резервного копирования можно выполнить команду следующего вида:

    # awk '/^to_lsn = / { print "PURGE CHANGED_PAGE_BITMAPS BEFORE " $3 ";"; }' /backup/db/xtrabackup_checkpoints | mysql

Скрипт резервного копирования
-----------------------------

Для автоматизации резервного копирования описанным выше способом я написал скрипт [[xtrabackup2.sh]]. Настроить скрипт можно с помощью файла конфигурации `/etc/xtrabackup2.conf`, внутри которого имеются следующие настройки:

* `BACKUP_PATH` - путь к каталогу с полной резервной копией,
* `EXCLUDE_TABLES` - список таблиц, которые не следует помещать в резервную копию,
* `RSERVER` - доменное имя или IP-адрес удалённого сервера, на который нужно скопировать архив с резервной копией,
* `RPATH` - путь к файлу архива на удалённом сервере,
* `RUSER` - имя пользователя на удалённом сервере,
* `RKEY` - путь к приватному ключу пользователя на удалённом сервере для подключения по SSH,
* `DAYS` - сколько архивов с резервной копией необходимо сохранять локально.

Внутри каталога, заданного переменной `BACKUP_PATH`, создаётся подкаталог `db` с резервной копией базы данных. При обновлении этой резервной копии создаётся каталог `inc`, в котором размещается инкрементальная резервная копия. Если резервная копия создана или обновлена успешно, то внутри каталога создаётся файл `ok`. Перед резервным копированием файл `ok` удаляется, в процессе резервного копирования вывод утилиты `xtrabackup` помещается в файл `log`. Если `xtrabackup` завершился успешно, то файл `log` удаляется и создаётся файл `ok`. В противном случае файл `log` остаётся для выяснения причин проблемы резервного копирования, а файл `ok` не создаётся. При отсутствии файла `ok` выполняется полное резервное копирование.

Архив с резервной копией отправляется на удалённый сервер только если определены все четыре опции `RSERVER`, `RPATH`, `RUSER` и `RKEY`.

Опция `DAYS` используется только в том случае, если архив с резервной копией не отправляется на удалённый сервер. В этом случае в каталоге `BACKUP_PATH` поддерживается указанное в переменной количество архивов с содержимым каталога `db`, имеющих имена вида `db_YYYYMMDD.tbz`, где символы `YYYY` соответствуют году, `MM` - номеру месяца, `DD` - числу месяца создания архива. Впрочем, логику работы скрипта можно поменять, отредактировав его.
