Настройка коммутатора Huawei S1720-10GW-2P
==========================================

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

Профессиональным сетевым администраторам эта заметка покажется бесполезной, т.к. в ней описываются совершенно базовые вещи. Моя профессия связана с Linux-серверами, а не компьютерными сетями, но для общего развития я иногда пытаюсь изучать смежные области. В этой заметке собраны команды, которые могут пригодиться мне самому.

Интерфейс командной строки коммутатора НЕ похож на таковой у коммутаторов Cisco. Для входа в режим администратора используется команда system-view, а для возврата обратно в режим пользователя - команда return. Команда quit позволяет выйти из текущего режима или отключиться от устройства, если текущий режим - режим пользователя. Вместо привычной для оборудования Cisco команды show используется команда display, которая обычно доступна во всех режимах.

Посмотреть текущую конфигурацию коммутатора можно при помощи команды display this, причём если вы находитесь в каком-то специфичном режиме настройки, то будет отображена только та часть конфигурации, которая имеет отношение к текущему режиму. Например в режиме настройки интерфейса будет показана конфигурация настраиваемого интерфейса.

Подключение к коммутатору
-------------------------

У этого коммутатора нет последовательного порта и подключиться к нему можно только по сети. По умолчанию на всех портах коммутатора настроена нетегированная VLAN 1 и все тегированные VLAN. На коммутаторе настроен IP-адрес 192.168.1.253 с маской подсети 255.255.255.0, коммутатор доступен через VLAN 1. Подключиться к нему можно через веб-интерфейс или через telnet, воспользовавшись именем пользователя admin и паролем admin@huawei.com. После первого входа коммутатор предложит заменить пароль по умолчанию на более безопасный.

Веб-интерфейс меня не интересует, поэтому всё дальнейшее описание относится к интерфейсу командной строки.

Просмотр информации о коммутаторе
---------------------------------

Просмотр модели коммутатора, объёмов оперативной и флэш-памяти, версий установленного на нём программного обеспечения:

    <huawei>display version      
    Huawei Versatile Routing Platform Software
    VRP (R) software, Version 5.170 (S1720GWR V200R010C00SPC600)
    Copyright (C) 2000-2016 HUAWEI TECH CO., LTD
    HUAWEI S1720-10GW-2P-E Routing Switch uptime is 0 week, 0 day, 15 hours, 53 minutes
    
    ES5D2T10S000 0(Master)  : uptime is 0 week, 0 day, 15 hours, 52 minutes
    DDR    Memory Size      : 512        M bytes
    FLASH  Memory Size      : 241        M bytes
    Pcb           Version   : VER.B
    BootROM       Version   : 020a.0001
    BootLoad      Version   : 020a.0001
    Software      Version   : VRP (R) Software, Version 5.170 (V200R010C00SPC600)

Просмотр модели коммутатора, состояния питания и состояния и роли в стеке:

    <huawei>display device
    S1720-10GW-2P-E's Device status:
    Slot Sub  Type                  Online    Power    Register     Status   Role
    -------------------------------------------------------------------------------
    0    -    S1720-10GW-2P         Present   PowerOn  Registered   Normal   Master

Просмотр серийного номера:

    <huawei>display device manufacture-info 
    Slot  Sub  Serial-number          Manu-date
    - - - - - - - - - - - - - - - - - - - - - -
    0     -    21980107533GJA002511   2018-10-30

Просмотр состояния устройства в стеке:

    <huawei>display device slot 0
    *down: administratively down
    
    S1720-10GW-2P-E's Device status:
    Slot Sub  Type                  Online    Power    Register     Status   Role  
    -------------------------------------------------------------------------------
    0    -    S1720-10GW-2P         Present   PowerOn  Registered   Normal   Master
    -------------------------------------------------------------------------------
      Board Type        : S1720-10GW-2P
      Board Description : 8 Ethernet 10/100/1000 ports, 2 Gig SFP, with license, AC 110/220V
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    Port     Port       Optic     MDI     Speed   Duplex  Flow-    Port   PoE    
             Type       Status            (Mbps)          Ctrl     State  State  
    -------------------------------------------------------------------------------
    0/0/1    GE(C)      Absent    Auto    1000    Full    Disable  Up     -      
    0/0/2    GE(C)      Absent    Auto    1000    Full    Disable  Down   -      
    0/0/3    GE(C)      Absent    Auto    1000    Full    Disable  Down   -      
    0/0/4    GE(C)      Absent    Auto    1000    Full    Disable  Down   -      
    0/0/5    GE(C)      Absent    Auto    1000    Full    Disable  Down   -      
    0/0/6    GE(C)      Absent    Auto    1000    Full    Disable  Down   -      
    0/0/7    GE(C)      Absent    Auto    1000    Full    Disable  Down   -      
    0/0/8    GE(C)      Absent    Auto    1000    Full    Disable  Down   -      
    0/0/9    GE(F)      Absent    -       1000    Full    Disable  Down   -      
    0/0/10   GE(F)      Absent    -       1000    Full    Disable  Down   -      
    -------------------------------------------------------------------------------

Для просмотра MAC-адреса коммутатора можно воспользоваться такой командой:

    <huawei>display bridge mac-address
    System bridge MAC address: 289e-97fb-41b4

Управление файлами
------------------

На коммутаторе имеется встроенная флеш-память, на которой хранятся различные файлы, в том числе с прошивкой коммутатора. Посмотреть список файлов можно при помощи команды dir:

    <huawei>dir
    Directory of flash:/
    
      Idx  Attr     Size(Byte)  Date        Time       FileName 
        0  drw-              -  Aug 23 2016 03:00:30   dhcp
        1  drw-              -  Aug 23 2016 03:00:06   user
        2  -rw-     61,931,532  Jul 31 2016 02:40:56   s1720-gw-v200r010c00spc600.cc
        3  -rw-             36  Aug 23 2016 03:06:25   $_patchstate_reboot
        4  -rw-          3,684  Aug 23 2016 03:06:25   $_patch_history
        5  drw-              -  Aug 23 2016 03:03:29   logfile
        6  -rw-          1,034  Apr 02 2000 14:05:45   vrpcfg.zip
        7  -rw-        207,239  Aug 23 2016 03:06:07   s1720-gw-v200r010sph008.pat
        8  -rw-          2,107  Aug 23 2016 03:05:16   qpzq1ka1183_21980107533gja002511.dat
        9  drw-              -  Aug 23 2016 02:59:54   $_install_mod
       10  -rw-            836  Apr 01 2000 23:55:48   rr.bak
       11  -rw-            836  Apr 01 2000 23:55:48   rr.dat
       12  -rw-            462  Aug 23 2016 03:00:28   private-data.txt
       13  drw-              -  Apr 02 2000 15:36:14   localuser
       14  -rw-        816,438  Aug 23 2016 03:00:30   mibtree.xml
       15  drw-              -  Apr 02 2000 01:55:42   $_backup
    
    247,032 KB total (187,332 KB free)

Можно заметить, что некоторые строчки помечены атрибутом d. Это каталоги. Переходить в них и обратно в родительский каталог можно при помощи команды cd:

    <huawei>cd dhcp/
    <huawei>cd ..

FIXME: *Каталоги можно создавать и удалять при помощи команд mkdir и rmdir:*

    <huawei>cd testdir
    Error: Wrong path or none existent directory.
    <huawei>mkdir testdir
    <huawei>cd testdir
    <huawei>cd ..
    <huawei>rmdir testdir
    Remove directory flash:/testdir?[Y/N]:Y
    %Removing directory flash:/testdir...Done!

Файлы можно копировать, перемещать, переименовывать и удалять при помощи команд copy, move, rename и delete соответственно:

    <huawei>copy vrpcfg.zip vrpсfg.bak
    Copy flash:/vrpcfg.zip to flash:/vrpсfg.bak?[Y/N]:Y
    100%  complete.
    Info: Copied file flash:/vrpcfg.zip to flash:/vrpсfg.bak...Done.
    <huawei>move vrpcfg.bak vrpcfg.new
    Move flash:/vrpcfg.bak to flash:/vrpcfg.new ?[Y/N]:Y
    %Moved file flash:/vrpcfg.bak to flash:/vrpcfg.new.
    <huawei>rename vrpcfg.bak vrpcfg.new
    Rename flash:/vrpcfg.bak to flash:/vrpcfg.new ?[Y/N]:Y
    Info: Rename file flash:/vrpcfg.bak to flash:/vrpcfg.new ......Done.
    <huawei>delete vrpcfg.new 
    Delete flash:/vrpcfg.new?[Y/N]:Y
    Info: Deleting file flash:/vrpcfg.new...succeeded.

Сохранить активную конфигурацию можно при помощи команды save:

    <huawei>save
    The current configuration (excluding the configurations of unregistered boards or cards) will be written to flash:/vrpcfg.zip.
    Are you sure to continue?[Y/N]Y
    Now saving the current configuration to the slot 0..
    Save the configuration successfully.

Сохранить текущую конфигурацию в текстовый файл можно следующим образом:

    <huawei>save startup.cfg
    The current configuration will be written to the device.
    Are you sure to continue?[Y/N]Y
    Now saving the current configuration to the slot 0..
    Save the configuration successfully.

Посмотреть содержимое файла можно при помощи команды more:

    <huawei>more startup.cfg
  
Посмотреть конфигурацию, которая будет применена при загрузке коммутатора, можно при помщи такой команды:

    <huawei>display saved-configuration last

Управление конфигурацией и прошивками коммутатора
-------------------------------------------------

    <huawei>display startup 
    MainBoard: 
      Configured startup system software:        flash:/s1720-gw-v200r010c00spc600.cc
      Startup system software:                   flash:/s1720-gw-v200r010c00spc600.cc
      Next startup system software:              flash:/s1720-gw-v200r010c00spc600.cc
      Startup saved-configuration file:          flash:/vrpcfg.zip
      Next startup saved-configuration file:     flash:/vrpcfg.zip
      Startup paf file:                          default
      Next startup paf file:                     default
      Startup license file:                      default
      Next startup license file:                 default
      Startup patch package:                     flash:/s1720-gw-v200r010sph008.pat
      Next startup patch package:                flash:/s1720-gw-v200r010sph008.pat

Настройка начальных сведений о коммутаторе
------------------------------------------

Входим в режим настройки коммутатора:

    <HUAWEI>system-view
    Enter system view, return user view with Ctrl+Z.

Настраиваем имя коммутатора:

    [HUAWEI]sysname huawei

Вернуться из режима настройки в пользовательский режим можно при помощи команды return:

    [huawei]return
    <huawei>

Настройка контактов системного администратора и местоположения коммутатора производится через команды настройки агента SNMP:

    [huawei]snmp-agent sys-info contact vladimir@stupin.su
    [huawei]snmp-agent sys-info location Ufa

Увидеть настроенные данные можно следующим образом:

    <huawei>display snmp-agent sys-info 
       The contact person for this managed node: 
               vladimir@stupin.su
    
       The physical location of this node: 
               Ufa
    
       SNMP version running in the system: 
               SNMPv3

Настройка пользователей и паролей
---------------------------------

Настройка пользователей коммутатора происходит в режиме aaa. Сначала перейдём в режим настройки коммутатора, а затем - в режим aaa:

     <huawei>system-view
    [huawei]aaa

Настраиваем локального пользователя с паролем, которому разрешаем заходить по SSH и назначаем наивысшие привилегии:

    [huawei-aaa]local-user stupin password irreversible-cipher $ecretP4ssw0rd
    [huawei-aaa]local-user stupin service-type ssh
    [huwaei-aaa]local-user stupin privilege level 15

Выйти из режима aaa можно при помощи команды quit. Возврат в начальный режим, как обычно, происходит по команде return:

    [huawei-aaa]quit
    [huawei]return
    <huawei>

Но из режима aaa не обязательно выходить по команде quit, если вы хотите вернуться сразу в начальный режим. Вернуться в него можно напрямую - по команде return.

Посмотреть список настроенных локальных пользователей можно следующим образом:

    <huawei>display local-user 
      ----------------------------------------------------------------------------
      User-name                      State  AuthMask  AdminLevel  
      ----------------------------------------------------------------------------
      admin                          A      TMH       15         
      stupin                         A      S         15         
      ----------------------------------------------------------------------------
      Total 2 user(s)

Для удаления локального пользователя можно воспользоваться командой undo local-user с именем удаляемого пользователя:

    <huawei>system-view
    [huawei]aaa
    [huawei-aaa]undo local-user admin
    [huawei-aaa]quit
    [huawei]return
    <huawei>

Система не даст удалить пользователя, если он вошёл на коммутатор:

    [huawei-aaa]undo local-user admin
    Error: Have user(s) online, can not be deleted.

Просмотр состояния портов и VLAN
--------------------------------

Посмотреть текущее состояние портов можно при помощи команды display interface brief:

    <huawei>display interface brief
    PHY: Physical
    *down: administratively down
    #down: LBDT down
    (l): loopback
    (s): spoofing
    (b): BFD down
    (e): ETHOAM down
    (dl): DLDP down
    (lb): LBDT block
    InUti/OutUti: input utility/output utility
    Interface                   PHY   Protocol  InUti OutUti   inErrors  outErrors
    GigabitEthernet0/0/1        up    up           0%     0%          0          0
    GigabitEthernet0/0/2        down  down         0%     0%          0          0
    GigabitEthernet0/0/3        down  down         0%     0%          0          0
    GigabitEthernet0/0/4        down  down         0%     0%          0          0
    GigabitEthernet0/0/5        down  down         0%     0%          0          0
    GigabitEthernet0/0/6        down  down         0%     0%          0          0
    GigabitEthernet0/0/7        down  down         0%     0%          0          0
    GigabitEthernet0/0/8        down  down         0%     0%          0          0
    GigabitEthernet0/0/9        down  down         0%     0%          0          0
    GigabitEthernet0/0/10       down  down         0%     0%          0          0
    NULL0                       up    up(s)        0%     0%          0          0
    Vlanif1                     up    up           --     --          0          0
    Vlanif2                     down  down         --     --          0          0

Посмотреть список VLAN и список портов в этих VLAN можно при помощи команды display port vlan:

    <huawei>display port vlan      
    Port                        Link Type    PVID  Trunk VLAN List
    -------------------------------------------------------------------------------
    GigabitEthernet0/0/1        auto         1     1-4094
    GigabitEthernet0/0/2        auto         1     1-4094
    GigabitEthernet0/0/3        auto         1     1-4094
    GigabitEthernet0/0/4        auto         1     1-4094
    GigabitEthernet0/0/5        auto         1     1-4094
    GigabitEthernet0/0/6        auto         1     1-4094
    GigabitEthernet0/0/7        auto         1     1-4094
    GigabitEthernet0/0/8        auto         2     1-4094
    GigabitEthernet0/0/9        auto         1     1-4094
    GigabitEthernet0/0/10       auto         1     1-4094

Настройка портов и VLAN
-----------------------

Переходим в режим настройки коммутатора:

    <huawei>system-view 
    Enter system view, return user view with Ctrl+Z.

Вход в режим настройки порта (выход осуществляется по команде quit):

    [huawei]interface GigabitEthernet 0/0/8 
    [huawei-GigabitEthernet0/0/8]

В режиме настройки интерфейса можно задать его описание:

    [huawei-GigabitEthernet0/0/8]description new manage port
    [huawei-GigabitEthernet0/0/8]

Перед настройкой VLAN на портах коммутатора можно настроить описание каждой VLAN:

    [huawei]vlan 2 configuration
    [huawei-vlan2]name System
    [huawei-vlan1]name default
    [huawei-vlan1]quit
    [huawei]

Можно добавлять порты в VLAN, а можно добавлять VLAN на порт. 

Порты в VLAN добавляются следующим образом:

    [huawei-vlan2]port GigabitEthernet 0/0/8 
    [huawei-vlan2]quit
    [huawei]

Таким образом можно добавить порт в VLAN только в режиме доступа.

Настроить VLAN в режиме доступа на порту можно и так:

    [huawei]interface GigabitEthernet 0/0/8
    [huawei-GigabitEthernet0/0/8]port default vlan 2
    [huawei-GigabitEthernet0/0/8]

По умолчанию все порты коммутатора настроены в режиме доступа в VLAN 1 - принимают Ethernet-кадры без меток и помечают их как принадлежащие VLAN 1. 

Переключить порт коммутатора в режим транк можно следующим образом:

    [huawei-GigabitEthernet0/0/4]port link-type trunk  
    Warning: This command will delete VLANs on this port. Continue?[Y/N]:Y
    Info: This operation may take a few seconds. Please wait for a moment...done.
    [huawei-GigabitEthernet0/0/4]

Добавить к транк-порту новые тегированные VLAN можно следующим образом:

    [huawei-GigabitEthernet0/0/8]port trunk allow-pass vlan 1
    Info: This operation may take a few seconds. Please wait a moment...done.

Чтобы удалить с порта лишние тегированные VLAN, можно указать список тех VLAN, которые нужно оставить:

    [huawei-GigabitEthernet0/0/8]port trunk allow-pass only-vlan 1 3
  
Удалить все тегированные VLAN с порта можно указав вместо списка VLAN ключевое слово none:

    [huawei-GigabitEthernet0/0/8]port trunk allow-pass only-vlan none

Кроме режима транк можно настроить порт коммутатора в гибридный режим, воспользовавшись ключевым словом hybrid:

    [huawei-GigabitEthernet0/0/4]port link-type hybrid
  
В гибридном режиме VLAN по умолчанию для входящих пакетов можно настроить следующим образом:

    [huawei-GigabitEthernet0/0/4]port hybrid pvid vlan 2

Следующим образом можно разрешить пакетам из VLAN 2 покидать порт в нетегированном режиме:

    [huawei-GigabitEthernet0/0/4]port hybrid untagged vlan 2
    Info: This operation may take a few seconds. Please wait a moment.done.
    [huawei-GigabitEthernet0/0/4]

Наконец, вот так можно разрешить движение через порт тегированных пакетов, принадлежащих VLAN 3:

    [huawei-GigabitEthernet0/0/4]port hybrid tagged vlan 3
    Info: This operation may take a few seconds. Please wait a moment.done.
    [huawei-GigabitEthernet0/0/4]
  
Переключить порт коммутатора обратно в режим доступа можно при помощи ключевого слова access:

    [huawei-GigabitEthernet0/0/4]port link-type access

Настройка IP-адреса и шлюза
---------------------------

По умолчанию на коммутаторе настроен интерфейс в VLAN 1 с IP-адресом 192.168.1.253 и маской сети 255.255.255.0:

    <huawei>display interface Vlanif main
    Vlanif1 current state : UP
    Line protocol current state : UP
    Last line protocol up time : 2000-04-02 15:20:20
    Description:
    Route Port,The Maximum Transmit Unit is 1500
    Internet Address is 192.168.1.253/24
    IP Sending Frames' Format is PKTFMT_ETHNT_2, Hardware address is 289e-97fb-41b4
    Current system time: 2020-09-21 16:12:24+05:00
        Input bandwidth utilization  : --
        Output bandwidth utilization : --

Настроим новый интерфейс в VLAN 2. Для этого сначала перейдём в режим настройки:

    <huawei>system-view 
    Enter system view, return user view with Ctrl+Z.

Настраиваем IP-адрес и маску на интерфейсе.

    [huawei]interface Vlanif 2
    [huawei-Vlanif2]ip address 169.254.254.28 24

Для удаления IP-адреса с интерфейса можно воспользоваться командой undo:

    [huawei-Vlanif2]undo ip address 169.254.254.28 24
  
Добавим описание к интерфейсу:

    [huawei-Vlanif2]description Uplink, dlink.lo.stupin.su, port 5

Применяем настройки к интерфейсу:

    [huawei-Vlanif2]restart

Выходим из режима настройки интерфейса:

    [huawei-Vlanif2]quit

Добавим маршрут по умолчанию. Это будет постоянный статический маршрут через VLAN 2:

    [huawei]ip route-static 0.0.0.0 0 Vlanif 2 169.254.254.1 permanent

Посмотреть текущую таблицу маршрутизации можно следующим образом:

    [huawei]display ip routing-table 
    Route Flags: R - relay, D - download to fib
    ------------------------------------------------------------------------------
    Routing Tables: Public
             Destinations : 5        Routes : 5        
    
    Destination/Mask    Proto   Pre  Cost      Flags NextHop         Interface
    
            0.0.0.0/0   Static  60   0           D   169.254.254.1   Vlanif2
          127.0.0.0/8   Direct  0    0           D   127.0.0.1       InLoopBack0
          127.0.0.1/32  Direct  0    0           D   127.0.0.1       InLoopBack0
        192.168.1.0/24  Direct  0    0           D   192.168.1.253   Vlanif1
      192.168.1.253/32  Direct  0    0           D   127.0.0.1       Vlanif1

Настройка SSH, отключение telnet и веб-интерфейса
-------------------------------------------------

Включаем SSH-сервер:

    <huawei>system-view
    [huawei]stelnet server enable
    [huawei]return
    <huawei>

Добавляем пользователя SSH-сервера, который может проходить аутентификацию по паролю и пользоваться SSH:

    <huawei>system-view
    [huawei]ssh user stupin
    [huawei]ssh user stupin authentication-type password
    [huawei]ssh user stupin service-type stelnet
    [huawei]return
    <huawei>

Коммутатор запоминает последние 5 паролей пользователя и не даёт установить пароль, который ранее уже использовался:

    stupin@stupin.su:~$ ssh stupin@huawei.lo.stupin.su
    User Authentication
    Password: 
    
    Warning: The initial password poses security risks.
    The password needs to be changed. Change now? [Y/N]: y
    Please enter old password: 
    Please enter new password: 
    Please confirm new password: 
    
    Error: The password has appeared in recent 5 times.

В таком случае приведённый выше диалог смены пароля повторяется до тех пор, пока не будет нажата клавиша N.

Чтобы очистить запомненные пароли пользователя, можно воспользоываться такой командой:

    <huawei>system-view
    [huawei]aaa
    [huawei-aaa]reset local-user stupin password history record 
    Warning: Clear history password records, there is a security risk.continue?[Y/N]Y
    [huawei-aaa]quit
    [huawei]return
    <huawei>

После этого получится настроить ранее использованный пароль.

Перейдём в режим настройки текущего терминала и посмотрим конфигурацию терминалов:

    <huawei>system-view
    [huawei]user-interface current 
    [huawei-ui-vty1]display this 
    #
    user-interface con 0
     authentication-mode aaa
    user-interface vty 0
     authentication-mode aaa
     user privilege level 15
    user-interface vty 1 4
     authentication-mode aaa
     user privilege level 15
     protocol inbound telnet
    user-interface vty 16 20
    #
    return
    [huawei-ui-vty1]quit
    [huawei]return
    <huawei>

Как можно увидеть, на виртуальные терминалы с 1 по 4 можно заходить через telnet. Заменим telnet на ssh при помощи следующих команд:

    <huawei>system-view
    [huawei]user-interface vty 1 4
    [huawei-ui-vty1-4]protocol inbound ssh
    [huawei-ui-vty1-4]quit
    [huawei]return
    <huawei>

Для отключения веб-интерфейсов воспользуемся такими командами:

    <huawei>system-view
    [huawei]undo http server enable
    Warning: The operation will stop HTTP service. Continue? [Y/N]:Y
    [huawei]undo http secure-server enable
    Warning: The operation will stop HTTP secure service. Continue? [Y/N]:Y
    [huawei]return
    <huawei>

Настройка DNS-клиента
---------------------

Для начала включим на коммутаторе DNS-клиента:

    <huawei>system-view
    [huawei]dns resolve 
    [huawei]return
    <huawei>

Как вы догадались, отключить его можно при помощи команды undo dns resolve.

Теперь укажем DNS-клиенту IP-адрес DNS-сервера:

    <huawei>system-view
    [huawei]dns server 169.254.254.1
    [huawei]return
    <huawei>

Можно настроить несколько DNS-серверов, повторяя команду dns server с IP-адресом каждого сервера.

Посмотреть список настроенных DNS-серверов можно следующей командой:

    <huawei>display dns server 
    
    IPv4 Dns Servers :
    Domain-server        IpAddress           
         1               169.254.254.1       
    
    IPv6 Dns Servers :
    No configured servers.

Удалить DNS-сервер из этого списка можно при помощи команды undo dns server, указав ей IP-адрес DNS-сервера, подлежащего удалению.

Можно такеж указать IP-адрес коммутатора, с которого DNS-клиент будет отправлять запросы:

    <huawei>system-view
    [huawei]dns server source-ip 169.254.254.28
    [huawei]return
    <huawei>

Чтобы иметь возможность не указывать в доменных именах правую часть домена, можно настроить один или несколько доменов по умолчанию:

    <huawei>system-view
    [huawei]dns domain lo.stupin.su
    [huawei]return
    <huawei>

Посмотреть настроенные домены по умолчанию можно при помощи следующей команды:

    <huawei>display dns domain
    No         Domain-name
    1          lo.stupin.su
    2          wi.stupin.su
    3          vm.stupin.su

Удалить домены из этого списка можно при помощи команды undo dns domain с именем удаляемго домена.

Убедиться, что разрешение доменных имён в IP-адреса работает, можно, например, при помощи команды ping:

    <huawei>ping stupin.su
      PING stupin.su (188.234.148.179): 56  data bytes, press CTRL_C to break
        Reply from 188.234.148.179: bytes=56 Sequence=1 ttl=64 time=1 ms
        Reply from 188.234.148.179: bytes=56 Sequence=2 ttl=64 time=1 ms
        Reply from 188.234.148.179: bytes=56 Sequence=3 ttl=64 time=1 ms
    
      --- stupin.su ping statistics ---
        3 packet(s) transmitted
        3 packet(s) received
        0.00% packet loss
        round-trip min/avg/max = 1/1/1 ms

Настройка часов коммутатора
---------------------------

Перед тем, как настраивать текущее время, лучше сначала настроить текущий часовой пояс, т.к. при смене часового пояса настроенное время изменится вместе с часовым поясом и тогда время придётся настраивать снова.

Для настройки часового пояса можно воспользоваться командой следующего вида:

    <huawei>clock timezone Asia/Yekaterinburg add 05:00:00

Именем часового пояса может быть произвольный текст длиной от одного до 32 символов. Я воспользовался стандартным для Unix-систем именем Asia/Yekaterinburg, настроив смещение на 5 часов относительно универсального скоординированного времени.

В конфигурации по умолчанию на коммутаторе отключен переход на летнее время. Но на всякий случай, если на коммутаторе до этого оно было настроено, можно сбросить его при помощи следующей команды:

    <huawei>undo clock daylight-saving-time 
    Info: This operation will take several seconds. Please wait...

Для настройки часов можно воспользоваться командой следующего вида:

    <huawei>clock datetime 13:48:00 2020-09-19

Чтобы посмотреть текущее время, воспользуемся следующей командой:

    <huawei>display clock
    2020-09-19 13:48:20+05:00
    Saturday
    Time Zone(Asia/Yekaterinburg) : UTC+05:00

Если вам понадобилось заглянуть в календарь, но лень отрывать руки от клавиатуры, то коммутаторы Huawei предоставляют практически уникальную возможность сделать это при помощи команды:

    <huawei>display calendar 
         September    2020
     Sun Mon Tue Wed Thu Fri Sat
               1   2   3   4   5
       6   7   8   9  10  11  12
      13  14  15  16  17  18  19
      20  21  22  23  24  25  26
      27  28  29  30
     Today is 19 September 2020.

Можно посмотреть календарь на произвольный месяц. Например, на январь 2021 года:

    <huawei>display calendar January 2021
           January    2021
     Sun Mon Tue Wed Thu Fri Sat
                           1   2
       3   4   5   6   7   8   9
      10  11  12  13  14  15  16
      17  18  19  20  21  22  23
      24  25  26  27  28  29  30
      31
     Today is 19 September 2020.

Можно указать только месяц и тогда будет показан календарь на месяц текущего года.

Настройка синхронизации времени с серверами NTP
-----------------------------------------------

Включаем использование NTP-сервера для синхронизации часов коммутатора:

    <huawei>system-view
    [huawei]undo ntp-service disable
    [huawei]ntp-service unicast-peer 169.254.254.1
    [huawei]return
    <huawei>

Указать интерфейс, с которого будут отправляться исходящие NTP-запросы, можно следующим образом:

    <huawei>system-view
    [huawei]ntp-service source-interface Vlanif 2
    [huawei]return
    <huawei>

Посмотреть сеансы связи с NTP-серверами можно следующим образом:

    <huawei>display ntp-service sessions 
     clock source: 169.254.254.1 
     clock stratum: 3 
     clock status: configured, master, sane, valid
     reference clock ID: 85.21.78.8
     reach: 1 
     current poll: 64 
     now: 8 
     offset: 0.0000 ms 
     delay: 0.00 ms 
     disper: 0.00 ms

Состояние сервиса NTP на коммутаторе можно увидеть такой командой:

    <huawei>display ntp-service status   
     clock status: synchronized 
     clock stratum: 4 
     reference clock ID: 169.254.254.1
     nominal frequency: 100.0000 Hz 
     actual frequency: 100.0000 Hz 
     clock precision: 2^18
     clock offset: 0.0000 ms 
     root delay: 0.00 ms 
     root dispersion: 0.54 ms 
     peer dispersion: 0.00 ms 
     reference time: 00:00:00.000 UTC Jan 1 1900(00000000.00000000)
     synchronization state: clock set 

Наконец, после успешной синхронизации времени можно посмотреть на часы:

    <huawei>display clock 
    2020-09-24 19:54:04+05:00
    Thursday
    Time Zone(Asia/Yekaterinburg) : UTC+05:00

Настройка журналирования
------------------------

Посмотреть в локальный журнал коммутатора можно следующим образом:

    <huawei>display logbuffer 
    Logging buffer configuration and contents : enabled
    Allowed max buffer size : 1024
    Actual buffer size : 512
    Channel number : 4 , Channel name : logbuffer
    Dropped messages : 0
    Overwritten messages : 0
    Current messages : 23
    
    Sep 24 2020 19:55:02+05:00 huawei %%01CFM/4/SAVE(s)[0]:The user chose Y when deciding whether to save the configuration to the device.
    Sep 24 2020 19:53:08+05:00 huawei %%01NTP/4/STRATUM_CHANGE(l)[1]:System stratum changes from 16 to 4. (SourceAddress=169.254.254.1)

Включаем службу журналирования:

    <huawei>system-view
    [huawei]info-center enable 
    Info: Information center is enabled.
    [huawei]return
    <huawei>

Включаем отправку журналов из logbuffer на syslog-сервер:

    <huawei>system-view
    [huawei]info-center loghost 169.254.254.1 channel logbuffer transport udp port 514 source-ip 169.254.254.28
    Warning: There is security risk as this operation enables a non secure syslog protocol.
    [huawei]return
    <huawei>

Для настройки rsyslog на приём syslog-пакетов от коммутатора и на запись в отдельный журнал, создадим файл /etc/rsyslog.d/huawei.conf со следующими настройками:

    $ModLoad imudp
    $UDPServerRun 514
    :FROMHOST, isequal, "169.254.254.28" /var/log/huawei.log
    :FROMHOST, isequal, "169.254.254.28" ~

После этого перезапустим rsyslogd:

    # systemctl restart rsyslog

Если UDP-порт 512 закрыт сетевым фильтром, не забудьте его открыть.

Чтобы настроить ротацию журнала /var/log/huawei.log, можно настроить logrotate. Для этого создадим файл /etc/logrotate.d/huawei со следующим содержимым:

    /var/log/huawei.log {
            weekly
            missingok
            rotate 10
            compress
            delaycompress
            notifempty
            create 640 root root
    }

Если всё сделано правильно, то в журналах на сервере syslog можно будет увидеть журнальные записи:  

    Sep 29 04:08:52 huawei %%01SSH/4/SSH_FAIL(s)[86]: Failed to login through SSH. (IP=169.254.254.1, VpnInstanceName= , UserName=stupin, Times=1, FailedReason=User public key authentication failed)
    Sep 29 04:09:30 huawei %%01SSH/4/SSH_FAIL(s)[87]: Failed to login through SSH. (IP=169.254.254.1, VpnInstanceName= , UserName=stupin, Times=1, FailedReason=User public key authentication failed)

Подобные сообщения можно увидеть и на самом коммутаторе:

    Sep 29 2020 09:09:30+05:00 huawei %%01SSH/4/SSH_FAIL(s)[4]:Failed to login through SSH. (IP=169.254.254.1, VpnInstanceName= , UserName=stupin, Times=1, FailedReason=User public key authentication failed)
    Sep 29 2020 09:08:52+05:00 huawei %%01SSH/4/SSH_FAIL(s)[5]:Failed to login through SSH. (IP=169.254.254.1, VpnInstanceName= , UserName=stupin, Times=1, FailedReason=User public key authentication failed)

Настройка SNMP
--------------

### Включение SNMP и RMON

Включить доступность SNMP-агента по отдельным версиям протокола можно при помощи команды следующего вида:

    [huawei]snmp-agent sys-info version v2c 
    Warning: SNMPv1/SNMPv2c is not secure, and it is recommended to use SNMPv3.

Вместо версии v2c можно указать v1, v3 или all.

Для просмотра включенных в SNMP-агенте версий протокола SNMP можно воспользоваться следующей командой:

    [huawei]display snmp-agent sys-info version
       SNMP version running in the system:
               SNMPv2c SNMPv3

Для отключения отдельных версий протоколов или можно воспользоваться командой включения, указав перед ней слово undo:

    [huawei]undo snmp-agent sys-info version all
    Warning: All SNMP versions will be disabled. Continue? [Y/N]:Y

Для включения статистики [RMON](http://www.circitor.fr/Mibs/Html/R/RMON-MIB.php) по интерфейсам необходимо войти на каждый из интерфейсов и включить сбор статистики следующим образом:

    [huawei]interface GigabitEthernet 0/0/1
    [huawei-GigabitEthernet0/0/1]rmon-statistics enable
    [huawei-GigabitEthernet0/0/1]rmon statistics 1 owner stupin

Для второго интерфейса:

    [huawei-GigabitEthernet0/0/1]interface GigabitEthernet 0/0/2
    [huawei-GigabitEthernet0/0/2]rmon-statistics enable
    [huawei-GigabitEthernet0/0/2]rmon statistics 2 owner stupin

После включения сбора статистики RMON, её можно будет увидеть на самом коммутаторе при помощи команды следующего вида:

    [huawei-GigabitEthernet0/0/10]display rmon statistics GigabitEthernet 0/0/1
    Statistics entry 1 owned by stupin is valid.
      Interface : GigabitEthernet0/0/1<ifIndex.5>
      Received  :
      octets              :165447    , packets          :1744      
      broadcast packets   :182       , multicast packets:303       
      undersize packets   :0         , oversize packets :0         
      fragments packets   :0         , jabbers packets  :0         
      CRC alignment errors:0         , collisions       :0         
      Dropped packet (insufficient resources):0         
      Packets received according to length (octets):
      64     :967       ,  65-127  :1580      ,  128-255  :271       
      256-511:100       ,  512-1023:12        ,  1024-1518:2 

Номер элемента статистики будет соответствовать индексу интерфейса в таблице, доступной по протоколу SNMP. Проверить правильность настройки можно, например, при помощи команды snmpwalk из пакета net-snmp:

    $ snmpwalk -v 3 -l authPriv -u mon -a SHA 'Authentic4ti0n$ecret' -x AES -X 'Encrypti0n$ecret' huawei.lo.stupin.su 1.3.6.1.2.1.16.1.1.1.8
    RMON-MIB::etherStatsCRCAlignErrors.1 = Counter32: 0 Packets
    RMON-MIB::etherStatsCRCAlignErrors.2 = Counter32: 0 Packets
    RMON-MIB::etherStatsCRCAlignErrors.3 = Counter32: 0 Packets
    RMON-MIB::etherStatsCRCAlignErrors.4 = Counter32: 0 Packets
    RMON-MIB::etherStatsCRCAlignErrors.5 = Counter32: 0 Packets
    RMON-MIB::etherStatsCRCAlignErrors.6 = Counter32: 0 Packets
    RMON-MIB::etherStatsCRCAlignErrors.7 = Counter32: 0 Packets
    RMON-MIB::etherStatsCRCAlignErrors.8 = Counter32: 0 Packets
    RMON-MIB::etherStatsCRCAlignErrors.9 = Counter32: 0 Packets
    RMON-MIB::etherStatsCRCAlignErrors.10 = Counter32: 0 Packets

Значение RMON-MIB::etherStatsCRCAlignErrors.1 в этой таблице соответствуют строчке CRC alignment errors в выводе команды, выполненной на коммутаторе до этого.

### Настройка представлений SNMP

Представление SNMP позволяет ограничить доступ к опредлённым веткам OID. Создадим представление ro с единственным правилом, разрешающим доступ к ветке OID 1.3.6.1:

    [huawei]snmp-agent mib-view included ro 1.3.6.1

Если представление должно разрешать доступ к нескольким веткам, то команду можно повторить, указывая правила с другими ветками OID. При необходимости исключить из представления определённую ветку, вместо ключевого слова include в правиле можно указать exclude.

Для удаления веток из представляения слева от команды нужно указать ключевое слово undo:

    [huawei]undo snmp-agent mib-view included ro 1.3.6.1

Удалить всё представление целиком можно следующим образом: 

    [huawei]undo snmp-agent mib-view ro

Коммутатор не даёт удалить представление ViewDefault, существующее на нём по умолчанию:

    [huawei]undo snmp-agent mib-view ViewDefault 
    Error: The default MIB view ViewDefault can not be modified or deleted.

Посмотреть список представлений и действующих в них правил в них можно при помощи команды display snmp-agent mib-view: 

    [huawei]display snmp-agent mib-view
       View name:ro
           MIB Subtree:internet
           Subtree mask:F0(Hex)
           Storage-type: nonVolatile
           View Type:included
           View status:active
    
       View name:rw
           MIB Subtree:internet
           Subtree mask:F0(Hex)
           Storage-type: nonVolatile
           View Type:included
           View status:active
    
       View name:ViewDefault
           MIB Subtree:internet
           Subtree mask:F0(Hex)
           Storage-type: nonVolatile
           View Type:included
           View status:active
    
       View name:ViewDefault
           MIB Subtree:snmpUsmMIB
           Subtree mask:FE(Hex)
           Storage-type: nonVolatile
           View Type:excluded
           View status:active
    
       View name:ViewDefault
           MIB Subtree:snmpVacmMIB
           Subtree mask:FE(Hex)
           Storage-type: nonVolatile
           View Type:excluded
           View status:active
    
       View name:ViewDefault
           MIB Subtree:snmpCommunityMIB
           Subtree mask:FE(Hex)
           Storage-type: nonVolatile
           View Type:excluded
           View status:active

### Список контроля доступа

Для того, чтобы разрешить доступ к SNMP-агенту только определённым IP-адресам, создадим список управления доступом под номером 2000:

    <huawei>system-view
    [huawei]acl 2000 match-order config 
    Info: When the ACL that is referenced by SACL is modified, the SACL will be dynamically updated. During the update, these SACL will become invalid temporarily.
    [huawei-acl-basic-2000]

Добавим в этот список два правила:

    [huawei-acl-basic-2000]rule 1 permit source 169.254.254.1 0 
    [huawei-acl-basic-2000]rule 2 permit source 169.254.252.2 0
    [huawei-acl-basic-2000]quit
    [huawei]return
    <huawei>

Посмотреть все списка управления доступом можно следующим образом:

    <huawei>display acl all
     Total nonempty ACL number is 1 
    
    Basic ACL 2000, 2 rules
    Acl's step is 5
     rule 1 permit source 169.254.254.1 0 
     rule 2 permit source 169.254.252.2 0 

### Настройка групп SNMP

Создаём группу с именем ro:

    <huawei>system-view
    [huawei]snmp-agent group v3 ro privacy read-view ro acl 2000

Этой командой мы:

* добавляем группу с именем ro,
* которая будет работать по протоколу SNMP версии 3 с секретами для аутентификации и шифрования,
* которой разрешаем доступ к OID'ам из представления ro на чтение,
* у которой нет OID'ов, доступных на запись,
* у которой нет OID'ов, доступных для отсылки трапов.
* которой разрешаем доступ с IP-адресов из списка управления доступом №2000.

Создаём группу с именем rw, которая аналогична ro, но будет иметь доступ на чтение и изменение значений OID'ов из представляения rw: 

    [huawei]snmp-agent group v3 rw privacy read-view rw write-view rw acl 2000
    [huawei]return
    <huawei>

Посмотреть список настроенных групп SNMP можно следующим образом:

    <huawei>display snmp-agent group 
       Group name: ro 
           Security model: v3 AuthPriv
           Readview: ro 
           Writeview: <no specified>  
           Notifyview :<no specified>  
           Storage-type: nonVolatile 
           Acl:2000
    
       Group name: rw 
           Security model: v3 AuthPriv
           Readview: rw 
           Writeview: rw 
           Notifyview :<no specified>  
           Storage-type: nonVolatile 
           Acl:2000

Для удаления группы можно воспользоваться командой такого вида:

    [huawei]undo snmp-agent group v3 rw privacy

### Настройка сообществ SNMP

Для настройки сообщества SNMP с именем $ecretC0mmunity, которое будет использовать представление ro только для чтения и будет иметь возможность делать запросы с IP-адресов, разрешённых списком доступа 2000, можно воспользоваться командой следующего вида: 

    [huawei]snmp-agent community read cipher $ecretC0mmunity acl 2000 mib-view ro

Посмотреть список настроенных сообществ можно следующим образом:  

    [huawei]display snmp-agent community 
       Community name:%^%#__#tTj1LuUC=~XGiJ544zytTY01DWW8+}&TD%r<",HZ=BY2eZWo+%",,oPlW>BrY2b0UHWyz3rIecJ=Q%^%# 
           Group name:%^%#__#tTj1LuUC=~XGiJ544zytTY01DWW8+}&TD%r<",HZ=BY2eZWo+%",,oPlW>BrY2b0UHWyz3rIecJ=Q%^%# 
           Acl:2000
           Storage-type: nonVolatile

Посмотреть, какая именно строка используется сообществом, таким образом нельзя. Имя сообщества и группы тоже ни о чём не говорят, отличить одно сообщество от другого может быть довольно сложно. Но к счастью у команды есть дополнительная опция, позволяющая назначить сообществу псевдоним:

    [huawei]snmp-agent community read cipher $ecretC0mmunity acl 2000 mib-view ro alias ro_2000

Теперь это сообщество можно легко найти в списке по псевдониму ro_2000:

    [huawei]display snmp-agent community 
       Community name:%^%#G48%)LZ^e)O"t{IGD_,4ASvIH>9A72|"W&De*LFYeE$s!'Vr5BT'/a1()`+O\O4o<B4+CB$@aMY9b<$O%^%# 
           Group name:%^%#G48%)LZ^e)O"t{IGD_,4ASvIH>9A72|"W&De*LFYeE$s!'Vr5BT'/a1()`+O\O4o<B4+CB$@aMY9b<$O%^%# 
           Alias name:ro_2000 
           Acl:2000
           Storage-type: nonVolatile 

К сожалению удалить сообщество по его псевдониму нельзя. Можно удалить его по имени, указанному в строчках Community name и Group name:

    [huawei]undo snmp-agent community %^%#G48%)LZ^e)O"t{IGD_,4ASvIH>9A72|"W&De*LFYeE$s!'Vr5BT'/a1()`+O\O4o<B4+CB$@aMY9b<$O%^%# 

Либо можно удалить сообщество по его строке, если она вам известна:

    [huawei]undo snmp-agent community $ecretC0mmunity

Проверить доступность коммутатора по протоколу SNMP версии 2c с настроенной строкой сообщества можно при помощи утилит из пакета net-snmp:

    $ snmpget -v 2c -c '$ecretC0mmunity' huawei.lo.stupin.su sysObjectID.0
    SNMPv2-MIB::sysObjectID.0 = OID: SNMPv2-SMI::enterprises.2011.2.23.509

### Настройка пользователей SNMPv3

Добавляем пользователя SNMP с именем mon:

    [huawei]snmp-agent usm-user v3 mon group ro acl 2000

Добавленный пользователь будет использовать права группы ro, будет использовать протокол SNMP версии 3 и делать запросы с IP-адресов, разрешённых списоком доступа 2000. У группы ro настроен уровень безопасности, предполагающий использование секретов для аутентификации и шифрования, которые для этого пользователя пока не настроены. Настроим их.

Настроим для пользователя mon аутентификацию с использованием алгоритма хэширования SHA и в ответ на предложения коммутатора дважды введём секрет для аутентификации:

    [huawei]snmp-agent usm-user v3 mon authentication-mode sha
    Please configure the authentication password (8-64)
    Enter Password:
    Confirm Password:

Коммутатор предоставляет широкий выбор алгоритмов шифрования: des56, 3des, aes128, aes192, aes256. К слову, алгоритм des56 в настоящее время считается не алгоритмом шифрования, а алгоритмом скремблирования, т.к. легко взламывается на современном широко распространённом оборудовании. Из остальных алгоритмов стандартом RFC утверждён только алгоритм AES128, о чём можно прочитать на странице проекта net-snmp: [Strong Authentication or Encryption](http://www.net-snmp.org/wiki/index.php/Strong_Authentication_or_Encryption).

Настроим для пользователя mon аутентификацию с использованием алгоритма шифрования AES128 и в ответ на предложения коммутатора дважды введём секрет для шифрования:

    [huawei]snmp-agent usm-user v3 mon privacy-mode aes128
    Please configure the privacy password (8-64)
    Enter Password:
    Confirm Password:

Важно настраивать секреты именно в такой последовательности. Если попытаться настроить секрет для шифрования до настройки секрета для аутентификации, коммутатор сообщит об ошибке:

    [huawei]snmp-agent usm-user v3 mon privacy-mode aes128
    Error: Please configure the authentication password first.

Посмотреть список настроенных пользователей можно следующим образом:

    <huawei>display snmp-agent usm-user 
       User name: mon 
           Engine ID: 800007DB03289E97FB41B4 active
           Authentication Protocol: sha 
           Privacy Protocol: aes128 
           Group name: ro 
           Acl: 2000

Удалить настроенного пользователя можно при помощи такой команды:

    [huawei]undo snmp-agent usm-user v3 mon

Проверить доступность коммутатора по протоколу SNMPv3 для пользователя mon можно при помощи такой команды из пакета net-snmp:

    $ snmpget -v 3 -l authPriv -u mon -a SHA -A 'Authentic4ti0n$ecret' -x AES -X 'Encrypti0n$ecret' huawei.lo.stupin.su sysObjectID.0
    SNMPv2-MIB::sysObjectID.0 = OID: SNMPv2-SMI::enterprises.2011.2.23.509

### Проблемы с SNMP

Обновление прошивки коммутатора
-------------------------------

Свежие прошивки для коммутатора можно найти на странице [Huawei S1720-10GW-2P Firmware & Software Download](https://support.huawei.com/enterprise/en/switches/s1720-10gw-2p-pid-22348265/software). Для скачивания прошивок нужно зарегистрироваться на сайте и ввести серийный номер коммутатора, после чего станет возможным скачать свежую версию прошивки и заплатки к ней.

На момент написания этой документации файл с самой свежей версией прошивки имел имя S1720-GW-V200R019C10SPC500.cc, а файл с самой свежей версией заплатки имел имя S1720-GW-V200R019SPH010.pat. Можно выложить их на TFTP-сервер и скачать на коммутатор при помощи следующих команд:

    <huawei>tftp 169.254.254.1 get S1720-GW-V200R019C10SPC500.cc                           
    Info: Transfer file in binary mode.
    Downloading the file from the remote TFTP server. Please wait...
    100%     
    TFTP: Downloading the file successfully.
    92742804 byte(s) received in 1848 second(s).
    <huawei>tftp 169.254.254.1 get S1720-GW-V200R019SPH010.pat
    Info: Transfer file in binary mode.
    Downloading the file from the remote TFTP server. Please wait...
    100%     
    TFTP: Downloading the file successfully.
    2959607 byte(s) received in 59 second(s).

Убедимся в том, что файлы скачались:

    <huawei>dir                                                
    Directory of flash:/
    
      Idx  Attr     Size(Byte)  Date        Time       FileName 
        0  drw-              -  Aug 23 2016 03:00:30   dhcp
        1  drw-              -  Aug 23 2016 03:00:06   user
        2  -rw-     61,931,532  Jul 31 2016 02:40:56   s1720-gw-v200r010c00spc600.cc
        3  -rw-             36  Aug 23 2016 03:06:25   $_patchstate_reboot
        4  -rw-          3,388  Sep 26 2020 16:15:57   startup.cfg
        5  -rw-          3,684  Aug 23 2016 03:06:25   $_patch_history
        6  drw-              -  Aug 23 2016 03:03:29   logfile
        7  -rw-          1,510  Oct 01 2020 19:53:36   vrpcfg.zip
        8  -rw-        207,239  Aug 23 2016 03:06:07   s1720-gw-v200r010sph008.pat
        9  -rw-          2,107  Aug 23 2016 03:05:16   qpzq1ka1183_21980107533gja002511.dat
       10  drw-              -  Aug 23 2016 02:59:54   $_install_mod
       11  -rw-            836  Sep 26 2020 12:51:45   rr.bak
       12  -rw-            836  Sep 26 2020 12:51:45   rr.dat
       13  -rw-            462  Aug 23 2016 03:00:26   private-data.txt
       14  drw-              -  Sep 26 2020 13:17:42   localuser
       15  -rw-        816,438  Aug 23 2016 03:00:28   mibtree.xml
       16  drw-              -  Apr 02 2000 01:55:42   $_backup
       17  -rw-              4  Sep 26 2020 12:49:54   snmpnotilog.txt
       18  -rw-     92,742,804  Oct 03 2020 21:23:33   s1720-gw-v200r019c10spc500.cc
       19  -rw-      2,959,607  Oct 03 2020 23:40:53   s1720-gw-v200r019sph010.pat
    
    247,032 KB total (95,852 KB free)
  
Выставим новые файлы в качестве используемых при следующей загрузке:

    <huawei>startup system-software s1720-gw-v200r019c10spc500.cc ..........
    Info: Succeeded in setting the software for booting system.
    <huawei>startup patch s1720-gw-v200r019sph010.pat
    Info: Succeeded in setting main board resource file for system.

Убедимся в том, что новые файлы будут использованы при следующей загрузке коммутатора:

    <huawei>display startup 
    MainBoard: 
      Configured startup system software:        flash:/s1720-gw-v200r010c00spc600.cc
      Startup system software:                   flash:/s1720-gw-v200r010c00spc600.cc
      Next startup system software:              flash:/s1720-gw-v200r019c10spc500.cc
      Startup saved-configuration file:          flash:/vrpcfg.zip
      Next startup saved-configuration file:     flash:/vrpcfg.zip
      Startup paf file:                          default
      Next startup paf file:                     default
      Startup license file:                      default
      Next startup license file:                 default
      Startup patch package:                     flash:/s1720-gw-v200r010sph008.pat
      Next startup patch package:                flash:/s1720-gw-v200r019sph010.pat

Перезагружаем коммутатор:

    <huawei>reboot
    Info: The system is now comparing the configuration, please wait.
    Info: If want to reboot with saving diagnostic information, input 'N' and then execute 'reboot save diagnostic-information'.
    System will reboot! Continue?[Y/N]:Y
    Comparing the firmware versions.............................
    Warning: It will take a few minutes to upgrade firmware. Please do not switchover, reset, remove, or power off the board when upgrade is being performed. Please keep system stable..........................................................................................
    Info: Online upgrade firmware on slot 0 successfully.
    Info: System is rebooting, please wait...

Перезагрузка коммутатора длится 4-5 минут.

После перезагрузки при входе появляется такое сообщение:

    Info: Smart-upgrade is currently disabled. Enable Smart-upgrade to get recommended version information.

Убедимся, что коммутатор запустился с новой прошивкой:

    <huawei>display version 
    Huawei Versatile Routing Platform Software
    VRP (R) software, Version 5.170 (S1720GWR V200R019C10SPC500)
    Copyright (C) 2000-2020 HUAWEI TECH Co., Ltd.
    HUAWEI S1720-10GW-2P-E Routing Switch uptime is 0 week, 0 day, 10 hours, 15 minutes
    
    ES5D2T10S000 0(Master)  : uptime is 0 week, 0 day, 10 hours, 14 minutes
    DDR             Memory Size : 512   M bytes
    FLASH Total     Memory Size : 512   M bytes
    FLASH Available Memory Size : 241   M bytes
    Pcb           Version   : VER.B
    BootROM       Version   : 0213.0000
    BootLoad      Version   : 0213.0000
    Software      Version   : VRP (R) Software, Version 5.170 (V200R019C10SPC500)
    FLASH         Version   : 0000.0000
    <huawei>display startup 
    MainBoard: 
      Configured startup system software:        flash:/s1720-gw-v200r019c10spc500.cc
      Startup system software:                   flash:/s1720-gw-v200r019c10spc500.cc
      Next startup system software:              flash:/s1720-gw-v200r019c10spc500.cc
      Startup saved-configuration file:          flash:/vrpcfg.zip
      Next startup saved-configuration file:     flash:/vrpcfg.zip
      Startup paf file:                          default
      Next startup paf file:                     default
      Startup license file:                      default
      Next startup license file:                 default
      Startup patch package:                     flash:/s1720-gw-v200r019sph010.pat
      Next startup patch package:                flash:/s1720-gw-v200r019sph010.pat

Попробуем последовать рекомендациям из сообщения, выведенного коммутатором при входе и попытаемся включить smart-upgrade:

    [huawei]smart-upgrade enable
    Error: Please bind ssl policy first.

Коммутатор требует сначала назначить политику SSL.

Для этого коммутатору нужно указать имя политики:

    [huawei]smart-upgrade ssl-policy ?
      STRING<1-23>  Name of SSL policy, only permits '_', letters(ignoring case)
                    and numbers

Смотрим имеющиеся политики:

    [huawei]display ssl policy 
    Error: No policy exists.

Их нет. Создадим одну:

    [huawei]ssl policy default  
    [huawei-ssl-policy-default]

Посмотрим на настройки этой политики:

    [huawei-ssl-policy-default]display this
    #
    ssl policy default
     ssl minimum version tls1.2
    #
    return

И покинем режим настройки политики:

    [huawei-ssl-policy-default]quit

Теперь попытаемся назначить эту политику smart-upgrade и включим его:

    [huawei]smart-upgrade ssl-policy default
    [huawei]smart-upgrade enable

Если попробовать скачать обновления:

    [huawei]smart-upgrade download
    Info: Getting version information from houp, please wait ...........
    Info: No download required, status is netError.

То коммутатор пытается связаться с IP-адресом 103.218.217.58 по протоколу HTTPS.

Резервное копирование конфигурации коммутатора
----------------------------------------------

Сохраним текущую конфигурацию коммутатора в текстовом виде в файл с именем startup.cfg:

    <huawei>save startup.cfg
    The current configuration will be written to the device.
    Are you sure to continue?[Y/N]Y
    Now saving the current configuration to the slot 0..
    Save the configuration successfully.

Теперь этот файл можно отправить на TFTP-сервер:

    <huawei>tftp 169.254.254.1 put startup.cfg
    Info: Transfer file in binary mode.
    Uploading the file to the remote TFTP server. Please wait...
    100%     
    TFTP: Uploading the file successfully.
    3388 byte(s) sent in 1 second(s).

Теперь удалим файл конфигурации startup.cfg:

    <huawei>delete startup.cfg
    Delete flash:/startup.cfg?[Y/N]:Y
    Info: Deleting file flash:/startup.cfg...succeeded.

И скачаем копию этого файла с TFTP-сервера:

    <huawei>tftp 169.254.254.1 get startup.cfg
    Info: Transfer file in binary mode.
    Downloading the file from the remote TFTP server. Please wait...
    100%     
    TFTP: Downloading the file successfully.
    3388 byte(s) received in 1 second(s).
