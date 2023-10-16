Удаление групп томов после некорректного удаления физических томов LVM
======================================================================

[[!tag lvm mdadm]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

Однажды понадобилось извлечь из работающего сервера диски на другие нужды. Размонтировал раздел и подумал, что этого будет достаточно для того, чтобы корректно извлечь диски из системы. Однако, диски были объединены в RAID 0, а на массиве была создана группа томов с логическим томом, так что после извлечения дисков из сервера на нём остались деградировавший RAID-массив и группа томов без физического тома.

Удаление группы томов
---------------------

Для начала нужно удалить группу томов. Для этого добавим в неё новый физический том, который создадим во временном файле:

Создаём пустой файл размером 100 мегабайт:

    # dd if=/dev/zero of=/tmp/tmp.raw bs=1M count=100

Сделаем из файла блочное устройство. Для этого сначала узнаем имя следующего свободного петлевого блочного устройства:

    # losetup -f
    /dev/loop0

Сопоставим этому петлевому блочному устройству пустой временный файл:

    # losetup /dev/loop0 /tmp/tmp.raw 

Добавим новый физический том в группу томов:

    # vgextend vg2 /dev/loop0 

Удалим группу томов:

    # vgremove --force vg2

Удалим физический том, оставшийся от удалённой группы томов:

    # pvremove /dev/loop0

Открепим временный файл от петлевого блочного устройства:

    # losetup -d /dev/loop0 

Удалим временный файл:

    # rm /tmp/tmp.raw

Удаление RAID-массива
---------------------

Теперь, когда группа томов больше не существует и RAID-массив не используется, можно удалить из системы сам RAID-массив:

    # mdadm --manage --stop /dev/md2

Обновим информацию об имеющихся программных RAID-массивах:

    # mdadm --examine --scan > /etc/mdadm/mdadm.conf

В начало сгенерированного файла можно добавить текст, который бывает в этом файле по умолчанию:

    # mdadm.conf
    #
    # !NB! Run update-initramfs -u after updating this file.
    # !NB! This will ensure that initramfs has an uptodate copy.
    #
    # Please refer to mdadm.conf(5) for information about this file.
    #
    
    # by default (built-in), scan all partitions (/proc/partitions) and all
    # containers for MD superblocks. alternatively, specify devices to scan, using
    # wildcards if desired.
    #DEVICE partitions containers
    
    # automatically tag new arrays as belonging to the local system
    HOMEHOST <system>
    
    # instruct the monitoring daemon where to send mail alerts
    MAILADDR root
    
    # definitions of existing MD arrays

Наконец, нужно собрать образ загрузочной файловой системы для ядра с новым файлом, чтобы ядро корректно определило программные RAID-массивы:

    # udpate-initramfs -u -k all

Удаление физического тома
-------------------------

После проделанных операций любая команда для работы с логическими и физическими томами или группами томов будет выводить предупреждение следующего вида об отсутствующем физическом томе:

    WARNING: Device for PV NFwK98-81XP-xcD6-keZ4-k8IF-CeSs-yCwKur not found or rejected by a filter.

Для исправления ситуации нужно просканировать физические тома и обновить кэш в соответствии с результатами сканирования:

    # pvscan --cache

Использованные материалы
------------------------

* [Can't remove volume group](https://serverfault.com/questions/894410/cant-remove-volume-group)

