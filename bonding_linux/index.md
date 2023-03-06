Объединение сетевых интерфейсов в Linux
=======================================

[[!tag linux bonding bridge openvswitch lacp]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------
Объединение сетевых интерфейсов в единый интерфейс с целью повышения отказоустойчивости или использования суммарной пропускной способности двух и более сетевых интерфейсов в Linux осуществляется с помощью модуля ядра, который называется `bonding`. По названию драйвера само объединение сетевых интерфейсов в Linux тоже часто называют бондингом. В случае других сетевых устройств подобное объединение может называться агрегацией, "эзерчанелом" или "портчанелом" (от имени интерфейса Ether-Channel или Port-Channel на сетевом устройстве) и т.п.

Для загрузки модуля ядра достаточно ввести команду:

    # modprobe bonding

Для того, чтобы этот модуль ядра загружался автоматически при загрузке операционной системы в Debian нужно вписать имя модуля в файл `/etc/modules`.

Модуль может создавать несколько объединённых интерфейсов, каждый из которых может работать в одном из следующих режимов:

|Название     |Код|Отказоустойчивость|Балансировка нагрузки|Описание                                                                                                                                                                                                   |
|:------------|:-:|:----------------:|:-------------------:|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|balance-rr   | 0 |        Да        |         Да          |Отправка сетевых пакетов поочередно через все агрегированные интерфейсы (политика round-robin).                                                                                                            |
|active-backup| 1 |        Да        |         Нет         |Отправка сетевых пакетов через активный интерфейс. При отказе активного интерфейса (link down и т.д.) автоматически переключается на резервный интерфейс.                                                  |
|balance-xor  | 2 |        Да        |         Да          |Передача сетевых пакетов распределяются между интерфейсами на основе формулы (могут использоваться MAC-адрес, IP-адреса или номера IP-портов). Один и тот же интерфейс работает с определенным получателем.|
|broadcast    | 3 |        Да        |         Нет         |Отправка всех сетевых пакетов через все агрегированные интерфейсы (широковещательная отправка).                                                                                                            |
|802.3ad      | 4 |        Да        |         Нет         |Link Agregation Control Protocol, LACP - IEEE 802.3ad.                                                                                                                                                     |
|balance-tlb  | 5 |        Да        |         Да          |Входящие сетевые пакеты принимаются только активным сетевым интерфейсом, исходящие распределяется в зависимости от текущей загрузки каждого интерфейса.                                                    |
|balance-alb  | 6 |        Да        |         Да          |Исходящие сетевые пакеты распределяется между интерфейсами, входящие сетевые пакеты принимаются всеми интерфейсами.                                                                                        |

Примечания:

* Для использования режимов `balance-rr`, `balance-xor` и `broadcast` на коммутаторе сети должен быть настроено статическое объединение портов (static port trunking).
* Для использования режима `802.3ad` данный режим должен поддерживаться сетевым коммутатором.
* Для использования режима `balance-alb` требуются сетевые карты, поддерживающие смену MAC-адреса.

Ручная настройка
----------------

В разных дистрибутивах Linux используются разные системы управления сетевыми интерфейсами, которые, как правило, используют в своей работе пакет утилиту `ifenslave` из одноимённого пакета. Эта утилита может не устанавливаться по умолчанию, для её установки из сетевых репозиториев нужно сначала настроить сеть или прибегнуть к использованию флеш-накопителя и компьютера, уже подключенного к сети, что может оказаться неудобным. Может оказаться проще настроить сетевой интерфейс вручную, без использования утилиты `ifenslave`.

Рассмотрим для примера ручную настройку агрегации в режиме `802.3ad`.

Загрузим модуль ядра:

    # modprobe bonding

При загрузке модуля ядра можно сразу указать опции для будущих агрегирующих сетевых интерфейсов:

    # modprobe bonding mode=802.3ad xmit_hash_policy=layer2+3 miimon=100 lacp_rate=fast

В случае нескольких агрегирующих сетевых интерфейсов, можно подготовить псевдонимы модуля ядра и указать для каждого из псевдонимов модуля собственные настройки. Для этого необходимо добавить в каталог `/etc/modprobe.d` новые файлы с расширением `.conf`. Например, создадим файл `/etc/modprobe.d/bonding.conf` со следующим содержимым:

    alias bond0 bonding
    optinons bond0 mode=802.3ad xmit_hash_policy=layer2+3 miimon=100 lacp_rate=fast

В таком случае при попытке загрузить модуль ядра `bond0` с помощью приведённой ниже команды получится создать одноимённого сетевой интерфейс с указанными опциями:

    # modprobe bond0

Однако то же самое можно проделать и с помощью файловой системы `/sys/class/net/` описанным ниже образом.

Создадим агрегирующий интерфейс с именем `bond0`:

    # echo "+bond0" > /sys/class/net/bonding_masters

Переведём его в режим `802.3ad`:

    # echo "802.3ad" > /sys/class/net/bond0/bonding/mode

Настроим балансировку исходящего трафика с использованием MAC- и IP-адресов пакетов:

    # echo "layer2+3" > /sys/class/net/bond0/bonding/xmit_hash_policy

Настраиваем интервал проверки исправности связи (в миллисекундах):

    # echo "100" > /sys/class/net/bond0/bondign/miimon

Настраиваем частый обмен информацией между сторонами агрегации:

    # echo "fast" > /sys/class/net/bond0/bonding/lacp_rate

Добавляем в агрегацию сетевые интерфейсы `eno1` и `eno2`, не активируя их:

    # ip link set eno1 master bond0
    # ip link set eno2 master bond0

Активируем агрегирующий интерфейс:

    # ip link set bond0 up

Настраиваем на агрегирующем интерфейсе IP-адрес и, при необходимости, маршруты через него:

    # ip addr add 172.16.7.2/24 dev bond0
    # ip route add default dev bond0 via 172.16.7.1

Проверка состояния
------------------

Состояние агрегирующего сетевого интерфейса `bond0` можно узнать из файла `/proc/net/bonding/bond0`. Все интерфейсы должны быть активны:

    $ fgrep Status /proc/net/bonding/bond0
    MII Status: up
    MII Status: up
    MII Status: up

Первая строчка соответствует состоянию агрегирующего сетевого интерфейса, а последующие - состоянию входящих в его состав агрегируемых сетевых интерфейсов. Если значение каждого из состояний соответствует тексту `up`, то агрегация полностью исправна.

Кроме этого, в случае с LACP, идентификаторы `Aggregator ID` у всех интерфейсов, входящих в агрегацию, должны совпадать:

    $ fgrep 'Aggregator ID' /proc/net/bonding/bond0
    Aggregator ID: 15
    Aggregator ID: 15

Настройка в Debian
------------------

Для того, чтобы описанные выше ручные настройки восстанавливались в Debian при загрузке, нужно установить пакет `ifenslave`:

    # apt-get install ifenslave

И вписать настройки в файл `/etc/network/interfaces`:

    auto eno1
    iface eno1 inet manual
        bond-master bond0
    
    auto eno2
    iface eno2 inet manual
        bond-master bond0
    
    auto bond0
    iface bond0 inet static
        bond-slaves eno1 eno2
        bond-mode 802.3ad
        bond-xmit-hash-policy layer2+3
        bond-miimon 100
        bond-lacp-rate fast
        address 172.16.7.2/24
        gateway 172.16.7.1

Опции `bond-master` в объединяемых сетевых интерфейсах позволяют возвращать сетевой интерфейс в объединение, если зачем-то понадобится выключить и снова включить их с помощью команд `ifdown` и `ifup`:

    # ifdown eno1
    # ifup eno1

Если опцию `auto` заменить на `allow-hotplug`, то можно будет пользоваться демоном `ifplugd` для настройки сетевых интерфейсов после их физического исчезновения и возврата в систему, например, если это внешний USB-адаптер Ethernet.

Чтобы зафиксировать имена сетевых интерфейсов, можно создать файл `/etc/udev/rules.d/70-persistent-net.rules`, содержащий по одной строчке следующего вида для каждого из сетевых интерфейсов:

    SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="00:1e:67:5b:08:17", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="eno1"

Для применения новых правил нужно выполнить следующие команды:

    # udevadm control -R
    # udevadm trigger

Сетевому интерфейсу с MAC-адресом `00:1e:67:5b:08:17` будет назначено имя `eno1`.

Настройка в CentOS 6
--------------------

В случае с CentOS 6 утилита `ifenslave` входит в состав пакета `iputils`, который устанавливается по умолчанию при установке операционной системы.

В CentOS 6 конфигурация сетевых интерфейсов находится в отдельных файлах. Для того, чтобы при загрузке операционной системы восстанавливались настройки, заданные нами выше вручную, нужно отредактировать по одному файлу для каждого из сетевых интерфейсов. В примере ниже сетевые интерфейсы будут называться `eth1` и `eth2`.

Настройки сетевого интерфейса `eth1` впишем в файл конфигурации `/etc/sysconfig/network-scripts/ifcfg-eth1`:

    DEVICE=eth1
    ONBOOT=yes
    BOOTPROTO=none
    SLAVE=yes
    MASTER=bond0

Аналогичным образом настройки сетевого интерфейса `eth2` впишем в файл конфигурации `/etc/sysconfig/network-scripts/ifcfg-eth2`:

    DEVICE=eth2
    ONBOOT=yes
    BOOTPROTO=none
    SLAVE=yes
    MASTER=bond0

Наконец, настройки агрегирующего сетевого интерфейса `bond0` впишем в файл конфигурации `/etc/sysconfig/network-scripts/ifcfg-bond0`:

    DEVICE=bond0
    ONBOOT=yes
    BOOTPROTO=none
    IPADDR=172.16.7.2
    NETMASK=255.255.255.0
    GATEWAY=172.16.7.1
    BONDING_OPTS="mode=802.3ad xmit_hash_policy=layer2+3 miimon=100 lacp_rate=fast"

В данном случае настройки сетевого интерфейса соответствуют опциям, которые можно передать модулю ядра `bonding` при его ручной загрузке описанной выше командой `modprobe`.

Тестовая среда 1
----------------

Для проверки правильности настройки агрегаций я решил воспользоваться двумя виртуальными машинами с Debian и CentOS. В качестве системы виртуализации я воспользовался KVM и графическим интерфейсом virt-manager, настроенными в соответствии со статьёй [[Настройка KVM и virt-manager в Debian 11|debian11_kvm]]. Предполагалось на каждой из виртуальных машин настроить по два сетевых интерфейса, объединённых в LACP. По плану предусматривалось настроить на системе виртуализации два сетевых моста и подключить к каждому из них по одному сетевому интерфейсу от каждой из виртуальных машин так, чтобы в итоге получилась такая схема:

    .---- vm1 ----.    .-------------- host ---------------.    .---- vm2 ----.
    |    bond0    |    |     virbr1      |     virbr2      |    |    bond0    |
    |------.------|    |--------.--------+--------+--------+    |------.------|
    | eno1 | eno2 |    | vm1-p1 | vm2-p1 | vm1-p2 | vm2-p2 |    | eth1 | eth2 |
    `------'------'    `--------'--------'--------'--------'    '------'------'
        |     |            |         |        |        |           |       |
        `-----(------------'         `--------(--------(-----------'       |
              |                               |        |                   |
              `-------------------------------'        `-------------------'

Для начала настроим на системе в виртуализации два сетевых моста с именами `virbr1` и `virbr2`, для чего впишем в файл конфигурации `/etc/network/interfaces` следующие настройки:

    auto virbr1
    iface virbr1 inet manual
        bridge_ports none
        bridge_stp off
        bridge_fd 0
        bridge_maxwait 0
    
    auto virbr2
    iface virbr2 inet manual
        bridge_ports none
        bridge_stp off
        bridge_fd 0
        bridge_maxwait 0

Активируем эти сетевые интерфейсы при помощи следующих команд:

    # ifup virbr1
    # ifup virbr2

На виртуальных машинах настроим сетевые интерфейсы следующим образом:

[[vm_nic.png]]

С помощью команды следующего вида можно посмотреть или отредактировать XML-конфигурацию виртуальной машины:

    # virsh edit vm

Фрагмент XML-конфигурации, соответствующий сетевому интерфейсу, выглядит следующим образом:

    <interface type='bridge'>
      <mac address='52:54:00:16:5e:3b'/>
      <source bridge='virbr1'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </interface>

Чтобы сетевые интерфейсы `vnet` создавались в системе всегда под одним и тем же именем, добавим в конфигурацию каждого из интерфейсов строчку вида `<target dev='vm1-p1'/>` с его именем в системе виртуализации:

    <interface type='bridge'>
      <mac address='52:54:00:16:5e:3b'/>
      <source bridge='virbr1'/>
      <target dev='vm1-p1'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </interface>

Стоит отметить, что постоянные имена сетевых интерфейсов не должны начинаться с префиксов `vnet`, `vif`, `macvtap` или `macvlan`, в противном случае такое постоянное имя может быть проигнорировано.

К сожалению, в этой тестовой среде агрегация сетевых интерфейсов работала загадочно. При неактивном сетевом интерфейсе `virbr2` связь между виртуальными машинами оставалась, а вот при неактивном сетевом интерфейсе `virbr1` связь пропадала.

На виртуальной машине с CentOS, судя по содержимому файла `/proc/net/bonding/bond0`, не происходило согласование агрегации по протоколу LACP с партнёром по агрегации - виртуальной машиной с Debian.

На виртуальной машине с Debian можно было наблюдать с виду более благоприятную картину, однако при ближайшем рассмотрении оказывалось, что второй сетевой интерфейс имеет идентификатор, отличный от интерфейсов агрегирующего интерфейса и первого интерфейса, входящего в агрегацию:

    # fgrep 'Aggregator ID' /proc/net/bonding/bond0
            Aggregator ID: 1
    Aggregator ID: 1
    Aggregator ID: 2

При исправно работающей согласованной по протоколу LACP агрегации, картина должна была бы выглядеть следующим образом:

    # fgrep 'Aggregator ID' /proc/net/bonding/bond0
    Aggregator ID: 1
    Aggregator ID: 1

Было подозрение, что сетевые мосты не транслируют трафик протокола LACP. В пользу этой версии говорило наблюдение за трафиком LACP на сетевых интерфейсах vm*-p* и virbr с помощью `tcpdump`:

    # tcpdump -npi vm1-p1 -e ether proto 0x8809

На сетевых интерфейсах vnet можно было наблюдать попытки отправить пакет по протоколу LACP на мультикаст-адрес, в то время как на мостовых интерфейсах virbr подобный трафик отсутствовал:

    16:16:59.047875 fe:54:00:16:5e:3b > 01:80:c2:00:00:02, ethertype Slow Protocols (0x8809), length 124: LACPv1, length 110

Я нашёл в интернете страницу, где была описана возникшая у меня проблема: [Multicast frames in Linux bridge dropped](https://answerbun.com/unix-linux/multicast-frames-in-linux-bridge-dropped/), однако единственное предложенное решение сводилось к изменению исходных текстов модуля ядра `bridge` и его пересборке.

Если попытаться включить пропуск мультикаст-адреса `01:80:c2:00:00:02` мостовым интерфейсом, то можно увидеть такую ошибку:

    # echo 4 > /sys/class/net/virbr1/bridge/group_fwd_mask 
    -bash: echo: write error: Invalid argument

После пересборки ядра Linux, которая описана ниже, становится возможным выполнить указанную выше команду без ошибок. Включаем пропуск мультикаст-трафика LACP на обоих сетевых мостах:

    # echo 4 > /sys/class/net/virbr1/bridge/group_fwd_mask 
    # echo 4 > /sys/class/net/virbr2/bridge/group_fwd_mask 

Как ни странно, но даже после этого партнёры по агрегации не смогли согласовать агрегацию по протоколу LACP. На этот раз я обнаружил в журналах `/var/log/messages` сообщения следующего вида:

    Mar  3 17:23:26 debian   kernel: [   91.295406] bond0: (slave eno1): failed to get link speed/duplex

Очевидно, модуль ядра `bonding` не смог узнать скорость на интерфейсе, потому что мы используется сетевую карту модели `virtio`, которая является виртуальной. Попробуем заменить в настройках виртуальной машины модель сетевой карты на `rtl8139` (для канальной скорости 100 Мбит/с) или на `e1000` (для канальной скорости 1 Гбит/с), вот так:

    <interface type="bridge">
      <mac address="52:54:00:16:5e:3b"/>
      <source bridge="virbr1"/>
      <target dev="vm1-p1"/>
      <model type="e1000"/>
      <link state="up"/>
      <address type="pci" domain="0x0000" bus="0x08" slot="0x00" function="0x0"/>
    </interface>

Выключим виртуальные машины и снова включим их. На этот раз виртуальные машины согласовали агрегацию по протоколу LACP. Отключение любого одного сетевого интерфейса на одной из виртуальной машине не приводит к потере связи между виртуальными машинами:

[[deactive-vm1-p2.png]]

### Пересборка ядра Linux

Для пересборки пакетов с ядром Linux понадобится около 60 гигабайт места на диске и ещё некоторый объём для установки пакетов, необходимых для сборки.

Первым делом установим пакеты, которые точно понадобятся для сборки:

    # apt-get install dpkg-dev quilt devscripts

Без пакета `dpkg-dev` команда `apt-get source` не сможет распаковать скачанные пакеты с исходными текстами, с помощью утилиты `quilt` я буду создавать заплатки к пакету, а с помощью утилиты `dch` из пакета `devscripts` буду редактировать журнал изменений пакета.

Теперь скачаем и распакуем пакет с исходными текстами ядра Linux:

    $ apt-get source linux

Для сборки пакета требуется установить дополнительные пакеты. Сделаем это, пометив установленные пакеты как установленные автоматически, чтобы их потом было легко удалить из системы:

    # apt-get install --mark-auto dpkg-dev quilt devscripts build-essential:native debhelper-compat dh-exec dh-python bison flex kernel-wedge libssl-dev:native libssl-dev libelf-dev:native libelf-dev lz4 dwarves python3-docutils zlib1g-dev libcap-dev libpci-dev autoconf automake libtool libglib2.0-dev libudev-dev libwrap0-dev asciidoctor gcc-multilib libaudit-dev libbabeltrace-dev libbabeltrace-dev libdw-dev libiberty-dev libnewt-dev libnuma-dev libperl-dev libunwind-dev libopencsd-dev python3-dev python3-sphinx python3-sphinx-rtd-theme texlive-latex-base texlive-latex-extra dvipng patchutils

Перейдём в каталог с распакованными исходными текстами пакета:

    $ cd linux-5.10.162

С помощью `quilt` создадим новую заплатку:

    $ quilt new allow-all-standard-group-mac-addresses

Добавим в текущую заплатку отслеживание изменений в файле `net/bridge/br_private.h`:

    $ quilt add net/bridge/br_private.h

Откроем файл `net/bridge/br_private.h` на редактирование, находим макрос `BR_GROUPFWD_RESTRICTED` и присваиваем ему значение `0x0u`.

Обновляем текущую заплатку, внеся в неё отличия в отредактированном нами файла:

    $ quilt refresh

Добавим в журнал изменений пакета описание нашей доработки и поменяем версию `5.10.162-1` на `5.10.162-1ufanet1`:

    $ dch -i

Добавленная мной запись в журнале выглядела следующим образом:

    linux (5.10.162-1ufanet1) UNRELEASED; urgency=medium
    
      * Allow use all standard group MAC-addresses in group_fwd_mask of bridge
        kernel module
    
     -- Vladimir Stupin <stupin_v@ufanet.ru>  Thu, 02 Mar 2023 17:00:32 +0500

Запускаем сборку пакетов:

    $ dpkg-buildpackage -us -uc -rfakeroot

По окончании процесса сборки переходим в родительский каталог:

    $ cd ..

Среди собранных двоичных пакетов будет пакет с именем `linux-image-5.10.0-21-amd64-unsigned_5.10.162-1ufanet1_amd64.deb`. Установим его с помощью следующей команды:

    # dpkg -i linux-image-5.10.0-21-amd64-unsigned_5.10.162-1ufanet1_amd64.deb

Осталось перезагрузить систему, чтобы можно было загрузить в ядро обновлённый модуль.

Тестовая среда 2
----------------

На этот раз вместо стандартных для Linux сетевых мостов, создаваемых с помощью модуля ядра `bridge`, я решил воспользоваться программным коммутатором Open vSwitch и реализовать следующую схему:

                       .-------------- host ---------------.
                       |             vswitch1              |
    .---- vm1 ----.    |-----------------.-----------------|    .---- vm2 ----.
    |    bond0    |    |      bond0      |      bond1      |    |    bond0    |
    |------.------|    |--------.--------+--------+--------+    |------.------|
    | eno1 | eno2 |    | vm1-p1 | vm1-p2 | vm2-p1 | vm2-p2 |    | eth1 | eth2 |
    `------'------'    `--------'--------'--------'--------'    '------'------'
        |     |            |         |        |        |           |       |
        `-----(------------'         |        '--------(-----------'       |
              |                      |                 |                   |
              `----------------------'                 `-------------------'

На компьютере с системой виртуализации предполагается создать программный коммутатор Open vSwitch с именем `vswitch1`, а на нём создать две агрегации с именами `bond1` и `bond2`, поддерживающие работу по протоколу LACP. В первую агрегацию включаются сетевые интерфейсы виртуальной машины с Debian, а во вторую агрегацию - сетевые интерфейсы виртуальной машины с CentOS. При такой схеме агрегацию на каждой из виртуальных машин можно будет проверять и настраивать независимо.

Установим пакет с Open vSwitch на компьютере с системой виртуализации:

    # apt-get install openvswitch-switch

Вместо настроенных ранее сетевых мостов `virbr1` и `virbr2` пропишем в файле конфигурации `/etc/network/interfaces` конфигурацию программного коммутатора `vswitch1`:

    auto vswitch1
    allow-ovs vswitch1
    iface vswitch1 inet manual
        ovs_type OVSBridge
        ovs_ports none

После этого создадим его с помощью команды:

    # ifup vswitch1

Теперь поменяем конфигурацию сетевых интерфейсов виртуальных машин с помощью команды вида:

    # virsh edit vm

Сделаем сетевые интерфейсы пригодными для подключения к программному коммутатору Open vSwitch. Чтобы KVM не пытался добавить эти интерфейсы в мосты, заменим строчки `<interface type='bridge'>` на `<interface type='ethernet'>` и удалим строчки вида `<source bridge="virbr1"/>`:

    <interface type='ethernet'>
      <mac address='52:54:00:16:5e:3b'/>
      <target dev='vm1-p1'/>
      <model type='e1000'/>
      <link state='up'/>
      <address type='pci' domain='0x0000' bus='0x08' slot='0x00' function='0x0'/>
    </interface>

Таким образом после запуска виртуальных машин мы получим сетевые интерфейсы Ethernet, не подключенные к какому-либо мосту. Создадим агрегирующие интерфейсы и включим в них интерфейсы виртуальных машин:

    # ovs-vsctl add-bond vswitch1 bond0 vm1-p1 vm1-p2 lacp=active other_config:lacp_time=fast other_config:bond-miimon-interval=100 other_config:bond-hash-basis=2
    # ovs-vsctl add-bond vswitch1 bond1 vm2-p1 vm2-p2 lacp=active other_config:lacp_time=fast other_config:bond-miimon-interval=100 other_config:bond-hash-basis=2

Состояние виртуального коммутатора `vswitch1` стало выглядеть следующим образом:

    # ovs-vsctl show
    0c1a793c-69d7-4606-8a14-2ea9317eaa47
        Bridge vswitch1
            Port bond0
                Interface vm1-p1
                Interface vm1-p2
            Port vswitch1
                Interface vswitch1
                    type: internal
            Port bond1
                Interface vm2-p1
                Interface vm2-p2
        ovs_version: "2.15.0"

Теперь виртуальный коммутатор запомнил конфигурацию, которую нужно применять к сетевым интерфейсам виртуальных машин и она будет автоматически восстанавливаться даже после выключения виртуальной машины.

В этой конфигурации агрегация интерфейсов по протоколу LACP тоже заработала ожидаемым образом, причём в этом случае не потребовалось исправлять исходные тексты модуля `bridge` и пересобирать ядро Linux.

Использованные материалы
------------------------

* [Механизмы агрегации сетевых каналов](https://wiki.astralinux.ru/pages/viewpage.action?pageId=158604474)
* [Preparing a bonded interface](https://www.ibm.com/docs/en/linux-on-systems?topic=connection-bonded-interface)
* [man interfaces-bond(5)](https://manpages.debian.org/testing/ifupdown-ng/interfaces-bond.5.en.html)
* [Linux bonding — объединение сетевых интерфейсов в Linux](https://www.adminia.ru/linux-bonding-obiedinenie-setevyih-interfeysov-v-linux/)
* [Ralph Mönchmeyer. KVM/qemu, libvirt, virt-manager – persistent names for virtual network interfaces of guest systems](https://linux-blog.anracom.com/2016/02/07/kvmqemu-libvirt-virt-manager-persistent-names-for-the-virtual-network-interfaces-of-guest-systems/)
* [Using advanced tcpdump filters / General trace principles / Tracing Ethernet header type LACP](https://my.f5.com/manage/s/article/K2289#6)
* [Multicast frames in Linux bridge dropped](https://answerbun.com/unix-linux/multicast-frames-in-linux-bridge-dropped/)
* [An oddly specific post about group_fwd_mask](https://interestingtraffic.nl/2017/11/21/an-oddly-specific-post-about-group_fwd_mask/)
* [libvirt / Domain XML format / Element and attribute overview / Devices / Network interfaces / Generic ethernet connection](https://libvirt.org/formatdomain.html#generic-ethernet-connection)
* [Link Aggregation and LACP with Open vSwitch](https://blog.scottlowe.org/2012/10/19/link-aggregation-and-lacp-with-open-vswitch/)
* [Radovan Brezula. Playing with Bonding on Openvswitch](https://brezular.com/2011/12/04/openvswitch-playing-with-bonding-on-openvswitch/)
* [Debian Linux Kernel Handbook / Chapter 4. Common kernel-related tasks](https://www.debian.org/doc/manuals/debian-kernel-handbook/ch-common-tasks.html)
