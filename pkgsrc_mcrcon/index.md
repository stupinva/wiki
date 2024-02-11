Делаем pkgsrc для клиента консоли администрирования сервера Minecraft mcrcon
============================================================================

[[!tag netbsd pkgsrc minecraft]]

Введиние
--------

В сервер Minecraft встроена консоль администрирования, которая доступна через стандартный поток ввода и стандартный поток вывода. Но также возможно получить доступ к консоли администрирования через сеть. Для этого сервер Minecraft поддерживает специальный протокол RCON, описание которого можно найти по ссылкам [RCON](https://wiki.vg/RCON) и [Source RCON Protocol](https://developer.valvesoftware.com/wiki/Source_RCON_Protocol).

Для подключения к консоли администрирования сервера по протоколу RCON существуют специальные клиенты. Одним из таких клиентов, написаным на языке программирования Си, является клиент [mcrcon](https://github.com/tiiffi/mcrcon).

Подготовка пакета
-----------------

В pkgsrc нет пакета с `mcrcon` и мне пришлось подготовить его самостоятельно. Наиболее подходящий раздел для этого пакета - games. Для скачивания исходных текстов воспользуемся официальной страницей проекта на [github.com/tiiffi/mcrcon](https://github.com/tiiffi/mcrcon). В репозитории имеются метки версий, самой свежей из которых является версия 0.7.2. Для скачивания исходных текстов я создал файл `games/mcrcon/Makefile` со следующим содержимым:

    # $NetBSD$
    
    DISTNAME=               mcrcon
    VERSION=                0.7.2
    PKGNAME=                ${DISTNAME}-${VERSION}
    CATEGORIES=             games
    MASTER_SITES=           ${MASTER_SITE_GITHUB:=Tiiffi/}
    GITHUB_PROJECT=         mcrcon
    GITHUB_TAG=             v${VERSION}

В качестве сопровождающего пакета я указал свой почтовый ящик, а в качестве ссылки на официальный сайт привёл всё ту же ссылку [github.com/tiiffi/mcrcon](https://github.com/tiiffi/mcrcon). В репозитории отмечено, что проект распространяется под лицензией Zlib. Краткое описание пакета взял из раздела About. В итоге, дописал в файл `games/mcrcon/Makefile` следующее:

    MAINTAINER=             vladimir@stupin.su
    HOMEPAGE=               https://github.com/Tiiffi/mcrcon
    COMMENT=                Rcon client for Minecraft
    LICENSE=                zlib

Также добавил более длинное описание в файл `games/mcrcon/DESCR`, взятое из файла `README.md`:

    mcrcon is console based Minecraft rcon client for remote administration and server maintenance scripts.

Файл `games/mcrcon/Makefile` завершил подключением системы pkgsrc:

.include "../../mk/bsd.pkg.mk"

И создадим пустой файл `PLIST`:

    # touch PLIST

Теперь можно скачать архив с исходными текстами и создать файл `distinfo` с хэш-суммами архивного файла:

    # make fetch
    # make distinfo

Поскольку программа написана на языке C, но у неё нет сценария конфигурирования, добавим в файл `games/mcrcon/Makefile` следующие строчки:

    NO_CONFIGURE=                   yes
    USE_LANGUAGES=                  c

Теперь можно попытаться собрать пакет:

    # make

Оказывается, для сборки `mcrcon` нужен GNU Make. Добавим к списку дополнительных инструментов для сборки GNU Make следующим образом:

    USE_TOOLS+=             gmake

Теперь сборка выполняется успешно, но собрать пакет не удаётся, т.к. в командах `install` в файле `Makefile` из исходных текстов проекта используются опции утилиты из Linux. Для исправления проблемы сделаем копию файла `Makefile` под именем `Makfile.orig`, например, следующим образом:

    # cp work/mcrcon-0.7.2/Makefile work/mcrcon-0.7.2/Makefile.orig

Отредактируем файл следующим образом:

    -       $(INSTALL) -vD $(EXENAME) $(DESTDIR)$(PREFIX)/bin/$(EXENAME)
    -       $(INSTALL) -vD -m 0644 mcrcon.1 $(DESTDIR)$(PREFIX)/share/man/man1/mcrcon.1
    +       $(INSTALL) -d $(DESTDIR)$(PREFIX)/bin/
    +       $(INSTALL) $(EXENAME) $(DESTDIR)$(PREFIX)/bin/
    +       $(INSTALL) -d $(DESTDIR)$(PREFIX)/share/man/man1/
    +       $(INSTALL) -m 0644 mcrcon.1 $(DESTDIR)$(PREFIX)/share/man/man1/

Сгенерируем заплатку с помощью утилиты `pkgdiff` из одноимённого пакета следующим образом:

    # mkdir patches
    # cd work/mcrcon-0.7.2
    # pkgdiff Makefile > ../../patches/patch-Makefile
    # cd ../..

Контрольная сумма новой заплатки должна быть указана в файле `distinfo`, добавим её с помощью следующей команды:

    # make distinfo

Попробуем собрать пакет:

    # make clean package

Теперь сборка и установка файлов вполняется успешно, но устанавливаемые файлы не указаны в файле `PLIST`. Исправим это с помощью следующей команды:

    # make print-PLIST > PLIST

После сборки в пакет попадут всего два файла: исполняемый файл mcrcon и его страница руководства. Но в репозитории имеются и другие файлы, которые можно было бы устанавливать в систему в качестве документации. Это файлы `LICENSE`, `README.md`, `INSTALL.md` и `CHANGELOG.md`. Исправим это, добавив в файл `Makefile` следующие дополнительные строчки:

    INSTALLATION_DIRS=      share/doc/${PKGBASE}
    
    post-install:
            ${INSTALL_DATA} ${WRKSRC}/LICENSE ${DESTDIR}${PREFIX}/share/doc/${PKGBASE}
            ${INSTALL_DATA} ${WRKSRC}/README.md ${DESTDIR}${PREFIX}/share/doc/${PKGBASE}
            ${INSTALL_DATA} ${WRKSRC}/INSTALL.md ${DESTDIR}${PREFIX}/share/doc/${PKGBASE}
            ${INSTALL_DATA} ${WRKSRC}/CHANGELOG.md ${DESTDIR}${PREFIX}/share/doc/${PKGBASE}

Снова попробуем собрать пакет и обновим файл `PLIST`, после чего сборка пакета должна оказаться успешной:

    # make clean package
    # make print-PLIST > PLIST
    # make package

Установка
---------

Установим пакет с помощью команд:

    # cd /usr/pkgsrc/games/mcrcon
    # make install

Я пользуюсь собственным сборочным сервером, настройка которого описана в статье [[Настройка сборочного сервера NetBSD|netbsd_sysbuild]], с помощью которого поддерживаю собственный репозиторий с готовыми двоичными пакетами, собранными с нужными мне опциями. Поэтому я установил готовый пакет из этого репозитория:

    # pkgin update
    # pkgin -y install mcrcon

Вклюение консоли администрирования
----------------------------------

Для включения и настройки консоли администрирования сервером Minecraft, работающей по протоколу RCON, предназначены следующие опции в файле `/var/games/minecraft-server/server.properties`:

   enable-rcon=true
   rcon.password=$ecret_p4$$w0rd
   rcon.port=25575
   broadcast-rcon-to-ops=false

Где:

* `enable-rcon` - логическая переменная, включающая консоль администрирования. Значение `true` включает консоль, значение `false` - выключает,
* `rcon.password` - пароль для доступа к консоли адинистрирования,
* `rcon.port` - номер TCP-порта для доступа к консоли администрирования. По умолчанию для консоли администрирования используется порт с номером 25575,
* `broadcast-rcon-to-ops` - логическая переменная, вклюающая отправку вывода команд всем администраторам, подключенным к серверу. Значение `true` включает отправку вывода команд всем администраторам сервера, значение `false` - отключает.

После изменения настроек сервер Minecraft нужно перезапустить, чтобы настройки вступили в силу. В моём случае сервер Minecraft работает под управлением `daemontools` (см. статью [[Запуск сервера Minecraft в NetBSD с помощью daemontools|netbsd_daemontools_minecraft_server]]), поэтому перезапустить его можно следующим образом:

    # svc -du /service/minecraft-server

Использованные материалы
------------------------

* [[Установка sinit в NetBSD|netbsd_sysbuild]]
* [Minecraft wiki / Создание и настройка сервера](https://minecraft.fandom.com/ru/wiki/%D0%A1%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5_%D0%B8_%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0_%D1%81%D0%B5%D1%80%D0%B2%D0%B5%D1%80%D0%B0)
