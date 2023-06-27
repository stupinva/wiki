Советы и рецепты по Zabbix
==========================

[[!tag zabbix snmp mysql mysqldump freebsd]]

Правка SNMP-коммунити на обнаруженных элементах данных
------------------------------------------------------

Бывает, что нужно сменить SNMP-коммунити на устройствах, но устройство поддерживает не более одного SNMP-коммунити, так что нельзя сначала добавить новое, а потом, спустя некоторое время, удалить старое. В таких случаях на узлах с большим количеством элементов данных, созданных низкоуровневым обнаружением, из-за большого количества не отвечающих элементов данных отключаются все SNMP-проверки. Из-за этого правила низкоуровневого обнаружения тоже не отрабатывают и не могут обновить обнаруженные элементы данных. Исправить подобные проблемы можно при помощи одного SQL-запроса:

    UPDATE items
    JOIN item_discovery ON item_discovery.itemid = items.itemid
      AND item_discovery.key_ <> ''
    JOIN items AS parent ON parent.itemid = item_discovery.parent_itemid
      AND parent.status = 0
      AND parent.snmp_community <> items.snmp_community
    SET items.snmp_community = parent.snmp_community
    WHERE items.status = 0;

Запрос находит все элементы данных, созданные низкоуровневым обнаружением, и у которых SNMP-коммунити отличается от SNMP-коммунити, прописанного в прототипе элемента данных. У всех таких элементов данных SNMP-коммунити заменяется SNMP-коммунити из прототипа.

Резервное копирование и восстановление БД
-----------------------------------------

Слив неполного дампа, без таблиц истории и тенденций:

    # mysqldump --single-transaction -uzabbix -pzabbix zabbix --ignore_table=zabbix.trends_uint --ignore-table=zabbix.history_uint --ignore-table=zabbix.history --ignore-table=zabbix.trends > drs.sql

Заливаем дамп:

    > source /home/stupin/drs.sql

Решение проблемы при создании пустой БД
---------------------------------------

Проблема по ссылке [Not possible to insert create.sql.gz on MariaDB 10.3.17](https://support.zabbix.com/browse/ZBX-16465) следующего вида:

    $ zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix
    Enter password:
    ERROR 1118 (42000) at line 1278: Row size too large (> 8126). Changing some columns to TEXT or BLOB may help. In current row format, BLOB prefix of 0 bytes is stored inline.

Решается выключением режима строгой проверки вставляемых данных:

    SET SESSION innodb_strict_mode=OFF;

Установка Zabbix из порта
-------------------------

**Внимание!** В этой заметке описан процесс бэкпортирования порта с Zabbix 2.4 в более старую версию системы портов, имевшей актуальность во времена FreeBSD 8.2. Операционную систему и систему портов с момента установки на одном из серверов ни разу не обновляли, но появилась необходимость установить на сервер более свежую версию Zabbix, порт с которой был только для более свежей версии системы портов, не совместимой с системой портов на сервере.

### Получение порта

Получить отдельные порты можно следующим образом:

    $ svn checkout https://svn0.us-east.freebsd.org/ports/branches/2015Q4/net-mgmt/zabbix24-frontend/ zabbix24-frontend
    $ svn checkout https://svn0.us-east.freebsd.org/ports/branches/2015Q4/net-mgmt/zabbix24-server/ zabbix24-server
    $ svn checkout https://svn0.us-east.freebsd.org/ports/branches/2015Q4/net-mgmt/zabbix24-proxy/ zabbix24-proxy
    $ svn checkout https://svn0.us-east.freebsd.org/ports/branches/2015Q4/net-mgmt/zabbix24-agent/ zabbix24-agent

Собрать их с имеющимися старыми портами напрямую нельзя, т.к. система портов развивается и меняется формат файлов портов. Нужно адаптировать свежий только что скачанный порт к системе портов, имеющейся в системе.

### Адаптация порта

В файле Makefile заменим --with-iconv на --with-iconv=${PREFIX}

В файле Makefile убрерём во всех `LIB_DEPENDS=` префиксы lib и суффиксы .so у всех библиотек

В файле Makefile заменим все конструкции такого вида:

    MYSQL_CONFIGURE_WITH=   mysql
    MYSQL_USE=              MYSQL=yes

На конструкции следующего вида:

    .if ${PORT_OPTIONS:MMYSQL}
    ZABBIX_REQUIRE= " mysql"
    USE_MYSQL=      yes
    CONFIGURE_ARGS+=        --with-mysql
    .endif

В файлах pkg-plist и pkg-plist.agent заменим @dir на @dirrmtry

В Makefile порта zabbix24-frontend для наложения патча patch-frontend-ufanet понадобилось закомментировать опцию:

    #PATCHDIR=

### Адаптация патча (вариант 1)

Извлекаем исходники:

    $ make clean
    $ make extract

Переходим в каталог с распакованными исходниками и делаем их копию:

    $ cd work/zabbix-2.4.6
    $ cp -R src orig

Накладываем имеющийся патч:

    $ patch -Np1 --ignore-whitespace -d src < ../../files/patch-snmp-timeout

Создаём новый патч:

    $ diff -x '*.orig' -x '*.rej' -Naur orig src > ../../files/patch-snmp-timeout
    $ cd ../..

Удаляем в текстовом редакторе из получившегося патча опции -x '*.orig' -x '*.rej'

    $ vim files/pach-snmp-timeout

Затем удаляем распакованные исходники и собираем порт:

    $ make clean
    $ make

### Адаптация патча (вариант 2)

Извлекаем исходники:

    $ make clean
    $ make extract

Переходим в каталог с распакованными исходниками и делаем их копию:

    $ cd work/zabbix-2.4.6

Накладываем имеющийся патч:

    $ patch -Np1 --ignore-whitespace -d src < ../../patch-snmp-timeout

Создаём новый патч:

    $ make makepatch
    $ cd ../..

В каталоге files будут созданы файлы с именами `patch-*` для каждого изменяемого файла.

Затем удаляем распакованные исходники и собираем порт:

    $ make clean
    $ make
