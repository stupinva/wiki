Система pkgsrc
==============

[[!tag pkgsrc pkgsrc-wip]]

Содержание
----------

[[!toc levels=4 startlevel=2]]

Получение pkgsrc
----------------

Скачиваем архив с системой package sources:

    # cd /usr
    # ftp ftp://ftp.NetBSD.org/pub/pkgsrc/pkgsrc-2020Q3/pkgsrc.tar.xz

Распакуем скачанный архив:

    # tar xJvf pkgsrc.tar.xz

Просмотр версии pkgsrc
----------------------

Посмотреть версию коллекции пакетов pkgsrc можно заглянув в файл `CVS/Tag`.

Обновление pkgsrc
-----------------

Обновим распакованные файлы с помощью `cvs`:

    # cd /usr/pkgsrc
    # cvs update -dP

Переключение на другую версию pkgsrc
------------------------------------

Для переключения на другую стабильную версию коллекции пакетов pkgsrc можно воспользоваться следующими командами:

    # cd /usr/pkgsrc
    # cvs update -rpkgsrc-2020Q4

Для переключения на текущую версию pkgsrc можно воспользоваться следующими командами:

    # cd /usr/pkgsrc
    # cvs update -A

Развёртывание системы
---------------------

Перед использованием системы нужно осуществить её первоначальное развёртывание. Для этого нужно перейти в каталог `/usr/pkgsrc/bootstrap` и выполнить скрипт `bootstrap`, вот так:

    # cd /usr/pkgsrc/bootstrap
    # ./bootstrap

В числе прочих пакетов будет установлен пакет `pkg_install` с инструментами `pkg_add`, `pkg_admin`, `pkg_create`, `pkg_delete`, `pkg_info` в каталоге `/usr/pkg/sbin/`.

Получение pkgsrc-wip
--------------------

Кроме основного репозитория pkgsrc существует специальный репозиторий wip - work in progress. В этот репозиторий помещают ещё не готовые пакеты, находящиеся в разработке. В нём бывает можно найти пакеты, которые давно не обновляются, но что не умаляет их ценности (например, `socklogd` или `mathopd`). Для скачивания этого репозитория можно воспользоваться следующими командами:

    # cd /usr/pkgsrc
    # git clone git://wip.pkgsrc.org/pkgsrc-wip.git wip

Приоритет программ из pkgsrc
----------------------------

По умолчанию при поиске программ без указания полного пути к ним отдаётся приоритет тем программам, которые имеются в базовой поставке. Чтобы при установке одноимённых программ из pkgsrc они имели приоритет над имеющимися в базовой поставке, нужно настроить переменную `PATH`.

Например, поменять значение переменной PATH для пользователя root можно через файл `/root/.profile`, изменив в нём переменную PATH следующим образом:

    export PATH=/usr/pkg/sbin:/usr/pkg/bin:/sbin:/usr/sbin:/bin:/usr/bin
    export PATH=${PATH}:/usr/X11R7/bin:/usr/local/sbin:/usr/local/bin

Изменение пути к базе данных установленных пакетов
--------------------------------------------------

В новых сеансах пользователя root предпочтение будет отдаваться программам, установленным через pkgsrc, в том числе утилитам pkg_* из пакета `pkg_install`.

Последнее особенно важно, т.к. начиная с 2021 года в pkgsrc используется новое положение базы данных установленных программ. Ранее это был каталог `/var/db/pkgsrc`, теперь же это каталог `/usr/pkg/pkgdb`. Новые утилиты используют второй путь. После изменения переменной `PATH` содержимое старого каталога можно переместить в новый. Задать положение этого каталога явным образом можно через переменную `PKG_DBDIR` в файле `/etc/mk.conf`, например вот так:

    PKG_DBDIR=                      /usr/pkg/pkgdb

Поиск пакетов
-------------

Поиск пакетов по названию или описанию можно осуществлять при помощи такой команды:

    # cd /usr/pkgsrc
    # make search key=dovecot

При первом запуске команда создаст индекс пакетов и их зависимостей, что может потребовать довольно много времени (на старых компьютерах - несколько часов).

Просмотр информации о пакете
----------------------------

Чтобы посмотреть доступные опции найденного пакета и опции, с которыми он будет собран по умолчанию, нужно перейти в его каталог и выполнить соответствующую команду:

    # /usr/pkgsrc/
    # make show-options

Чтобы посмотреть зависимости пакета, можно воспользоваться такой командой:

    # make show-depends

Посмотреть список всех сборочных зависимостей можно при помощи команды:

    # make print-build-depends-list

Посмотреть список всех зависимостей, требующихся для работы программы, можно при помощи команды:

    # make print-run-depends-list

Стоит учитывать, что список зависимостей может меняться в зависимости от выбранных опций, с которыми пакет будет собираться. Поэтому имеет смысл сначала отметить необходимые опции и лишь затем смотреть зависимости.

Получить команды для скачивания необходимых зависимостей и исходников самого пакета можно при помощи такой команды:

    # make fetch-list

Запустить скачивание можно следующим образом:

    # make fetch-list | sh

Просмотр опций пакета и его зависимостей
----------------------------------------

Для рекурсивного просмотра опций пакетов я доработал файл `/usr/pkgsrc/mk/bsd.pkg.readme.mk` и добавил два новых правила, сделав их на основе правил `build-depends-list` и `print-build-depends-list`. Выглядят новые правила следующим образом:

    .PHONY: show-options-depends
    .if !target(show-options-depends)
    show-options-depends:
            @${ECHO} "--- `${RECURSIVE_MAKE} ${MAKEFLAGS} package-name` ---"
            @${RECURSIVE_MAKE} ${MAKEFLAGS} show-options
            @${ECHO} ""
    
            @${_DEPENDS_WALK_CMD} ${PKGPATH} |                              \
            while read dir; do                                              \
                    ( cd ../../$$dir &&                                     \
                    ${ECHO} "--- `${RECURSIVE_MAKE} ${MAKEFLAGS} package-name` ---" &&      \
                    ${RECURSIVE_MAKE} ${MAKEFLAGS} show-options &&          \
                    ${ECHO} "")                                             \
            done
    .endif
    
    .PHONY: show-options-recursive
    .if !target(show-options-recursive)
    show-options-recursive:
    .  if !empty(BUILD_DEPENDS) || !empty(DEPENDS)
            @${RECURSIVE_MAKE} ${MAKEFLAGS} show-options-depends
    .  endif
    .endif

Для рекурсивного просмотра опций пакета и его зависимостей после доработки файла `/usr/pkgsrc/mk/bsd.pkg.readme.mk` можно воспользоваться такой командой:

    # make show-options-recursive

Вывод команды будет иметь примерно следующий вид:
  
    --- curl-7.76.0 ---
    Any of the following general options may be selected:
            gssapi   Enable gssapi (Kerberos V) support.
            http2    Add support for HTTP/2.
            idn      Internationalized Domain Names (IDN) support.
            inet6    Enable support for IPv6.
            ldap     Enable LDAP support.
            libssh2  Use libssh2 for SSHv2 protocol support.
            rtmp     Enable rtmp:// support using rtmpdump.
    
    These options are enabled by default:
            gssapi http2 idn inet6
    
    These options are currently enabled:
    
    You can select which build options to use by setting PKG_DEFAULT_OPTIONS
    or PKG_OPTIONS.curl.
    
    --- cwrappers-20180325 ---
    This package does not use the options framework.
    
    --- digest-20190127 ---
    This package does not use the options framework.
    
    --- m4-1.4.18nb2 ---
    This package does not use the options framework.
    
    --- libtool-base-2.4.6nb2 ---
    This package does not use the options framework.
    
    --- perl-5.32.1 ---
    Any of the following general options may be selected:
            debug    Enable debugging facilities in the package.
            dtrace   Enable DTrace support.
            mstats   Enable memory statistics.
            threads  Enable threads support.
    Exactly one of the following perlbits options is required:
            64bitall
            64bitauto
            64bitint
            64bitmore
            64bitnone
    
    These options are enabled by default:
            64bitauto threads
    
    These options are currently enabled:
            64bitauto
  
    You can select which build options to use by setting PKG_DEFAULT_OPTIONS
    or PKG_OPTIONS.perl.

Скачивание исходных текстов
---------------------------

Скачать исходные тексты можно при помощи команды:

    # make fetch

Скачанные архивы попадают в каталог `/usr/pkgsrc/distfiles/`.

Проверка целостности исходных текстов
-------------------------------------

Для проверки целостности скачанных исходных текстов можно воспользоваться такой командой:

    # make checksum

Наложение заплат
----------------

Для наложения заплат на исходные тексты можно воспользоваться этой командой:

    # make patch

Команда может пригодиться для добавления собственных заплаток перед сборкой программы.

Распаковка исходных текстов
---------------------------

Распаковать их можно при помощи команды:

    # make extract

Настройка опций сборки
----------------------

Чтобы изменить опции, с которыми будет собираться тот или иной пакет, нужно прописать их в файле `/etc/mk.conf`, вот так:

    PKG_OPTIONS.dovecot=    ssl kqueue -pam -tcpwrappers

Отключаемые опции указываются с минусом, включаемые указываются без минуса. Если файла `/etc/mk.conf` ещё нет, то нужно создать его.

Сборка исходных текстов
-----------------------

Сборка пакета осуществляется при помощи следующей команды:

    # make

Сборка пакета
-------------

Для сборки пакета можно воспользоваться такой командой:

    # make package

Собранные пакеты помещаются в каталоге `/usr/pkgsrc/packages/All/`.

Установка пакета
----------------

Установка пакета осуществляется при помощи такой команды:

    # make install

Использование двоичных зависимостей
-----------------------------------

Для сборки пакета из системы pkgsrc могут понадобиться зависимости, необходимые для его работы или для сборки. По умолчанию все зависимости устанавливаются из той же системы pkgsrc. Сборка и установка зависимостей может потребовать очень много времени. Чтобы ускорить сборку интересующего пакета, готовые пакеты-зависимости можно взять из двоичного репозитория. Для этого достаточно прописать в файл `/etc/mk.conf` две опции:

    DEPENDS_TARGET=bin-install
    BINPKG_SITES=file:///var/pkg_comp/packages

Первая опция как раз предписывает использовать двоичные пакеты для удовлетворения зависимостей, а вторая опция указывает путь к репозиторию, из которого нужно брать двоичные пакеты. Значение этой опции можно взять из файла `/usr/pkg/etc/pkgin/repositories.conf`, убрав из пути подкаталог `All` в конце.

Удаление сборочных файлов
-------------------------

После того, как пакет был собран и установлен, в системе pkgsrc остаются результаты сборки в каталогах work внутри каталога соответствующего пакета. Эти файлы во-первых занимают место на диске, а во-вторых могут привести к неожиданным результатам при попытке собрать пакеты с другими опциями.

Удалить эти файлы самого пакета можно командой:

    # make clean

Для удаления таких файлов из всех пакетов, которые использовались при сборке этого, можно при помощи команды:

    # make clean-depends

При использовании команды make удаление сборочных файлов пакетов-зависимостей происходит путём вызова команды `make` в соответствующих каталогах, из-за чего процесс удаления файлов может занять довольно много времени. Чтобы ускорить удаление, можно воспользоваться одной из следующих команд:

    # find /usr/pkgsrc -name work -exec rm -r {} +
    # find /usr/pkgsrc -maxdepth 3 -mindepth 3 -name work -exec rm -r {} +

Вторая команда должна отработать быстрее, т.к. ищет каталог `work` только внутри каталогов портов, не занимаясь поиском каталога `work` в вышележащих и нижележащих каталогах.

Отслеживание уязвимостей
------------------------

[5.1.6. Checking for security vulnerabilities in installed packages](https://www.netbsd.org/docs/pkgsrc/using.html#vulnerabilities)

Скачивание свежей информации об уязвимостях в программном обеспечении:

    # pkg_admin fetch-pkg-vulnerabilities

Проверка наличия уязвимостей в установленных пакетах:

    # pkg_admin audit

Для автоматического периодического обновления информации об уязвимостях нужно вписать в `/etc/daily.conf`:

    fetch_pkg_vulnerabilities=YES

Для автоматической периодической проверки установленных пакетов на уязвимости нужно вписать в `/etc/security.conf`:

    check_pkg_vulnerabilities=YES

Для того, чтобы в скриптах из базовой системы использовались пути к утилитам, установленным из pkgsrc, нужно заменить пути к программам `pkg_admin` и `pkg_info` в файле `/etc/pkgpath.conf`:

    pkg_admin=/usr/pkg/sbin/pkg_admin
    pkg_info=/usr/pkg/sbin/pkg_info

Решение проблем
---------------

### Проблема 1

Если при обновлении Perl возникает ошибка следующего вида:

    pkg_add: Can't open +CONTENTS of depending package p5-Crypt-OpenSSL-Guess-0.11

То решить её можно при помощи следующей команды:

    # pkg_admin rebuild-tree

Источник: [RE: Error Installing perl-5.28.1 on netbsd 7.1.1 - pkg_add: Can't open +CONTENTS of depending package p5-Crypt-OpenSSL-Guess-0.11](https://mail-index.netbsd.org/pkgsrc-users/2019/01/19/msg027965.html)

### Проблема 2

Если при сборке какой-либо программы из pkgsrc в процессе установки зависимостей из двоичных пакетов возникает проблема такого вида:

    ===> Binary install for perl-5.36.1
    ERROR: perl-5.34.0nb3 is already installed - perhaps an older version?
    ERROR: If so, you may wish to ``pkg_delete perl-5.34.0nb3'' and install
    ERROR: this package again by ``/usr/bin/make bin-install'' to upgrade it properly.
    *** Error code 1

Происходит это из-за повреждённой базы данных пакетов. Можно попробовать переустановить все установленные в системе пакеты с помощью `pkgin` (перед удалением пакетов не забудьте сохранить архив с пакетом `pkgin`). Сохраним в файл список установленных пакетов:

    # pkgin export > /root/pkgs

Удалим все установленные в системе пакеты:

    # pkg_info | awk '{ print $1; }' | xargs -n1 pkg_delete -ffrR

Возможно потребуется выполнить указанную выше команду дважды, т.к. после удаления пакета `pkg_install` будет использоваться утилита `pkg_info` из базовой системы, которая может использовать вшитый в неё путь к базе данных с пакетами, список пакетов в которой будет непустым и может отличаться от списка уже удалённых пакетов.

Теперь удалим базу данных пакетов:

    # rm -R /usr/pkg/pkgdb.refcount /usr/pkg/pkgdb

Установим пакет `pkgin` из заранее сохранённого архива:

    # pkg_add /var/pkg_comp/packages/All/pkgin-22.10.0nb2.tgz

Заново установим все пакеты, которые были установлены в системе:

    # pkgin import /root/pkgs

Учтите, что `pkgin` должен быть настроен, а повторная установка удалённых пакетов будет происходить из репозитория, указанного в настройках `pkgin`.

Цели make
---------

* `make clean` - удалить исходные файлы из рабочего каталога так, что можно будет начать сборку сначала с новыми опциями, заплатами и т.д.
* `make fetch` - просто скачивает файлы и проверяет соответствие его хэш-суммы. Сообщает об ошибке, если хэш-сумма не существует.
* `make distinfo` или `make mdi` - обновляет описанные выше хэш-суммы файлов в файле `distinfo`.
* `make extract` - извлекает исходные тексты программы из её архива в каталог `work`.
* `make patch` - применяет локальные заплаты из pkgsrc к исходным текстам.
* `make configure` - запускает сценарий GNU configure.
* `make` или `make build` или `make all` - остановиться после компиляции программы.
* `make stage-install` - установка в целевой промежуточный каталог `destdir` для проверки, что список установленных файлов соответствует указанному в `PLIST`, перед установкой в каталог prefix. Например, в случае `wget`, если у вас есть каталог по умолчанию `WRKOBJDIR` (будет объяснён ниже), файлы программы сначала будут установлены в `<путь>/pkgsrc/net/wget/work/.destdir`, а затем, после нескольких проверок, в каталог установки, такой как `/usr/pkg`.
* `make test` - запускает тесты пакета, если они существуют.
* `make package` - создаёт пакет без его установки, но при этом всё равно будут установлены зависимости.
* `make replace` - модернизировать или переустановить пакет, если он уже установлен.
* `make deinstall` - удалить программу.
* `make install` - установить из вышеупомянутого каталога `work/.destdir` в каталог `prefix`.
* `make bin-install` - установить пакет локально, если он ранее уже был собран, или удалённо, как описано в переменной `BINPKG_SITES` в файле `mk.conf`. Вы можете установить зависимости из пакетов, если настроите переменную `DEPENDS_TARGET= bin-install` в файле `mk.conf`.
* `make show-depends` - показать зависимости порта.
* `make show-options` - показать различные опции порта, описанные в `options.mk`.
* `make clean-depends` - очистить все зависимости порта.
* `make distclean` - удалить архив с исходными текстами.
* `make package-clean` - удалить пакет.
* `make distinfo` или `make mdi` - обновить файл `distinfo`, содержащий хэш-суммы файлов, если у вас новый `distfile` или заплатка.
* `make makepatchsum` - обновить хэш-суммы заплаток в файле `distinfo`.
* `make print-PLIST` - сгенерировать файл `PLIST` из файлов, найденных в каталоге `work/.destdir`.

Использованные материалы
------------------------

* [The pkgsrc guide. Chapter 3. Where to get pkgsrc and how to keep it up-to-date](https://www.netbsd.org/docs/pkgsrc/getting.html)
* [The pkgsrc guide. Chapter 5. Using pkgsrc](https://www.netbsd.org/docs/pkgsrc/using.html)
* [The pkgsrc guide. Chapter 13. The build process](https://www.netbsd.org/docs/pkgsrc/build.html)
* [An introduction to packaging](https://wiki.netbsd.org/pkgsrc/intro_to_packaging/)
