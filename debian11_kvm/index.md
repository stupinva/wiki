Настройка KVM и virt-manager в Debian 11
========================================

Настройка KVM
-------------

Установим пакеты с демоном KVM и системой виртуализации Qemu, реализующей виртуальные машины с процессорами архитектур x86 и x86-64. Для успешного запуска демона KVM понадобится также установить dnsmask-base. Установим необходимые пакеты:

    # apt-get install libvirt-daemon-system qemu-system-x86 dnsmasq-base

Подгрузим модуль поддержки аппаратного ускорения виртуализации kvm:

    # modprobe kvm

Перезапустим демона виртуализации:

    # systemctl restart libvirtd

Включим пользователя, который будет пользоваться системой виртуализации KVM, в группу libvirtd:

    # usermod -aG libvirt stupin

Настройка virt-manager
----------------------

Установим клиента виртуализации KVM с графическим интерфейсом:

    # apt-get install virt-manager

Для работы virt-manager понадобятся дополнительные пакеты: netcat-openbsd для установки подключения к демону, gir1.2-spiceclientgtk-3.0 для вывода изображения виртуальной машины на хост-машину. Установим их:

    # apt-get install netcat-openbsd gir1.2-spiceclientgtk-3.0

Ссылки
------

* [Virt-manager для управления виртуальными машинами под управлением KVM и Xen](http://stupin.su/blog/virt-manager/)
