Настройка отчётов и периодических задач NetBSD
==============================================

В NetBSD есть 4 стандартных периодических отчёта:

* ежеденевный,
* еженедельный,
* ежемесячный,
* отчёт о безопасности.

Ежедневный отчёт
----------------

Настройки по умолчанию находятся в файле `/etc/default/daily.conf`, изменить настройки можно в файле `/etc/daily.conf`. В последний файл я прописываю следующие настройки:

    check_disks=NO
    check_network=NO
    fetch_pkg_vulnerabilities=NO
    run_makemandb=NO

Этими настройками отключается формирование разделов отчёта о дисках и сетевых интерфейсах, отключается получение информации о уязвимостях и отключается перестроение базы данных страниц руководства.

Кроме того, можно создать файл `/etc/daily.local`, в который можно вписать произвольный скрипт, вывод которого будет добавлен в конец ежедневного отчёта. В этот файл я вписываю следующие команды:

    /usr/pkg/sbin/pkg_admin fetch-pkg-vulnerabilities
    /usr/pkg/sbin/pkg_admin audit | /usr/bin/grep -vE 'CVE-(2020-16156|2011-4116)$'
    /usr/pkg/bin/pkgin update > /dev/null
    /usr/pkg/bin/pkgin -n upgrade

Как видно, несмотря на то, что я отключил получени информации об уязвимостях в файле `/etc/daily.conf`, я всё равно получаю её, запуская соответствующую команду вручную. Далее я формирую отчёт об уязвимостях в установленных пакетах, исключая из него информацию об уязвимостях, наличие которых в системе меня не беспокоит. В третьей строчке обновляется база данных пакетов, доступных через удалённый репозиторий. И в последней строчке формируется список установленных в системе пакетов, для которых доступны обновления.

Еженедельный отчёт
------------------

Настройки по умолчанию находятся в файле `/etc/default/weekly.conf`, изменить настройки можно в файле `/etc/weekly.conf`.

    rebuild_locatedb=NO
    rebuild_mandb=NO

Я отключил обновление баз данных о нахождении команд и страниц руководства. При необходимости я могу выполнить их вручную.

Также возможно создать файл `/etc/weekly.local` со скриптом, вывод которого будет добавляться в конец еженедельного отчёта.

Ежемесячный отчёт
-----------------

В настоящее время скрипты для его формирования пусты и поэтому его формирование по умолчанию отключено.

Отчёт о безопасности
--------------------

Настройки по умолчанию находятся в файле `/etc/default/security.conf`, изменить настройки можно в файле `/etc/security.conf`. В последний файл я прописываю следующую настройку:

    check_pkg_vulnerabilities=NO

Я отключаю проверку наличия уязвимостей в пакетах, т.к. мне нужно исключить из списка уязвимостей не беспокоящие меня, а стандартный отчёт не позволяет выполнить такую фильтрацию. Поэтому формирование отчёта об уязвимых пакетах я выполняю через файл `/etc/daily.local`, описание которого можно найти выше.

Также возможно создать файл `/etc/security.local` со скриптом, вывод которого будет добавляться в конец отчёта о безопасности.

Один из разделов отчёта проверяет соответствие прав доступа к файлам базовой системы. Формирование этого отчёта включено по умолчанию при помощи строчки `check_mtree=YES` в файле `/etc/default/security.conf`. Этот отчёт использует для сверки информацию из файла `/etc/mtree/special`. Сам этот файл трогать не рекомендуется, однако настройки из него можно заменить, создав файл `/etc/mtree/special.local`.

Например, у меня отключена сборка межсетевых экранов IPFilter и PF, поддержка iSCSI и сборка DNS-сервера Unbound. Чтобы в отчёт не попадали сообщения о недостающих файлах, я скопировал интересующие меня строчки из файла `/etc/mtree/special` и добавил в каждую из них опцию `optional`, чтобы пометить файл как необязательный. В результате у меня получился файл `/etc/mtree/special.local` со следующим содержимым:

    ./etc/iscsi                     type=dir  mode=0755 optional
    ./etc/iscsi/auths               type=file mode=0600 optional tags=nodiff
    ./etc/iscsi/targets             type=file mode=0644 optional
    ./etc/rc.d/iscsi_target         type=file mode=0555 optional
    ./etc/rc.d/iscsid               type=file mode=0555 optional
    
    ./etc/pf.conf                   type=file mode=0644 optional
    ./etc/pf.os                     type=file mode=0444 optional
    ./etc/rc.d/pf                   type=file mode=0555 optional
    ./etc/rc.d/pf_boot              type=file mode=0555 optional
    ./etc/rc.d/pflogd               type=file mode=0555 optional
    ./var/chroot/pflogd             type=dir  mode=0755 optional
    
    ./etc/rc.d/ftp_proxy            type=file mode=0555 optional
    ./var/chroot/ftp-proxy          type=dir  mode=0755 optional
    ./var/chroot/tftp-proxy         type=dir  mode=0755 optional
    
    ./etc/rc.d/ipfilter             type=file mode=0555 optional
    ./etc/rc.d/ipfs                 type=file mode=0555 optional
    ./etc/rc.d/ipmon                type=file mode=0555 optional
    ./etc/rc.d/ipnat                type=file mode=0555 optional
    
    ./etc/rc.d/postfix              type=file mode=0555 optional
    
    ./etc/rc.d/unbound              type=file mode=0555 optional
    
    ./etc/named.conf                type=file mode=0644 optional
    ./etc/namedb                    type=dir  mode=0755 optional
    ./etc/rc.d/named                type=file mode=0555 optional
    ./var/chroot/named              type=dir  mode=0755 optional
    ./var/chroot/named/dev          type=dir  mode=0755 optional
    ./var/chroot/named/etc          type=dir  mode=0755 optional
    ./var/chroot/named/etc/namedb   type=dir  mode=0755 uname=named gname=named optional
    ./var/chroot/named/etc/namedb/cache     type=dir mode=0775 uname=named gname=named optional
    ./var/chroot/named/etc/namedb/keys      type=dir mode=0775 uname=named gname=named optional
    ./var/chroot/named/usr          type=dir  mode=0755 optional
    ./var/chroot/named/usr/libexec  type=dir  mode=0755 optional
    ./var/chroot/named/var          type=dir  mode=0755 optional
    ./var/chroot/named/var/run      type=dir  mode=0775 uname=named gname=named optional
    ./var/chroot/named/var/tmp      type=dir  mode=01775 uname=named gname=named optional
    
    ./etc/rc.d/ypbind               type=file mode=0555 optional
    ./etc/rc.d/yppasswdd            type=file mode=0555 optional
    ./etc/rc.d/ypserv               type=file mode=0555 optional
    
    ./etc/saslc.d                   type=dir  mode=0755 optional
    ./etc/saslc.d/postfix           type=dir  mode=0755 optional
    ./etc/saslc.d/postfix/mech      type=dir  mode=0755 optional
    ./etc/saslc.d/saslc             type=dir  mode=0755 optional
    ./etc/saslc.d/saslc/mech        type=dir  mode=0755 optional
