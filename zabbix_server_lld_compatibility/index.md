Совместимость сервера Zabbix 3.4 с агентами версий 4.2 и выше
=============================================================

[[!tag zabbix debian buster]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

Чтобы идти в ногу со временем, стоит своевременно обновлять программное обеспечение. Однако при обновлении может возникать множество проблем из-за несовместимости новой версии программного обеспечения с экосистемой, построенной вокруг этого программного обеспечения. В случае с программным обеспечением с открытыми исходными текстами положение дополнительно может осложняться ещё и тем, что в используемое программное обеспечение могли быть внесены собственные доработки. Чтобы продлить жизнь программного обеспечения, часто прибегают к так называемому бэкпортированию - переносу некоторых функций из более новых версий программного обеспечения в предыдущие.

В Zabbix-агенте и сервере, начиная с версии 4.2, изменилась структура JSON, используемая элементами данных низкоуровневого обнаружения. Теперь возвращаемые данные больше не помещаются вовнутрь структуры `{"data": [...]}`, а возвращаются как есть, в виде массива `[...]`.

В документации [Руководство по Zabbix / Низкоуровневое обнаружение (LLD) / Низкоуровневое обнаружение (LLD)](https://www.zabbix.com/documentation/current/ru/manual/discovery/low_level_discovery) об этом написано следующее:

> Обратите внимание, что начиная с Zabbix 4.2 формат JSON, возвращаемого правилами низкоуровневого обнаружения, изменился. Более не ожидается, что JSON будет содержать объект "data". Чтобы поддерживать новые возможности - такие как предобработку значений элементов данных и пользовательские пути к значениям LLD-макросов в документе JSON, - правила LLD теперь будут воспринимать обычный JSON, содержащий массив.

> ...

> Хотя элемент "data" был убран из всех собственных элементов данных, относящихся к обнаружению, в целях обратной совместимости Zabbix всё ещё будет воспринимать нотацию JSON с элементом "data", хотя его использование не рекомендуется. Если JSON содержит объект только с одним элементом "data" (массивом), то будет автоматически извлекаться содержимое этого элемента, используя JSONPath $.data. Низкоуровневое обнаружение теперь воспринимает необязательные определённые пользователем LLD-макросы, с настраиваемым путём, указанным с помощью синтаксиса JSONPath.

В этой статье пойдёт речь о поддержании совместимости Zabbix 3.4 с Zabbix-агентами версий 4.2 и выше, а также о совместимости со скритами низкоуровневого обнаружения, возвращающими простой массив без обёртки в хэш-массив с ключом "data".

Подгототовка к сборке
---------------------

Установим в систему пакеты, которые понадобятся для доработки исходных текстов и доработки пакета:

    # apt-get install vim dpkg-dev devscripts quilt

Я пользуюсь редактором `vim`, поэтому он тоже фигурирует в этом списке.

Установим в систему пакеты, необходимые для сборки и работы пакетов Zabbix:

    # apt-get build-dep zabbix=1:3.4.12-1+buster-stupin1

Как видно, в качестве основы для доработки будем использовать пакет версии 3.4.12-1+buster-stupin1. В этом пакете уже имеются другие мои заплатки, к которым я добавлю ещё одну.

Теперь скачаем и распакуем исходные тексты пакета версии 3.4.12-1+buster-stupin1:

    $ apt-get source zabbix=1:3.4.12-1+buster-stupin1

Перейдём в каталог с распакованными исходными текстами пакета:

    $ cd zabbix-3.4.12-1+buster

Исправление исходных текстов
----------------------------

Идею для заплатки подсмотрим в исходных текстах Zabbix версии 6.4 в файле [src/zabbix_server/lld/lld.c](https://git.zabbix.com/projects/ZBX/repos/zabbix/browse/src/zabbix_server/lld/lld.c?at=refs%2Fheads%2Frelease%2F6.4) в функции lld_rows_get:

    	if ('[' == *jp.start)
    	{
    		jp_array = jp;
    	}
    	else if (SUCCEED != zbx_json_brackets_by_name(&jp, ZBX_PROTO_TAG_DATA, &jp_array))	/* deprecated */
    	{
    		*error = zbx_dsprintf(*error, "Cannot find the \"%s\" array in the received JSON object.",
    				ZBX_PROTO_TAG_DATA);
    		goto out;
   	}
    
    

Как видно, перед разбором JSON с информацией об обнаруженных элементах, делается проверка - начинается ли эта структура с открывающейся квадратной скобки. Если она начинается с квадратной скобки, то это формат версии Zabbix 4.2 и выше. Этот формат соответствует простому массиву с макросами. В противном случае считается, что это устаревший формат Zabbix версии до 4.2. В этом формате массив помещается вовнутрь хэш-массива в качестве значения ключа "data".

Создадим новую заплатку:

    $ quilt new zabbix3_4_12_support_both_lld_formats.patch

Укажем, что в заплатке отслеживаются изменения в файле `src/libs/zbxdbhigh/lld.c`:

    $ quilt add src/libs/zbxdbhigh/lld.c

Доработаем в этом файле функцию `lld_rows_get` так же, как и в версии 6.4:

    Index: zabbix-3.4.12-1+buster/src/libs/zbxdbhigh/lld.c
    ===================================================================
    --- zabbix-3.4.12-1+buster.orig/src/libs/zbxdbhigh/lld.c
    +++ zabbix-3.4.12-1+buster/src/libs/zbxdbhigh/lld.c
    @@ -497,9 +497,17 @@ static int lld_rows_get(const char *valu
                    goto out;
            }
     
    +       /* Support LLD for versions >= 4.2 */
    +       /* [{"{#IFNAME}":"eth0"},{"{#IFNAME}":"lo"},...] */
    +       /* ^-------------------------------------------^ */
    +       if ('[' == *jp.start)
    +       {
    +               jp_data = jp;
    +       }
    +       /* Support LLD for versions < 4.2 */
            /* {"data":[{"{#IFNAME}":"eth0"},{"{#IFNAME}":"lo"},...]} */
            /*         ^-------------------------------------------^  */
    -       if (SUCCEED != zbx_json_brackets_by_name(&jp, ZBX_PROTO_TAG_DATA, &jp_data))
    +       else if (SUCCEED != zbx_json_brackets_by_name(&jp, ZBX_PROTO_TAG_DATA, &jp_data))
            {
                    *error = zbx_dsprintf(*error, "Cannot find the \"%s\" array in the received JSON object.",
                                    ZBX_PROTO_TAG_DATA);

Сформируем заплатку с изменениями:

    $ quilt refresh

Опишем внесённые изменения в журнале изменений и откорректируем версию пакета. Для этого запустим команду:

    $ dch -i

И приведём последнюю запись в журнале изменений к следующему виду:

    zabbix (1:3.4.12-1+buster-stupin2) UNRELEASED; urgency=low
    
      * Added SNMPTimeout and SNMPRetries settings to server and proxy
        configuration files.
      * Fixed availability of SNMPv3 on authentication errors.
      * Added support for ClickHouse history storage.
      * Added preloading valuecache from ClickHouse history storage.
      * Added a grace period after starting the server, until which data
        reading from the history storage is prohibited.
      * Added support of both LLD formats for versions < 4.2 and >= 4.2
    
    -- Vladimir Stupin (vladimir@stupin.su)   Thu, 18 Jan 2024 15:37:46 +0500

Сборка пакетов
--------------

Для сборки двоичных пакетов и пакета с исходными текстами осталось выполнить одну команду:

    # dpkg-buildpackage -us -uc -rfakeroot

В каталоге выше указанного появятся собранные пакеты:

* [[zabbix_3.4.12-1+buster.orig.tar.gz]]
* [[zabbix-agent_3.4.12-1+buster-stupin2_amd64.deb]]
* [[zabbix-agent-dbgsym_3.4.12-1+buster-stupin2_amd64.deb]]
* [[zabbix-frontend-php_3.4.12-1+buster-stupin2_all.deb]]
* [[zabbix-get_3.4.12-1+buster-stupin2_amd64.deb]]
* [[zabbix-get-dbgsym_3.4.12-1+buster-stupin2_amd64.deb]]
* [[zabbix-java-gateway_3.4.12-1+buster-stupin2_all.deb]]
* [[zabbix-proxy-mysql_3.4.12-1+buster-stupin2_amd64.deb]]
* [[zabbix-proxy-mysql-dbgsym_3.4.12-1+buster-stupin2_amd64.deb]]
* [[zabbix-proxy-pgsql_3.4.12-1+buster-stupin2_amd64.deb]]
* [[zabbix-proxy-pgsql-dbgsym_3.4.12-1+buster-stupin2_amd64.deb]]
* [[zabbix-proxy-sqlite3_3.4.12-1+buster-stupin2_amd64.deb]]
* [[zabbix-proxy-sqlite3-dbgsym_3.4.12-1+buster-stupin2_amd64.deb]]
* [[zabbix-sender_3.4.12-1+buster-stupin2_amd64.deb]]
* [[zabbix-sender-dbgsym_3.4.12-1+buster-stupin2_amd64.deb]]
* [[zabbix-server-mysql_3.4.12-1+buster-stupin2_amd64.deb]]
* [[zabbix-server-mysql-dbgsym_3.4.12-1+buster-stupin2_amd64.deb]]
* [[zabbix-server-pgsql_3.4.12-1+buster-stupin2_amd64.deb]]
* [[zabbix-server-pgsql-dbgsym_3.4.12-1+buster-stupin2_amd64.deb]]
