Устранение проблем загрузки Debian на RAID1 и LVM через Grub
============================================================

[[!tag debian raid1 mdadm lvm grub]]

После обновления операционной системы с помощью команды `apt-get dist-upgrade` операционная система перестала грузиться. Загрузчик Grub выводил следующее сообщение об ошибке:

    error: symbol `grub_disk_native_sectors` not found

Загрузил систему с установочного диска и переустановил загрузчик через пункт меню Recovery. Чтобы ситуация больше не повторялась, поменял настройки пакета `grub-pc` с помощью следующей команды:

    # dpkg-reconfigure grub-pc

Настройки в полях "Linux command line" и "Linux default command line" оставил прежними. В поле "Grub install devices" выбрал дисковые устройства для установки Grub. В моём случае это были  устройства `/dev/sdc` и `/dev/sdd`.

Использованные материалы
------------------------

* [Unable to boot after dist-upgrade to 11.5 [SOLVED]](https://forums.debian.net/viewtopic.php?t=152850)
