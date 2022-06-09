Настройка NetBSD
----------------

* [[Система pkgsrc|pkgsrc]]
* [[Сторонние утилиты для управления pkgsrc|netbsd_pkg]]
* [[Изменение размера диска NetBSD|netbsd_resize_disk]]
* [[Пересборка ядра NetBSD|netbsd_kernel]]
* [[Пересборка базовой системы NetBSD|netbsd_base]]

Настройка сервисов в NetBSD
---------------------------

* [[Настройка сборочного сервера NetBSD|netbsd_sysbuild]]
* [[Настройка sysbuild для получения исходных текстов через git|netbsd_sysbuild_git]]
* [[Использование basepkg для сборки пакетов с базовой системой NetBSD|netbsd_basepkg]]
* [[Postfix из базовой системы NetBSD как локальный SMTP-ретранслятор|netbsd_postfix_relay_base]]
* [[Postfix из pkgsrc как локальный SMTP-ретранслятор в NetBSD|netbsd_postfix_relay_pkgsrc]]
* [[Установка и настройка Gitea в NetBSD|netbsd_gitea]]
* [[Запуск Gitea в NetBSD с помощью daemontools|netbsd_daemontools_gitea]]
* [[Настройка nullmailer в NetBSD|netbsd_nullmailer]]
* [[Запуск nullmailer в NetBSD с помощью daemontools|netbsd_daemontools_nullmailer]]
* [[Локальный SMTP-ретранслятор dma в NetBSD|netbsd_dma]]
* [[Настройка отчётов и периодических задач NetBSD|netbsd_reports]]
* [[Установка и настройка агента Zabbix в NetBSD|netbsd_zabbix_agent]]
* [[Запуск Zabbix-агента в NetBSD с помощью daemontools|netbsd_daemontools_zabbix_agent]]
* [[Установка и настройка openntpd в NetBSD|netbsd_openntpd]]
* [[Запуск OpenNTPd в NetBSD с помощью daemontools|netbsd_daemontools_openntpd]]
* [[Запуск socklog в NetBSD с помощью daemontools|netbsd_daemontools_socklog]]
* [[Запуск sshd в NetBSD с помощью daemontools|netbsd_daemontools_sshd]]
* [[Запуск powerd в NetBSD с помощью daemontools|netbsd_daemontools_powerd]]
* [[Запуск cron в NetBSD с помощью daemontools|netbsd_daemontools_cron]]
* [[Запуск dhcpd в NetBSD с помощью daemontools|netbsd_daemontools_dhcpd]]
* [[Запуск wpa_supplicant в NetBSD с помощью daemontools|netbsd_daemontools_wpa_supplicant]]
* [[Настройка tftp-hpa в NetBSD|netbsd_tftp_hpa]]
* [[Запуск nginx в NetBSD с помощью daemontools|netbsd_daemontools_nginx]] (добавить раздел про совместимость с rc)
* [[Запуск spawn-fcgi и fcgiwrap в NetBSD с помощью daemontools|netbsd_daemontools_spwan_fcgi_fcgiwrap]] (добавить раздел про совместимость с rc)
* [[Настройка mathopd в NetBSD|mathopd_netbsd]]
* [[Запуск mathopd в NetBSD с помощью daemontools|netbsd_daemontools_mathopd]]
* [[Ikiwiki как генератор статических сайтов|ikiwiki_static_netbsd]]
* [[Ikiwiki в режиме CGI|ikiwiki_cgi_netbsd]]
* [[Установка и настройка Dovecot|netbsd_dovecot]]
* [[Запуск dovecot в NetBSD с помощью daemontools|netbsd_daemontools_dovecot]]
* [[Установка и настройка Exim в NetBSD|netbsd_exim]] (черновик)
* [[Запуск exim в NetBSD с помощью daemontools|netbsd_daemontools_exim]]
* [[Запуск xdm в NetBSD с помощью daemonotools|netbsd_daemontools_xdm]]
* [[Настройка внешнего вида xdm в NetBSD|netbsd_xdm]]
* [[Настройка dnscache из djbdns в NetBSD|netbsd_dnscache]]
* [[Мониторинг dnscache из djbdns в NetBSD через Zabbix-агента|netbsd_dnscache_zabbix_agent]] (черновик)
* [[Настройка tinydns и axfrdns из djbdns в NetBSD|netbsd_tinydns_axfrdns]] (разбить на статьи: 1. tinydns, 2. axfrdns, 3. настройка файлов зон)

Настройка сетевого оборудования
-------------------------------

* [[Настройка коммутатора D-Link DGS-3200-10|dlink]]
* [[Настройка коммутатора SNR-S2985G-8T|snr]]
* [[Настройка коммутатора Huawei S1720-10GW-2P|huawei]]
* [[Настройка маршрутизатора HP/H3C A-MSR900 JF812A|hp]] (черновик)
* [[Настройка точки доступа Ubiquiti UAP-AC-Lite|ubiquiti]]

MySQL
-----

* [[MySQL|mysql]] (черновик)
* [[Настройка Linux для MySQL|mysql_linux]] (черновик)
* [[Привилегии пользователей MySQL|mysql_privileges]]
* [[Настройка клиентских буферов MySQL|mysql_client_buffers]]
* [[Настройка общих буферов MySQL|mysql_buffers]]
* [[Настройка журнала транзакций в MySQL|mysql_logs]]
* [[Настройка количества потоков MySQL|mysql_threads]]
* [[Настройка источника репликации в MySQL|mysql_master]]
* [[Настройка реплики в MySQL|mysql_slave]]
* [[Настройка многопоточной репликации MySQL|mysql_threads_slave]]
* [[Настройка других опций MySQL|mysql_tuning_misc]]
* [[Настройка реплики MySQL с помощью xtrabackup|mysql_slave_xtrabackup]]
* [[Настройка реплики MySQL с помощью снимков LVM и rysnc|mysql_slave_lvm_rsync]]
* [[Настройка реплики MySQL с помощью mysqldump|mysql_slave_mysqldump]]
* [[Перенос базы данных с одного сервера MySQL на другой с помощью xtrabackup|mysql_migration_xtrabackup]]
* [[Периодическое резервное копирование MySQL с помощью xtrabackup|mysql_periodic_xtrabackup]]
* [[Мониторинг MySQL с помощью Zabbix|mysql_zabbix]]
* [[Игнорирование ошибок репликации MySQL|mysql_slave_ignore_errors]]
* [[Установка Percona Server в Debian/Ubuntu|percona_server_debian_ubuntu]]
* [[Отслеживание подключений к MySQL|mysql_connections]]
* [[Настройка ProxySQL|proxysql]]
* [[Сборка ProxySQL для Debian 10.12 Buster|proxysql_deb]]

PostgreSQL
----------

* [[Ещё одна шпаргалка по PostgreSQL|postgresql]]
* [[Настройка буферов PostgreSQL|postgresql_buffers]]
* [[Мониторинг PostgreSQL с помощью Zabbix|postgresql_zabbix]]
* [[Рекомендации по поиску проблем и тонкой настройке PostgreSQL|postgresql_tuning]]
* [[Ускорение запросов LIKE с % в начале шаблона в PostgreSQL|postgresql_trgm]]
* [[Ускорение запросов с Hash Join в плане выполнения в PostgreSQL|postgresql_hash]]
* [[Ускорение запросов с ORDER BY и LIMIT в плане выполнения в PostgreSQL|postgresql_order_limit]]
* [[Принудительное сжатие таблиц PostgreSQL|postgresql_force_vacuum]]
* [[Сборка pg_repack для Debian 8.11.1 LTS Jessie и PostgresPro 9.5.14.1|pg_repack_debian_jessie_postgrespro95]]
* [[Сборка pg_repack для Ubuntu 16.04 LTS Xenial и PostgresPro 9.6.21.1|pg_repack_ubuntu_xenial_postgrespro96]]
* [[Сборка pg_repack для Ubuntu 18.04 LTS Bionic и PostgreSQL 12.11|pg_repack_ubuntu_bionic_postgresql12]]
* [[Настройка PgBouncer|postgresql_pgbouncer]]

ClickHouse
----------

* [[Установка ClickHouse|clickhouse_install]]
* [[Настройка ClickHouse|clickhouse_config]]
* [[Перенос базы данных ClickHouse|clickhouse_move_db]]
* [[Шпаргалка по ClickHouse|clickhouse]]

SQLite
------

* [[Шпаргалка по SQLite|sqlite]]

SQL-серверы
-----------

* [[Розеттский камень DBA|dba_rosetta]]
* [[Миграция трекера MogileFS с MySQL на PostgreSQL|mogilefs_mysql_postgresql]]
* [[MogileFS с поддержкой работы через PgBouncer|mogilefs_pgbouncer]]

Другие статьи
-------------

* [[Сборка deb-пакета nginx из Debian 11 Bullseye для Debian 8.11 Jessie|nginx_debian_jessie]]
* [[Приоритеты звуковых карт в ALSA|alsa]]
* [[Полезные sysctl|sysctl]]
* [[Порты FreeBSD|freebsd_ports]]
* [[uWSGI под FreeBSD|uwsgi_freebsd]]
* [[Проверка IP-адреса по чёрным спискам DNS|dnsbl]]
* [[Настройка виртуальной машины с Debian 11 под управлением VMware|debian11_vmware]]
* [[Настройка KVM и virt-manager в Debian 11|debian11_kvm]]
* [[Настройка и использование cntlm|cntlm]]
* [[Настройка и использование redsocks|redsocks]]
* [[Использование tmux|tmux]]
* [[Кросскомпиляция deb-пакетов|deb_crosscompile]]
* [[Debian 11 в виртуальной машине Qemu на архитектуре ARM|qemu_debian11_armhf]]
* [[Опции gcc|gcc]]
* [[Проблема со сбором статики в Django|django_collectstatic]]
* [[Использование pip|pip]]
* [[Установка, настройки и управление supervisord|supervisor]]
* [[Использование virtualenv|virtualenv]]
* [[Настройки клиента Net-SNMP|netsnmp]]
* [[Настройка NSD|nsd3]]
* [[Программы для установки на рабочее место|progs]]
* [[Жизнь в Windows-сети|samba]]
* [[Настройка SSH|ssh]]
* [[Настройки telnet|telnet]]
* [[Советы и рецепты по Zabbix|zabbix]]
* [[Замена сбойного диска при использовании LVM|migrate_lvm]]
* [[Определение модели сервера|dmi]]
* [[Функции rshift и and в BSD AWK|bsd-awk]]
* [[Установка модуля yaml для PHP5.4 в Debian Wheezy|wheezy-php-yaml]]
* [[Настройки ядра Linux при загрузке через GRUB|grub]]
* [[Замена sysvinit на systemd в Debian|debian_sysvinit_systemd]]
* [[После обновления операционной системы Debian|after_upgrade]]
* [[Репозитории и пакеты Debian|deb]]
* [[Репозитории и пакеты CentOS|centos]]
* [[Модули Perl в Debian|debian_perl]]
* [[Подготовка deb-пакетов с модулями Python|python-deb]]
* [[Использование update-alternatives|update-alternatives]]

Черновики и заготовки
---------------------

* [[Использование debconf|debconf]]
* [[Печать сложных документов в Linux|printing]]
* [[Настройка музыкального сервера на основе mpd|mpd]]
* [[Настройка сервера ejabberd|ejabberd]]
* [[Шифрование области подкачки|crypt_swap]]
* [[Где взять образы дисков устарешвих релизов Debian|debian_old_images]]
* [[Настройка и использование wget|wget]]
* [[Работа с репозиторием Git|git]]
* [[Обновление установленной NetBSD|netbsd_upgrade]]
* [[Программы для изучения|investigate_progs]]
* [[Проверка и исправление неисправных блоков на дисках|badblocks]]
* [[LVM|lvm]]
* [[Монтирование|mount]]
* [[Монтирование устройств по протоколу MTP|mtp]]
* [[Материалы о NetBSD|netbsd_articles]]
* [[Настройка сети в NetBSD|netbsd_network]]
* [[Установка и настройка Dokuwiki в NetBSD|netbsd_dokuwiki]]
* [[Установка и настройка Ikiwiki в NetBSD|netbsd_ikiwiki]]
* [[Структурированная документация по конфигурации mathopd.conf|mathopd.conf]]
* [[Настройка SOCKS4/5-прокси сервера Dante|dante]]
* [[Настройка AltLinux|altlinux]]
* [[Советы и рецепты по KVM|kvm]]
* [[Настройка системы виртуализации Virtualbox|virtualbox]]
* [[Настройка Xen|xen]]
* [[Кластер высокой доступности на основе Xen|ha]]
* [[Источник бесперебойного питания APC Smart-UPS 1500|apc1500]]
* [[Cisco ATA 186|ata186]]
* [[Электросчётчик, КИ и БП|counter]]
* [[Настройка GVRP|gvrp]]
* [[Настройка D-Link DWA-566|hostapd_ac]]
* [[Блок питания GLOBE FAN RL4Z S1352512H|psu]]
* [[Raspberry Pi|rapi]]
* [[BeagleBone Black|beablebone_black]]
* [[Java|java]]
* [[Celery и Django|celery]]
* [[Хэширование паролей|pwhash]]
* [[Многоэтапная многопроцессная обработка данных в Python|queue]]
* [[Блоги и сайты|blogs]]
* [[Цитаты|citates]]
* [[Использование fetchmail|fetchmail]]
* [[Бесплатный вторичный DNS-сервер|free_secondary_dns_server]]
* [[Использование GPG|gpg]]
* [[Настройка IPMI|ipmi]]
* [[Ссылки|links]]
* [[Песни и стихи|lyrics]]
* [[Тарифы и опции Мегафон|megafon]]
* [[Настройка mutt|mutt]]
* [[Сборка ndprbrd|ndprbrd]]
* [[Настройка nginx|nginx]]
* [[Исправление проблемы при импорте OSM с помощью osm2pgsql|osm2pgsql]]
* [[Использование partclone.ntfs|partclone.ntfs]]
* [[Работа с файлами PDF|pdf]]
* [[Настройка php5-fpm|php5-fpm]]
* [[Настройка PolicyKit|policykit]]
* [[Сборка PPPoE-сервера с модулем ядра|pppoe-server-kernel-support]]
* [[Настройка mam в Prosody|prosody]]
* [[Настройка Pure-FTPd|pure-ftpd]]
* [[Резервное копирование по SSH|rbackup]]
* [[Настройка Roundcube для использования SQLite|roundcube-sqlite]]
* [[Настройка rspamd|rspamd]]
* [[Установка и настройка Seafile|seafile]]
* [[Использование tcpdump|tcpdump]]
* [[Программы с текстовым интерфейсом|tui]]
* [[Перекодирование видео|video]]
* [[Редактор Vim|vim]]
* [[Настройка vsftpd|vsftpd]]
* [[Установка и настройка XWiki|xwiki]]
* [[Методы увеличения производительности Zabbix|zabbix_performace]]
* [[Линейка мейнфреймов PDP-6|pdp6]]
* [[Друзья djb|djbfriends]]
* [[Сетевое оборудование, на которое можно прошить Linux|network_hardware_linux]]
* [[Программирование на Си|clang]]

Чужие материалы
---------------

* [[Django + PostgreSQL за 8 шагов|django_pgsql]]
* [[Установка и настройка Elasticsearch для хранения данных Zabbix|elasticsearch]]
* [[Конспекты материалов по операционной системе Android|android]]
* [[Используем менеджер памяти Jemalloc для всех Linux приложений|jemalloc]]

[[Рабочий раздел|ufanet]]
-------------------------

* [[Статьи для преемников|ncc]]

[[Приватный раздел|private]]
----------------------------
