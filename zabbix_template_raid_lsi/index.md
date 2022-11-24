Контроль аппаратного RAID-массива в Linux средствами Zabbix
===========================================================

[[!tag megacli zabbix]]

Оглавление
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

Эта заметка представляет собой переделку статьи [Контроль в Zabbix параметров SMART дисков, подключенных к аппаратному RAID-массиву](https://stupin.su/blog/zabbix-template-smart-lsi/). В отличие от той статьи, в этой для контроля параметров S.M.A.R.T. жёстких дисков используются данные, отдаваемые самим RAID-контроллером, а утилиты `smartmontools` и `lsscsi` не используются.

В отличие от предыдущего шаблона, в этом реализован раздельный контроль состояния батареи каждого из обнаруженных RAID-контроллеров. Контроль состояния батареи и её наличия в каждом из RAID-контроллеров можно отключить с помощью соответствующих макросов. Триггеры о состоянии зарядки/разрядки батареи убраны, т.к. оказались практически бесполезны.

Также из шаблона удалены макросы, определяющие порог срабатывания триггеров о высоком количестве перемещённых секторов и секторов-кандидатов на перемещение, т.к. опыт использования этой функциональности показал, что они лишь создают суету и не несут практической пользы.

В этой статье не описывается явным образом настройка в FreeBSD, т.к. она в целом аналогична настройке в Linux.

Настройка Zabbix-агента в Linux
-------------------------------

Для контроля состояния аппаратного RAID-массива нам понадобится утилита `megacli`. Установить утилиту `megacli` в Debian можно из неофициального [репозитория HwRAID](http://hwraid.le-vert.net/wiki/DebianPackages). Например, чтобы подключить репозиторий в Debian Stretch, нужно добавить в файл `/etc/apt/sources.list` такую строчку:

    deb http://hwraid.le-vert.net/debian stretch main

Установим в систему GPG-ключ для проверки подлинности репозитория при помощи команды:

    # wget -O - https://hwraid.le-vert.net/debian/hwraid.le-vert.net.gpg.key | apt-key add -

Теперь можно обновить список пакетов, доступных для установки из репозиториев:

    # apt-get update

И установить утилиту `mecacli` для управления RAID-контроллером:

    # apt-get install megacli

Теперь пользователю `zabbix`, от имени которого работает Zabbix-агент, дать права вызывать утилиты `megacli`. Для этого воспользуемся утилитой `sudo`. Если она ещё не установлена, то установить её можно при помощи команды:

    # apt-get install sudo

Запускаем `visudo` для редактирования прав доступа через `sudo`:

    # visudo

Добавим следующую строчку, чтобы Zabbix-агент мог вызывать утилиту `sudo` в неинтерактивном режиме:

    Defaults:zabbix !requiretty

Добавляем права запускать `megacli`:

    zabbix ALL=(ALL) NOPASSWD: /usr/sbin/megacli -LDInfo -Lall -aALL, \
                               /usr/sbin/megacli -AdpBbuCmd -GetBbuStatus -aALL, \
                               /usr/sbin/megacli -PdList -aALL

Создаём скрипт `/etc/zabbix/megacli.sh`, который можно взять по ссылке [[megacli.sh]]:

Выставляем права доступа к скрипту:

    # chown root:root /etc/zabbix/megacli.sh
    # chmod u=rwx,go=rx /etc/zabbix/megacli.sh

Добавляем в файл `/etc/zabbix/zabbix_agentd.conf` следующие строчки:

    UserParameter=megacli.discover.adapters,/etc/zabbix/megacli.sh discover_adapters
    UserParameter=megacli.battery.missing[*],/etc/zabbix/megacli.sh battery_missing $1
    UserParameter=megacli.battery.state[*],/etc/zabbix/megacli.sh battery_state $1
    UserParameter=megacli.discover.arrays,/etc/zabbix/megacli.sh discover_arrays
    UserParameter=megacli.array.state[*],/etc/zabbix/megacli.sh array_state $1 $2
    UserParameter=megacli.discover.disks,/etc/zabbix/megacli.sh discover_disks
    UserParameter=megacli.disk.model[*],/etc/zabbix/megacli.sh model $1 $2 $3
    UserParameter=megacli.disk.serial[*],/etc/zabbix/megacli.sh serial $1 $2 $3
    UserParameter=megacli.disk.health[*],/etc/zabbix/megacli.sh health $1 $2 $3
    UserParameter=megacli.disk.reallocated[*],/etc/zabbix/megacli.sh reallocated $1 $2 $3
    UserParameter=megacli.disk.temperature[*],/etc/zabbix/megacli.sh temperature $1 $2 $3
    UserParameter=megacli.disk.spare[*],/etc/zabbix/megacli.sh spare $1 $2 $3

Осталось перезапустить Zabbix-агента:

    # systemctl restart zabbix-agent

Шаблоны для Zabbix
------------------

Я подготовил два шаблона для контроля состояния RAID-контроллера и параметров S.M.A.R.T. жёстких дисков, которые к нему подключены:

* [[Template_RAID_megacli.xml]] - шаблон с элементами данных типа "Zabbix-агент",
* [[Template_RAID_megacli_Active.xml]] - шаблон с элементами данных типа "Zabbix-агент (активный)".

В шаблоне есть три низкоуровневых обнаружения:

[[megacli_discoveries.png]]

Первое низкоуровневое обнаружение обнаруживает контроллеры. На картинках ниже показаны соответствующие элементы данных и триггеры:

[[megacli_adapters_items.png]]

[[megacli_adapters_triggers.png]]

Второе низкоуровневое обнаружение обнаруживает RAID-массивы за каждым из контроллеров. На картинках ниже показаны соответствующие элементы данных и триггеры:

[[megacli_arrays_items.png]]

[[megacli_arrays_triggers.png]]

Третье низкоуровневое обнаружение обнаруживает диски, принадлежащие RAID-массивам на контроллерах. На картинках ниже показаны соответствующие элементы данных и триггеры:

[[megacli_disks_items.png]]

[[megacli_disks_triggers.png]]

Отключить контроль наличия и состояния батареи на отдельном RAID-контроллере можно с помощью макроса вида `{$MEGACLI_CHECK_BATTERY:"{#ADAPTER}"}`, где вместо `{#ADAPTER}` нужно подставить номер соответствующего контроллера. Для отключения контроля батареи на всех контроллерах можно воспользоваться макросом `{$MEGACLI_CHECK_BATTERY}`. Соответствующий макрос нужно добавить в контролируемый узел сети в Zabbix. На картинке ниже показан макрос по умолчанию из шаблона:

[[megacli_macros.png]]
