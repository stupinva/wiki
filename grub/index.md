Настройки ядра Linux при загрузке через GRUB
============================================

Отключение IPv6
---------------

В файле /etc/default/grub нужно дописать в переменную GRUB\_CMDLINE\_LINUX настройку:

    ipv6.disable=1

Затем применить настройки командой:

    # update-grub

Начальное разрешение мониторов
------------------------------

В файле /etc/default/grub можно дописать в переменную GRUB\_CMDLINE\_LINUX настройки разрешения для тех мониторов, разрешение которых нужно изменить в процессе загрузке:

    video=VGA-1:640x480 video=TV-1:640x480 video=DVI-I-1:640x480


Настройки опций модулей ядра
----------------------------

* [Linux kernel module options on Debian](https://feeding.cloud.geek.nz/posts/linux-kernel-module-options-on-debian/)

Затем применить настройки командой:

    # update-grub
