Замена сбойного диска при использовании LVM
===========================================

При настройке серверов, которым нужно для работы не более 10 гигабайт на дисках размером 160-500 гигабайт решил подстелить соломки и оставить место для манёвров: сделал на диске два раздела - один загрузочный и один использовал под LVM, а корневой раздел операционной системы разместил на LVM. Расчитывал во-первых, при необходимости иметь возможность использовать свободное пространство, а во-вторых - иметь возможность удобно снимать резервные копии корневого раздела системы.

В итоге, когда на диске появились перемещённые секторы, решил скопировать систему на новый жёсткий диск. Копирование загрузочного сектора, таблицы разделов и загрузочного раздела оставлю за рамками изложения, т.к. это вещи довольно просты. Опишу только перенос логического тома с группы томов на старом диске в группу томов на новом диске.

Создаём мгновенный снимок исходного раздела:

    # lvcreate -L 10G -s mon.sterl-disk -n mon.sterl-cpy

Создаём новую группу томов на новом жёстком диске:

    # pvcreate /dev/sdb2
    # vgcreate vg1 /dev/sdb2

В выводе команды следующей команды ищем размер спасаемого логического тома:

    # lvdisplay --units k

Создаём новый логический том на новой группе томов:

    # lvcreate -L 9764864k -n mon.sterl-disk vg1

Копируем данные из снимка в новый логический том:

    # ddrescue --force /dev/vg0/mon.sterl-cpy /dev/vg1/mon.sterl-disk /root/cpylog

Создадим точки монтирования логических томов:

    # cd /mnt
    # mkdir src
    # mkdir dst

Смонтируем их:

    # mount /dev/vg0/mon.sterl-disk src
    # mount /dev/vg1/mon.sterl-disk dst

Отсинхронизируем каталоги:

    # rsync -av src/ dst/

Отредактируем монтируемые разделы на новом логическом томе:

    # vim /mnt/dst/etc/fstab - меняем vg0 на vg1
    # vim /mnt/dst/boot/grub/grub.cfg - мнеяем vg0 на vg1

Смонтируем виртуальные файловые системы и перейдём в chroot-среду, корнем которой станет новый логический том:

    # mount -t devtmpfs udev /mnt/dst/dev
    # mount -t sysfs sysfs /mnt/dst/sys
    # mount -t proc proc /mnt/dst/proc
    # chroot /mnt/dst

Обновим образ загрузочной файловой системы ядра:

    # update-initramfs -k all -u
