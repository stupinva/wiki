Установка и настройка агента Zabbix в NetBSD
============================================

[[!tag netbsd pkgsrc zabbix_agent]]

Впишем в файл /etc/mk.conf опции сборки пакетов:

    PKG_OPTIONS.perl=               -debug -dtrace -mstats -threads 64bitauto
    PKG_OPTIONS.curl=               -gssapi -http2 -idn -inet6 -libssh2 -rtmp
    PKG_OPTIONS.zabbix50-agent=     -inet6 

Переходим в каталог /usr/pkgsrc/sysutils/zabbix50-agent и запускаем установку:

    # cd /usr/pkgsrc/sysutils/zabbix50-agent
    # make install

После установки копируем пример файла инициализации агента:

    # cp /usr/pkg/share/examples/rc.d/zabbix_agentd /etc/rc.d/

Создаём пустой журнальный файл агента и выставляем права доступа к нему:

    # cd /var/log/
    # touch zabbix_agentd.log
    # chown root:zabbix zabbix_agentd.log
    # chmod ug=rw,o=r zabbix_agentd.log

Прописываем в файле конфигурации /usr/pkg/etc/zabbix_agentd.conf имена журнального и PID-файлов, адрес сервера Zabbix и имя, под которым этот узел заведён на сервере Zabbix:

    git# egrep -v '^(#|$)' /usr/pkg/etc/zabbix_agentd.conf
    LogFile=/var/log/zabbix_agentd.log
    Server=169.254.252.2
    ServerActive=169.254.252.2
    Hostname=git2.vm.stupin.su

Разрешаем запуск агента Zabbix в файле /etc/rc.conf:

    zabbix_agentd=YES

И запускаем агенат Zabbix:

    # /etc/rc.d/zabbix_agentd start
