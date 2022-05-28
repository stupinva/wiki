Пересборка базовой системы NetBSD
=================================

Для уменьшения места, занимаемого системой на диске, и для увеличения безопасности системы можно отключить сборку неиспользуемых компонентов и включить опции для усложнения эксплуатации имеющихся в системе уязвимостей.

Для этого отредактируем файл `/etc/mk.conf`, прописав в него следующие опции:

* `MKATF=no` - отключение фреймворка [ATF](https://en.wikipedia.org/wiki/Automated_Testing_Framework) для тестирования кода,
* `MKCOMPAT=no` - отключение совместимости с двоичными файлами архитектур процессоров, отличных от основной, см. [NetBSD Binary Emulation](https://www.netbsd.org/docs/compat.html),
* `MKCTF=no` - отключение поддержки отладочных секций исполняемых ELF-файлов в формате [CTF](https://man.netbsd.org/ctf.5), содержащих описание используемых в программе типов и структур данных,
* `MKDTRACE=no` - отключение средства трассировки программ [dtrace](https://ru.wikipedia.org/wiki/DTrace),
* `MKHESIOD=no` - отключение системы [Hesiod](https://en.wikipedia.org/wiki/Hesiod_(name_service)) - каталога учётных данных, подобного LDAP, но основанного на DNS,
* `USE_HESIOD=no` - отключение сборки пакетов из pkgsrc с поддержкой Hesiod,
* `MKHTML=no` - отключение сборки документации в формате HTML,
* `#MKINET6=no` - отключение поддержки протокола адресации сети интернет шестой версии [IPv6](https://ru.wikipedia.org/wiki/IPv6),
* `#USE_INET6=no` - отключение сборки пакетов из pkgsrc с поддержкой IPv6,
* `MKIPFILTER=no` - отключение поддержки межсетевого экрана [IPFilter](https://ru.wikipedia.org/wiki/IPFilter),
* `MKISCSI=no` - отключение поддержки протокола [iSCSI](https://ru.wikipedia.org/wiki/ISCSI) для работы с блочными устройствами по сети,
* `MKKERBEROS=no` - отключение поддержки протокола [Kerberos](https://en.wikipedia.org/wiki/Kerberos_(protocol)) для централизованной аутентификации пользователей,
* `USE_KERBEROS=no` - отключение сборки пакетов из pkgsrc с поддержкой Kerberos,
* `MKKYUA=no` - отключение фреймворка [KYUA](https://wiki.netbsd.org/kyua/) для тестирования кода, пришедшего на смену аналогичному фреймворку ATF,
* `MKLDAP=no` - отключение поддержки протокола [LDAP](https://ru.wikipedia.org/wiki/LDAP) - каталога учётных данных,
* `USE_LDAP=no` - отключение сборки пакетов из pkgsrc с поддержкой LDAP,
* `MKMDNS=no`- отключение поддержки протокола [mDNS](https://en.wikipedia.org/wiki/Multicast_DNS), позволяющего выполнять DNS-запросы к серверам по мультикаст-адресу,
* `MKNSD=no` - отключение сборки авторитетного сервера DNS [NSD](https://ru.wikipedia.org/wiki/NSD),
* `MKPF=no` - отключение поддержки межсетевого экрана [PF](https://ru.wikipedia.org/wiki/Packet_Filter),
* `MKPIE=yes` - включение сборки ядра NetBSD как позиционно-независимого кода (такое ядро можно загружать по новому адресу при каждой загрузке системы, что затрудняет эксплуатацию уязвимостей),
* `MKPOSTFIX=no` - отключение сборки почтового сервера [Postfix](https://ru.wikipedia.org/wiki/Postfix) (вместо него я использую [dma](https://man.dragonflybsd.org/?command=dma&section=8) и [Exim](https://en.wikipedia.org/wiki/Exim)),
* `MKRUMP=no` - отключение сборки [RUMP-ядер](https://en.wikipedia.org/wiki/Rump_kernel), позволяющих запускать драйверы устройств и файловых систем в пространстве пользователя,
* `MKSKEY=no` - отключение поддержки [S/Key](https://ru.wikipedia.org/wiki/S/Key) для аутентификации при помощи одноразовых паролей,
* `USE_SKEY=no` - отключение сборки пакетов из pkgsrc с поддержкой S/Key,
* `MKUNBOUND=no` - отключение сборки кэширующего рекурсивного сервера DNS [Unbound](https://en.wikipedia.org/wiki/Unbound_(DNS_server)),
* `#MKYP=no` - отключение поддержки протокола [NIS](https://ru.wikipedia.org/wiki/Network_Information_Service) - каталога учётных данных,
* `#USE_YP=no` - отключение сборки пакетов из pkgsrc с поддержкой NIS,
* `MKZFS=no` - отключение поддержки файловой системы [ZFS](https://ru.wikipedia.org/wiki/ZFS),
* `USE_FORT=yes` - включение замены функций, работающих с областями памяти, на их более безопасные аналоги, если на этапе компиляции размер области памяти известен заранее,
* `USE_SSP=yes` - включение защиты от срыва стека.

Сразу после установки собранной системы нужно отключить использование следующих PAM-модулей в файлах в каталоге `/etc/pam.d`:

* `pam_krb5` - поддержка протокола Kerberos,
* `pam_afslog` - поддержка интеграции распределённой файловой системы [AFS](https://en.wikipedia.org/wiki/Andrew_File_System) и Kerberos,
* `pam_ksu` - поддержка аутентификации пользователя root в Kerberos.

В противном случае можно лишиться возможности попасть в систему даже под пользователем root с консоли или повысить привилегии до root с помощью утититы `su`.

Дополнительные материалы
------------------------

* [security(7)](https://man.netbsd.org/security.7)
* [The pkgsrc guide / Appendix B. Security hardening](https://www.netbsd.org/docs/pkgsrc/hardening.html#hardening.audit.pie)
