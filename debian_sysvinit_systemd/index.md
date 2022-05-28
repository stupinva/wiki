Замена sysvinit на systemd в Debian
===================================

Устанавливаем systemd:

    # apt-get install systemd

Добавляем в `/etc/default/grub` опцию для запуска `/lib/systemd/systemd` вместо `/sbin/init`:

    GRUB_CMDLINE_LINUX_DEFAULT="init=/lib/systemd/systemd"

Обновляем конфигурацию загрузчика GRUB, так чтобы в неё попали только что настроенные нами опции загрузки ядра Linux:

    # update-grub

Перезагружаем систему:

    # reboot

Смотрим на дерево процессов:

    # ps -eHo pid,command

Если дерево растёт от процесса с именем `systemd` и идентификатором 1, то удаляем пакет `sysvinit` и устанавливаем пакет `systemd-sysv`:

    # apt-get remove sysvinit
    # apt-get install systemd-sysv

При попытке удаления `sysvinit` нужно будет не просто нажать `Enter` или набрать `Yes`, а чётко выразить своё намерение набором требуемой подтверждающей фразы.

Пакет `systemd-sysv` содержит в себе ссылку с именем `/sbin/init`, указывающую на `/lib/systemd/systemd`, поэтому из конфигруации загрузчика можно убрать добавленную опцию и вернуть файл `/etc/default/grub` к прежнему виду:

    GRUB_CMDLINE_LINUX_DEFAULT=""

Теперь можно перезагрузить систему ещё раз:

    # reboot

На этот раз система должна загрузиться под управлением systemd штатным образом.
