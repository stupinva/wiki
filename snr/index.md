Настройка коммутатора SNR-S2985G-8T
===================================

[[!toc startlevel=2 levels=3]]

Профессиональным сетевым администраторам эта заметка покажется совершенно бесполезной, т.к. в ней описываются совершенно базовые вещи. Моя профессия связана с Linux-серверами, а не компьютерными сетями, но для общего развития я иногда пытаюсь изучать смежные области. В этой заметке собраны команды, которые могут пригодиться мне самому.

В целом интерфейс командной строки коммутатора похож на таковой у коммутаторов Cisco.

Подключение к консоли
---------------------

Для подключения к консоли коммутатора я воспользовался кабелем для COM-порта, идущим в комплекте с коммутатором и программой minicom.

Для изменения настроек minicom, используемых по умолчанию, можно воспользоваться такой командой:

    # minicom -s

По умолчанию COM-порт коммутатора настроен так:

* Скорость обмена данными - 9600 бод
* Контроль чётности - отсутствует
* Битов данных - 8
* Стоп-битов - 1

После явного ручного указания всех этих настроек у меня получился такой файл /etc/minicom/minirc.dfl:

    # Автоматически сгенерированный файл - используйте "minicom -s" для
    # изменения параметров.
    pu port             /dev/ttyS0
    pu baudrate         9600
    pu bits             8
    pu parity           N
    pu stopbits         1

Теперь для подключения к консоли осталось просто запустить команду:

    # minicom

Выйти из minicom можно по нажатию следующих клавиш:

    Ctrl+A Z Q

По умолчанию на коммутаторе настроен пользователь admin с паролем admin.

Первоначальную настройку коммутатора можно производить и по сети. По умолчанию на нём настроен IP-адрес 192.168.1.1 с маской 255.255.255.0 и включен telnet.

Просмотр информации о коммутаторе
---------------------------------

Для просмотра инфорации о модели коммутаторе, его MAC-адресах, версиях прошивки, загрузчика, серийного номера, можно воспользоваться командоу show version:

    SNR-S2985G-8T#show version
      SNR-S2985G-8T Device, Compiled on Jan 23 14:49:06 2017
      sysLocation Ufa, 50 years of October, 12-26
      CPU Mac xx:xx:xx:xx:xx:xx
      Vlan MAC xx:xx:xx:xx:xx:xx
      SoftWare Version 7.0.3.5(R0241.0137)
      BootRom Version 7.2.21
      HardWare Version 1.1.2
      CPLD Version N/A
      Serial No.:xxxxxxxxxxxxxxxxxx
      Copyright (C) 2017 NAG LLC
      All rights reserved
      Last reboot is cold reset.
      Uptime is 0 weeks, 0 days, 2 hours, 10 minutes

Управление файлами
------------------

На коммутаторе имеется встроенная флеш-память, на которой хранятся файлы с загрузчиком прошивки, прошивкой коммутатора и его конфигурацией, применяемой при загрузке коммутатора.

Увидеть список файлов во флеш-памяти можно при помощи команды dir:

    switch2#dir
    
    total  13293K
    -rw-        13.0M           nos.img
    -rw-        1.8K            startup.cfg
    
    Drive : flash:
    Size:30.0M  Used:14.1M  Avaliable:15.9M  Use:47%

Файл nos.img - это прошивка коммутатора, файл startup.cfg - это конфигурация коммутатора, которая применится при его загрузке.

Также во флеш-памяти имеется скрытый файл boot.rom с загрузчиком прошивки коммутатора. Узнать информацию о нём можно только явным образом указав его имя:

    switch2#dir boot.rom
    
    -rw-        385.5K          boot.rom
    
    Drive : flash:
    Size:30.0M  Used:14.1M  Avaliable:15.9M  Use:47%

Предполагаю, что это было сделано для защиты файла от удаления некомпетентными лицами.

Удалять файлы можно при помощи команды delete, копировать - при помощи команды copy, а переименовывать при помощи команды rename.

Также имеется команда cd для изменения текущего каталога, которая для этого коммуатора, похоже, не имеет смысла. Можно было бы изменить текущий каталог с корневого каталога флеш-памяти на корневой каталог карты CompactFlash, но в этом коммутаторе нет слота для карт памяти CompactFlash. Команды для создания новых каталогов тоже не предусмотрено.

Чтобы посмотреть текущую конфигурацию коммутатора, можно воспользоваться командой show running-config:

    switch2#show running-config

Чтобы сохранить текущую конфигурацию во флеш-память, нужно записать её в файл с указанным именем. Если нужно сохранить текущую конфигурацию в файл startup.cfg, то сделать это можно командой write running-config startup.cfg:

    switch2#write running-config startup.cfg
    Write running-config to startup.cfg on switch successful
    switch2#%Apr 13 13:46:30 2020 Write configuration successfully!

Можно делать резервные копии файлов уже имеющихся во флеш-памяти. Например, можно сделать резервную копию только что сохранённого файла:

    switch2#copy startup.cfg startup2.cfg
    Write ok.
    switch2#dir
    
    total  13295K
    -rw-        13.0M           nos.img
    -rw-        1.8K            startup.cfg
    -rw-        1.8K            startup2.cfg
    
    Drive : flash:
    Size:30.0M  Used:14.0M  Available:16.0M  Use:47%

Это может пригодиться для того, чтобы вернуться к предыдущей заведомо рабочей конфигурации. Если копия больше не нужна, её можно удалить:

    switch2#delete startup2.cfg
    Delete file, Are you sure? (Y/N)?[N]Y
    Delete file ok.

Аналогичным образом можно делать резервные копии прошивки и загрузчика. Правда, во флеш-памяти не так-то много места, но на одну резервную копию прошивки места должно хватить.

    switch2#copy nos.img nos2.img
    
    Begin to write local file, please wait...
    
    Write ok.
    switch2#copy boot.rom boot2.rom
    
    Begin to write local file, please wait...
    
    Write ok.
    switch2#dir
    
    total  26970K
    -rw-        385.5K          boot2.rom
    -rw-        13.0M           nos.img
    -rw-        13.0M           nos2.img
    -rw-        1.8K            startup.cfg
    
    Drive : flash:
    Size:30.0M  Used:27.4M  Available:2.6M  Use:91%

Правильно пользуясь резервными копиями, можно уменьшить вероятность проблем при обновлении прошивки, которые могут возникнуть из-за внезапного пропадания электричества или связи с TFTP-сервером.

Можно указать коммутатору использовать при загрузке файл конфигурации с определённым именем. Чтобы коммутатор при загрузке применял конфигурацию из файла startup.cfg, можно воспользоваться такой командой:

    switch2#boot startup-config startup.cfg
    flash:/startup.cfg will be used as the startup-config file at the next time!

После указания имени файла с начальной конфигурацией коммутатору можно будет не указывать его имя явно:

    switch2#write running-config
    Confirm to overwrite current startup-config configuration [Y/N]:Y
    Write running-config to current startup-config successful

Можно указать коммутатору использовать при загрузки и прошивку из файла с другим именем. Делается это следующим образом:

    switch2#boot img nos.img primary 
    flash:/nos.img will be used as the primary img file at the next time!

Можно указать коммутатору резервную прошивку на случай проблем с основной. Делается это при помощи такой команды:

    switch2#boot img nos2.img backup
    flash:/nos2.img will be used as the backup img file at the next time!

Посмотреть текущие используемые при загрузке файлы можно с помощью команды show boot:

    switch2#show boot
    Booted files on switch
    The primary img file at the next boot time:       flash:/nos.img
    The backup img file at the next boot time:        flash:/nos2.img
    Current booted img file:                          flash:/nos.img
    
    The startup-config file at the next boot time:    flash:/startup.cfg
    Current booted startup-config file:               flash:/startup.cfg

Настройка начальных сведений о коммутаторе
------------------------------------------

Вход в режим настройки (выход осуществляется по команде exit):

    SNR-S2985G-8T#config terminal

Установка имени коммутатора:

    SNR-S2985G-8T(config)#hostname switch2

Настройка контактов сетевого администратора:

    switch2(config)#sysContact vladimir@stupin.su

Настройка местоположения устройства:

    switch2(config)#sysLocation Ufa

Осталось выйти из режима настройки командой exit и сохранить конфигурацию командой write running-config. В дальнейшем я не буду упоминать о необходимости входа в режим настройки и напиоминать о необходимости сохранять изменения. Признаком того, что команда должна быть введена в режиме настройки, служит текст "(config)" в приглашении коммутатора.

Настройка пользователей и паролей
---------------------------------

Чтобы пароли локальных пользователей нельзя было увидеть просто заглянув в файл конфигурации коммутатора, нужно включить хэширование паролей (или другими словами - необратимое шифрование паролей):

    switch2(config)#service password-encryption

Добавляем нового пользователя с привилегиями администратора:

    switch2(config)#username stupin privilege 15 password $ecretPassw0rd

Поскольку этот коммуатор стоит у меня дома и доступен только из домашней локальной сети, я - единственный пользователь этого коммутатора, то заморачиваться с уровнями доступа я не стал.

Удалить имеющегося пользователя по умолчанию admin можно следующим образом:

    switch2(config)#no username admin

Посмотреть список пользователей, зашедших на коммутатор, можно при помощи команды show users:

    switch2#show users
     vty 0-15: telnet users
     vty 16-31: ssh users
     -------------------------------------------------------------------------------------------
     Line              User                                Location         Time
     vty 16            stupin                              169.254.254.1    May 27 13:28:13 2020

Просмотр состояния портов и VLAN
--------------------------------

Посмотреть текущее состояние портов можно при помощи команды show interface ethernet status:

    switch2#show interface ethernet status
    Codes: A-Down - administratively down, E-Down - errdisable down, a - auto, f - force, G - Gigabit
    
    Interface  Link/Protocol  Speed   Duplex  Vlan   Type            Alias Name
    1/0/1      UP/UP          a-100M  a-FULL  trunk  G-TX            stupin.su
    1/0/2      UP/UP          a-100M  a-FULL  2      G-TX            USR-RS485-Ethernet
    1/0/3      DOWN/DOWN      auto    auto    2      G-TX            TCL
    1/0/4      DOWN/DOWN      auto    auto    2      G-TX
    1/0/5      UP/UP          a-100M  a-FULL  2      G-TX            Mariya
    1/0/6      UP/UP          a-100M  a-FULL  3      G-TX            ufanet
    1/0/7      UP/UP          a-100M  a-FULL  2      G-TX            Yuri
    1/0/8      UP/UP          a-100M  a-FULL  4      G-TX            ertelecom
    1/0/9      DOWN/DOWN      auto    auto    1      SFP
    1/0/10     DOWN/DOWN      auto    auto    1      SFP

Посмотреть список VLAN и список портов в этих VLAN можно при помощи команды show vlan:

    switch2#show vlan
    VLAN Name         Type       Media     Ports
    ---- ------------ ---------- --------- ----------------------------------------
    1    default      Static     ENET      Ethernet1/0/9       Ethernet1/0/10
    2    System       Static     ENET      Ethernet1/0/1       Ethernet1/0/2
                                           Ethernet1/0/3       Ethernet1/0/4
                                           Ethernet1/0/5       Ethernet1/0/7
    3    ufanet       Static     ENET      Ethernet1/0/1(T)    Ethernet1/0/6
    4    ertelecom    Static     ENET      Ethernet1/0/1(T)    Ethernet1/0/8

Порты в режиме транка, работающие с Ethernet-кадрами с меткой VLAN, помечены буквой T. Остальные порты настроены в режиме доступа - работают с Ethernet-пакетами без меток VLAN.

Настройка портов и VLAN
-----------------------

Вход в режим настройки порта (выход осуществляется по команде exit):

    switch2(config)#interface ethernet 1/0/1

В режиме настройки интерфейса можно задать его описание:

    switch2(config-if-ethernet1/0/1)#description stupin.su

Перед настройкой VLAN на портах коммутатора можно настроить описание каждой VLAN:

    switch2(config)#vlan 3
    switch2(config-vlan3)#name ufanet
    switch2(config-vlan3)#exit

Для полного удаления VLAN с коммутатора и всех портов можно воспользоваться простой командой:

    switch2(config)#no vlan 3
    
Можно добавлять порты в VLAN, а можно добавлять VLAN на порт.

Порты в VLAN добавляются следующим образом:

    switch2(config)#vlan 2
    switch2(config-vlan2)#switchport interface ethernet 1/0/1                                                  
    Set the port Ethernet1/0/1 access vlan 2 successfully
    switch2(config-vlan2)#exit

Таким образом можно добавить порт в VLAN только в режиме доступа.

Настроить VLAN в режиме доступа на порту можно и так:

    swithc2(config)#interface ethernet 1/0/2
    switch2(config-if-ethernet1/0/2)#switchport access vlan 2
    Set the port Ethernet1/0/2 access vlan 2 successfully

По умолчанию все порты коммутатора настроены в режиме доступа в VLAN 1 - принимают Ethernet-кадры без меток и помечают их как принадлежащие VLAN 1.

Чтобы переключить порт в режим транка, можно воспользоваться такой командой:

    switch2(config)#interface ethernet 1/0/1
    switch2(config-if-ethernet1/0/1)#switchport mode trunk
    Set the port Ethernet1/0/1 mode Trunk successfully

Теперь можно настроить на транк-порту нетегированную VLAN:

    switch2(config-if-ethernet1/0/1)#switchport trunk native vlan 2
    Set the port Ethernet1/0/1 native vlan 2 successfully

И можно настроить на транк-порту все остальные VLAN, которые должны снабжаться метками:

    switch2(config-if-ethernet1/0/1)#switchport trunk allowed vlan 3,4
    set the trunk port Ethernet1/0/1 allowed vlan successfully.

Настройка IP-адреса и шлюза
---------------------------

Настроим на коммутаторе виртуальный интерфейс в VLAN 2 с указанным IP-адресом:

    switch2(config)#interface vlan 2
    switch2(config-if-vlan2)#ip address 169.254.254.24 255.255.255.0
    
После настройки нужного нам IP-адреса можно удалить с коммутатора IP-адрес по умолчанию из VLAN 1:

    switch2(config-if-vlan1)#no ip address 192.168.1.1 255.255.255.0

Шлюз по умолчанию настраивается следующим образом:

    switch2(config)#ip default-gateway 169.254.254.1

Настройка SSH и отключение telnet
---------------------------------

Для безопасности лучше защитить сетевой трафик между администратором и коммутатором от прослушивания. Для этого достаточно включить SSH-сервер и отключить telnet-сервер.

Включаем SSH-сервер:

    switch2(config)#ssh-server enable
    ssh is enabled successfully. 

Отключаем telnet-сервер:

    switch2(config)#no telnet-server enable

Кроме шифрования SSH позволяет защититься от атак посредника, для чего клиент при первом подключении предлагает сохранить публичный ключ сервера, а при каждом последующем подключении сверяет публичный ключ SSH-сервера с сохранённым.

К сожалению, в прошивке коммутатора не предусмотрена возможность отключения веб-сервера.

Настройка часов коммутатора
---------------------------

Настраиваем текущее время:

    switch2#clock set 20:22:50 2020.04.13
    Current time is Mon Apr 13 20:22:50 2020 [UTC]

Настраиваем часовой пояс:

    switch2(config)#clock timezone Yekaterinburg add 5

Отключаем переход на летнее/зимнее время:

    switch2(config)#no clock summer-time

Посмотреть текущее время можно так:

    switch2#show clock 
    Current time is Sun May 10 15:11:01 2020 [Yekaterinburg+05:00]

К сожалению, обычно сетевое оборудование не снабжается энергонезависимыми часами реального времени, поэтому при перезагрузке коммутатора настройки времени собьются (настройки часового пояса сохранятся). Впрочем, есть стандартный выход - использовать серверы NTP или SNTP.

Настройка синхронизации времени с серверами NTP
-----------------------------------------------

Включаем использование NTP-сервера для синхронизации часов коммутатора:

    switch2(config)#ntp enable
    switch2(config)#ntp server 169.254.254.1

Проверить доступность NTP-серверов можно следующим образом:

    switch2#show ntp session
    
      server                                  stratum    type          rootdelay    rootdispersion    trustlevel
    * 169.254.254.1                           2          unicast       21.683 ms     0.000 ms          10     

У меня NTP-сервер всего один.

Настройка журналирования
------------------------

Коммутатор можно настроить так, чтобы он слал журнальные сообщения на сервер syslog. Для этого достаточно указать IP-адрес сервера syslog:

    switch2(config)#logging 169.254.254.1

Для настройки rsyslog на приём syslog-пакетов от коммутатора и на запись в отдельный журнал, создадим файл /etc/rsyslog.d/switch2.conf со следующими настройками:

    $ModLoad imudp
    $UDPServerRun 514
    :FROMHOST, isequal, "169.254.254.24" /var/log/switch2.log
    :FROMHOST, isequal, "169.254.254.24" ~

После этого перезапустим rsyslogd:

    # systemctl restart rsyslog

Если UDP-порт 512 закрыт сетевым фильтром, не забудьте его открыть.

Чтобы настроить ротацию лога /var/log/switch2.log, можно настроить logrotate. Для этого создадим файл /etc/logrotate.d/switch со следующим содержимым:

    /var/log/switch2.log {
            weekly
            missingok
            rotate 10
            compress
            delaycompress
            notifempty
            create 640 root root
    }

Если всё сделано правильно, то в журналах на сервере syslog можно будет увидеть журнальные записи:

    May 10 15:07:29 169.254.254.24  switch2 %May 10 15:07:27:350 2020 MODULE_UTILS_SSH[tSshdSessionTask0]:SSH: User stupin login successfully from 169.254.254.1 
    May 10 15:20:11 169.254.254.24  switch2 %May 10 15:20:10:020 2020 MODULE_UTILS_SSH[tSshdSessionTask0]:SSH: User stupin logout from 169.254.254.1

Подобные сообщения можно увидеть и на самом коммутаторе:

    switch2#show logging 
    Current messages in SDRAM:131
    
    131 %May 10 15:22:52:305 2020 <warnings> MODULE_UTILS_SSH[tSshdSessionTask0]:SSH: User stupin login successfully from 169.254.254.1 
    
    130 %May 10 15:20:10:020 2020 <warnings> MODULE_UTILS_SSH[tSshdSessionTask0]:SSH: User stupin logout from 169.254.254.1

Настройка SNMP
--------------

У меня на работе используются коммутаторы SNR, однако сетевые администраторы на них обчно настраивают SNMP второй версии. Мне же было интересно узнать, поддерживает ли коммутатор SNMP третьей версии и насколько хорошо эта поддержка будет работать. Поэтому SNMP второй версии я настраивать даже не пробовал.

### Включение SNMP и RMON

Включаем SNMP-агента:

    switch2(config)#snmp enable
    switch2(config)#snmp-server enable

Включаем RMON:

    switch2(config)#rmon enable

RMON - это дополнительная ветка OID'ов, включающая в себя дополнительную статистику. В частности, для меня особый интерес представляет OID с именем [etherStatsCRCAlignErrors](http://www.circitor.fr/Mibs/Html/R/RMON-MIB.php#etherStatsCRCAlignErrors).

### Настройка представлений SNMP

Представление SNMP позволяет ограничить доступ к опредлённым веткам OID. Создадим представление ro с единственным правилом, разрешающим доступ к ветке OID 1.3.6.1:

    switch2(config)#snmp view ro 1.3.6.1. include

Если представление должно разрешать доступ к нескольким веткам, то команду можно повторить, указывая правила с другими ветками OID. При необходимости исключить из представления определённую ветку, вместо ключевого слова include в правиле можно указать exclude.

Для удаления веток из представляения слева от команды нужно указать ключевое слово no:

    switch2(config)#no snmp view ro 1.3.6.1. include

Удалить всё представление целиком можно следующим образом:

    switch2(config)#snmp view ro
    
Представление v1defaultviewname, существующее на коммутаторе по умолчанию, удалить почему-то не получается.

Посмотреть список представлений и действующих в них правил в них можно при помощи команды show snmp view:

    switch2(config)#show snmp view                             
    View Name:ro
            1.3.6.1.
           -Included    active
    View Name:rw
            1.3.6.1.
           -Included    active
    View Name:v1defaultviewname
            1.0.
           -Included    active
            1.2.
           -Included    active
            1.3.
           -Included    active

### Список контроля доступа

Для того, чтобы разрешить доступ к SNMP-агенту только определённым IP-адресам, создадим список управления доступом под номером 1:

    switch2(config)#access-list 1 permit host-source 169.254.254.1 vlanId 2
    switch2(config)#access-list 1 permit host-source 169.254.252.2 vlanId 2

Правила из списков управления доступом можно посмотреть следующим образом:

    switch2(config)#show access-lists
    access-list 1(used 0 time(s)) 2 rule(s)
       rule ID 1: permit host-source 169.254.254.1 vlanId 2
       rule ID 2: permit host-source 169.254.252.2 vlanId 2

Команде show access-list можно указать номер конкретного списка доступа.

### Настройка групп SNMP

Создаём группу с именем ro:

    switch2(config)#snmp group ro authpriv read ro access 1

Этой командой мы:

- добавляем группу с именем ro,
- которая будет работать по протоколу SNMP версии 3 с секретами для аутентификации и шифрования,
- которой разрешаем доступ к OID'ам из представления ro на чтение,
- у которой нет OID'ов, доступных на запись,
- у которой нет OID'ов, доступных для отсылки трапов.
- которой разрешаем доступ с IP-адресов из списка управления доступом №1.

Создаём группу с именем rw, которая аналогична ro, но будет иметь доступ на чтение и изменение значений OID'ов из представляения rw:

    switch2(config)#snmp-server group rw authpriv read rw write rw access 1

Посмотреть на список групп SNMP можно при помощи команды show snmp group:

    switch2(config)#show snmp group 
    Group Name:ro
                Security Level:AuthPriv
    Read View:ro
    
    Write View:<no writeview specified>
    Notify View:<no notifyview specified>
        access-list 1
    
    Group Name:rw
                Security Level:AuthPriv
    Read View:rw
    
    Write View:rw
    
    Notify View:<no notifyview specified>
        access-list 1

Вывод команды трудно назвать структурированным, но разобраться можно. Сначала идёт название группы, а ниже - её свойства. Если бы разработчики прошивки добавили перед названиями представлений  и перед строчкой access-list такие же отступы, как перед Security Level, то было бы гораздо нагляднее.

### Настройка сообществ SNMP

Для настройки сообщества SNMP с именем $ecretC0mmunity, которое будет использовать представление ro только для чтения и будет иметь возможность делать запросы с IP-адресов, разрешённых списком доступа 1, можно воспользоваться командой следующего вида:

    switch2(config)#snmp community ro 0 $ecretC0mmunity access 1 read ro

Аналогичным образом можно добавить сообщество с правами на чтение и запись OID'ов из представления rw:

    switch2(config)#snmp community rw 0 Wery$ecretC0mmunity access 1 read rw write rw

Для удаления сообщества можно воспользоваться командой no snmp community:

    switch2(config)#no snmp community 0 $ecretC0mmunity

Чтобы посмотреть список имеющихся на коммутаторе сообществ, можно воспользоваться командой show snmp status:

    switch2(config)#show snmp status
    System Name : NAG LLC
    System Contact : vladimir@stupin.su
    System Location : Ufa
    Trap disable
    RMON enable
    Community Information:
            Community string: Wery$ecretC0mmunity
            Community access: Read-Write
            Community read view name: rw
            Community write view name: rw
            Community string: $ecretCommunity
            Community access: Read-only
            Community read view name: ro
            Community write view name: v1defaultviewname
    V1/V2c Trap Host Information:
    V3 Trap Host Information:
    Security IP is Enabled.

Здесь вывод тоже не достаточно структурирован: сообщества и их права идут подряд одной сплошной стеной. Но разобраться также можно.

Как видно из вывода команды, если не указано представление, то используется представление-заглушка v1defaultviewname. При настройке сообществ, имеющих доступ на чтение и запись, можно указать два представления: для чтения и для записи. При настройке сообществ только для чтения имеет смысл указать только одно представление - то, которое будет ограничивать доступ на чтение. Поскольку в режиме только для чтения представление для записи не нужно, то в это поле записывается то самое представление-заглушка v1defaultviewname. Видимо именно поэтому это представление нельзя удалить. Хотя на мой взгляд, это сомнительное решение. Лучше бы вместо него указывалось такое же представление, которое используется только для чтения.

### Настройка пользователей SNMPv3

Добавляем пользователя SNMP с именем mon:

    switch2(config)#snmp user mon ro authPriv aes Encrypti0n$ecret auth sha Authentic4ti0n$ecret access 1

Добавленный пользователь будет использовать права группы ro, будет использовать протокол SNMP версии 3 и делать запросы с IP-адресов, разрешённых списоком доступа 1. В качестве секрета для аутентификации будет использоваться строка Authentic4ti0n$ecret и алгоритм хэширования SHA, а в качестве секрета для шифрования будет использоваться строка Encrypti0n$ecret и алгоритм AES.

Добавлять пользователя, имеющего доступ на изменение значений OID'ов я пока не буду, т.к. мне это пока не нужно.

Просматриваем список пользователей SNMP:

    switch2(config)#show snmp user
    User name: mon
    
    Engine ID: 18c3f8f08277e135
    
    Auth Protocol:SHA    Priv Protocol:AES-CFB-128
    Row status:active    access-list 1

Как можно заметить, в списке есть один пользователь с именем mon.

### Проблемы с SNMP

После настройки SNMP на коммутаторе, я попробовал поставить его на контроль в Zabbix. Однако, опрос работал не стабильно, в последних данных были только данные об активности портов, а данные о трафике и количестве ошибок на портах не снимались. В журнале сервера Zabbix /var/log/zabbix/zabbix_server.log при этом появлялись ошибки следующего вида:

    6226:20200510:113414.322 resuming SNMP agent checks on host "switch2": connection restored
    6226:20200510:113419.416 SNMP agent item "ifOperStatus.1" on host "switch2" failed: first network error, wait for 30 seconds
    6226:20200510:113459.507 SNMP agent item "ifOperStatus.5" on host "switch2" failed: another network error, wait for 30 seconds
    6226:20200510:113538.618 SNMP agent item "ifOperStatus.2" on host "switch2" failed: another network error, wait for 30 seconds
    6226:20200510:113608.757 resuming SNMP agent checks on host "switch2": connection restored

У меня на коммутаторе была установлена прошивка версии 7.0.3.5(R0241.0137) и я решил попробовать её обновить на более свежую. Вдруг поможет?

Обновление прошивки коммутатора
-------------------------------

Рекомендуемые прошивки для коммутаторов модели SNR-S2985G-8T можно взять по ссылке [data.nag.ru/SNR Switches/Firmware/SNR-S2985G/recommended/](http://data.nag.ru/SNR%20Switches/Firmware/SNR-S2985G/recommended/). В каталоге лежит текстовый файл с описанием изменений в каждой из версий прошивки и zip-архив с прошивками и загрузчиками. Перед обновлением прошивки коммутатора стоит ознакомиться с примечаниями в файле README_first.txt. Новые версии прошивок могут не загружаться старыми версиями загрузчика, поэтому может понадобиться вместе с прошивкой обновить и загрузчик. Загрузчик в таком случае стоит обновить первым.

Обновление прошивки коммутатора:

    switch2#copy tftp://169.254.254.1/SNR-S2985G-48T(24T_8T)(POE)(UPS)(RPS)_7.0.3.5(R0241.0339)_nos.img nos.img
    Confirm to overwrite the existed destination file?  [Y/N]:Y
    Begin to receive file, please wait...
    Get Img file size success, Img file size is:13609688(bytes).
    ##################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################
    File transfer complete.
    Recv total 13609688 bytes
    
    Begin to write local file, please wait...
    
    Write ok.
    close tftp client.

Если в процессе копирования файла nos.img пропадёт электричество или связь между коммутатором и TFTP-сервером, то загрузчик возьмёт прошивку из файла nos2.img.

Перезагрузить коммутатор можно командой reload. Если коммутатор успешно загрузился, то можно обновить резервную копию прошивки, скопировав файл nos.img в nos2.img.

Обновление загрузчика коммутатора:

    switch2#copy tftp://169.254.254.1/SNR-S2985G-8T(POE)(RPS)(UPS)_7.2.40_boot.rom boot.rom
    Confirm to overwrite the existed destination file?  [Y/N]:Y
    Begin to receive file, please wait...
    #############################################################################
    File transfer complete.
    Recv total 394800 bytes
    
    Begin to write local file, please wait...
    
    Write ok.
    close tftp client.

Хотя файл небольшой, но и в процессе его обновления может пропасть электричество или связь. При пропадании электричества без консольного подключения восстановить загрузчик не удастся. Однако на этот случай у нас уже есть резервная копия с именем boot2.rom, и можно будет просто скопировать её содержимое в файл boot.rom.

Кстати, обновление прошивки помогло устранить проблемы с нестабильной работой SNMP.

Резервное копирование конфигурации коммутатора
----------------------------------------------

Чтобы снять резервную копию конфигурации коммутатора, файл можно скопировать на TFTP-сервер:

    switch2#copy startup.cfg tftp://169.254.254.1/switch2.cfg
    Confirm copy file [Y/N]:Y
    Begin to send file, please wait...
    
    File transfer complete.
    close tftp client.

Аналогичным образом можно загрузить конфигурацию с TFTP-сервера. Для этого надо лишь поменять в команде copy источник и цель местами.
