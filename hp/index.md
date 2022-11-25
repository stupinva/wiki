Настройка маршрутизатора HP/H3C A-MSR900 JF812A
===============================================

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

FIXME: *Первоначальную настройку маршрутизатора можно производить и по сети. По умолчанию на нём настроен IP-адрес 192.168.1.1 с маской 255.255.255.0 и включен telnet.*

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

Посмотреть конфигурацию, которая будет применена при загрузке маршрутизатора, можно при помщи такой команды:

    <HP>display saved-configuration

Управление конфигурацией и прошивками маршрутизатора
----------------------------------------------------

    <HP>display startup 
     Current startup saved-configuration file: flash:/startup.cfg
     Next main startup saved-configuration file: flash:/startup.cfg
     Next backup startup saved-configuration file: NULL

Настройка начальных сведений о коммутаторе
------------------------------------------

Входим в режим настройки коммутатора:

    <HP>system-view
    Enter system view, return user view with Ctrl+Z.

Настраиваем имя коммутатора:

    [HP]sysname hp

Вернуться из режима настройки в пользовательский режим можно при помощи команды return:

    [hp]return
    <hp>

Настройка контактов системного администратора и местоположения коммутатора производится через команды настройки агента SNMP:

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

Настройка пользователей коммутатора происходит в режиме system-view:

     <hp>system-view
    [hp]

Переходим к настройке локального пользователя с логином stupin:

    [hp]local-user stupin 
    New local user added.
    [hp-luser-stupin]

Как видно, на коммутаторе не было пользователя с указанным логином и он был создан, после чего коммутатор перешёл в режим настройки нового пользователя.

Настраиваем локального пользователя с паролем, которому разрешаем заходить по SSH и назначаем наивысшие привилегии:

    [hp-luser-stupin]password cipher $ecretP4ssw0rd
    [hp-luser-stupin]service-type ssh 
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

Коммутатор позволяет удалить пользователя, даже если он используется в текущем сеансе.
