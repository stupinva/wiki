Изменение размера диска NetBSD
==============================

[[!tag netbsd lvm gpt resize_ffs]]

NetBSD установлена на виртуальную машину, диском для которой является логический том LVM. Логический диск называется `vm-mda` и находится в группе логических томов `stupin`.

Определим имя раздела виртуальной машины, размер которого нужно увеличить:

    # df -h
    Filesystem                         Size       Used      Avail %Cap Mounted on
    /dev/dk0                            29G        24G       3.8G  86% /
    kernfs                             1.0K       1.0K         0B 100% /kern
    ptyfs                              1.0K       1.0K         0B 100% /dev/pts
    procfs                             4.0K       4.0K         0B 100% /proc
    tmpfs                              768M         0B       768M   0% /var/shm

Определим имя диска, на котором находится этот раздел:

    # dkctl dk0 getwedgeinfo
    dk0 at ld0: cbab4f4f-597e-405e-b556-06dfc88e63cd
    dk0: 62914463 blocks at 64, type: ffs

Зафиксируем информацию до начала изменений размера диска `ld0`. Для начала посмотрим на содержимое заголовка разметки GPT:

    # gpt header ld0
    Media Size: 5368709120 (5G)
    Sector Size: 512
    Number of Sectors: 10485760 (10M)
    
    Header Information:
    - GPT Header Revision: 1.0
    - First Data Sector: 34 (34B)
    - Last Data Sector: 10485726 (10M)
    - Media GUID: 237a94ab-e984-46f0-a2e0-795eb3df7450
    - Number of GPT Entries: 128

Теперь ознакомимся с полным списком всех участков и разделов разметки GPT:

    mda# gpt show ld0
         start      size  index  contents
             0         1         PMBR
             1         1         Pri GPT header
             2        32         Pri GPT table
            34        30         Unused
            64  10485663      1  GPT part - NetBSD FFSv1/FFSv2
      10485727        32         Sec GPT table
      10485759         1         Sec GPT header

На физической машине, где находятся LVM-тома и запущена виртуализация KVM, выполним увеличение размера LVM-тома виртуальной машины:

    # lvresize -L 10G stupin/vm-mda
      Size of logical volume stupin/vm-mda changed from 5,00 GiB (1280 extents) to 10,00 GiB (2560 extents).
      Logical volume stupin/vm-mda successfully resized.

После выключения и включения виртуальной машины можно увидеть, что размер носителя увеличился до 10 гигабайт:

    # gpt header ld0
    Media Size: 10737418240 (10G)
    Sector Size: 512
    Number of Sectors: 20971520 (20M)
    
    Header Information:
    - GPT Header Revision: 1.0
    - First Data Sector: 34 (34B)
    - Last Data Sector: 10485726 (10M)
    - Media GUID: 237a94ab-e984-46f0-a2e0-795eb3df7450
    - Number of GPT Entries: 128

В выводе следующей команды видно, что вместо вторичных заголовка и таблицы появилось неиспользуемое пространство:

    # gpt show ld0
         start      size  index  contents
             0         1         PMBR
             1         1         Pri GPT header
             2        32         Pri GPT table
            34        30         Unused
            64  10485663      1  GPT part - NetBSD FFSv1/FFSv2
      10485727  10485793         Unused

Запускаем обновление таблицы разделов GPT до размера носителя:

    # gpt resizedisk ld0

Снова смотрим на таблицу разделов и видим, что за неиспользуемым пространством вновь появились вторичные заголовок и таблица GPT:

    # gpt show ld0
         start      size  index  contents
             0         1         PMBR
             1         1         Pri GPT header
             2        32         Pri GPT table
            34        30         Unused
            64  10485663      1  GPT part - NetBSD FFSv1/FFSv2
      10485727  10485760         Unused
      20971487        32         Sec GPT table
      20971519         1         Sec GPT header

Изменяем размер GPT-раздела:

    # gpt resize -i 1 ld0
    /dev/rld0: Partition 1 resized: 64 20971423

И убеждаемся, что размер GPT-раздела увеличился, а неиспользуемое место позади него исчезло:

    # gpt show ld0
         start      size  index  contents
             0         1         PMBR
             1         1         Pri GPT header
             2        32         Pri GPT table
            34        30         Unused
            64  20971423      1  GPT part - NetBSD FFSv1/FFSv2
      20971487        32         Sec GPT table
      20971519         1         Sec GPT header

Осталось изменить размер диска, для чего нужно будет загрузиться с другого носителя. Я воспользовался компакт-диском и выполнил следующую команду:

    # resize_ffs -p /dev/dk0
    It's required to manually run fsck on file system before you can resize it
    
     Did you run fsck on your disk (Yes/No) ? Yes

После обычной загрузки системы с диска можно наконец увидеть, что увеличился и размер файловой системы:

    # df -h /
    Filesystem         Size       Used      Avail %Cap Mounted on
    /dev/dk0           9.7G       3.6G       5.6G  39% /

Полезные материалы:
-------------------

* [What do you do to use a large disk with NetBSD?](https://wiki.netbsd.org/users/mlelstv/using-large-disks/)
