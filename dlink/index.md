Настройка коммутатора D-Link DGS-3200-10
========================================

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

Профессиональным сетевым администраторам эта заметка покажется совершенно бесполезной, т.к. в ней описываются совершенно базовые вещи. Моя профессия связана с Linux-серверами, а не компьютерными сетями, но для общего развития я иногда пытаюсь изучать смежные области. В этой заметке собраны команды, которые могут пригодиться мне самому.

Интерфейс командной строки коммутатора НЕ похож на таковой у коммутаторов Cisco. На коммутаторе нет деления на режимы просмотра и настройки, нет отдельных подрежимов для настройки интерфейсов. Все команды вводятся в одном и том же режиме, лишь бы у пользователя было достаточно прав для выполнения команды. Если прав не хватает, то можно переключиться на другого пользователя при помощи команды вида `enable <имя_другого_пользователя>`.

Подключение к консоли
---------------------

Для подключения к консоли коммутатора я воспользовался кабелем USB-RS232 и программой minicom.

Для изменения настроек minicom, используемых по умолчанию, можно воспользоваться такой командой:

    # minicom -s

По умолчанию COM-порт коммутатора настроен так:

* Скорость обмена данными - 115200 бод
* Контроль чётности - отсутствует
* Битов данных - 8
* Стоп-битов - 1

После явного ручного указания всех этих настроек у меня получился такой файл /etc/minicom/minirc.dfl:

    # Автоматически сгенерированный файл - используйте "minicom -s" для
    # изменения параметров.
    pu port             /dev/ttyUSB0
    pu baudrate         115200
    pu bits             8
    pu parity           N
    pu stopbits         1

Теперь для подключения к консоли осталось просто запустить команду:

    # minicom

Выйти из minicom можно по нажатию следующих клавиш:

    Ctrl+A Z Q

По умолчанию на коммутаторе настроен пользователь admin с паролем admin.

Первоначальную настройку коммутатора можно производить и по сети. По умолчанию на нём настроен IP-адрес 10.90.90.90 с маской 255.0.0.0 и включен telnet.

Просмотр информации о коммутаторе
---------------------------------

Для просмотра инфорации о модели коммутаторе, его MAC-адресах, версиях прошивки, загрузчика, серийного номера, можно воспользоваться командоу show switch:

    DGS-3200-10:4#show switch
    Command: show switch
  
    Device Type       : DGS-3200-10 Gigabit Ethernet Switch
    MAC Address       : xx-xx-xx-xx-xx-xx
    IP Address        : 10.90.90.90 (Manual)
    VLAN Name         : default
    Subnet Mask       : 255.0.0.0
    Default Gateway   : 0.0.0.0
    Boot PROM Version : Build 1.00.B012
    Firmware Version  : Build 2.21.B008
    Hardware Version  : B1
    Serial Number     : xxxxxxxxxxxx
    System Name       :
    System Location   :
    System Contact    :
    Device Uptime     : 2 days, 22 hours, 43 minutes, 16 seconds
    Spanning Tree     : Disabled
    GVRP              : Disabled
    IGMP Snooping     : Disabled
    MLD Snooping      : Disabled
    VLAN Trunk        : Disabled
    Telnet            : Enabled (TCP 23)
    Web               : Enabled (TCP 80)
    SNMP              : Disabled
    RMON              : Disabled
    Safeguard Engine  : Disabled
    SSL Status        : Disabled
    SSH Status        : Disabled
    802.1x            : Disabled
    Jumbo Frame       : Off
    CLI Paging        : Enabled
    MAC Notification  : Disabled
    Port Mirror       : Disabled
    SNTP              : Disabled
    DHCP Local Relay  : Disabled
    Syslog Global State  : Disabled
    Single IP Management : Disabled
    Dual Image           : Supported
    Password Encryption Status : Disabled
    DNS Resolver               : Disabled

Управление конфигурацией коммутатора
------------------------------------

В энергонезависимой памяти коммутатора нет файловой системы, поэтому нет команд для управления файлами. Вместо файловой системы в энергонезависимой памяти коммутатора предусмотрены два слота для хранения файлов конфигурации, а для манипуляции этими слотами предназначены специальные команды.

Чтобы посмотреть текущую конфигурацию коммутатора, можно воспользоваться командой show config current_config:

    DGS-3200-10:4#show config current_config

Посмотреть состояние обоих слотов конфигурации в энергонезависмой памяти можно при помощи команды show config information:

    DGS-3200-10:4#show config information
    Command: show config information
  
    Save Configuration Trap       : Disabled
    Upload Configuration Trap     : Disabled
    Download Configuration Trap   : Disabled
  
     ID         : 1(Boot up configuration)
     FileName   :
     Version    : 2.21.B008
     Size       : 22672 Bytes
     Updata Time: 2000/06/29 06:13:46
     From Server: Local save(SSH)
     By User    : stupin
     
    
     ID         : 2
     ID: (Empty)

Для просмотра конфигурации, сохранённой в каждом из слотов, можно воспользоваться командой show config config_in_nvram config_id N, где N - это номер слота:

    DGS-3200-10:4#show config config_in_nvram config_id 1

Для сохранения текущей конфигурации в указанный слот предназначена команда save config config_id N. В примере ниже текущая конфигурация сохраняется во второй слот флеш-памяти:

    DGS-3200-10:4#save config config_id 2
    Command: save config config_id 2
    
    Saving configuration 2 to NV-RAM.......... Done.

В выводе команды show config information можно заметить строчки с именем файла, которые в примере выше были пустыми. Чтобы назначить конфигурациям имена, можно воспользоваться командами вида config cfg_name config_id N config_name FILE_NAME:

    DGS-3200-10:4#config cfg_name config_id 1 config_name box.cfg
    Command: config cfg_name config_id 1 config_name box.cfg
    
    Success.
    
    DGS-3200-10:4#config cfg_name config_id 2 config_name room.cfg
    Command: config cfg_name config_id 2 config_name room.cfg
    
    Success.

Теперь у обоих файлов появилось имя:

    DGS-3200-10:4#show config information
    Command: show config information
    
    Save Configuration Trap       : Disabled
    Upload Configuration Trap     : Disabled
    Download Configuration Trap   : Disabled
    
     ID         : 1(Boot up configuration)
     FileName   : box.cfg
     Version    : 2.21.B008
     Size       : 22672 Bytes
     Updata Time: 2000/06/29 06:13:46
     From Server: Local save(SSH)
     By User    : stupin
    
    
     ID         : 2
     FileName   : room.cfg
     Version    : 2.21.B008
     Size       : 20837 Bytes
     Updata Time: 2000/01/04 09:01:44
     From Server: Local save(Console)
     By User    : Anonymous

К файлам теперь можно обращаться не по номерам слотов, в которых они лежат, а по их именам. Для этого в командах show config config_in_nvram вместо config_id можно указывать config_name.

Чтобы при загрузке коммутатора использовалась конфигурация из другого слота, можно воспользоваться такой командой:

    DGS-3200-10:4#config configuration config_id 2 boot_up
    Command: config configuration config_id 2 boot_up
    
    Success.

То же самое можно сделать, указав имя файла желаемой конфигурации:

    DGS-3200-10:4#config configuration config_name room.cfg boot_up
    Command: config configuration config_name room.cfg boot_up
    
    Success.

Применить конфигурацию из энергонезависимой памяти, не перезагружая коммутатор, можно воспользовавшись аналогичной командой, в которой вместо boot_up нужно указать active.

Чтобы удалить конфигурацию из слота, нужно вместо boot_up указать delete.

Управление прошивками
---------------------

Аналогично файлам конфигурации коммутатора, в энергонезависимой памяти коммутатора имеются два слота для хранения прошивок. Для просмотра списка пошивок в слотах можно воспользоваться командой show firmware information:

    DGS-3200-10:4#show firmware information
    Command: show firmware information
    
    Image ID   : 1(Boot up firmware)
        Version    : 2.21.B008
        Size       : 4168008 Bytes
        Update Time: 2000/01/01 00:45:43
        From       : 10.90.90.77(Console)
        User       : Anonymous
    
    
    Image ID: 2
        Version    : (Empty)
        Size       :
        Update Time:
        From       :

Чтобы при следующей загрузке коммутатора использовалась прошивка из определённого слота, можно выполнить команду config firmware image_id N boot_up, где N - это номер слота:

    DGS-3200-10:4#config firmware image_id 1 boot_up
    Command: config firmware image_id 1 boot_up
    
    Success.

Удалить ненужную прошивку можно аналогичной командой, заменив в ней boot_up на delete.

Настройка начальных сведений о коммутаторе
------------------------------------------

В отличие от коммутаторов SNR, на коммутаторе D-Link нет общесистемных команд для настройки сведений о коммутаторе. Команды для их настройки являются командами настройки агента SNMP.

Установка имени коммутатора:

    DGS-3200-10:4#config snmp system_name switch
    Command: config snmp system_name switch
    
    Success.

Настройка контактов сетевого администратора:

    DGS-3200-10:4#config snmp system_contact vladimir@stupin.su
    Command: config snmp system_contact vladimir@stupin.su
    
    Success.

Настройка местоположения устройства:

    DGS-3200-10:4#config snmp system_location Ufa
    Command: config snmp system_location Ufa
    
    Success.

После изменения настроек не забываем сохранить конфигурацию командой save.

Как можно заметить, настроенное имя коммутатора не меняет выводимое им приглашение. Это может быть несколько неудобно, т.к. при множестве открытых подключений к разным коммутаторам становится не очевидным, какое из окон соответствует определённому коммутатору.

Настройка пользователей и паролей
---------------------------------

Чтобы пароли локальных пользователей нельзя было увидеть просто заглянув в файл конфигурации коммутатора, нужно включить хэширование паролей (или другими словами - необратимое шифрование паролей):

    DGS-3200-10:4#enable password encryption
    Command: enable password encryption
    
    Success.

На коммутаторе можно создавать учётные записи администраторов и простых пользователей.

Добавляем нового пользователя с привилегиями администратора. В процессе выполнения команды будет запрошен пароль, который нужно будет подтвердить повторным набором:

    DGS-3200-10:4#create account admin stupin
    Command: create account admin stupin
    
    Enter a case-sensitive new password:*********
    Enter the new password again for confirmation:*********
    Success.

Поскольку этот коммуатор стоит у меня дома и доступен только из домашней локальной сети, я - единственный пользователь этого коммутатора, то заморачиваться с уровнями доступа я не стал.

При создании первого же администратора имеющийся администратор admin с паролем admin будет удалён автоматически. Чтобы удалить пользователя, можно воспользоваться командой delete account USER, где USER - имя удаляемого пользователя. Например, пользователя test можно удалить следующим образом:

    DGS-3200-10:4#delete account test
    Command: delete account test
    
    Success.

Посмотреть список пользователей, заведённых на коммутаторе, можно при помощи команды show account:

    DGS-3200-10:4#show account
    Command: show account
    
     Current Accounts:
     Username             Access Level
     ---------------      ------------
     stupin               Admin
     test                 User
    
     Total Entries : 2

Просмотр состояния портов и VLAN
--------------------------------

Посмотреть текущее состояние портов можно при помощи команды show ports:

    DGS-3200-10:4#show ports
    Command: show ports
    
     Port      Port            Settings             Connection          Address
               State     Speed/Duplex/FlowCtrl  Speed/Duplex/FlowCtrl   Learning
     -------  --------  ---------------------  ----------------------  ---------
     1        Enabled   Auto/Disabled           100M/Full/None          Enabled
     2        Enabled   Auto/Disabled           Link Down               Enabled
     3        Enabled   Auto/Disabled           Link Down               Enabled
     4        Enabled   Auto/Disabled           10M/Half/None           Enabled
     5        Enabled   Auto/Disabled           Link Down               Enabled
     6        Enabled   Auto/Disabled           Link Down               Enabled
     7        Enabled   Auto/Disabled           Link Down               Enabled
     8        Enabled   Auto/Disabled           Link Down               Enabled
     9    (C) Enabled   Auto/Disabled           Link Down               Enabled
     9    (F) Enabled   Auto/Disabled           Link Down               Enabled
     10   (C) Enabled   Auto/Disabled           Link Down               Enabled
     10   (F) Enabled   Auto/Disabled           Link Down               Enabled
    Notes:(F)indicates fiber medium and (C)indicates copper medium in a combo port

Как следует из примечаний, комбо-порты в выводе присутствуют дважды. Один раз комбо-порт фигурирует в списке как медный и обозначен меткой "(C)", а второй раз фигурирует в этом же списке как оптический и помечен меткой "(F)".

Для просмотра списка портов с их описанием можно воспользоваться командой show ports description:

    DGS-3200-10:4#show ports description
    Command: show ports description
    
     Port      Port            Settings             Connection          Address
               State     Speed/Duplex/FlowCtrl  Speed/Duplex/FlowCtrl   Learning
     -------  --------  ---------------------  ----------------------  ---------
     1        Enabled   Auto/Disabled           100M/Full/None          Enabled
               Description: Uplink, switch2 port 7
     2        Enabled   Auto/Disabled           Link Down               Enabled
               Description: Computer 1
     3        Enabled   Auto/Disabled           Link Down               Enabled
               Description: ATA 1
     4        Enabled   Auto/Disabled           10M/Half/None           Enabled
               Description:
     5        Enabled   Auto/Disabled           Link Down               Enabled
               Description:
     6        Enabled   Auto/Disabled           Link Down               Enabled
               Description:
     7        Enabled   Auto/Disabled           Link Down               Enabled
               Description:
     8        Enabled   Auto/Disabled           Link Down               Enabled
               Description:
     9    (C) Enabled   Auto/Disabled           Link Down               Enabled
               Description:
     9    (F) Enabled   Auto/Disabled           Link Down               Enabled
               Description:
     10   (C) Enabled   Auto/Disabled           Link Down               Enabled
               Description:
     10   (F) Enabled   Auto/Disabled           Link Down               Enabled
               Description:
    Notes:(F)indicates fiber medium and (C)indicates copper medium in a combo port

Посмотреть список VLAN и список портов в этих VLAN можно при помощи команды show vlan:

    DGS-3200-10:4#show vlan
    Command: show vlan
    
    
    VLAN Trunk State        : Disabled
    VLAN Trunk Member Ports :
    
    
    VID             : 1               VLAN Name     : default
    VLAN Type       : Static          Advertisement : Enabled
    Member Ports    :
    Static Ports    :
    Current Tagged Ports  :
    Current Untagged Ports:
    Static Tagged Ports   :
    Static Untagged Ports :
    Forbidden Ports       :
    
    VID             : 2               VLAN Name     : system
    VLAN Type       : Static          Advertisement : Disabled
    Member Ports    : 1-10
    Static Ports    : 1-10
    Current Tagged Ports  :
    Current Untagged Ports: 1-10
    Static Tagged Ports   :
    Static Untagged Ports : 1-10
    Forbidden Ports       :
    
     Total Static VLAN Entries: 2
     Total GVRP VLAN Entries: 0

Для каждой VLAN выводится список портов, фигурирующих в ней:

* В списки Static попадают те порты, для которых соответствие VLAN настроено вручную.
* В списки Current попадают те порты, для которых соответствие VLAN настроено вручную или автоматически.
* В списки Tagged попадают порты, работающие с помеченными VLAN Ethernet-кадрами.
* В списки Untagged попадают порты, которые работают с Ethernet-кадрами без метки. Такие порты назначают Ethernet-кадру метку VLAN при получении, как будто Ethernet-кадр уже пришёл с меткой, и удаляют с Ethernet-кадра внутреннюю метку перед их отправкой.
* В список Member попадают все порты, имеющиеся в этой VLAN.

Тот же самый список можно увидеть в виде более наглядной таблицы, если воспользоваться командой show vlan ports:

    DGS-3200-10:4#show vlan ports
    Command: show vlan ports
    
     Port   VID   Untagged  Tagged  Dynamic  Forbidden
    -----   ----  --------  ------  -------  ---------
     1      2       X         -       -        -
     2      2       X         -       -        -
     3      2       X         -       -        -
     4      2       X         -       -        -
     5      2       X         -       -        -
     6      2       X         -       -        -
     7      2       X         -       -        -
     8      2       X         -       -        -
     9      2       X         -       -        -
     10     2       X         -       -        -

Настройка портов и VLAN
-----------------------

Настроить описание порта можно при помощи команды config ports N description TEXT, где N - номер порта, а TEXT - текст описания. Например:

    DGS-3200-10:4#config ports 1 description Uplink, switch2 port 7
    Command: config ports 1 description Uplink, switch2 port 7
    
    Success.

Если есть необходимость, то часть портов можно административно отключить. Например, отключим порты с 3 по 6:

    DGS-3200-10:4#config ports 3-6 state disable
    Command: config ports 3-6 state disable
    
    Success.

Чтобы снова включить порты, нужно в предыдущей команде disable заменить на enable:

    DGS-3200-10:4#config ports 3-6 state enable
    Command: config ports 3-6 state enable
    
    Success.

Перед настройкой соответствия VLAN портам коммутатора, нужно создать соответствующие VLAN.

Можно создавать VLAN без указания имени, тогда имя будет назначено автоматически. Например, следующим образом можно создать VLAN с номером 2, которая получит автоматически назначенное имя VLAN2:

    DGS-3200-10:4#create vlan vlanid 2
    Command: create vlan vlanid 2
    
    Success.

При создании VLAN можно указать её имя явно. Например, для создания VLAN 2 с именем system можно воспользоваться такой командой:

    DGS-3200-10:4#create vlan system tag 2
    Command: create vlan system tag 2
    
    Success.

Если нужно поменять имя VLAN, то сделать это можно при помощи соответствующей команды. В примере ниже VLAN с номером 2 назначается имя system:

    DGS-3200-10:4#config vlan vlanid 2 name system
    Command: config vlan vlanid 2 name system
    
    Success.

Удалять VLAN можно по номеру:

    DGS-3200-10:4#delete vlan vlanid 2
    Command: delete vlan vlanid 2
    
    Success.

Или по имени:

    DGS-3200-10:4#delete vlan system
    Command: delete vlan system
    
    Success.

Прокидываем VLAN 2 в нетегированном режиме на порты с 1 по 10:

    DGS-3200-10:4#config vlan vlanid 2 add untagged 1-10
    Command: config vlan system add untagged 1-10
    
    Success.

То же самое можно сделать, указывая вместо номера VLAN её имя:

    DGS-3200-10:4#config vlan vlanid 2 add untagged 1-10
    Command: config vlan system add untagged 1-10
    
    Success.

Чтобы прокинуть VLAN на порты в тегированном режиме, слово untagged надо заменить на tagged.

Для удаления VLAN 1 с портов с 1 по 10 можно воспользоваться такой командой:

    DGS-3200-10:4#config vlan vlanid 1 delete 1-10
    Command: config vlan vlanid 1 delete 1-10
    
    Success.

Настройка IP-адреса, шлюза и статических маршрутов
--------------------------------------------------

Чтобы посмотреть текущие настройки управляющего интерфейса коммутатора, можно воспользоваться командой show ipif:

    DGS-3200-10:4#show ipif
    Command: show ipif
    
    IP Interface Settings
    
    IP Interface                : System
    IP Address                  : 10.90.90.90 (Manual)
    Subnet Mask                 : 255.0.0.0
    VLAN Name                   : default
    Interface Admin State       : Enabled
    DHCPv6 Client State         : Disabled
    Link Status                 : LinkUp
    Member Ports                : 1-10
    DHCP Option12 State         : Disabled
    DHCP Option12 Host Name     :
    
    Total Entries   : 1

Поместим интерфейс в VLAN 2, которой ранее было назначено имя system:

    DGS-3200-10:4#config ipif System vlan system
    Command: config ipif System vlan system
    
    Success.

Чтобы настроить автоматическое конфигурирование управляющего интерфейса по протоколу DHCP, можно воспользоваться командой config ipif System dhcp:

    DGS-3200-10:4#config ipif System dhcp
    Command: config ipif System dhcp
    
    Success.

Для включения клиента DHCPv6 можно воспользоваться такой командой:

    DGS-3200-10:4#config ipif System dhcpv6_client enable
    Command: config ipif System dhcpv6_client enable
    
    Success.

Отключить клиента DHCPv6 можно аналогичной командой, в которой enable нужно заменить на disable.

Для ручного задания IP-адреса и маски подсети используем такую команду:

    DGS-3200-10:4#config ipif System ipaddress 169.254.254.6/255.255.255.0
    Command: config ipif System ipaddress 169.254.254.6/24
    
    Success.

Маршрут по умолчанию можно добавить следующим образом:

    DGS-3200-10:4#create iproute default 169.254.254.1
    Command: create iproute default 169.254.254.1
    
    Success.

Посмотреть список настроенных статических маршрутов можно при помощи команды show iproute static:

    DGS-3200-10:4#show iproute static
    Command: show iproute static
    
    
    Routing Table
    
    IP Address/Netmask  Gateway          Hops   Protocol  Weight  Status
    ------------------  ---------------  -----  --------  ------  ------
    0.0.0.0/0           169.254.254.1    1      Default   None    Inactive
    
    Total Entries : 1

Полный список действующих маршрутов можно увидеть при помощи команды show iproute:

    DGS-3200-10:4#show iproute
    Command: show iproute
    
    
    Routing Table
    
    IP Address/Netmask  Gateway          Interface     Hops     Protocol
    ------------------  ---------------  ------------  --------  --------
    0.0.0.0/0           169.254.254.1    System        1         Default
    169.254.254.0/24    0.0.0.0          System        1         Local
    
    Total Entries : 2

Настройка SSH, отключение telnet и веб-интерфейса
-------------------------------------------------

Для безопасности лучше защитить сетевой трафик между администратором и коммутатором от прослушивания. Для этого достаточно включить SSH-сервер и отключить telnet-сервер.

Включаем SSH-сервер:

    DGS-3200-10:4#enable ssh
    Command: enable ssh
    
    Success.

Отключаем telnet-сервер:

    DGS-3200-10:4#disable telnet
    Command: disable telnet
    
    Success.

Отключаем веб-интерфейс:

    DGS-3200-10:4#disable web
    Command: disable web
    
    Success.

Кроме шифрования SSH позволяет защититься от атак посредника, для чего клиент при первом подключении предлагает сохранить публичный ключ сервера, а при каждом последующем подключении сверяет публичный ключ SSH-сервера с сохранённым.

Настройка DNS-клиента
---------------------

Для того, чтобы на коммутаторе можно было пользоваться доменными именами вместо IP-адресов, например, в командах ping и telnet, нужно включить и настроить DNS-клиента.

Включить DNS-клиента можно при помощи команды enable dns_resolver:

    DGS-3200-10:4#enable dns_resolver
    Command: enable dns_resolver
    
    Success.

В настройках DNS-клиента можно указать IP-адреса двух DNS-серверов: первичного и вторичного. IP-адрес первичного DNS-сервера можно настроить при помощи команды такого вида:

    DGS-3200-10:4#config name_server add 169.254.254.1 primary
    Command: config name_server add 169.254.254.1 primary
    
    Success.

Для настройки IP-адреса вторичного DNS-сервера используется аналогичная команда, но без ключевого слова primary.

Посмотреть текущие настройки DNS-клиента можно при помощи команды show name_server:

    DGS-3200-10:4#show name_server
    Command: show name_server
    
     Name Server Timeout: 3 seconds
    
     Static Name Server Table:
     Server IP Address   Priority
     ------------------- --------
     169.254.254.1       Primary
    
     Dynamic Name Server Table:
     Server IP Address   Priority
     ------------------- ---------

Теперь можно использовать доменные имена, например, в команде ping:

    DGS-3200-10:4#ping ya.ru
    Command: ping ya.ru
    
    
    Reply from 87.250.250.242, time=30ms
    Reply from 87.250.250.242, time=20ms
    Reply from 87.250.250.242, time=20ms
    
     Ping Statistics for 87.250.250.242
     Packets: Sent =3, Received =3, Lost =0

Настройка часов коммутатора
---------------------------

Настраиваем текущее время:

    DGS-3200-10:4#config time 27may2020 20:48:00
    Command: config time 27may2020 20:48:0
    
    Success.

Настраиваем часовой пояс (+5 часов ко времени по Гринвичу):

    DGS-3200-10:4#config time_zone operator + hour 5 min 0
    Command: config time_zone operator + hour 5 min 0
    
    Success.

По умолчанию переход на летнее/зимнее время отключен, но если понадобится, то отключить его можно при помощи следующей команды:

    DGS-3200-10:4#config dst disable
    Command: config dst disable
    
    Success.

Посмотреть текущее время и настройки часов можно так:

    DGS-3200-10:4#show time
    Command: show time
    
         Current Time Source  : System Clock
         Boot Time    : 27 May 2020  20:48:07
         Current Time : 27 May 2020  22:04:57
         Time Zone    : GMT +05:00
         Daylight Saving Time  : Disabled
             Offset In Minutes : 60
             Repeating    From : Apr 1st  Sun 00:00
                          To   : Oct last Sun 00:00
             Annual       From : 29 Apr 00:00
                          To   : 12 Oct 00:00

К сожалению, обычно сетевое оборудование не снабжается энергонезависимыми часами реального времени, поэтому при перезагрузке коммутатора настройки времени собьются (настройки часового пояса сохранятся). Впрочем, есть стандартный выход - использовать серверы NTP или SNTP.

Настройка синхронизации времени с серверами NTP
-----------------------------------------------

Коммутатор не поддерживает NTP, но поддерживает SNTP - упрощённую версию NTP, совместимую с ним на уровне протокола. Разница заключается в том, что SNTP не умеет отбраковывать серверы с неправильным временем и имеет меньшую точность синхронизации.

Включаем использование SNTP-сервера для синхронизации часов коммутатора:

    DGS-3200-10:4#enable sntp
    Command: enable sntp
    
    Success.

Настроим первичный SNTP-сервер:

    DGS-3200-10:4#config sntp primary 169.254.254.1
    Command: config sntp primary 169.254.254.1
    
    Success.

Для настройки вторичного SNTP-сервера, который будет использоваться для синхронизации времени при недоступности первого сервера, используется такая же команда, с той лишь разницей, что вместо ключевого слова primary нужно использовать ключевое слово secondary. У меня NTP-сервер всего один, поэтому второй я не указывал.

Проверить доступность NTP-серверов можно следующим образом:

    DGS-3200-10:4#show sntp
    Command: show sntp
    
         Current Time Source   : System Clock
         SNTP                  : Enabled
         SNTP Primary Server   : 169.254.254.1
         SNTP Secondary Server : 0.0.0.0
         SNTP Poll Interval    : 720 sec

Проверить текущее время можно при помощи уже упомянутой ранее команды show time:

    DGS-3200-10:4#show time
    Command: show time
    
         Current Time Source  : Primary SNTP Server
         Boot Time    : 27 May 2020  21:25:10
         Current Time : 27 May 2020  21:28:44
         Time Zone    : GMT +05:00
         Daylight Saving Time  : Disabled
             Offset In Minutes : 60
             Repeating    From : Apr 1st  Sun 00:00
                          To   : Oct last Sun 00:00
             Annual       From : 29 Apr 00:00
                          To   : 12 Oct 00:00

В случае успешной синхронизации в строчке Current Time Source будет фигурировать SNTP-сервер.

Настройка журналирования
------------------------

Коммутатор можно настроить так, чтобы он слал журнальные сообщения на сервер syslog.

Для этого сначала включим подсистему syslog:

    DGS-3200-10:4#enable syslog
    Command: enable syslog
    
    Success.

Коммутатор позволяет слать сообщения на 4 syslog-сервера. Настроим IP-адрес первого и единственного сервера syslog:

    DGS-3200-10:4#create syslog host 1 ipaddress 169.254.254.1 udp_port 514 state enable
    Command: create syslog host 1 ipaddress 169.254.254.1 udp_port 514 state enable
  
    Success.

Список текущих syslog-серверов можно увидеть при помощи команды show syslog host:

    DGS-3200-10:4#show syslog host
    Command: show syslog host
    
    Syslog Global State: Enabled
    
    Host Id  Host IP Address  Severity        Facility  UDP Port  Status
    -------  ---------------  --------------  --------  --------  --------
    1        169.254.254.1    All             Local0    514       Enabled
    
    Total Entries : 1

Удалить из этого списка сервер syslog под номером 1 можно при помощи такой команды:

    DGS-3200-10:4#delete syslog host 1
    Command: delete syslog host 1
    
    Success.

Для настройки rsyslog на приём syslog-пакетов от коммутатора и на запись в отдельный журнал, создадим файл /etc/rsyslog.d/switch.conf со следующими настройками:

    $ModLoad imudp
    $UDPServerRun 514
    :FROMHOST, isequal, "169.254.254.6" /var/log/switch.log
    :FROMHOST, isequal, "169.254.254.6" ~

После этого перезапустим rsyslogd:

    # systemctl restart rsyslog

Если UDP-порт 512 закрыт сетевым фильтром, не забудьте его открыть.

Чтобы настроить ротацию лога /var/log/switch.log, можно настроить logrotate. Для этого создадим файл /etc/logrotate.d/switch со следующим содержимым:

    /var/log/switch.log {
            weekly
            missingok
            rotate 10
            compress
            delaycompress
            notifempty
            create 640 root root
    }

Если всё сделано правильно, то в журналах на сервере syslog можно будет увидеть журнальные записи:

    May 27 21:39:30 169.254.254.6 INFO: Configuration saved to flash by SSH (Username: stupin   IP: 169.254.254.1)

Подобные сообщения можно увидеть и на самом коммутаторе:

    DGS-3200-10:4#show log
    Command: show log
    
    Index Date       Time     Log Text
    ----- ---------- -------- ------------------------------------------------------
    10    2020-05-27 21:39:30 Configuration saved to flash by SSH (Username: stupin
                                IP: 169.254.254.1)
    9     2020-05-27 21:34:46 Successful login through SSH (Username: stupin,IP: 169
                              .254.254.1)
    8     2020-05-27 21:30:44 SSH session timed out (Username: stupin,IP: 169.254.25
                              4.1)
    7     2000-01-01 05:01:45 Successful login through SSH (Username: stupin,IP: 169
                              .254.254.1)
    6     2000-01-01 05:00:45 Port 1 link up, 100Mbps FULL duplex
    5     2000-01-01 05:00:41 Port 4 link up, 10Mbps HALF duplex
    4     2000-01-01 05:00:41 SSH server is enabled
    3     2000-01-01 05:00:41 Port 4 link down
    2     2000-01-01 05:00:41 Port 1 link down
    1     2000-01-01 05:00:40 System started up

Настройка SNMP
--------------

### Включение SNMP и RMON

Включаем SNMP-агента:

    DGS-3200-10:4#enable snmp
    Command: enable snmp
    
    Success.

Включаем RMON:

    DGS-3200-10:4#enable rmon
    Command: enable rmon
    
    Success.

RMON - это дополнительная ветка OID'ов, включающая в себя дополнительную статистику. В частности, для меня особый интерес представляет OID с именем etherStatsCRCAlignErrors.

### Настройка представлений SNMP

Представление SNMP позволяет ограничить доступ к опредлённым веткам OID. Создадим представление ro с единственным правилом, разрешающим доступ к ветке OID 1.3.6.1:

    DGS-3200-10:4#create snmp view ro 1.3.6.1 view_type included
    Command: create snmp view ro 1.3.6.1 view_type included
    
    Success.

Если представление должно разрешать доступ к нескольким веткам, то команду можно повторить, указывая правила с другими ветками OID. При необходимости исключить из представления определённую ветку, вместо ключевого слова included в правиле можно указать excluded.

Для удаления веток из представляения можно воспользоваться аналогичной командой:

    DGS-3200-10:4#delete snmp view ro 1.3.6.1
    Command: delete snmp view ro 1.3.6.1
    
    Success.

Удалить всё представление целиком можно следующим образом:

    DGS-3200-10:4#delete snmp view ro all
    Command: delete snmp view ro all
    
    Success.

На коммутаторе по умолчанию уже настроено два представления с именами restricted и CommunityView. Т.к. использовать их я не собираюсь, то я их удалил.

Посмотреть список представлений и действующих в них правил в них можно при помощи команды show snmp view:

    DGS-3200-10:4#show snmp view
    Command: show snmp view
    
    Vacm View Table Settings
    View Name                         Subtree                             View Type
    --------------------------------  ----------------------------------  ----------
    
    ro                                1.3                                 Included
    rw                                1.3                                 Included
    
    Total Entries: 2

### Настройка доверенных узлов

Для того, чтобы ограничить доступ к управлению коммутатором и скрыть наличие коммутатора на IP-адресе, на коммутаторе предусмотрен список доверенных сетевых узлов. Если этот список не пуст, то коммутатор будет доступен только для IP-адресов из списка.

Будьте осторожны, добавляя в этот список первую запись - ей должен стать IP-адрес, с которого вы подключились к коммутатору, в противном случае вы немедленно потеряете доступ к коммутатору и получить его сможете только с добавленного в список IP-адреса, через консоль или после перезагрузки коммутатора, когда применится конфигурация, сохранившаяся в энергонезависимой памяти. Учтите, что между вами и коммутатором могут быть серверы NAT, из-за которых подключение к коммутатору будет установлено с IP-адреса, принадлежащего серверу NAT, а не вашему компьютеру. Попробуйте найти свой IP-адрес в выводе команды show session.

Добавить новый узел в список можно при помощи команды create trusted_host:

    DGS-3200-10:4#create trusted_host 169.254.254.1
    Command: create trusted_host 169.254.254.1
    
    Success.

При добавлении узла после его IP-адреса можно указать через пробел список протоколов, по которым коммутатор должен быть доступен с этого IP-адреса: ping, snmp, telnet, ssh, http, https.

Если узел уже создан, то можно добавить или удалить доступные ему протоколы:

    DGS-3200-10:4#config trusted_host 169.254.252.2 add snmp ping
    Command: config trusted_host 169.254.252.2 add snmp ping
    
    Success.
    DGS-3200-10:4#config trusted_host 169.254.252.2 delete telnet ssh http https
    Command: config trusted_host 169.254.252.2 delete telnet ssh http https
    
    Success.

В список можно добавлять не только одиночные IP-адреса, но и целые сети:

    DGS-3200-10:4#create trusted_host network 169.254.253.0/24 ping
    Command: create trusted_host network 169.254.253.0/24 ping
    
    Success.

Для удаления узлов и сетей из списка доверенных предназначены соответствующие команды:

    DGS-3200-10:4#delete trusted_host ipaddr 169.254.252.2
    Command: delete trusted_host ipaddr 169.254.252.2
    
    Success.
    DGS-3200-10:4#delete trusted_host network 169.254.253.0/24
    Command: delete trusted_host network 169.254.253.0/24
    
    Success.

Посмотреть список текущих доверенных узлов и сетей с доступными им протоколами можно при помощи команды show trusted_host:

    DGS-3200-10:4#show trusted_host
    Command: show trusted_host
    
    
    Management Stations
    
    IP Address                                  Access Interface
    ----------------------------------------------------------------
    169.254.254.1                               SNMP SSH Ping
    169.254.252.2                               SNMP Ping
    
    Total Entries: 2

### Настройка групп SNMP

Создаём группу с именем ro:

    DGS-3200-10:4#create snmp group ro v3 auth_priv read_view ro
    Command: create snmp group ro v3 auth_priv read_view ro
    
    Success.

Этой командой мы:

* добавляем группу с именем ro,
* которая будет работать по протоколу SNMP версии 3 с секретами для аутентификации и шифрования,
* которой разрешаем доступ к OID'ам из представления ro на чтение,
* у которой нет OID'ов, доступных на запись,
* у которой нет OID'ов, доступных для отсылки трапов.

Создаём группу с именем rw, которая аналогична ro, но будет иметь доступ на просмотр и изменение значений OID'ов из представления rw:

    DGS-3200-10:4#create snmp group rw v3 auth_priv read_view rw write_view rw
    Command: create snmp group rw v3 auth_priv read_view rw write_view rw
    
    Success.

На коммутаторе по умолчанию уже существуют группы с именами public, initial, private, ReadGroup, WriteGroup. Удалить их можно при помощи команды delete snmp group:

    DGS-3200-10:4#delete snmp group public
    Command: delete snmp group public
    
    Success.

Для просмотра групп SNMP можно воспользоваться командой show snmp group:

    DGS-3200-10:4#show snmp group
    Command: show snmp groups
    
    Vacm Access Table Settings
    
    Group    Name    : ro
    ReadView Name    : ro
    WriteView Name   :
    Notify View Name :
    Security Model   : SNMPv3
    Security Level   : authPriv
    
    Group    Name    : rw
    ReadView Name    : rw
    WriteView Name   : rw
    Notify View Name :
    Security Model   : SNMPv3
    Security Level   : authPriv
    
    Total Entries: 2

### Настройка сообществ SNMP

Для добавления нового сообщества SNMP с именем $ecretC0mmunity, которое будет использовать представление ro только для чтения, можно воспользоваться командой следующего вида:

    DGS-3200-10:4#create snmp community $ecretC0mmunity view ro read_only
    Command: create snmp community $ecretC0mmunity view ro read_only
    
    Success.

Для добавления нового сообщества SNMP, которое будет использовать представление rw для чтения и записи, можно воспользоваться аналогичной командой:

    DGS-3200-10:4#create snmp community Very$ecretC0mmunity view rw read_write
    Command: create snmp community Very$ecretC0mmunity view rw read_write
    
    Success.

По умолчанию на коммутаторе имеются сообщества с именами public и private, которые можно удалить командами delete snmp community:

    DGS-3200-10:4#delete snmp community public
    Command: delete snmp community public
    
    Success.

Стот учитывать, что при создании сообществ на коммутаторе автоматически создаются одноимённые группы. Поэтому после удаления сообществ следует также удалить группы с такими же именами.

Чтобы посмотреть список имеющихся на коммутаторе сообществ, можно воспользоваться командой show snmp community:

    DGS-3200-10:4#show snmp community
    Command: show snmp community
    
    
    SNMP Community Table
    Community Name                    View Name                         Access Right
    --------------------------------  --------------------------------  ------------
    $ecretC0mmunity                   ro                                read_only
    Very$ecretC0mmunity               rw                                read_write
    
    Total Entries: 2

### Настройка пользователей SNMPv3

Добавляем пользователя SNMP с именем mon:

    DGS-3200-10:4#create snmp user mon ro encrypted by_password auth sha Authentic4ti0n$ecret priv des Encrypti0n$ecret
    Command: create snmp user mon ro encrypted by_password auth sha Authentic4ti0n$ecret priv des Encrypti0n$ecret
    
    Success.

Добавленный пользователь SNMPv3 будет использовать права группы ro. В качестве секрета для аутентификации будет использоваться строка Authentic4ti0n$ecret и алгоритм хэширования SHA, а в качестве секрета для шифрования будет использоваться строка Encrypti0n$ecret и алгоритм DES. К сожалению, коммутатор не поддерживает алгоритм шифрования AES, поэтому пришлось довольствоваться DES.

Добавлять пользователя, имеющего доступ на изменение значений OID'ов я пока не буду, т.к. мне это пока не нужно.

На коммутаторе по умолчанию настроен пользователь с именем initial. Для его удаления можно воспользоваться такой командой:

    DGS-3200-10:4#delete snmp user initial
    Command: delete snmp user initial
    
    Success.

Увидеть список пользователей SNMP можно при помощи команды show snmp user:

    DGS-3200-10:4#show snmp user
    Command: show snmp user
    
    Username                          Group Name                        VerAuthPriv
    --------------------------------  --------------------------------  -----------
    mon                               ro                                V3 SHA1DES
    
    Total Entries: 1

Как можно заметить, в списке есть один пользователь с именем mon.

Обновление прошивки коммутатора
-------------------------------

На российском FTP-сервере D-Link есть каталог с прошивками для коммутатора [DGS-3200-10 Firmware](http://ftp.dlink.ru/pub/Switch/DGS-3200-10/Firmware/), однако он пустой. В разделе с прошивками для всей серии коммутаторов [DGS-3200 Series Firmware](http://ftp.dlink.ru/pub/Switch/DGS-3200%20Series/Firmware/) прошивки имеются.

Однако, самые свежие версии прошивок можно найти на российском форуме D-Link в теме [ПРОШИВКИ И ЗАПРОСЫ SNMP HowTo для коммутаторов D-Link](https://forum.dlink.ru/viewtopic.php?t=92700), они скрыты под заголовком "Бета-версии прошивок для каждой из серий - под спойлером."

Перед обновлением прошивки следует учесть два важных замечания из раздела форума:

* DGS-3200 Series: DGS-3200-10, DGS-3200-16, DGS-3200-24 (не путать с серией DES!!!)
* Для DGS-3200 Series сначала необходимо обновить прошивку, затем BootPROM до высылаемых версий.

Для скачивания прошивки с TFTP-сервера во второй слот воспользуемся командой download firmware_fromTFTP:

    DGS-3200-10:4#download firmware_fromTFTP 169.254.254.1 DGS3200_Run_2_21_B019.had image_id 2
    Command: download firmware_fromTFTP 169.254.254.1 DGS3200_Run_2_21_B019.had image_id 2
    
     Connecting to server................... Done.
     Download firmware...................... Done.  Do not power off!
     Please wait, programming flash......... Done.

Для того, чтобы коммутатор при следующей загрузке использовал прошивку из слота 2, нужно выполнить команду:

    DGS-3200-10:4#config firmware image_id 2 boot_up
    Command: config firmware image_id 2 boot_up
    
    Success.

Для немедленной перезагрузки коммутатора можно выполнить команду reboot:

    DGS-3200-10:4#reboot

Обновить загрузчик коммутатора можно только через консоль на последовательном порту. В процессе включения коммутатора нужно нажать Shift+3.

Резервное копирование конфигурации коммутатора
----------------------------------------------

Чтобы снять резервную копию текущей конфигурации коммутатора, файл можно скопировать на TFTP-сервер:

    DGS-3200-10:4#upload cfg_toTFTP 169.254.254.1 switch.cfg
    Command: upload cfg_toTFTP 169.254.254.1 switch.cfg
    
     Connecting to server................... Done.
     Upload configuration................... Done.

Чтобы сохранить конфигурацию из слота энергонезависимой памяти, команде нужно указать номер слота или имя файла:

    DGS-3200-10:4#upload cfg_toTFTP 169.254.254.1 config_id 1
    DGS-3200-10:4#upload cfg_toTFTP 169.254.254.1 config_name box.cfg

Для восстановления текущей конфигурации коммутатора из резервной копии можно воспользоваться аналогичной командой:

    DGS-3200-10:4#download cfg_fromTFTP 169.254.254.1 switch.cfg

Команда скачает файл конфигурации с TFTP-сервера и выполнит все команды настройки из него так, как будто вы ввели их с консоли сами.

Аналогичным образом, если нужно сохранить файл конфигурации в энергонезависимую память, не применяя её, можно указать номер слота или имя файла. Файл, загруженный с TFTP-сервера, будет сохранён в указанный слот или перезапишет файл с указанным именем.

Сброс конфигурации коммутатора
------------------------------

При повторной настройке коммутатора для установки в другое место может оказаться проще сбросить все настройки коммутатора и настроить его с нуля. Сброс конфигурации осуществляется следующим образом:

    DGS-3200-10:4#reset config
    Command: reset config
    
    Are you sure you want to proceed with system reset?(y/n) y
    Success.

Настройки для заметки про настройку Mikrotik
--------------------------------------------

В статье [IPSec между Debian и MikroTik](https://vladimir-stupin.blogspot.com/2015/11/ipsec-debian-mikrotik.html) я использовал следующие настройки:

Mikrotik был подключен к 3 и 4 портам коммутатора, на порты в нетегированном режиме были прокинуты VLAN 5 и 6 соответственно. Обе эти VLAN в тегированном режиме были прокинуты на порт 1, к которому был подключен мой компьютер. Тогда я использовал сегментацию портов, поэтому эти настройки здесь тоже приведены.

Включаем порты:

    # config ports 3-4 state enable

Создаём две vlan:

    # create vlan vlanid 5
    # create vlan vlanid 6

Назначаем vlan'ам имена:

    # config vlan vlanid 5 name mikrotik1
    # config vlan vlanid 6 name mikrotik2

Прокидываем vlan'ы на порты коммутатора, в которые включен Mikrotik:

    # config vlan vlanid 5 add untagged 3
    # config vlan vlanid 6 add untagged 4

Прокидываем vlan'ы на порт, к которому подключена хост-система:

    # config vlan vlanid 5 add tagged 1
    # config vlan vlanid 6 add tagged 1

Настраиваем сегментацию трафика между портами. Важно: после forward_list нужно указывать ПОЛНЫЙ список портов.

    # config traffic_segmentation 3-4 forward_list 1
    # config traffic_segmentation 1 forward_list 3,4,7-10

Сохраняем новую конфигурацию:

    # save config
