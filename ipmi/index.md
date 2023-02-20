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

Таблица алгоритмов безопасности
-------------------------------

Список поддерживаемых алгоритмов обеспечения безопасности можно посмотреть следующим образом:

    # ipmitool lan print 3 | grep 'RMCP+ Cipher Suites'
    RMCP+ Cipher Suites     : 1,2,3,6,7,8,11,12,15,16,17

Более подробную информацию о каждом из алгоритмов можно узнать следующим образом:

    # ipmitool channel getciphers ipmi 3
    ID   IANA    Auth Alg        Integrity Alg   Confidentiality Alg
    1    N/A     hmac_sha1       none            none
    2    N/A     hmac_sha1       hmac_sha1_96    none
    3    N/A     hmac_sha1       hmac_sha1_96    aes_cbc_128
    6    N/A     hmac_md5        none            none
    7    N/A     hmac_md5        hmac_md5_128    none
    8    N/A     hmac_md5        hmac_md5_128    aes_cbc_128
    11   N/A     hmac_md5        md5_128         none
    12   N/A     hmac_md5        md5_128         aes_cbc_128
    15   N/A     hmac_sha256     none            none
    16   N/A     hmac_sha256     sha256_128      none
    17   N/A     hmac_sha256     sha256_128      aes_cbc_128

Список настроенных алгоритмов можно посмотреть следующим образом:

    # ipmitool lan print 3 | grep 'Cipher Suite Priv Max'
    Cipher Suite Priv Max   : XXXXXXXXXXaXXXX

Каждая букава в строчке соответствует сочетанию алгоритма и максимального уровня привилегий пользователя, которые разрешено использовать. Таблица соответствия букв уровню привилегий приведена ниже:

|Буква|Привилегии              |
|:---:|------------------------|
|  X  |Алгоритм не используется|
|  c  |CALLBACK                |
|  u  |USER                    |
|  o  |OPERATOR                |
|  a  |ADMIN                   |
|  O  |OEM                     |

Для настройки алгоритмов можно воспользоваться такой командой:

    # ipmitool lan set 3 cipher_privs XXaXXXXXXXaXXXX

Каждый символ соответствует алгоритму с 1 по 15, но в списке поддерживаемых алгоритмов встречаются и номера больше 15. Указание более 15 символов при этом приводит к выводу сообщения об ошибке. Каким образом разрешить использовать сочетание в таком случае - не понятно.

Просмотр и настройка часов
--------------------------

Для просмотра показаний таймера реального времени можно воспользоваться такой командой:

    # ipmitool sel time get
    02/20/2023 05:41:32

Для настройки показаний таймера реального времени предназначена команда следующего вида:

    # ipmitool sel time set "02/20/2023 05:41:32"

Журнал событий
--------------

Посмотреть статистику журнала событий:

    # ipmitool sel info
    SEL Information
    Version          : 1.5 (v1.5, v2 compliant)
    Entries          : 366
    Free Space       : 65535 bytes or more
    Percent Used     : unknown
    Last Add Time    : 02/16/2023 12:11:17
    Last Del Time    : 12/08/2020 11:18:05
    Overflow         : false
    Supported Cmds   : 'Partial Add' 'Reserve' 'Get Alloc Info' 
    # of Alloc Units : 4000
    Alloc Unit Size  : 24
    # Free Units     : 3634
    Largest Free Blk : 3634
    Max Record Size  : 1

Посмотреть содержимое журнала событий:

    # ipmitool sel list

Очистить журнал событий:

    # ipmitool sel clear

Сброс модуля управления
-----------------------

При зависании веб-интерфейса модуля управления можно попробовать выполнить мягкий или жёсткий сброс одной из соответствующих команд:

    # ipmitool mc reset warm
    # ipmitool mc reset cold

Настройка порядка загрузки
--------------------------

При следующей загрузки системы войти в меню настройки BIOS:

    # ipmitool chassis bootdev bios

При следующей загрузке системы использовать в качестве источника жёсткий диск, указанный в BIOS:

    # ipmitool chassis bootdev disk

При следующей загрузке системы использовать в качестве источника CDROM:

    # ipmitool chassis bootdev cdrom

При следующей загрузке системы использовать в качестве источника сеть:

    # ipmitool chassis bootdev pxe 

Последовательный порт
---------------------

Включить поддержку доступа к последовательному порту через IPMI:

    # ipmitool sol set enabled true

Включить доступ через IPMI к последовательному порту через сетевой интерфейс 1 для пользователя 3:

    # ipmitool sol payload enable 1 3

Подключение к последовательному порту:

    # ipmitool sol activate

Завершить зависший сеанс доступа к последовательному порту:

    # ipmitool sol deactivate

Для настройки консоли на последовательном порту в GRUB 2 и Linux можно воспользоваться разделом "Настройка консоли в GRUB 2 и Linux" из статьи [Настройка текстового терминала для использования в virsh](https://stupin.su/blog/serial-console-virsh/).

Управление питанием
-------------------

Узнать текущее состояние подачи электропитания можно следующим образом:

    # ipmitool chassis power status
    Chassis Power is on

Выполнить отключение средствами ACPI:

    # ipmitool chassis power soft

Выключить питание без ACPI, подождать одну секунду и снова включить:

    # ipmitool chassis power cycle

Выключить питание без ACPI:

    # ipmitool chassis power off

Включить питание:
 
    # ipmitool chassis power on

Выполнить перезагрузку без участия ACPI: 

    # ipmitool chassis power reset

Вместо длинной команды `chassis power` можно использовать более короткий вариант - `power`.

Просмотр информации о модулях/платах
------------------------------------

Для просмотра информации о моделях, серийных номерах электронных компонентов, входящих в состав оборудования, можно воспользоваться командой:

    # ipmitool fru print

Просмотр состояния датчиков
---------------------------

Для просмотра полного списка датчиков можно воспользоваться следующей командой:

    # ipmitool sensor

Вывести текущие значения датчиков и статус их доступности:

    # ipmitool sdr list

Вывести только информацию от датчиков температуры:

    # ipmitool sdr type Temperature

Вывести информацию только от датчиков частоты вращения вентиляторов:

    # ipmitool sdr type Fan

Вывести информацию только о блоках питания:

    # ipmitool sdr type 'Power Supply'

Утилита syscfg от Intel
-----------------------

Для работы с модулем удалённого управления у Intel есть своя собственная утилита, которая называется syscfg.

Утилиту можно скачать по ссылке [Save and Restore System Configuration Utility (SYSCFG) for the Intel® Server System S9200WK Product Family](https://www.intel.com/content/www/us/en/download/19502/save-and-restore-system-configuration-utility-syscfg-for-the-intel-server-system-s9200wk-product-family.html)

Заглянул в скачанный архив [[syscfg_v14_1_build29_allos.zip]]:

    $ unzip -v syscfg_v14_1_build29_allos.zip

Увидел, что там есть deb-пакет для Ubuntu. У меня Debian, но пакет для Ubuntu подойдёт лучше, чем пакет для какой-либо другой системы. Извлёк его:

    $ unzip syscfg_v14_1_build29_allos.zip 'Linux_x64/UBUNTU/syscfg-V14.1-B29.x86_64.deb' -d .

Залил deb-пакет по SSH на сервер:

    $ scp syscfg-V14.1-B29.x86_64.deb bm5.core.ufanet.ru:

Установил пакет на сервере:

    # dpkg -i syscfg-V14.1-B29.x86_64.deb

Заглянул в список файлов, установленных пакетом:

    # dpkg -L syscfg

Руководство по использованию утилиты можно скачать на этой странице [User Guide for Intel System Configuration Utility](https://www.intel.com/content/www/us/en/support/articles/000023060/server-products.html). Скачанное руководство можно взять тут: [[Intel System Configuration Utility. User Guide|intel-syscfg-userguide-v1-03.pdf]]

Решение проблем
---------------

### Отключение ограниченного доступа

Утилита syscfg от Intel возвращает ошибку следующего вида:

KCS Policy Control Mode is currently set to "RESTRICTED". This function depends on an unrestricted KCS environment to operate.  To run utility, please change "KCS Policy Control Mode" using BMC web console or other authenticated session.

Поиск ошибки в интернете привёл на страницу [How to set the Keyboard Controller Style (KCS) Policy Control from Deny all to Allow all](https://www.intel.com/content/www/us/en/support/articles/000058730/server-products/server-boards.html).

В приведённой на этой странице команде есть ошибка - опцию `-c` нужно указывать в верхнем регистре, так что команда приобретает следующий вид:

    # ipmitool -C 17 raw 0x30 0xB4 0x03

Однако такой вызов команды приводит к следующей ошибке:

    Unable to send RAW command (channel=0x0 netfn=0x30 lun=0x0 cmd=0xb4 rsp=0xd4): Insufficient privilege level

Для того, чтобы команда сработала, нужно запустить её через сеть с указанием IP-адреса модуля удалённого управления и заведённого на нём пользователя, имеющего права администратора, вот так:

    # ipmitool -I lanplus -L ADMINISTRATOR -H 192.168.1.2 -C 17 -U admin -P $ecretP4ssw0rd raw 0x30 0xB4 0x03

### Восстановление доступа к веб-интерфейсу

На сервере модели Intel Corporation R2224WFTZSR с материнской платой Intel Corporation S2600WFT с прошивкой модуля удалённого управления версии 2.48 столкнулся с проблемой, описанной на странице [Unable to access http on RMM4 after disabling https](https://community.intel.com/t5/Server-Products/Unable-to-access-http-on-RMM4-after-disabling-https/td-p/559119): в веб-интерфейсе имеется возможность раздельного включения/выключения протоколов HTTP и HTTPS, а при отключении протокола HTTPS пропадает доступ и по протоколу HTTP. В этой статье было предложено воспользоваться утилитой syscfg, однако попытки воспользоваться ей для сброса настроек модуля удалённого управления к успеху не привели.

Зато помогла команда, найденная в статье: ["syscfg /hc https 3 enable 443" -> Invalid data in the switch parameters](https://community.intel.com/t5/Server-Products/quot-syscfg-hc-https-3-enable-443-quot-gt-Invalid-data-in-the/m-p/722554):

    # ipmitool raw 0x30 0xb1 0x01 0x79 0x00

### Высокая загрузка от kipmi0

На сервере модели Intel Corporation с материнской платой R2312GZ4GC4 Intel Corporation S2600GZ с прошивкой модуля удалённого управления версии 1.17 столкнулся с проблемой, описанной на странице [kipmi kernel helper thread kipmi0 is generating high CPU load](https://access.redhat.com/solutions/21322): утилита ipmitool не работает, при этом поток ядра с именем kipmiN (где N - цифра, совпадающая с номером устройства /dev/ipmiN) создаёт высокую нагрузку на процессор сервера (может полностью занять одно ядро процессора).

Проблема вызвана тем, что модуль удалённого управления не умеет отправлять процессору сигнал о завершении некоторых операций, поэтому устройство приходится периодически опрашивать. Опросом устройства занимается специально предназначенный для этого поток ядра с именем вида kipmiN. В некоторых ситуациях устройство завершает операцию, но драйвер продолжает считать, что операция ещё не завершена и продолжает опрашивать устройство в ожидании готовности, что приводит к повышенной нагрузке на процессор сервера.

Одно из возможных решений приведено в той же статье. Смотрим параметры модуля удалённого управления:

    $ cat /proc/ipmi/0/params
    kcs,i/o,0xca2,rsp=1,rsi=1,rsh=0,irq=0,ipmb=32

Удаляем устройство `/dev/ipmi0`, передав драйверу команду на удаление с этими параметрами следующим образом:

    # echo "remove,kcs,i/o,0xca2,rsp=1,rsi=1,rsh=0,irq=0,ipmb=32" > /sys/module/ipmi_si/parameters/hotmod

Стоит учесть, что оболочка, выполняющая команду echo, может зависнуть в ожидании завершения операции ввода-вывода. Нужно подождать завершения операции, что может занять от 8 до 30 минут.

Затем можно попытаться снова добавить устройство `/dev/ipmi0` с теми же параметрами командой следующего вида:

    # echo "add,kcs,i/o,0xca2,rsp=1,rsi=1,rsh=0,irq=0,ipmb=32" > /sys/module/ipmi_si/parameters/hotmod

Перед попытками запуска утилиты ipmitool следует уменьшить время непрерывной работы потока kipmiN, указав сколько миллисекунд в секунду он может работать:

    # echo 100 > /sys/module/ipmi_si/parameters/kipmid_max_busy_us

Затем можно попробовать снова воспользоваться утилитой ipmitool. При необходимости, если нагрузка на процессор снизилась недостаточно, лимит времени работы потока kipmiN можно уменьшить ещё.

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

Использованные материалы
------------------------

* [egernst/ipmi-sol.md](https://gist.github.com/egernst/66febb5b95a1d303881db05c926e0b63)
* [ipmitool: Reset and manage IPMI (Intelligent Platform Management Interface) / ILO (Integrated Lights Out) remote board on Linux servers](https://www.pc-freak.net/blog/ipmitool-reset-manage-ipmi-intelligent-platform-management-interface-ilo-integrated-lights-remote-board-linux-servers/)

Дополнительная информация
-------------------------

* [[Фирменная утилита syscfg от Intel|syscfg_v14_1_build29_allos.zip]]
* [[Intel System Configuration Utility. User Guide|intel-syscfg-userguide-v1-03.pdf]]
