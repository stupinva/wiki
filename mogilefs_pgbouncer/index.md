MogileFS с поддержкой работы через PgBouncer
============================================

После [[миграции трекера MogileFS с MySQL на PostgreSQL|mogilefs_mysql_postgresql]] на сервере PostgreSQL возросло количество используемых подключений. Поскольку каждое подключение обслуживается отдельным процессом PostgreSQL, для которого выделяются буферы `work_mem` и `temp_buffers`, возрастает потребление оперативной памяти. Для экономии оперативной памяти можно воспользоваться PgBouncer, который позволяет экономить подключения к серверу PostgreSQL за счёт повторного использования одного и того же процесса для обслуживания запросов, поступающих из разных входящих подключений. Однако при попытке переключить `mogilefsd` на работу через PgBouncer возникли проблемы.

Заготовленные запросы
---------------------

Драйвер `DBD::Pg`, используемый трекером MogieFS, при подключении к PostgreSQL версии 8.8 и выше автоматически использует заготовленные запросы (prepared statements). К сожалению, при использовании PgBouncer заготовка запроса и попытка использования заготовленного запроса могут попадать в разные процессы PostgreSQL, из-за чего заготовленные запросы будут завершаться ошибкой.

В драйвере `DBD::Pg` имеется опция [pg_server_prepare](https://metacpan.org/pod/DBD::Pg#pg_server_prepare-(boolean)), позволяющая отключить использование заготовленных запросов. К сожалению, её нельзя указать в строке DSN с настройками подключения и поэтому не получится указать в файле конфигурации трекера MogileFS. Для того, чтобы отключить использование заготовленных запросов, придётся отредактировать исходные тексты трекера MogileFS. Интересующий нас фрагмент находится в файле [MogileFS::Store](https://github.com/mogilefs/MogileFS-Server/blob/master/lib/MogileFS/Store.pm#L382). Строка 382 выглядит следующим образом:

    sqlite_use_immediate_transaction => 1,

Добавим сразу за ней такую строчку:

    pg_server_prepare => 0,

Аналогичные исправления нужно внести в исходные тексты `mogstats`. Интересующий нас фрагмент находится в одноимённом файле [mogstats](https://github.com/mogilefs/MogileFS-Utils/blob/master/mogstats#L312). Строчка 312 выглядит следующим образом:

    RaiseError => 1,

Добавим сразу за ней строчку:

    pg_server_prepare => 0,

Рекомендательные блокировки
---------------------------

Если ограничиться описанным выше исправлением, то в журнале сервера PostgreSQL периодически будут появляться ошибки следующего вида:

    [local] WARNING:  you don't own a lock of type ExclusiveLock

Оказалось, что в модуле `MogileFS::Store::Postgres` используются рекомендательные блокировки (advisory locks). Если заглянуть в исходные тексты модуля [MogileFS::Store::Postgres](https://github.com/mogilefs/MogileFS-Server/blob/master/lib/MogileFS/Store/Postgres.pm), то можно обнаружить, что в нём используются функции PostgreSQL `pg_try_advisory_lock` и `pg_advisory_unlock`. Обе эти функции не блокируют доступ к каким-либо объектам в самой базе данных, а являются просто удобным механизмом синхронизации частей приложения, работающих на разных серверах, но использующих одну и ту же базу данных. Первая функция принимает идентификатор блокировки, который может состоять из одного или двух чисел и создаёт блокировку с указанным идентификатором. Блокировка действует до её снятия с помощью второй функции, либо до конца подключения.

Возникающая проблема хорошо описана в статье [The Pitfall of Using PostgreSQL Advisory Locks with Go's DB Connection Pool](https://engineering.qubecinema.com/2019/08/26/unlocking-advisory-locks.html). освбодить блокировку можно только из того же процесса PostgreSQL, в котором она была создана. Поскольку PgBouncer может направлять запросы из входящих подключений в разные процессы PostgreSQL, попытка снять блокировку из другого процесса приведёт к возникновению приведённой выше ошибки: блокировка принадлежит другому процессу и поэтому не снимается.

Я снова обратился к исходным текстам MogileFS, для чего сначала получил исходные тексты из репозитория:

    $ git clone https://github.com/mogilefs/MogileFS-Server

Перешёл в каталог с репозиторием:

    $ cd MogileFS-Server

И переключился на используемую мной версию 2.70:

    $ git checkout 2.70

Я просмотрел историю изменений модуля `MogileFS::Store::Postgres` следующим образом:

    $ git log -p lib/MogileFS/Store/Postgres.pm

Оказалось, что до того, как в трекере начали использоваться рекомендательные блокировки (advisory locks), тот же функционал был реализован с использованием таблицы `lock`. Для возврата нужно откатить две фиксации, одна из которых заменяет использование таблицы `lock` на рекомендательные блокировки, а вторая исправляет ошибку, добавленную первой фиксацией. Для начала я сформировал заплатку с изменениями:

    $ git diff -R ac5534a0c3d046e660fa7581c9173857f182bd81 21a66942fde3bb4f9e5ee24dac787d3c9ebbb41f lib/MogileFS/Store/Postgres.pm > mogilefs_without_pg_advisory_locks.patch

Применить эти изменения к исходным текстам можно следующим образом:

    $ patch -p1 < mogilefs_without_pg_advisory_locks.patch

Статистика дисков
-----------------

В выводе команды `mogadm device list` могут отображаться не верные данные. Эти данные берутся из таблицы device, которая по каким-то причинам не обновляется. В журнале трекера можно найти следующие ошибки:

    Mar 19 14:56:42 mogilefs-tracker-2 mogilefsd[8211]: crash log: DBD::Pg::db do failed: ERROR:  smallint out of range at /usr/share/perl5/MogileFS/Store.pm line 1886.#012 at /usr/share/perl5/MogileFS/Worker/Delete.pm line 189
    Mar 19 14:56:43 mogilefs-tracker-2 mogilefsd[8199]: Child 8211 (delete) died: 256 (UNEXPECTED)
    Mar 19 14:56:43 mogilefs-tracker-2 mogilefsd[8199]: Job delete has only 0, wants 1, making 1.

Исправить проблему можно изменив тип поля `failcount` в таблице `file_to_delete2` со `smallint` на `integer` с помощью следующего запроса:

    ALTER TABLE file_to_delete2 ALTER COLUMN failcount SET DATA TYPE integer;

Чтобы таблица `file_to_delete2` сразу создавалась с полем `failcount` типа `integer`, поправим исходные тексты. Интересующий нас фрагмент находится в файле [lib/MogileFS/Store](https://github.com/mogilefs/MogileFS-Server/blob/master/lib/MogileFS/Store.pm#L813). В строке 813 поле `failcount` имеет тип `TINYINT`:

    failcount TINYINT UNSIGNED NOT NULL default '0',

Заменим тип поля на `INT`, так что строка примет следующий вид:

    failcount INT UNSIGNED NOT NULL default '0',

Также утилита `mogstats` не выводит статистику по дискам, на которых нет файлов. Интересующая нас фрагмент находится в файле [mogstats](https://github.com/mogilefs/MogileFS-Utils/blob/master/mogstats#L410). Строка 410 выглядит следующим образом:

    my $stats = $dbh->selectall_arrayref('SELECT devid, COUNT(devid) FROM file_on GROUP BY 1');

Заменим в ней запрос, так чтобы строчка приняла следующий вид:

    my $stats = $dbh->selectall_arrayref('SELECT device.devid, COUNT(file_on.devid) FROM device LEFT JOIN file_on ON file_on.devid = device.devid WHERE device.status = \'alive\' GROUP BY 1;');

Теперь можно приступить к сборке доработанного deb-пакета.

Настройка виртуальной машины
----------------------------

Для сборки настроим виртуальную машину, аналогичную используемой на том сервере, где установлен трекер MogileFS. В рассматриваемом примере это система Debian 7.11.0 с кодовым именем Wheezy. Получить образ установочного диска можно по ссылке [debian-7.11.0-amd64-netinst.iso](http://cdimage.debian.org/cdimage/archive/7.11.0/amd64/iso-cd/debian-7.11.0-amd64-netinst.iso).

Настройка репозиториев
----------------------

Для настройки репозиториев поместим в файл `/etc/apt/sources.list` следующие строки:

    deb http://archive.debian.org/debian/ wheezy main contrib non-free
    deb http://archive.debian.org/debian-security/ wheezy/updates main contrib non-free
    deb http://archive.debian.org/debian/ wheezy-backports main contrib non-free

Поскольку мы установили устаревший релиз, отключим проверку актуальности репозиториев, создав файл `/etc/apt/apt.conf.d/valid` со следующим содержимым:

    Acquire::Check-Valid-Until "false";

Отключаем установку предлагаемых зависимостей, создав файл `/etc/apt/apt.conf.d/suggests` со следующим содержимым:

    APT::Install-Suggests "false";

Отключаем установку рекомендуемых зависимостей, создав файл `/etc/apt/apt.conf.d/recommends` со следующим содержимым:

    APT::Install-Recommends "false";

Система apt сохраняет скачанные пакеты в каталоге `/var/cache/apt/archives/`, чтобы при необходимости не скачивать их снова. Файлы в этом каталоге по умолчанию не удаляются, что может привести к переполнению диска. Чтобы отключить размер файлов в этом каталоге 200 мегабайтами, создадим файл `/etc/apt/apt.conf.d/cache` со следующим содержимым:

    APT::Cache-Limit "209715200";

Создадим файл `/etc/apt/apt.conf.d/timeouts` с настройками таймаутов обращения к репозиториям:

    Acquire::http::Timeout "5";
    Acquire::https::Timeout "5";
    Acquire::ftp::Timeout "5";

При необходимости, если репозитории доступны через веб-прокси, можно создать файл `/etc/apt/apt.conf.d/proxy`, прописав в него прокси-серверы для протоколов HTTP, HTTPS и FTP:

    Acquire::http::Proxy "http://10.0.25.3:8080";
    Acquire::https::Proxy "http://10.0.25.3:8080";
    Acquire::ftp::Proxy "http://10.0.25.3:8080";

Обновим список пакетов, доступных через репозиторий:

    # apt-get update

Обновим систему с использованием самых свежих пакетов, доступных через репозитории:

    # apt-get upgrade
    # apt-get dist-upgrade

Установка пакетов
-----------------

Установим пакеты, необходимые для сборки:

    # apt-get install dpkg-dev devscripts libparse-debcontrol-perl quilt fakeroot build-essential:native debhelper debconf perl sysstat libstring-crc32-perl libperlbal-perl libio-aio-perl libdbd-mysql-perl libdbi-perl libnet-netmask-perl libwww-perl libdanga-socket-perl libsys-syscall-perl libfile-fcntllock-perl git

Сборка клиента
--------------

Скачиваем репозитории с исходниками клиентской библиотеки MogileFS:

    $ GIT_SSL_NO_VERIFY=yes git clone https://github.com/mogilefs/perl-MogileFS-Client

Перейдём в каталог с получеными исходным текстами:

    $ cd perl-MogileFS-Client

И переключимся на используемую на сервере версию 2.16:

    $ git checkout 1.16

Меняем уровень совместимости для утилиты `debhelper`:

    $ echo -n "7" > debian/compat

Исправим в файле `changelog` номер версии, отредактировав этот файл с помощью команды `dch -i`, добавив в его начало дополнительную запись:

    libmogilefs-perl (1.16) UNRELEASED; urgency=low
    
      * Building version 1.16.
    
     -- Vladimir Stupin <stupin_v@ufanet.ru>  Wed, 20 Mar 2024 11:52:35 +0500

Выполняем сборку пакета с исходниками и двоичного пакета:

    $ dpkg-buildpackage -us -uc -rfakeroot

В вышестоящем каталоге появятся следующие файлы с результатами сборки:

* [[libmogilefs-perl_1.16_all.deb]]
* [[libmogilefs-perl_1.16_amd64.changes]]
* [[libmogilefs-perl_1.16.dsc]]
* [[libmogilefs-perl_1.16.tar.gz]]

Эти файлы можно поместить в репозиторий, например, с помощью утилиты `aptly`.

Доработка и сборка пакета с сервером
------------------------------------

Скачиваем репозитории с исходниками сервера MogileFS:

    $ GIT_SSL_NO_VERIFY=yes git clone https://github.com/mogilefs/MogileFS-Server

Перейдём в каталог с получеными исходным текстами:

    $ cd MogileFS-Server

И переключимся на используемую на сервере версию 2.70:

    $ git checkout 2.70

Подготовим описанную выше заплатку, если она ещё не подготовлена:

    $ git diff -R ac5534a0c3d046e660fa7581c9173857f182bd81 21a66942fde3bb4f9e5ee24dac787d3c9ebbb41f lib/MogileFS/Store/Postgres.pm > ../mogilefs_without_pg_advisory_locks.patch

Начинаем добавление новой заплатки с названием `revert_pg_advisory_revert`:

    $ quilt new pg_advisory_locks_revert

Добавляем отслеживание в заплатке файла `lib/MogileFS/Store/Postgres.pm`:

    $ quilt add lib/MogileFS/Store/Postgres.pm

Вносим в файл `lib/MogileFS/Store/Postgres.pm` изменения, отменяющие использование Advisory Locks из PostgreSQL:

    $ patch -p1 < ../mogilefs_without_pg_advisory_locks.patch

Вносим изменения в патч:

    $ quilt refresh

Начинаем добавление новой заплатки с названием `pg_server_prepare_disabled`:

    $ quilt new pg_server_prepare_disabled

Добавляем в заплатку отслеживание изменений в файле `lib/MogileFS/Store.pm`:

    $ quilt add lib/MogileFS/Store.pm

Редактируем файл `lib/MogileFS/Store.pm`, за строкой 380 с текстом `sqlite_use_immediate_transaction => 1,` добавляем строку `pg_server_prepare => 0,`.

Вносим изменения в патч:

    $ quilt refresh

Начинаем добавление новой заплатки с названием `file_to_delete2_failcount_int`:

    $ quilt new file_to_delete2_failcount_int

Добавляем в заплатку отслеживание изменений в файле `lib/MogileFS/Store.pm`:

    $ quilt add lib/MogileFS/Store.pm

Откроем файл `lib/MogileFS/Store` на редактирвоание, перейдём к строчке 813, которая имеет вид:

    failcount TINYINT UNSIGNED NOT NULL default '0',

Заменим тип поля на `INT`, так что строка примет следующий вид:

    failcount INT UNSIGNED NOT NULL default '0',

Вносим изменения в патч:

    $ quilt refresh

Запускаем утилиту `dch` для обновления журнала изменений пакета:

    $ dch -i

Вводим описание доработанной нами версии пакета:

    mogilefs-server (2.70+ufanet2) UNRELEASED; urgency=low
    
      * Revert usage of PostgreSQL advisory locks to support PgBouncer,
      * Disabled option pg_server_prepare to support PgBouncer.
      * Type of field failcount in table file_to_delete2 changed from TINYINT to INT.
    
     -- Vladimir Stupin <stupin_v@ufanet.ru>  Wed, 20 Mar 2024 14:43:44 +0500

Меняем уровень совместимости для утилиты `debhelper`:

    $ echo -n "7" > debian/compat

Выполняем сборку доработанного deb-пакета:

    $ dpkg-buildpackage -us -uc -rfakeroot

В результате в каталоге выше должны появиться следующие файлы:

* [[mogilefsd_2.70+ufanet2_all.deb]]
* [[mogilefs-server_2.70+ufanet2_amd64.changes]]
* [[mogilefs-server_2.70+ufanet2.dsc]]
* [[mogilefs-server_2.70+ufanet2.tar.gz]]
* [[mogstored_2.70+ufanet2_all.deb]]

Эти файлы можно поместить в репозиторий, например, с помощью утилиты `aptly`.

Доработка и сборка пакета с утилитами
-------------------------------------

Устанавливаем в систему пакет `libmogilefs-perl`, собранный нами ранее:

    # dpkg -i libmogilefs-perl_1.16_all.deb

Скачиваем репозитории с исходниками утилит MogileFS:

    $ GIT_SSL_NO_VERIFY=yes git clone https://github.com/mogilefs/MogileFS-Utils

Перейдём в каталог с получеными исходным текстами:

    $ cd MogileFS-Utils

И переключимся на используемую на сервере версию 2.28:

    $ git checkout 2.28

Начинаем добавление новой заплатки с названием `pg_server_prepare_disabled`:

    $ quilt new pg_server_prepare_disabled

Добавляем в заплатку отслеживание изменений в файле `mogstats`:

    $ quilt add mogstats

Редактируем файл `mogstats`, за строкой 312 с текстом `RaiseError => 1,` добавляем строку `pg_server_prepare => 0,`.

Вносим изменения в патч:

    $ quilt refresh

Начинаем добавление новой заплатки с названием `listing_devices_without_files`:

    $ quilt new listing_devices_without_files

Добавляем в заплатку отслеживание изменений в файле `mogstats`:

    $ quilt add mogstats

Откроем файл `mogstats` для редактирования, перейдём к строке 411:

    my $stats = $dbh->selectall_arrayref('SELECT devid, COUNT(devid) FROM file_on GROUP BY 1');

Заменим в ней запрос, так чтобы строчка приняла следующий вид:

    my $stats = $dbh->selectall_arrayref('SELECT device.devid, COUNT(file_on.devid) FROM device LEFT JOIN file_on ON file_on.devid = device.devid WHERE device.status = \'alive\' GROUP BY 1');

Вносим изменения в патч:

    $ quilt refresh

Запускаем утилиту `dch` для обновления журнала изменений пакета:

    $ dch -i

Вводим описание доработанной нами версии пакета:

    mogilefs-utils (2.28+ufanet2) UNRELEASED; urgency=low
    
      * Disabled option pg_server_prepare to support PgBouncer in mogstats.
      * Added listing devices without files in mogstats.
    
     -- Vladimir Stupin <stupin_v@ufanet.ru>  Wed, 20 Mar 2024 12:48:41 +0500

Меняем уровень совместимости для утилиты `debhelper`:

    $ echo -n "7" > debian/compat

Выполняем сборку доработанного deb-пакета:

    $ dpkg-buildpackage -us -uc -rfakeroot

В результате в каталоге выше должны появиться следующие файлы:

* [[mogilefs-utils_2.28+ufanet2_all.deb]]
* [[mogilefs-utils_2.28+ufanet2_amd64.changes]]
* [[mogilefs-utils_2.28+ufanet2.dsc]]
* [[mogilefs-utils_2.28+ufanet2.tar.gz]]

Эти файлы можно поместить в репозиторий, например, с помощью утилиты `aptly`.

Дополнительные материалы
------------------------

* [Миграция трекера MogileFS с MySQL на PostgreSQL](mogilefs_mysql_postgresql)
* [Настройка PgBouncer](postgresql_pgbouncer)
* [Настройка буферов PostgreSQL](postgresql_buffers)
* [How To Setup MogileFS](https://mogilefs.github.io/mogilefs-docs/InstallHowTo.html)
* [How To Interact with MogileFS](https://mogilefs.github.io/mogilefs-docs/CommandlineUsage.html)
