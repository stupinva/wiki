Репозитории и пакеты CentOS
===========================

[[!toc startlevel=2 levels=4]]

Для настройки репозиториев используются файлы `/etc/yum.repos.d/*.repo` в формате INI следующего вида:

    [base]
    name=CentOS-$releasever - Base
    mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os
    #baseurl=https://mirror.centos.org/centos/$releasever/os/$basearch/
    gpgcheck=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
    enabled=1

Где:

* `[base]` - секция, начинающая описание нового репозитория. Имя секции произвольное, но для наглядности желательно, чтобы оно тем или иным образом намекало на тип репозитория,
* `name` - имя репозитория для отображения администратору,
* `mirrorlist` - URL, по которому можно найти список зеркал этого репозитория. Если нужно указать какое-то определённое зеркало, то вместо этой опции нужно использовать опцию `baseurl`,
* `baseurl` - URL, по которому расположен репозиторий. Желательно вместо определённого адреса указывать список зеркал с помощью опции `mirrorlist` для распределения нагрузки по зеркалам,
* `gpgcheck` - булевая опция, принимающая два значения: 1 - нужно проверять GPG-подписи пакетов, 0 - не нужно проверять GPG-подписи пакетов,
* `gpgkey` - при включенной проверке GPG-подписей пакетов можно указать расположение публичного GPG-ключа, при помощи которого будет проверяться GPG-подпись,
* `enabled` - булевая опция, указывающая на то, нужно ли использовать этот репозиторий: 1 - ипользовать, 0 - не использовать.

Кроме этих опций поддерживаются также следующие:

* `includepkgs` - список пакетов, которые можно брать из этого репозитория. Имена пакетов перечисляются через пробел, в именах можно использовать шаблоны имён со звёздочкой в качестве символа подстановки,
* `exclude` - списко пакетов, которые нельзя брать из этого репозитория. Аналогично, имена пакетов перечисляются через пробел, в именах можно использовать шаблоны имён со звёздочкой в качестве символа подстановки,
* `priority` - приоритет репозитория. Чем больше число, тем ниже приоритет. При наличии в разных репозиториях пакетов с одним и тем же именем предпочтение будет отдаваться пакетам из репозиториев с более высоким приоритетом, невзирая на версию пакета.

Официальные репозитории
-----------------------

Базовый репозиторий `/etc/yum.repos.d/CentOS-Base.repo`:

    [base]
    name=CentOS-$releasever - Base
    mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os
    #baseurl=https://mirror.centos.org/centos/$releasever/os/$basearch/
    gpgcheck=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
    enabled=1

Репозиторий с обновлениями `/etc/yum.repos.d/CentOS-Updates.repo`:

    [updates]
    name=CentOS-$releasever - Updates
    enabled=0
    mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates
    #baseurl=https://mirror.centos.org/centos/$releasever/updates/$basearch/
    gpgcheck=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
    enabled=1

Репозиторий с дополнительными пакетами `/etc/yum.repos.d/CentOS-Extras.repo`:

    [extras]
    name=CentOS-$releasever - Extras
    mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras
    #baseurl=https://mirror.centos.org/centos/$releasever/extras/$basearch/
    gpgcheck=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
    enabled=0

Ещё один репозиторий с дополнительными пакетами `/etc/yum.repos.d/CentOS-Plus.repo`:

    [centosplus]
    name=CentOS-$releasever - Plus
    mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus
    #baseurl=https://mirror.centos.org/centos/$releasever/centosplus/$basearch/
    gpgcheck=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
    enabled=0

Репозиторий `/etc/yum.repos.d/CentOS-Contrib.repo` с пакетами, собранными пользователями для собственных нужд:

    [contrib]
    name=CentOS- - Contrib
    mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=contrib
    #baseurl=https://mirror.centos.org/centos/$releasever/contrib/$basearch/
    gpgcheck=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
    enabled=0

Репозиторий `/etc/yum.repos.d/CentOS-Debuginfo.repo` с пакетами, содержащими отладочные данные:

    [base-debuginfo]
    name=CentOS-$releasever - Debuginfo
    baseurl=https://debuginfo.centos.org/$releasever/$basearch/
    gpgcheck=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Debug-6
    enabled=0

Репозитории для неподдерживаемых релизов системы можно найти по URL `http://vault.centos.org`.

Репозитории EPEL
----------------

EPEL - сокращение от Extra Packages for Enterprise Linux 6.

Для подключения основного репозитория с двоичными пакетами создаём файл `/etc/yum.repo.d/EPEL.repo`:

    [epel]
    name=Extra Packages for Enterprise Linux $release - $basearch
    baseurl=https://archives.fedoraproject.org/pub/archive/epel/$release/$basearch
    gpgcheck=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
    enabled=1

Для подключения репозитория с отладочной информацией создаём файл `/etc/yum.repo.d/EPEL-DebugInfo.repo`:

    [epel-debuginfo]
    name=Extra Packages for Enterprise Linux $release - $basearch - Debug
    baseurl=https://archives.fedoraproject.org/pub/archive/epel/$release/$basearch/debug
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
    gpgcheck=1
    enabled=0

Для подключения репозитория с исходными текстами для сборки пакетов создаём файл `/etc/yum.repo.d/EPEL-Sources.repo`:

    [epel-source]
    name=Extra Packages for Enterprise Linux $release - $basearch - Source
    baseurl=https://archives.fedoraproject.org/pub/archive/epel/$release/SRPMS
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
    gpgcheck=1
    enabled=0

Репозитории Percona
-------------------

Репозиторий `/etc/yum.repos.d/percona-release.repo` с пакетами Percona:

    ########################################
    # Percona releases and sources, stable #
    ########################################
    [percona-release-$basearch]
    name = Percona-Release YUM repository - $basearch
    baseurl = http://repo.percona.com/release/$release/RPMS/$basearch
    enabled = 1
    gpgcheck = 1
    gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Percona
    
    [percona-release-noarch]
    name = Percona-Release YUM repository - noarch
    baseurl = http://repo.percona.com/release/$release/RPMS/noarch
    enabled = 1
    gpgcheck = 1
    gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Percona 
    
    [percona-release-source]
    name = Percona-Release YUM repository - Source packages
    baseurl = http://repo.percona.com/release/$release/SRPMS
    enabled = 0
    gpgcheck = 1
    gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Percona 
    
    ####################################################################
    # Testing & pre-release packages. You don't need it for production #
    ####################################################################
    [percona-testing-$basearch]
    name = Percona-Testing YUM repository - $basearch
    baseurl = http://repo.percona.com/testing/$release/RPMS/$basearch
    enabled = 0
    gpgcheck = 1
    gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Percona
    
    [percona-testing-noarch]
    name = Percona-Testing YUM repository - noarch
    baseurl = http://repo.percona.com/testing/$release/RPMS/noarch
    enabled = 0
    gpgcheck = 1
    gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Percona
    
    [percona-testing-source]
    name = Percona-Testing YUM repository - Source packages
    baseurl = http://repo.percona.com/testing/$release/SRPMS
    enabled = 0
    gpgcheck = 1
    gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Percona
    
    ############################################
    # Experimental packages, use with caution! #
    ############################################
    [percona-experimental-$basearch]
    name = Percona-Experimental YUM repository - $basearch
    baseurl = http://repo.percona.com/experimental/$release/RPMS/$basearch
    enabled = 0
    gpgcheck = 1
    gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Percona
    
    [percona-experimental-noarch]
    name = Percona-Experimental YUM repository - noarch
    baseurl = http://repo.percona.com/experimental/$release/RPMS/noarch
    enabled = 0
    gpgcheck = 1
    gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Percona
    
    [percona-experimental-source]
    name = Percona-Experimental YUM repository - Source packages
    baseurl = http://repo.percona.com/experimental/$release/SRPMS
    enabled = 0
    gpgcheck = 1
    gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Percona

Репозитории Zabbix
------------------

Репозиторий `/etc/yum.repos.d/zabbix.repo` с пакетами Zabbix:

    [zabbix]
    name=Zabbix Official Repository - $basearch
    baseurl=http://repo.zabbix.com/zabbix/3.4/rhel/$release/$basearch/
    gpgcheck=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX
    enabled=1
    
    [zabbix-non-supported]
    name=Zabbix Official Repository non-supported - $basearch 
    baseurl=http://repo.zabbix.com/non-supported/rhel/$release/$basearch/
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX
    gpgcheck=1
    enabled=1

Первый репозиторий содержит сами пакеты Zabbix, а во втором находятся зависимости, отсутствующие в основных репозиториях CentOS.

Настройка переменных yum
------------------------

Для настройки переменных, таких как `releasever`, подставляемых в настройки репозиториев, можно создавать файлы в каталоге `/etc/yum/vars/`. Например, для задания переменной `releasever` нужно создать файл `/etc/yum/vars/releasever` с точным номером версии:

    6.10

Если же в имени репозитория фигурирует только номер релиза, то я ипользую перменную `release` и создаю файл `/etc/yum/vars/release` с номером релиза:

    6

Включенные репозитории
----------------------

Для получения списка включенных репозиториев и проверки их доступности можно воспользоваться следующей командой:

    # yum repolist enabled

Для получения списка отключенных репозиториев и всех репозиториев предназначены, соответственно, следующие команды:

    # yum repolist disabled
    # yum repolist all

Обновление локального кэша
--------------------------

Для очистки локального кэша и помещения в него свежих данных используются следующие команды:

    # yum clean all
    # yum makecache

Решение проблем
---------------

Если система устарела и не поддерживает протокол TLS1.2, то при попытке воспользоваться репозиториями может быть выведена ошибка следующего вида:

    https://vault.centos.org/centos/6.10/os/x86_64/repodata/repomd.xml: [Errno 14] problem making ssl connection

Для решения проблемы можно воспользоваться другим репозиторием, доступным по протоколу HTTP:

    baseurl=http://linuxsoft.cern.ch/centos-vault/$releasever/os/$basearch/

Удаление невостребованных пакетов
---------------------------------

Для поиска пакетов с библиотеками, не требуемыми какими-либо другими пакетами, можно воспользоваться командой:

    # package-cleanup --leaves

Использованные материалы:

Установка GPG-ключей репозиториев
---------------------------------

Для установки публичных GPG-ключей репозиториев можно воспользоваться командой следующего вида:

    # rpm --import http://centos.excellmedia.net/7.0.1406/os/x86_64/RPM-GPG-KEY-CentOS-7

* [TrevorH. 2021/12/29 13:57:14. Re: [Errno 14] problem making ssl connection](https://forums.centos.org/viewtopic.php?t=78580#p330186)
* [fometeo. 2022/03/04 08:56:38. Re: [Errno 14] problem making ssl connection](https://forums.centos.org/viewtopic.php?t=78580#p331204)
* [Available Repositories for CentOS](https://wiki.centos.org/AdditionalResources/Repositories)
