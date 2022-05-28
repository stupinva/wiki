Настройка AltLinux
==================

Имя узла
--------

Имя узла находится в файле /etc/sysconfig/network. За имя узла и имя домена отвечают опции HOSTNAME и DOMAINNAME в этом файле. Например, значения могут быть такими:

    HOSTNAME=inet.stupin.su
    DOMAINNAME=stupin.su

Чтобы поменять имя узла сразу, можно воспользоваться соответствующими командами:

    # hostname -f inet.stupin.su
    # hostname inet

Часовой пояс
------------

Часовой пояс настраивается в файле /etc/sysconfig/clock. Для этого нужно задать значение переменной ZONE:

    ZONE="Asia/Yekaterinburg"

Однако, при попытке применить изменения, я наталкивался на ошибку:

    # /etc/init.d/clock tzset
    Setting timezone information initlog: execvp: No such file or directory
    [FAILED]

Заглянул вовнутрь файла /etc/init.d/clock и нашёл, что часовой пояс устанавливается командой /usr/sbin/tzupdate, которой в системе нет. С помощью скрипта apt-file, который описан ниже, я нашёл пакет, в котором находится эта команда и доустановил его:

    # apt-get install tzdata

После чего часовой пояс установился успешно:

    # /etc/init.d/clock tzset
    Setting timezone information [ DONE ]
    # date
    Fri Jun 17 22:48:46 YEKT 2016

Поскольку внутри domU отсутствует устройство /dev/rtc, отвечающее за часы реального времени, можно отключить попытки считывать и записывать время в аппаратные часы. Для этого нужно прописать в том же файле /etc/sysconfig/clock такие значения переменных:

    HWCLOCK_SET_TIME_AT_START=false
    HWCLOCK_SET_AT_HALT=false
    HWCLOCK_ADJUST=false

Настройка сетевого интерфейса
-----------------------------

Во-первых, нужно задать метод конфигурирования интерфейса в файле /etc/net/ifaces/eth0/options:

    BOOTPROTO=static

Описание других опций и их возможных значений можно посмотреть в man etcnet-options.

Во-вторых, нужно настроить IP-адрес и маску подсети на интерфейсе. Для этого впишем в файл /etc/net/ifaces/eth0/ipv4address:

    169.254.254.10/24

В-третьих, настроим маршрут по умолчанию. Для этого создадим файл /etc/net/ifaces/eth0/ipv4route и впишем один маршрут:

    default via 169.254.254.1

В этот файл можно вписывать несколько маршрутов, по одному в строчке.

В-четвёртых, настроим DNS-клиент. Для этого создадим файл /etc/net/ifaces/eth0/resolv.conf и впишем туда настройки:

    search stupin.su
    nameserver 169.254.254.1

Дополнительно, можно указать настройки интерфейса, которые будут переданы утилите ethtool. Вписать эти настройки нужно в соответствующий файл /etc/net/ifaces/eth0/ethtool. Например, чтобы отключить согласование скорости и принудительно выставить скорость в 10 Мбит/с, можно вписать туда такие опции:

    speed 10 autoneg off

Реально будет выполнена такая команда настройки интерфейса:

    ethtool -s eth0 speed 10 autoneg off

Поскольку у ethtool есть много других опций, кроме -s, то применимость файла /etc/net/ifaces/eth0/ethtool довольно ограничена. Чтобы выполнить другие команды настройки интерфейса, можно воспользоваться файлом /etc/net/iface/eth0/ifup-post, в который вписать команду, которую нужно выполнить после активации интерфейса. Например, вот так:

    /usr/sbin/ethtool -K eth0 tx off

О других файлах для настройки сетевых интерфейсов можно почитать на странице man etcnet или по ссылке [Подсказки пользователю /etc/net](https://www.altlinux.org/Etcnet)

Для введения настроек в силу я не нашёл ничего лучшего, чем выполнить последовательно две команды:

    # ifdown eth0 ; ifup eth0

Однако, если вы выполняете эти команды подключившись к серверу по сети именно через этот интерфейс, то выполнение этих команд может быть чревато разрывом связи после выполнения первой команды до выполнения второй. Вторая команда может при этом и не выполниться.

Настройка репозиториев
----------------------

Первое, на что я обратил внимание, это то, что в системе уже имеются файлы-заготовки с источниками для скачивания пакетов. В каталоге /etc/apt/sources.list.d имеются следующие файлы:

* alt.list
* heanet.list
* informika.list - был в p7, нет в p8
* ipsl.list
* kiev.list - был в p7, нет в p8
* yandex.list

В каждом файле есть закомментированные строчки с репозиториями, находящимися на различных серверах. По умолчанию раскомментированы только строчки в файле alt.list, соответствующие протоколу HTTP.

Подробнее о ветках и архитектурах дистрибутива, а также о разделах репозиториев можно почитать тут: [Репозитории ALT Linux](https://www.altlinux.org/%D0%A0%D0%B5%D0%BF%D0%BE%D0%B7%D0%B8%D1%82%D0%BE%D1%80%D0%B8%D0%B8_ALT_Linux)

Я не знаю, есть ли в AltLinux у пакетов необязательные зависимости. Найти опций apt, которые бы отключали установку рекомендуемых и предлагаемых необязательных зависимостей, как в Debian, мне не удалось. Поэтому я просто запросил свежий список пакетов в репозитории и установил обновления:

    # apt-get update
    # apt-get upgrade

Заметно, что AltLinux'овский apt-get upgrade справляется с обновлениями гораздо быстрее, чем Debian'овский. Приятно порадовала свежесть пакетов - в репозитории имеется наисвежайший на момент написания этой статьи Zabbix 3.0.3

Подробнее об управлении пакетами в AltLinux можно почитать по двум ссылкам:

* [Управление пакетами. Консольные команды apt](https://www.altlinux.org/%D0%A3%D0%BF%D1%80%D0%B0%D0%B2%D0%BB%D0%B5%D0%BD%D0%B8%D0%B5_%D0%BF%D0%B0%D0%BA%D0%B5%D1%82%D0%B0%D0%BC%D0%B8#.D0.9A.D0.BE.D0.BD.D1.81.D0.BE.D0.BB.D1.8C.D0.BD.D1.8B.D0.B5_.D0.BA.D0.BE.D0.BC.D0.B0.D0.BD.D0.B4.D1.8B_apt)
* [Система управления пакетами APT](http://heap.altlinux.org/issues/compactbook/packages_apt.kirill/index.html)

apt-file в AltLinux
-------------------

Самая "замечательная" особенность дистрибутива заключается в отсутствии утилиты, подобной apt-file. Кажется, что пользователей и разработчиков дистрибутива это совсем не смущает. Разработчики предпочитают потратить время на разработку всяких программ типа alterator, но не предусматривают возможности решить такую простую задачу: найти пакет, в котором есть утилита strings. Пришлось соображать и соорудить замену <del>из спичек и желудей</del> на shell'e:

    #!/bin/sh
    
    contents_index=/root/contents_index
    
    update()
    {
      cat /etc/apt/sources.list /etc/apt/sources.list.d/* \
        | egrep -v '^(#|\s*$)' \
        | while read pkgtype sign url arch part ; do
            curl -L "$url/$arch/base/contents_index"
          done \
       > $contents_index
    }
    
    search()
    {
      file="$1"
  
      if [ "$file" = "" ]
      then
        echo "apt-file search <file>"
      else
        if [ ! -f $contents_index ]
        then
          echo "apt-file update"
        else
          cat $contents_index \
            | awk -v file="$file" '$1 ~ file { print $2 ":\t" $1; }'
        fi
      fi
    }
    
    show()
    {
      package="$1"
  
      if [ "$package" = "" ]
      then
        echo "apt-file show <package>"
      else
        if [ ! -f $contents_index ]
        then
          echo "apt-file update"
        else
          cat $contents_index \
            | awk -v package="$package" '$2 == package { print $2 ":\t" $1; }'
        fi
      fi
    }
    
    mode="$1"
    arg="$2"
    
    if [ "$mode" = "update" ]
    then
      update
    elif [ "$mode" = "search" ]
    then
      search "$arg"
    elif [ "$mode" = "show" ]
    then
      show "$arg"
    else
      echo "apt-file update"
      echo "apt-file search <file>"
      echo "apt-file show <package>"
    fi

Скрипт в целом ведёт себя привычным образом, как и программа apt-file из Debian. Но, поскольку сооружена из подручных средств, не учитывает несколько моментов:

- Один и тот же пакет может встречаться в нескольких источниках. Результаты поиска при этом будут задваиваться, затраиваться и т.д.
- Скрипт не учитывает что в строке с источникам может отсутствовать столбец, указывающий ключ, которым подписан репозиторий. Например, "[p7]". Если такие источники указаны, то скрипт работать не будет.
- Соответственно, скрипт не проверяет подписи источников.
- Скрипт умеет работать только с HTTP-источниками. Если в списке есть источники FTP или Rsync, то скрипт работать не будет.

Наверняка имеются ещё какие-то недоработки, но свою задачу я решил. Например, найти все пакеты, в которых есть программа strings, можно так:

    # cd /root
    # ./apt-file update
    # ./apt-file search bin/strings$

После этого мне удалось найти почти привычным способом имена пакетов, которые я обычно доустанавливаю в Debian. Вот этот список для AltLinux:

    # apt-get install vim-console curl binutils net-tools screen rsync
    # apt-get install sysstat tcpdump bind-utils telnet psmisc curl
    # apt-get install openntpd sudo postfix mailx logwatch

Установка и настройка Zabbix-агента
-----------------------------------

Установим Zabbix-агента:

    # apt-get install zabbix-agent

Установка в Xen
---------------

    $ wget http://ftp.altlinux.org/pub/distributions/ALTLinux/p8/images/starterkits/basealt-p8-vm-net-20160612-x86_64.img.xz
    $ 7z x basealt-p8-vm-net-20160612-x86_64.img.xz
   
    # lvcreate -n image -L 622854144b stupin
    # dd if=/home/stupin/basealt-p8-vm-net-20160612-x86_64.img of=/dev/mapper/stupin-image
    # partprobe 
    # mount /dev/mapper/stupin-image1 /mnt/image

etc/inittab:

    1:2345:respawn:/sbin/mingetty hvc0
    #1:2345:respawn:/sbin/mingetty --noclear tty1
    #2:2345:respawn:/sbin/mingetty tty2

etc/fstab:

    /dev/xvda     /                       ext4    relatime                        1 1
    #UUID=5b7c2d58-0afa-4bf4-9a42-542935636a05 / ext4 relatime 1 1

boot/grub:

    # cd /mnt/root/boot
    # mkdir grub

boot/grub/menu.lst:

    default         0
    timeout         2
    
    title           BaseAlt p8 x86_64
    root            (hd0,0)
    kernel          /boot/vmlinuz root=/dev/xvda ipv6.disable=1 ro
    initrd          /boot/initrd.img
    
    title           BaseAlt p8 x86_64 (Single-User)
    root            (hd0,0)
    kernel          /boot/vmlinuz root=/dev/xvda ipv6.disable=1 ro single
    initrd          /boot/initrd.img

    # chroot /mnt/root
    # passwd
    # exit

    # cd /mnt/image
    # tar cjvf /home/stupin/basealt-p8-vm-net-20160612-x86_64.tbz *

    # umount /mnt/image
    # dd if=/dev/zero of=/dev/mapper/stupin-image
    # partprobe
    # lvremove /dev/mapper/stupin-image

Ошибки сети в Xen
-----------------

В процессе работы с виртуальной машиной по SSH соединение разрывается со следующими сообщениями об ошибках:

    Corrupted MAC on input.
    Disconnecting: Packet corrupt

В интернете можно найти рекомендации отключить вычисление контрольных сумм пакетов на сетевой карте при помощи такой команды:

    # ethtool -K eth0 tx off

Если зайти на виртуальную машину и посмотреть соответствующие настройки сетевой карты, то можно увидеть, что вычисление контрольной суммы включено:

    # ethtool -k eth0
    Offload parameters for eth0:
    rx-checksumming: on
    tx-checksumming: on
    scatter-gather: on
    tcp-segmentation-offload: on
    udp-fragmentation-offload: off
    generic-segmentation-offload: on
    generic-receive-offload: on
    large-receive-offload: off
    rx-vlan-offload: off
    tx-vlan-offload: off
    ntuple-filters: off
    receive-hashing: off

Однако попытки выключить вычисление контрольных сумм при передаче пакета не приводит к действительному отключению:

    # ethtool -K eth0 tx off
    # ethtool -k eth0
    Offload parameters for eth0:
    rx-checksumming: on
    tx-checksumming: on
    scatter-gather: on
    tcp-segmentation-offload: on
    udp-fragmentation-offload: off
    generic-segmentation-offload: on
    generic-receive-offload: on
    large-receive-offload: off
    rx-vlan-offload: off
    tx-vlan-offload: off
    ntuple-filters: off
    receive-hashing: off

При этом, на хост-машине посмотреть такие же настройки на виртуальной сетевой карте гостевой машины, то можно увидеть гораздо больше настроек, хоть некоторые из них и не доступны для изменения:

    # ethtool -k vif2.0
    Features for vif2.0:
    rx-checksumming: on [fixed]
    tx-checksumming: on
    	tx-checksum-ipv4: on
    	tx-checksum-ip-generic: off [fixed]
    	tx-checksum-ipv6: on
    	tx-checksum-fcoe-crc: off [fixed]
    	tx-checksum-sctp: off [fixed]
    scatter-gather: on
    	tx-scatter-gather: on
    	tx-scatter-gather-fraglist: off [fixed]
    tcp-segmentation-offload: on
    	tx-tcp-segmentation: on
    	tx-tcp-ecn-segmentation: off [fixed]
    	tx-tcp6-segmentation: on
    udp-fragmentation-offload: off [fixed]
    generic-segmentation-offload: on
    generic-receive-offload: on
    large-receive-offload: off [fixed]
    rx-vlan-offload: off [fixed]
    tx-vlan-offload: off [fixed]
    ntuple-filters: off [fixed]
    receive-hashing: off [fixed]
    highdma: off [fixed]
    rx-vlan-filter: off [fixed]
    vlan-challenged: off [fixed]
    tx-lockless: off [fixed]
    netns-local: off [fixed]
    tx-gso-robust: off [fixed]
    tx-fcoe-segmentation: off [fixed]
    tx-gre-segmentation: off [fixed]
    tx-ipip-segmentation: off [fixed]
    tx-sit-segmentation: off [fixed]
    tx-udp_tnl-segmentation: off [fixed]
    tx-mpls-segmentation: off [fixed]
    fcoe-mtu: off [fixed]
    tx-nocache-copy: off
    loopback: off [fixed]
    rx-fcs: off [fixed]
    rx-all: off [fixed]
    tx-vlan-stag-hw-insert: off [fixed]
    rx-vlan-stag-hw-parse: off [fixed]
    rx-vlan-stag-filter: off [fixed]
    l2-fwd-offload: off [fixed]
    busy-poll: off [fixed]

После того, как я переустановил систему, заменив образ AltLinux p7 на BaseAlt p8, внутри виртуалки команда ethtool стала выдавать на глаз столько же настроек, как и ethtool в хост-системе:

    # ethtool -k eth0
    Features for eth0:
    rx-checksumming: on [fixed]
    tx-checksumming: on
    	tx-checksum-ipv4: on [fixed]
    	tx-checksum-ip-generic: off [fixed]
    	tx-checksum-ipv6: on
    	tx-checksum-fcoe-crc: off [fixed]
    	tx-checksum-sctp: off [fixed]
    scatter-gather: on
    	tx-scatter-gather: on
    	tx-scatter-gather-fraglist: off [fixed]
    tcp-segmentation-offload: on
    	tx-tcp-segmentation: on
    	tx-tcp-ecn-segmentation: off [fixed]
    	tx-tcp6-segmentation: on
    udp-fragmentation-offload: off [fixed]
    generic-segmentation-offload: on
    generic-receive-offload: on
    large-receive-offload: off [fixed]
    rx-vlan-offload: off [fixed]
    tx-vlan-offload: off [fixed]
    ntuple-filters: off [fixed]
    receive-hashing: off [fixed]
    highdma: off [fixed]
    rx-vlan-filter: off [fixed]
    vlan-challenged: off [fixed]
    tx-lockless: off [fixed]
    netns-local: off [fixed]
    tx-gso-robust: on [fixed]
    tx-fcoe-segmentation: off [fixed]
    tx-gre-segmentation: off [fixed]
    tx-ipip-segmentation: off [fixed]
    tx-sit-segmentation: off [fixed]
    tx-udp_tnl-segmentation: off [fixed]
    fcoe-mtu: off [fixed]
    tx-nocache-copy: off
    loopback: off [fixed]
    rx-fcs: off [fixed]
    rx-all: off [fixed]
    tx-vlan-stag-hw-insert: off [fixed]
    rx-vlan-stag-hw-parse: off [fixed]
    rx-vlan-stag-filter: off [fixed]
    l2-fwd-offload: off [fixed]
    busy-poll: off [fixed]


[Ошибка 31465 - mount: /root/run: filesystem mounted, but mount(8) failed: No such file or directory](https://bugzilla.altlinux.org/show_bug.cgi?id=31465)

Файл для исправления этой ошибки: [/usr/share/make-initrd/data/lib/initrd/modules/980-umount](https://bugzilla.altlinux.org/attachment.cgi?id=6429)

    [    4.514175] EXT4-fs (xvda): Unrecognized mount option "realtime" or missing value
