Настройка маршрутизатора HP/H3C A-MSR900 JF812A
===============================================

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

Профессиональным сетевым администраторам эта заметка покажется бесполезной, т.к. в ней описываются совершенно базовые вещи. Моя профессия связана с Linux-серверами, а не компьютерными сетями, но для общего развития я иногда пытаюсь изучать смежные области. В этой заметке собраны команды, которые могут пригодиться мне самому.

Интерфейс командной строки маршрутизатора НЕ похож на таковой у маршрутизаторов Cisco, а практически совпадает, за редкими небольшими исключениями, с интерфейсом командной строки коммутаторов Huawei. Для входа в режим администратора используется команда system-view, а для возврата обратно в режим пользователя - команда return. Команда quit позволяет выйти из текущего режима или отключиться от устройства, если текущий режим - режим пользователя. Вместо привычной для оборудования Cisco команды show используется команда display, которая обычно доступна во всех режимах.

Посмотреть текущую конфигурацию маршрутизатора можно при помощи команды display this, причём если вы находитесь в каком-то специфичном режиме настройки, то будет отображена только та часть конфигурации, которая имеет отношение к текущему режиму. Например в режиме настройки интерфейса будет показана конфигурация настраиваемого интерфейса.

Подключение к маршрутизатору
----------------------------

Для подключения к консоли маршрутизатора я воспользовался кабелем для COM-порта, идущим в комплекте с маршрутизатором, и программой minicom.

Для изменения настроек minicom, используемых по умолчанию, можно воспользоваться такой командой:

    # minicom -s

По умолчанию COM-порт маршрутизатора настроен так:

* Скорость обмена данными - 9600 бод
* Контроль чётности - отсутствует
* Битов данных - 8
* Стоп-битов - 1

После явного ручного указания всех этих настроек у меня получился такой файл /etc/minicom/minirc.dfl:

    # Автоматически сгенерированный файл - используйте "minicom -s" для
    # изменения параметров.
    pu port             /dev/ttyUSB0
    pu baudrate         9600
    pu bits             8
    pu parity           N
    pu stopbits         1

Теперь для подключения к консоли осталось просто запустить команду:

    # minicom

Выйти из minicom можно по нажатию следующих клавиш:

    Ctrl+A Z Q

FIXME: *По умолчанию на маршрутизаторе настроен пользователь admin с паролем admin.*

FIXME: *Первоначальную настройку маршрутизатора можно производить и по сети. По умолчанию на интерфейсе Ethernet 0/0 настроен IP-адрес 10.0.0.1 с маской 255.255.255.0 и включен telnet.*

Просмотр информации о маршрутизаторе
------------------------------------

Просмотр модели маршрутизатора, объёмов оперативной и флэш-памяти, версий установленного на нём программного обеспечения:

    <HP>display version 
    HP Comware Platform Software
    Comware Software, Version 5.20, Release 2209L22, RU
    Copyright (c) 2010-2012 Hewlett-Packard Development Company, L.P.
    HP A-MSR900 uptime is 0 week, 0 day, 0 hour, 1 minute
    Last reboot 2007/01/01 00:00:29
    System returned to ROM By Power-up.
    
    CPU type: FREESCALE MPC8313 266MHz
    256M bytes DDR2 SDRAM Memory
    256M bytes Flash Memory
    Pcb               Version:  3.0
    Logic             Version:  1.0
    Basic    BootROM  Version:  1.16
    Extended BootROM  Version:  1.16
    [SLOT  0]AUX            (Hardware)3.0,  (Driver)1.0,    (Cpld)1.0
    [SLOT  0]ETH0/0         (Hardware)3.0,  (Driver)1.0,    (Cpld)1.0
    [SLOT  0]ETH0/1         (Hardware)3.0,  (Driver)1.0,    (Cpld)1.0
    [SLOT  0]ETH0/2         (Hardware)3.0,  (Driver)1.0,    (Cpld)1.0
    [SLOT  0]ETH0/3         (Hardware)3.0,  (Driver)1.0,    (Cpld)1.0
    [SLOT  0]ETH0/4         (Hardware)3.0,  (Driver)1.0,    (Cpld)1.0
    [SLOT  0]ETH0/5         (Hardware)3.0,  (Driver)1.0,    (Cpld)1.0
    [SLOT  0]CELLULAR0/0    (Hardware)3.0,  (Driver)1.0,    (Cpld)1.0

Просмотр модели маршрутизатора, состояния и максимального количества портов (физически их всего 6):

    <HP>display device
     Slot No.  Board Type                Status    Max Ports
     0         A-MSR900 RPU Board        Normal       8

Просмотр серийного номера и MAC-адреса:

    <HP>display device manuinfo 
    slot 0
    DEVICE_NAME          : A-MSR 900 JF812A
    DEVICE_SERIAL_NUMBER : XXXXXXXXXX
    MAC_ADDRESS          : 7848-59XX-XXXX
    MANUFACTURING_DATE   : 2015-01-11
    VENDOR_NAME          : HP

Просмотр состояния слота 0:

  <HP>display device slot 0
   Slot 0
    Status:   Normal
    Type:     A-MSR900 RPU Board
    Hardware:  3.0
    Driver:    1.0
    CPLD:      1.0

Управление файлами
------------------

На маршрутизаторе имеется встроенная флеш-память, на которой хранятся различные файлы, в том числе с прошивкой маршрутизатора. Посмотреть список файлов можно при помощи команды dir:

    <HP>dir               
    Directory of flash:/
    
       0     -rw-  20679804  Jan 01 2007 00:03:28   a_msr9xx-cmw520-r2209l22-ru.bin
       1     drw-         -  Jan 01 2007 00:00:15   domain1
       2     drw-         -  Jan 01 2007 00:00:02   logfile
       3     -rw-     16256  Jan 01 2007 00:01:26   p2p_default.mtd
       4     -rw-      3539  Jan 01 2007 00:06:19   system.xml
       5     -rw-      1243  Jan 01 2007 00:06:21   startup.cfg
    
    261760 KB total (240232 KB free)

Можно заметить, что некоторые строчки помечены атрибутом d. Это каталоги. Переходить в них и обратно в родительский каталог можно при помощи команды cd:

    <HP>cd logfile
    <HP>cd ..

Каталоги можно создавать и удалять при помощи команд mkdir и rmdir:

    <HP>cd testdir
    % Such file or path doesn't exist. 
    
    <HP>mkdir testdir
    
    %Created dir flash:/testdir.
    
    <HP>cd testdir
    <HP>cd ..
    <HP>rmdir testdir
    Rmdir flash:/testdir?[Y/N]:Y
    
    %Removed directory flash:/testdir.

Файлы можно копировать, перемещать, переименовывать и удалять при помощи команд copy, move, rename и delete соответственно:

    <HP>copy startup.cfg startup.bak
    Copy flash:/startup.cfg to flash:/startup.bak?[Y/N]:Y
    .
    %Copy file flash:/startup.cfg to flash:/startup.bak...Done.
    <HP>move startup.bak startup.new
    Move flash:/startup.bak to flash:/startup.new?[Y/N]:Y
    
    %Moved file flash:/startup.bak to flash:/startup.new.
    <HP>rename startup.new startup.bak
    Rename flash:/startup.new to flash:/startup.bak?[Y/N]:Y
    
    %Renamed file flash:/startup.new to flash:/startup.bak.
    <HP>delete startup.bak
    
    Delete flash:/startup.bak?[Y/N]:Y
    
    %Delete file flash:/startup.bak...Done.

Сохранить текущую конфигурацию в текстовый файл можно следующим образом:

    <HP>save
    The current configuration will be written to the device. Are you sure? [Y/N]:y
    Please input the file name(*.cfg)[flash:/startup.cfg]
    (To leave the existing filename unchanged, press the enter key):
    flash:/startup.cfg exists, overwrite? [Y/N]:y
     Validating file. Please wait....
     Configuration is saved to device successfully.

Посмотреть содержимое файла можно при помощи команды more:

    <HP>more startup.cfg

Посмотреть конфигурацию, которая будет применена при загрузке маршрутизатора, можно при помощи такой команды:

    <HP>display saved-configuration

Управление конфигурацией маршрутизатора
---------------------------------------

Посмотреть имя файла конфигурации, который использовался при загрузке маршрутизатора или будет использоват при следующей загрузке, можно с помощью команды display startup:

    <HP>display startup 
     Current startup saved-configuration file: flash:/startup.cfg
     Next main startup saved-configuration file: flash:/startup.cfg
     Next backup startup saved-configuration file: NULL

В строчке, начинающейся со слова Current, отображается имя файла конфигурации, который использовался при загрузке маршрутизатора. В строчке, начинающейся со слов Next main, отображается имя файла конфигурации, который будет использоваться при следующей загрузке маршрутизатора. В строчке, начинающейся со слов Next backup, отображается имя запасного файла конфигурации, который будет использован при следующей загрузке маршутизатора, если основной файл конфигурации будет недоступен или повреждён.

Для изменения файла конфигурации, который будет использоваться при следующей загрузке маршрутизатора, можно воспользоваться командой следующего вида:

    <hp>startup saved-configuration startup.cfg main
    Please wait ...
    ... Done!

Ключевое слово main в этом случае не обязательно и приведено лишь для наглядности. Для настройки запасного файла конфигурации можно воспользоваться следующей командой:

    <hp>startup saved-configuration startup.cfg backup
    Please wait ...
    ... Done!

К сожалению, очистить имя запасного файла конфигурации можно только путём одновременного сброса имён и основного и запасного файлов конфигурации с последующей установкой имени основного файла конфигурации:

    <hp>undo startup saved-configuration
     Please wait ...... Done!
    <hp>display startup                                                             
     Current startup saved-configuration file: flash:/startup.cfg
     Next main startup saved-configuration file: NULL
     Next backup startup saved-configuration file: NULL
    <hp>startup saved-configuration startup.cfg main                                
    Please wait ...                                                                 
    ... Done!                                                                       
    <hp>display startup                                                             
     Current startup saved-configuration file: flash:/startup.cfg                   
     Next main startup saved-configuration file: flash:/startup.cfg                 
     Next backup startup saved-configuration file: NULL

Управление прошивками
---------------------

Посмотреть имя файла прошивки, который использовался при загрузке маршрутизататора и имя файла, который будет использоваться при следующей загрузке маршрутизатора, можно следующим образом:

    <hp>display boot-loader
     The boot file used at this reboot:flash:/a_msr9xx-cmw520-r2516p13.bin attribute: main
     The boot file used at the next reboot:flash:/a_msr9xx-cmw520-r2516p13.bin attribute: main
     The boot file used at the next reboot:flash:/a_msr9xx-cmw520-r2209l22-ru.bin attribute: backup
     Failed to get the secure boot file used at the next reboot!

В строчке со словами this reboot указано имя файла прошивки, которая использовалась при загрузке маршрутизатора. В строчке со словами next reboot, оканчивающейся словом main, указано имя файла прошивки, который будет использоваться при следующей загрузке маршрутизатора. В строчке со словами next boot, оканчивающейся словом backup, указано имя файла запасной прошивки, которая будет использоваться при следующей загрузке маршрутизатора, если по каким-то причинам не удалось воспользоваться файлом с основной прошивкой.

Изменить имя файла основной прошивки, которая будет использоваться при следующей загрузке, можно следующим образом:

    <hp>boot-loader file flash:/a_msr9xx-cmw520-r2516p13.bin main
      This command will set the boot file. Continue? [Y/N]:Y
    
      The specified file will be used as the main boot file at the next reboot on slot 0!

Изменить имя файла запасной прошивки, которая будет использоваться при недоступности основной прошивки, можно следующим образом:

    <hp>boot-loader file flash:/a_msr9xx-cmw520-r2516p13.bin backup
      This command will set the boot file. Continue? [Y/N]:Y
    
      The specified file will be used as the backup boot file at the next reboot on slot 0!

К сожалению, очистить имя файла запасной прошивки нельзя. Если нужно удалить файл с запасной прошивкой из флеш-памяти маршуртизатора, то следует выставить в качестве имени файла с запасной прошивкой имя файла с основной прошивкой.

Настройка начальных сведений о маршрутизаторе
---------------------------------------------

Входим в режим настройки маршрутизатора:

    <HP>system-view
    Enter system view, return user view with Ctrl+Z.

Настраиваем имя маршрутизатора:

    [HP]sysname hp

Вернуться из режима настройки в пользовательский режим можно при помощи команды return:

    [hp]return
    <hp>

Настройка контактов системного администратора и местоположения маршрутизатора производится через команды настройки агента SNMP:

    [hp]snmp-agent sys-info contact vladimir@stupin.su
    [hp]snmp-agent sys-info location Ufa

Увидеть настроенные данные можно следующим образом:

<hp>display snmp-agent sys-info 
   The contact person for this managed node:
           vladimir@stupin.su

   The physical location of this node:
           Ufa

   SNMP version running in the system:
           SNMPv3

Настройка пользователей и паролей
---------------------------------

Настройка пользователей маршрутизатора происходит в режиме system-view:

    <hp>system-view
    System View: return to User View with Ctrl+Z.
    [hp]

Переходим к настройке локального пользователя с логином stupin:

    [hp]local-user stupin 
    New local user added.
    [hp-luser-stupin]

Как видно, на маршрутизаторе не было пользователя с указанным логином и он был создан, после чего маршрутизатор перешёл в режим настройки нового пользователя.

Настраиваем локального пользователя с паролем, которому разрешаем заходить по SSH, через консоль и назначаем наивысшие привилегии:

    [hp-luser-stupin]password cipher $ecretP4ssw0rd
    [hp-luser-stupin]service-type ssh terminal
    [hp-luser-stupin]authorization-attribute level 3

Выйти из режима настройки локального пользователя можно при помощи команды quit. Возврат в начальный режим, как обычно, происходит по команде return:

    [hp-luser-stupin]quit
    [hp]return
    <hp>

Но из режима настройки пользователя не обязательно выходить по команде quit, если вы хотите вернуться сразу в начальный режим. Вернуться в него можно напрямую - по команде return.

Посмотреть список настроенных локальных пользователей можно следующим образом:

    <hp>display local-user 
    The contents of local user admin:
     State:                    Active
     ServiceType:              telnet/web
     Access-limit:             Disabled          Current AccessNum: 0
     User-group:               system
     Bind attributes:
     Authorization attributes:
      User Privilege:          3
    The contents of local user stupin:
     State:                    Active
     ServiceType:              ssh
     Access-limit:             Disabled          Current AccessNum: 0
     User-group:               system
     Bind attributes:
     Authorization attributes:
      User Privilege:          3
    Total 2 local user(s) matched.

Для удаления локального пользователя можно воспользоваться командой undo local-user с именем удаляемого пользователя:

    <hp>system-view 
    System View: return to User View with Ctrl+Z.
    [hp]undo local-user admin
    [hp]return
    <hp>

Маршрутизатор позволяет удалить пользователя, даже если он используется в текущем сеансе.

Просмотр состояния портов и VLAN
--------------------------------

Посмотреть текущее состояние портов можно при помощи команды display interface brief:

    <hp>display interface brief 
    The brief information of interface(s) under route mode:
    Link: ADM - administratively down; Stby - standby
    Protocol: (s) - spoofing
    Interface            Link Protocol Main IP         Description
    Aux0                 UP   UP       --
    Cellular0/0          DOWN DOWN     --
    Eth0/0               DOWN DOWN     10.0.0.1
    Eth0/1               DOWN DOWN     --
    NULL0                UP   UP(s)    --
    Vlan1                DOWN DOWN     192.168.1.1
    
    The brief information of interface(s) under bridge mode:
    Link: ADM - administratively down; Stby - standby
    Speed or Duplex: (a)/A - auto; H - half; F - full
    Type: A - access; T - trunk; H - hybrid
    Interface            Link Speed   Duplex Type PVID Description
    Eth0/2               DOWN auto    A      A    1
    Eth0/3               DOWN auto    A      A    1
    Eth0/4               DOWN auto    A      A    1
    Eth0/5               DOWN auto    A      A    1

Как видно, сначала выводятся порты, находящиеся в режиме маршрутизации, а потом - в режиме коммутации.

Посмотреть список портов и VLAN на них можно при помощи команд display vlan all:

    <hp>display vlan all 
     VLAN ID: 1
     VLAN Type: static
     Route Interface: configured
     IP Address: 192.168.1.1
     Subnet Mask: 255.255.255.0
     Description: VLAN 0001
     Name: VLAN 0001
     Tagged   Ports: none
     Untagged Ports:
        Ethernet0/2              Ethernet0/3              Ethernet0/4
        Ethernet0/5

Настройка портов и VLAN
-----------------------

Переходим в режим настройки маршрутизатора:

    <hp>system-view 
    Enter system view, return user view with Ctrl+Z.

Вход в режим настройки порта (выход осуществляется по команде quit):

    [hp]interface Ethernet 0/2
    [hp-Ethernet0/2]

В режиме настройки интерфейса можно задать его описание:

    [hp]interface Ethernet 0/2
    [hp-Ethernet0/2]description mgmt
    [hp-Ethernet0/2]quit

Очистить описание у интерфейса можно следующим образом:

    [hp]interface Ethernet 0/2
    [hp-Ethernet0/2]undo description
    [hp-Ethernet0/2]quit

Для переключения режима работы порта из коммутируемого в маршрутизируемый можно воспользоваться командой port link-mode route:

    [hp-Ethernet0/2]port link-mode route

Для обратного переключения режима работы порта из маршрутизируемого в коммутируемый можно воспользоваться командой port link-mode bridge:

    [hp-Ethernet0/2]port link-mode bridge

Стоит учитывать, что первые два порта Ethernet 0/0 и Ethernet 0/1 работают только в маршрутизируемом режиме, а попытка поменять их режим работы на коммутируемый завершится выводом сообщения об ошибке следующего вида:

     Error: This mode is not supported on this interface!

Перед настройкой VLAN на портах маршрутизатора можно настроить описание каждой VLAN:

    [hp]vlan 1
    [hp-vlan1]name default
    [hp-vlan1]vlan 2
    [hp-vlan2]name System
    [hp-vlan2]quit
    [hp]

Настроить VLAN в режиме доступа на порту можно и так:

    [hp]interface Ethernet 0/2
    [hp-Ethernet0/2]port access vlan 2
    [hp-Ethernet0/2]

По умолчанию все коммутируемые порты маршрутизатора настроены в режиме доступа в VLAN 1 - принимают Ethernet-кадры без меток и помечают их как принадлежащие VLAN 1.

Переключить порт коммутатора в режим транк можно следующим образом:

    [hp]interface Ethernet 0/2
    [hp-Ethernet0/2]port link-type trunk
    [hp-Ethernet0/2]

Определить список VLAN на транк-порту можно следующим образом:

    [hp-Ethernet0/2]port trunk permit vlan 2
     Please wait... Done.

Можно указать номера нескольких VLAN через пробел. Вместо одного номера можно указать диапазон, разделив начальный и конечный номера ключевым словом to:

    [hp-Ethernet0/2]port trunk permit vlan 1 to 4 8 

Если на интерфейс поступит пакет без метки, то его можно принять как принадлежащую VLAN по умолчанию для этого порта. Для указания номера VLAN по умолчанию для этого порта можно воспользоваться командой такого вида:

    [hp-Ethernet0/2]port trunk pvid vlan 2

Кроме режима транк можно настроить коммутируемый порт в гибридном режиме, воспользовавшись ключевым словом hybrid:

    [hp-Ethernet0/2]port link-type hybrid

Переключить порт в гибридный или транк-режимы можно только из режима доступа. Если порт находится в другом режиме, то будет выведено сообщение об ошибке:

     Because it is a Trunk-port, Hybrid can not be specified, please set it Access first.

Для переключения порта в режим доступа можно воспользоваться такой командой:

    [hp-Ethernet0/2]port link-type access
     Please wait........................................... Done.

В гибридном режиме VLAN по умолчанию для входящих пакетов можно настроить следующим образом:

    [hp-Ethernet0/2]port hybrid pvid vlan 2

Следующим образом можно разрешить пакетам из VLAN 2 покидать порт в нетегированном режиме:

    [hp-Ethernet0/2]port hybrid vlan 2 untagged
     Please wait... Done.

Наконец, вот так можно разрешить движение через порт тегированных пакетов, принадлежащих VLAN 1:

    [hp-Ethernet0/2]port hybrid vlan 1 tagged
     Please wait... Done.

Настройка IP-адреса и шлюза
---------------------------

По умолчанию на маршрутизаторе настроен интерфейс в VLAN 1 с IP-адресом 192.168.1.1 и маской сети 255.255.255.0:

    <hp>display interface Vlan-interface 1
    Vlan-interface1 current state: DOWN
    Line protocol current state: DOWN
    Description: Vlan-interface1 Interface
    The Maximum Transmit Unit is 1500
    Internet Address is 192.168.1.1/24 Primary
    IP Packet Frame Type: PKTFMT_ETHNT_2,  Hardware Address: 7848-59da-b569
    IPv6 Packet Frame Type: PKTFMT_ETHNT_2,  Hardware Address: 7848-59da-b569
     Last clearing of counters:  Never
        Last 300 seconds input rate: 0 bytes/sec, 0 bits/sec, 0 packets/sec
        Last 300 seconds output rate: 0 bytes/sec, 0 bits/sec, 0 packets/sec
        0 packets input, 0 bytes, 0 drops
        0 packets output, 0 bytes, 0 drops

Настроим новый интерфейс в VLAN 2. Для этого сначала перейдём в режим настройки:

    <hp>system-view                                                                 
    System View: return to User View with Ctrl+Z. 

Настраиваем IP-адрес и маску на интерфейсе.

    [hp]interface Vlan-interface 2
    [hp-Vlan-interface2]ip address 192.168.254.29 24

Для удаления IP-адреса с интерфейса можно воспользоваться командой undo:

    [hp-Vlan-interface2]undo ip address 192.168.254.29 24

Добавим описание к интерфейсу:

    [hp-Vlan-interface2]description Uplink, snr.lo.ufanet.ru, port 1

Выходим из режима настройки интерфейса:

    [hp-Vlan-interface2]quit

Добавим маршрут по умолчанию. Это будет постоянный статический маршрут через VLAN 2:

    <hp>system-view
    System View: return to User View with Ctrl+Z.
    [hp]ip route-static 0.0.0.0 0 Vlan-interface 2 192.168.254.1 permanent

Посмотреть текущую таблицу маршрутизации можно следующим образом:

    <hp>display ip routing-table
    Routing Tables: Public
            Destinations : 5        Routes : 5
    
    Destination/Mask    Proto  Pre  Cost         NextHop         Interface
    
    0.0.0.0/0           Static 60   0            192.168.254.1   Vlan2
    127.0.0.0/8         Direct 0    0            127.0.0.1       InLoop0
    127.0.0.1/32        Direct 0    0            127.0.0.1       InLoop0
    192.168.254.0/24    Direct 0    0            192.168.254.29  Vlan2
    192.168.254.29/32   Direct 0    0            127.0.0.1       InLoop0

Учтите, что в выводе этой команды отображаются только маршруты через активные интерфейсы. Если интерфейс неактивен, то маршрута в списке не будет.

Настройка SSH, защита консоли, отключение telnet и веб-интерфейса
-----------------------------------------------------------------

Включаем SSH-сервер:

    <hp>system-view
    System View: return to User View with Ctrl+Z.
    [hp]ssh server enable
    Info: Enable SSH server.
    [hp]return
    <hp>

После включения SSH-сервера нужно сгенерировать его ключ идентификации:

    <hp>system-view
    System View: return to User View with Ctrl+Z.
    [hp]public-key local create rsa
    The range of public key size is (512 ~ 2048).
    NOTES: If the key modulus is greater than 512,
    it will take a few minutes.
    Press CTRL+C to abort.
    Input the bits of the modulus[default = 1024]:
    Generating Keys...
    +++
    +++++
    ++
    +++++++
    
    [hp]return
    <hp>

Если этого не сделать, то при попытке подключения к маршрутизатору по SSH можно получить такую ошибку:

    $ ssh stupin@192.168.254.29
    Received disconnect from 192.168.254.29 port 22:2: The connection is closed by SSH Server
      Current FSM is SSH_Main_VersionMatch
    Disconnected from 192.168.254.29 port 22

Теперь добавим пользователя SSH-сервера, который может проходить аутентификацию по паролю и пользоваться SSH:

    <hp>system-view
    System View: return to User View with Ctrl+Z.
    [hp]ssh user stupin service-type stelnet authentication-type password
    [hp]return
    <hp>

Посмотреть текущую конфигурацию терминалов можно следующим образом:

    <hp>display user-interface      
      Idx  Type     Tx/Rx      Modem Privi Auth  Int
      12   TTY 12   9600       -     0     N     Cellular0/0
    F 80   AUX 0    9600       -     3     N     -
      81   VTY 0               -     0     A     -
      82   VTY 1               -     0     A     -
      83   VTY 2               -     0     A     -
      84   VTY 3               -     0     A     -
      85   VTY 4               -     0     A     -
    UI(s) not in async mode -or- with no hardware support:
    0-11  13-80
      +    : Current UI is active.
      F    : Current UI is active and work in async mode.
      Idx  : Absolute index of UIs.
      Type : Type and relative index of UIs.
      Privi: The privilege of UIs.
      Auth : The authentication mode of UIs.
      Int  : The physical location of UIs.
      A    : Authentication use AAA.
      L    : Authentication use local database.
      N    : Current UI need not authentication.
      P    : Authentication use current UI's password.

Как можно заметить в столбце Auth, в конфигурации по умолчанию консоль не защищена паролем. Исправить это можно с помощью такой команды:

    <hp>system-view
    System View: return to User View with Ctrl+Z.
    [hp]user-interface aux 0
    [hp-ui-aux0]authentication-mode scheme
    [hp-ui-aux0]quit
    [hp]return
    <hp>

Посмотреть текущую конфигурацию терминалов можно следующим образом:

    <hp>system-view
    System View: return to User View with Ctrl+Z.
    [hp]user-interface aux 0
    [hp-ui-aux0]display this 
    #
    user-interface tty 12
    user-interface aux 0
     authentication-mode scheme
    user-interface vty 0 4
     authentication-mode scheme
    #
    return
    [hp]return
    <hp>

По умолчанию к виртуальным терминалам можно подключиться по любому протоколу. Для того, чтобы разрешить подключение только по протоколу SSH, воспользуемся такими командами:

    <hp>system-view
    System View: return to User View with Ctrl+Z.
    [hp]user-interface vty 0 4
    [hp-ui-vty0-4]protocol inbound ssh 
    [hp-ui-vty0-4]quit
    [hp]return
    <hp>

Для отключения telnet и веб-интерфейсов на уровне маршрутизатора в целом воспользуемся такими командами:

    <hp>system-view
    System View: return to User View with Ctrl+Z.
    [hp]undo telnet server enable
    [hp]undo ip http enable
    [hp]undo ip https enable
    Info: HTTPS server has been stopped!
    [hp]return
    <hp>

Настройка DNS-клиента
---------------------

Для начала включим на маршрутизаторе DNS-клиента:

    <hp>system-view
    System View: return to User View with Ctrl+Z.
    [hp]dns resolve
    [hp]return
    <hp>

Как вы догадались, отключить его можно при помощи команды undo dns resolve.

Теперь укажем DNS-клиенту IP-адрес DNS-сервера:

    <hp>system-view
    System View: return to User View with Ctrl+Z.
    [hp]dns server 192.168.254.2
    [hp]return
    <hp>

Можно настроить несколько DNS-серверов, повторяя команду dns server с IP-адресом каждого сервера.

Посмотреть список настроенных DNS-серверов можно следующей командой:

    <hp>display dns server 
     Type:
      D:Dynamic    S:Static
    
    DNS Server  Type  IP Address
        1       S     192.168.254.2

Удалить DNS-сервер из этого списка можно при помощи команды undo dns server, указав ей IP-адрес DNS-сервера, подлежащего удалению.

Можно также указать интерфейс маршрутизатора, с которого DNS-клиент будет отправлять запросы:

    <hp>system-view
    System View: return to User View with Ctrl+Z.
    [hp]dns source-interface Vlan-interface 2
    [hp]return
    <hp>

Чтобы иметь возможность не указывать в доменных именах правую часть домена, можно настроить один или несколько доменов по умолчанию:

    <hp>system-view
    System View: return to User View with Ctrl+Z.
    [hp]dns domain lo.stupin.su
    [hp]return
    <hp>

Посмотреть настроенные домены по умолчанию можно при помощи следующей команды:

    <hp>display dns domain 
     Type:
      D:Dynamic    S:Static
    
    No.    Type   Domain-name
    1      S      lo.stupin.su
    2      S      wi.stupin.su
    3      S      vm.stupin.su

Удалить домены из этого списка можно при помощи команды undo dns domain с именем удаляемго домена.

Убедиться, что разрешение доменных имён в IP-адреса работает, можно, например, при помощи команды ping:

    <hp>ping dnscache
     Trying DNS resolve, press CTRL_C to break 
     Trying DNS server (192.168.254.2) 
     Trying DNS server (192.168.254.2) 
     Trying DNS server (192.168.254.2) 
      PING dnscache.vm.stupin.su (192.168.252.2):
      56  data bytes, press CTRL_C to break
        Reply from 192.168.252.2: bytes=56 Sequence=0 ttl=255 time=1 ms
        Reply from 192.168.252.2: bytes=56 Sequence=1 ttl=255 time=2 ms
        Reply from 192.168.252.2: bytes=56 Sequence=2 ttl=255 time=1 ms
        Reply from 192.168.252.2: bytes=56 Sequence=3 ttl=255 time=1 ms
        Reply from 192.168.252.2: bytes=56 Sequence=4 ttl=255 time=1 ms
    
      --- dnscache.vm.stupin.su ping statistics ---
        5 packet(s) transmitted
        5 packet(s) received
        0.00% packet loss
        round-trip min/avg/max = 1/1/2 ms
    
    <hp>

Настройка часов маршрутизатора
------------------------------

Перед тем, как настраивать текущее время, лучше сначала настроить текущий часовой пояс, т.к. при смене часового пояса настроенное время изменится вместе с часовым поясом и тогда время придётся настраивать снова.

Для настройки часового пояса можно воспользоваться командой следующего вида:

    <hp>system-view
    System View: return to User View with Ctrl+Z.
    [hp]clock timezone Asia/Yekaterinburg add 05:00:00
    [hp]return
    <hp>

Именем часового пояса может быть произвольный текст длиной от одного до 32 символов. Я воспользовался стандартным для Unix-систем именем Asia/Yekaterinburg, настроив смещение на 5 часов относительно универсального скоординированного времени.

В конфигурации по умолчанию на коммутаторе отключен переход на летнее время. Но на всякий случай, если на коммутаторе до этого оно было настроено, можно сбросить его при помощи следующей команды:

    <hp>system-view
    System View: return to User View with Ctrl+Z.
    [hp]undo clock summer-time
    [hp]return
    <hp>

Для настройки часов можно воспользоваться командой следующего вида:

    <hp>clock datetime 22:56:40 2023/01/11

Чтобы посмотреть текущее время, воспользуемся следующей командой:

    <hp>display clock
    22:57:45 Asia/Yekaterinburg Wed 01/11/2023
    Time Zone : Asia/Yekaterinburg add 05:00:00

Настройка синхронизации времени с серверами NTP
-----------------------------------------------

Включаем использование NTP-сервера для синхронизации часов маршрутизатора:

    <hp>system-view
    System View: return to User View with Ctrl+Z.
    [hp]ntp-service unicast-peer 192.168.254.2
    [hp]return
    <hp>

Указать интерфейс, с которого будут отправляться исходящие NTP-запросы, можно следующим образом:

    <hp>system-view
    System View: return to User View with Ctrl+Z.
    [hp]ntp-service source-interface Vlan-interface 2                                                                       
    [hp]return
    <hp>

Посмотреть сеансы связи с NTP-серверами можно следующим образом:

    <hp>display ntp-service sessions
           source          reference       stra reach poll  now offset  delay disper
    ********************************************************************************
    [12345]192.168.254.2   192.36.143.130     2    15   64   20  -26.4    2.1    0.8
    note: 1 source(master),2 source(peer),3 selected,4 candidate,5 configured
    Total associations :  1

Состояние сервиса NTP на коммутаторе можно увидеть такой командой:

    <hp>display ntp-service status
     Clock status: synchronized
     Clock stratum: 3
     Reference clock ID: 192.168.254.2
     Nominal frequency: 100.0000 Hz
     Actual frequency: 100.0000 Hz
     Clock precision: 2^18
     Clock offset: -11.5570 ms
     Root delay: 44.49 ms
     Root dispersion: 4.68 ms
     Peer dispersion: 0.00 ms
     Reference time: 17:21:34.269 UTC Jan 12 2023(E76AC01E.44DDF86E)

Наконец, после успешной синхронизации времени можно посмотреть на часы:

    <hp>display clock
    22:28:52 Asia/Yekaterinburg Thu 01/12/2023
    Time Zone : Asia/Yekaterinburg add 05:00:00

Обновление прошивки маршрутизатора
----------------------------------

Свежие прошивки для маршрутизатора можно найти на странице [Aruba Support Portal](https://asp.arubanetworks.com/downloads/software/RmlsZToxOWQ4YmIzZS0yODRjLTExZTktODBkMi0wNzM0NjFiY2QxZTc%3D).

На момент написания этой документации архив с самой свежей версией прошивки имел имя MSR9XX_5.20.R2516P13.zip. Можно извлечь файлы из архива, выложить на TFTP-сервер файл с именем A_MSR9XX-CMW520-R2516P13.BIN и скачать на маршрутизатор при помощи следующих команд:

    <hp>tftp 192.168.254.2 get A_MSR9XX-CMW520-R2516P13.BIN
    
      File will be transferred in binary mode
      Downloading file from remote TFTP server, please wait...\
      TFTP: 22644736 bytes received in 89 second(s) 
      File downloaded successfully.
    
    <hp>

Убедимся в том, что файл скачался:

    <hp>dir
    Directory of flash:/
    
       0     -rw-  22644736  Jan 01 2007 00:05:03   a_msr9xx-cmw520-r2516p1n
       1     -rw-  20679804  Jan 01 2007 00:03:28   a_msr9xx-cmw520-r2209l2n
       2     drw-         -  Jan 01 2007 00:00:15   domain1
       3     drw-         -  Jan 01 2007 00:00:02   logfile
       4     -rw-     16256  Jan 01 2007 00:01:26   p2p_default.mtd
       5     -rw-      3653  Jan 09 2007 06:36:58   system.xml
       6     -rw-      1902  Jan 09 2007 06:37:00   startup.cfg
    
    261760 KB total (218068 KB free)
    
    <hp>

Настроим загрузчик так, чтобы он использовал прежнюю прошивку в качестве запасной, а обновлённую в качестве основной:

    <hp>boot-loader file flash:/a_msr9xx-cmw520-r2209l22-ru.bin backup 
      This command will set the boot file. Continue? [Y/N]:Y
    
      The specified file will be used as the backup boot file at the next reboot on slot 0!
    <hp>boot-loader file flash:/a_msr9xx-cmw520-r2516p13.bin main      
      This command will set the boot file. Continue? [Y/N]:Y
    
      The specified file will be used as the main boot file at the next reboot on slot 0!

Проверим, какая прошивка запасная, какая основная и какая будет использоваться при следующей загрузке маршрутизатора:

    <hp>display boot-loader 
     The boot file used at this reboot:flash:/a_msr9xx-cmw520-r2209l22-ru.bin attribute: main
     The boot file used at the next reboot:flash:/a_msr9xx-cmw520-r2516p13.bin attribute: main
     The boot file used at the next reboot:flash:/a_msr9xx-cmw520-r2209l22-ru.bin attribute: backup
     Failed to get the secure boot file used at the next reboot!
    <hp>

Перезагружаем маршрутизатор:

    <hp>reboot 
     Start to check configuration with next startup configuration file, please wait.........DONE!
     This command will reboot the device. Continue? [Y/N]:Y
    #Jan  1 00:14:53:921 2007 hp DEVM/1/REBOOT: 
     Reboot device by command. 
    
    %Jan  1 00:14:53:922 2007 hp DEVM/5/SYSTEM_REBOOT: System is rebooting now.
     Now rebooting, please wait...

Процесс перезагрузки с консоли выглядел следующим образом:

    <hp>
    System is starting...
    Booting Normal Extend BootWare........
    The Extend BootWare is self-decompressing...................
    Done!
    
    ****************************************************************************
    *                                                                          *
    *                  HP A-MSR900  BootWare, Version 1.16                     *
    *                                                                          *
    ****************************************************************************
    Copyright (c) 2010-2011 Hewlett-Packard Development Company, L.P.
    
    Compiled Date       : Dec 21 2011
    CPU Type            : MPC8313
    CPU L1 Cache        : 16KB
    CPU Clock Speed     : 266MHz
    Memory Type         : DDR2 SDRAM
    Memory Size         : 256MB
    Memory Speed        : 266MHz
    BootWare Size       : 2048KB
    CPLD Version        : 1.0
    PCB Version         : 3.0
    
    
    BootWare Validating...
    Press Ctrl+B to enter extended boot menu...
    Starting to get the main application file--flash:/a_msr9xx-cmw520-r2516p13.b
    in!.........................................................................
    ............................................................................
    ........................
    The main application file is self-decompressing.............................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ........
    Done!
    Extend BootWare Version is not equal,updating? [Y/N]Y
    Updating Extend BootWare..........Done!
    Basic BootWare Version is not equal,updating? [Y/N]Y
    Updating Basic BootWare...........Done!
    BootWare updated,System is rebooting now.
    System is starting...
    Press Ctrl+D to access BASIC-BOOTWARE MENU
    Booting Normal Extend BootWare........
    The Extend BootWare is self-decompressing..........................
    Done!
    
    ****************************************************************************
    *                                                                          *
    *                  HP A-MSR900  BootWare, Version 5.01                     *
    *                                                                          *
    ****************************************************************************
    Copyright (c) 2010-2014 Hewlett-Packard Development Company, L.P.
    
    Compiled Date       : Nov  6 2014
    CPU Type            : MPC8313
    CPU L1 Cache        : 16KB
    CPU Clock Speed     : 266MHz
    Memory Type         : DDR2 SDRAM
    Memory Size         : 256MB
    Memory Speed        : 266MHz
    BootWare Size       : 2048KB
    CPLD Version        : 1.0
    PCB Version         : 3.0
    
    
    BootWare Validating...
    Normal Basic BootWare Version is newer than Backup Basic BootWare!
    Begin to Update the Backup Basic BootWare.........Done!
    Press Ctrl+B to enter extended boot menu...
    Starting to get the main application
    file--flash:/a_msr9xx-cmw520-r2516p13.bin!..................................
    ............................................................................
    ...............................................................
    The main application file is self-decompressing.............................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ............................................................................
    ........
    Done!
    System application is starting...
    .........................................................................................................
    User interface aux0 is available.
    
    
    
    Press ENTER to get started.
    <hp>
    #Jan  1 00:01:41:906 2007 hp SHELL/4/LOGIN: 
     Trap 1.3.6.1.4.1.25506.2.2.1.1.3.0.1: login from Console
    %Jan  1 00:01:41:906 2007 hp SHELL/5/SHELL_LOGIN: Console logged in from aux0.
    <hp>

Убедимся, что маршрутизатор загрузился с новой прошивкой:

    <hp>display version 
    HPE Comware Platform Software
    Comware Software, Version 5.20.106, Release 2516P13
    Copyright (c) 2010-2017 Hewlett Packard Enterprise Development LP
    HPE A-MSR900 uptime is 0 week, 0 day, 0 hour, 6 minutes
    Last reboot 2007/01/01 00:00:38
    System returned to ROM By <Reboot> Command.
    
    CPU type: FREESCALE MPC8313 266MHz
    256M bytes DDR2 SDRAM Memory
    256M bytes Flash Memory
    Pcb               Version:  3.0
    Logic             Version:  1.0
    Basic    BootROM  Version:  5.01
    Extended BootROM  Version:  5.01
    [SLOT  0]AUX            (Hardware)3.0,  (Driver)1.0,    (Cpld)1.0
    [SLOT  0]ETH0/0         (Hardware)3.0,  (Driver)1.0,    (Cpld)1.0
    [SLOT  0]ETH0/1         (Hardware)3.0,  (Driver)1.0,    (Cpld)1.0
    [SLOT  0]ETH0/2         (Hardware)3.0,  (Driver)1.0,    (Cpld)1.0
    [SLOT  0]ETH0/3         (Hardware)3.0,  (Driver)1.0,    (Cpld)1.0
    [SLOT  0]ETH0/4         (Hardware)3.0,  (Driver)1.0,    (Cpld)1.0
    [SLOT  0]ETH0/5         (Hardware)3.0,  (Driver)1.0,    (Cpld)1.0
    [SLOT  0]CELLULAR0/0    (Hardware)3.0,  (Driver)1.0,    (Cpld)1.0
    
    <hp>

Использованные материалы
------------------------

* [[HP MSR 900 Router Series Installation Guide|HP_MSR_900_Router_Series_Installation_Guide.pdf]]
* [[HP MSR Router Series Fundamentals Command Reference (V7)|HP_MSR_Router_Series_Fundamentals_Command_Reference___40__V7__41__.pdf]]
* [[HP A-MSR Router Series Fundamentals Configuration Guide (Mar. 2012)|HP_A-MSR_Router_Series_Fundamentals_Configuration_Guide___40__Mar._2012__41__.pdf]]
