Настройка IPMI
==============

[[!tag ipmi debian linux]]

Оглавление
----------

[[!toc startlevel=2 levels=4]]

Загрузка модулей ядра
---------------------

Для начала нужно загрузить в ядро модули для работы с IPMI:

    # modprobe ipmi_si
    # modprobe ipmi_devintf
    # modprobe ipmi_msghandler

Если в файловой системе появилось устройство /dev/ipmi0, значит IPMI-контроллер успешно определился операционной системой. Для того, чтобы необходимые модули загружались автоматически при загрузке системы, нужно добавить их имена в файл /etc/modules:

    ipmi_si
    ipmi_devintf
    ipmi_msghandler

Установка пакетов
-----------------

В Debian для установки утилиты `ipmitool` достаточно установки одноимённого пакета:

    # apt-get install ipmitool

Настройка сетевых интерфейсов
-----------------------------

Для просмотра текущих настроек сетевого интерфейса 3 можно воспользоваться такой командой:

    # ipmitool lan print 3

Мне попадались только системы, у которых есть три сетевых интерфейса с номерами 1, 2 и 3. Если указать не существующий номер интерфейса, команда выведет сообщение об ошибке такого вида:

    Invalid channel: 4

Переключение сетевого интерфейса 3 в режим статически прописанных настроек:

    # ipmitool lan set 3 ipsrc static

Настройка IP-адреса на сетевом интерфейсе 3:

    # ipmitool lan set 3 ipaddr 192.168.1.2
    Setting LAN IP Address to 192.168.1.2

Настройка маски сети на сетевом интерфейсе 3:

    # ipmitool lan set 3 netmask 255.255.255.0
    Setting LAN Subnet Mask to 255.255.255.0

Настройка сетевого шлюза по умолчанию на сетевом интерфейсе 3:

    # ipmitool lan set 3 defgw ipaddr 192.168.1.1
    Setting LAN Default Gateway IP to 192.168.1.1

Управление пользователями
-------------------------

Просмотр списка пользователей на сетевом интерфейсе 1:

    # ipmitool user list 1
    ID  Name	     Callin  Link Auth	IPMI Msg   Channel Priv Limit
    1                    false   false      true       ADMINISTRATOR
    2   root             false   true       true       ADMINISTRATOR
    3   zabbix           true    true       true       USER
    4   admin            true    true       true       ADMINISTRATOR

Смена имени пользователя:

    # ipmitool user set name 3 zabbix

Смена пароля пользователя:

    # ipmitool user set password 3 $ecretP4ssw0rd
    Set User Password command successful (user 3)

Выдача прав пользователю на доступ к сетевому интерфейсу 1:

    # ipmitool channel setaccess 1 3 callin=on ipmi=on link=on privilege=2
    Set User Access (channel 1 id 3) successful.

Список возможных уровней привилегий пользователей:

|Уровень|Описание             |
|:-----:|---------------------|
|   1   |Callback level       |
|   2   |User level           |
|   3   |Operator level       |
|   4   |Administrator level  |
|   5   |OEM Proprietary level|
|  15   |No access            |

Отбор прав пользователя на доступ к сетевым интерфейсам 2 и 3:

    # ipmitool channel setaccess 2 3 callin=off ipmi=off link=off privilege=15
    Set User Access (channel 2 id 3) successful.
    # ipmitool channel setaccess 3 3 callin=off ipmi=off link=off privilege=15
    Set User Access (channel 3 id 3) successful.

Включение пользователя:

    # ipmitool user enable 3

Удалённый доступ
----------------

После настройки сетевого интерфейса и пользователя становится возможным вызывать утилиту ipmitool для просмотра информации и настройки удалённых серверов:

    $ ipmitool -H 192.168.1.2 -L user -U zabbix -P $ecretP4ssw0rd type 'Power Supply'

Важно в опции `-L` указать минимально необходимый уровень привилегий, потому что по умолчанию утилита использует привилегии администратора. Если у пользователя нет привилегий администратора, то утилита выдаст ошибку следующего вида:

    Activate Session error:	Requested privilege level exceeds limit

Возможные уровни привилегий:

* callback
* user
* operator
* administrator

Чтобы не передавать открытым текстом пароль в командную строку, где его смогут увидеть другие пользователи, можно воспользоваться файлом с паролем. Например, сделать это можно следующим образом:

    $ echo -n "$ecretP4ssw0rd" > .pwd
    $ ipmitool -H 192.168.1.2 -L user -U zabbix -f .pwd sdr type 'Power Supply'

Если на пути между клиентом и интерфейсом IPMI находится фаервол, то необходимо открыть доступ к UDP-порту 623 (соответствующий протокол называется IPMI over LAN).

Дополнительная информация
-------------------------

### Минимальная настройка

    ipmitool lan print 1
  
    ipmitool lan set 1 password myPaSsW0rD
    ipmitool lan set 1 user
    ipmitool lan set 1 access on

### С ограниченными привилегиями

    # Просмотр настроек интерфейса 1
    ipmitool lan print 1
  
    # Выставляем настройки интерфейса
    ipmitool lan set 1 ipaddr 192.168.1.4
    ipmitool lan set 1 netmask 255.255.255.0
    ipmitool lan set 1 defgw ipaddr 192.168.1.1
  
    # Выставляем доступные методы аутентификации для каждого уровня привилегий
    ipmitool lan set 1 auth callback ''
    ipmitool lan set 1 auth user md5
    ipmitool lan set 1 auth operator ''
    ipmitool lan set 1 auth admin ''
  
    # Включаем доступ через интерфейс
    ipmitool lan set 1 access on
