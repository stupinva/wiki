Настройка системы виртуализации Virtualbox
==========================================

Создаём VLAN-интерфейсы:

    # ip link add link eth0 name vlan5 type vlan id 5
    # ip link add link eth0 name vlan6 type vlan id 6

Установка VirtualBox:

    # apt-get install virtualbox virtualbox-qt virtualbox-dkms linux-headers-amd64
    # modprobe vboxdrv
    # modprobe vboxnetflt
