Установка sinit в NetBSD
========================

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

Существует концепция минимального демона инициализации, выдвинутая автором библиотеки musl libc Ричем Фелькером (Rich Felker), согласно которой минимальный процесс init должен лишь вызывать при запуске скрипт `/etc/rc.init`, усыновлять осиротевшие процессы и вызывать скрипт `/etc/rc.shutdown` при получении сигналов, инициирующих завершение работы. Эта концепция была воплощена в демоне sinit, исходные тексты которого распространяются проектом suckless.org, через репозиторий [git.suckless.org/sinit/](https://git.suckless.org/sinit/).

В NetBSD терминалы запускаются не при помощи rc-скриптов, а самим демоном `init`, который руководствуется списком терминалов из файла `/etc/ttys`. В статье [[Запуск getty в NetBSD с помощью daemontools|netbsd_daemontools_getty]] описано, как снять функцию запуска терминалов с демона init и возложить её на плечи `daemontools`.

После настройки запуска консолей с помощью `daemontools` становится возможным заменить `init` из NetBSD на `sinit` и получить операционную систему с максимально простой и надёжной системой инициализации.

Хотя демон `init` в NetBSD уже достаточно прост и при его замене на `sinit` мы потеряем, например, возможность запуска NetBSD в однопользовательском режиме, можно попытаться сделать это не из каких-то практических соображений, а скорее из чистого любопытства и любви к искусству.

Подготовка пакета
-----------------

В pkgsrc нет пакета с sinit и мне пришлось подготовить его самостоятельно. Наиболее подходящий раздел для этого пакета - sysutils. Первая задача - найти в интернете источник, из которого можно скачать архив с исходными текстами. Два найденных git-репозитория [git.suckless.org/sinit](https://git.suckless.org/sinit/) и [git.2f30.org/sinit/](https://git.2f30.org/sinit/) не позволяют скачать архив. Пришлось воспользоваться зеркалом на [github.com/mathumani/sinit/](https://github.com/mathumani/sinit/). В репозитории нет меток версий и нет никаких веток, кроме ветки master, поэтому пришлось сослаться на хэш-сумму последней фиксации, соответствующей версии 1.1. Для скачивания исходных текстов я создал файл `sysutils/sinit/Makefile` со следующим содержимым:

    # $NetBSD$
    
    DISTNAME=                       sinit
    PKGNAME=                        ${DISTNAME}-1.1
    CATEGORIES=                     sysuitls
    MASTER_SITES=                   ${MASTER_SITE_GITHUB:=mathumani/}
    GITHUB_PROJECT=                 sinit
    GITHUB_TAG=                     28c44b6b94a870f2942c37f9cfbae8b770595712

В качестве сопровождающего пакета я указал свой почтовый ящик, а в качестве ссылки на официальный сайт привёл страницу [git.suckless.org/sinit/](https://git.suckless.org/sinit/). Судя по файлу лицензии в репозитории, это лицензия MIT. Описание пакета взял из файла README. В итоге, дописал в файл `sysutils/sinit/Makefile` следующее:

    MAINTAINER=                     vladimir@stupin.su
    HOMEPAGE=                       https://git.suckless.org/sinit/
    COMMENT=                        sinit is a simple init
    LICENSE=                        mit

Также добавил более длинное описание в файл `sysutils/sinit/DESCR`:

    sinit is a simple init.  It was initially based on Rich Felker's minimal init.

Файл `sysutils/sinit/Makefile` завершил подключением системы pkgsrc:

    .include "../../mk/bsd.pkg.mk"

Теперь можно скачать архив с исходными текстами и создать файл `distinfo` с хэш-суммами архивного файла:

    # make fetch
    # make distinfo

Поскольку программа написана на языке C, но у неё нет сценария конфигурирования, добавим в файл `sysutils/sinit/Makefile` следующие строчки:

    NO_CONFIGURE=                   yes
    USE_LANGUAGES=                  c

Теперь можно попытаться собрать пакет:

    # make

Оказывается, для сборки `sinit` нужен GNU Make, но использовать его мне не хочется. Единственное, что не получается сделать без его помощи - сгенерировать файл `config.h` из файла `config.def.h`. Но достичь этого можно простым копированием файла. Я не стану копировать файл, а просто переименую его:

    post-extract:
            ${MV} ${WRKSRC}/config.def.h ${WRKSRC}/config.h

Следующее, что мы сделаем, это избавимся от файла `config.mk`, в котором определены переменные с настройками для сборки файла `sinit.c`. Большинство настроек определяется через переменные системы pkgsrc. Единственные две переменные, которые потребуются и которых нет в pkgsrc - это переменные `MANPREFIX` и `VERSION`. Итак, удаляем директиву include в начале файла `Makefile`, добавим значение переменной `VERSION` и заменим `$(MANPREFIX)` на `$(PREFIX)/man`:

    $NetBSD$
    
    --- Makefile.orig       2018-03-26 16:48:09.000000000 +0000
    +++ Makefile
    @@ -1,7 +1,6 @@
    -include config.mk
    -
     OBJ = sinit.o
     BIN = sinit
    +VERSION = 1.1
     
     all: $(BIN)
     
    @@ -11,10 +10,10 @@ $(BIN): $(OBJ)
     $(OBJ): config.h
     
     install: all
    -       mkdir -p $(DESTDIR)$(PREFIX)/bin
    -       cp -f $(BIN) $(DESTDIR)$(PREFIX)/bin
    -       mkdir -p $(DESTDIR)$(MANPREFIX)/man8
    -       sed "s/VERSION/$(VERSION)/g" < $(BIN).8 > $(DESTDIR)$(MANPREFIX)/man8/$(BIN).8
    +       mkdir -p $(DESTDIR)$(PREFIX)/sbin
    +       cp -f $(BIN) $(DESTDIR)$(PREFIX)/sbin
    +       mkdir -p $(DESTDIR)$(PREFIX)/man/man8
    +       sed "s/VERSION/$(VERSION)/g" < $(BIN).8 > $(DESTDIR)$(PREFIX)/man/man8/$(BIN).8
     
     uninstall:
            rm -f $(DESTDIR)$(PREFIX)/bin/$(BIN)

Кроме этого я поменял каталог установки `bin` на `sbin`, т.к. исполняемый файл не предназначен для использования непривилегированным пользователем.

Сгенерировать заплатку можно с помощью утилиты `pkgdiff`, перенаправив её вывод в файл `sysutils/sinit/patches/patch-Makefile` и подредактировав результат так, чтобы в ней фигурировали имена файлов `Makefile` и `Makefile.orig` без предшествующих каталогов, как это показано выше.

Аналогичным образом я внёс одно небольшое изменение в исходный текст `sinit.c`, удалив из него две бесполезные директивы `include`. Не знаю, повлияло ли это как-то на конечный результат. Получившуюся заплатку я поместил в каталог `sysutils/sinit/patches/patch-sinit.c`:

    $NetBSD$
    
    --- sinit.c.orig        2018-03-26 16:48:09.000000000 +0000
    +++ sinit.c
    @@ -1,10 +1,8 @@
     /* See LICENSE file for copyright and license details. */
    -#include <sys/types.h>
     #include <sys/wait.h>
     
     #include <signal.h>
     #include <stdio.h>
    -#include <stdlib.h>
     #include <unistd.h>
     
     #define LEN(x) (sizeof (x) / sizeof *(x))

Чтобы заплатки без проблем применялись при сборке, нужно сгенерировать их хэш-суммы. Сделать это можно с помощью одной из следующих команд:

    # make makepatchsum
    # make mdi

Кроме результатов сборки я хочу поместить в пакет файлы `LICENSE` и `README`. Для этого я добавил в `Makefile` дополнительное правило:

    post-install:
            ${INSTALL_DATA} ${WRKSRC}/LICENSE ${DESTDIR}${PREFIX}/share/doc/${PKGBASE}
            ${INSTALL_DATA} ${WRKSRC}/README ${DESTDIR}${PREFIX}/share/doc/${PKGBASE}

Чтобы установка этих файлов сработала, нужно создать каталог. Сделать это можно с помощью такой опции:

    INSTALLATION_DIRS=              share/doc/${PKGBASE}

В уже упомянутом выше файле `config.h` находятся настройки с командами, которые `sinit` должен выполнить при запуске, перезагрузке или выключении системы. Команду перезагрузки `sinit` выполняет при получении сигнала `INT`, а команду выключения - при получении сигнала `USR`.

Файл `/etc/rc`, при помощи которого фактически запускается вся система, в NetBSD не имеет бита исполнимости. Есть и другие обстоятельства, которые вскрылись в процессе попыток воспользоваться `sinit` по прямому назначению, по которым файл `/etc/rc` нельзя использовать напрямую. Никакого другого подходящего готового файла в системе я не нашёл, поэтому в качестве команды запуска решил прописать пока не существующий файл `/etc/rc.init`, который будет описан ниже. В качестве команд для перезагрузки и выключения системы пропишем `/sbin/reboot` и `/sbin/poweroff`. Для этого добавим в файл `sysutils/sinit/Makefile` следующие правила замены фрагментов текста с помощью утилиты `sed`:

    .if "${OPSYS}" == "NetBSD"
    SUBST_CLASSES+=                 config.h
    SUBST_STAGE.config.h=           post-patch
    SUBST_MESSAGE.config.h=         Fixing config.h.
    SUBST_FILES.config.h+=          config.h
    SUBST_SED.config.h=             -e 's:/bin/rc.init:/etc/rc.init:g'
    SUBST_SED.config.h+=            -e 's:/bin/rc.shutdown", "reboot:/sbin/reboot:g'
    SUBST_SED.config.h+=            -e 's:/bin/rc.shutdown", "poweroff:/sbin/poweroff:g'
    .endif

Правила применяются только для операционной системы NetBSD, поскольку в других системах команды могут быть другими.

Честно говоря, я не совсем понимаю, зачем в `sinit` предусмотрена обработка сигналов `INT` и `USR1`, т.к. эти команды можно вызвать и напрямую. Я бы, пожалуй, просто вырезал бы этот функционал из `sinit`.

Вернёмся к файлу `/etc/rc.init`. Запустить систему, в которой демоны `getty` уже запускаются с помощью `daemontools`, как это описано в статье [[Запуск getty в NetBSD с помощью daemontools|netbsd_daemontools_getty]], у меня получилось с помощью такого файла `/etc/rc.init`:

    #!/bin/sh
    
    exec >/dev/constty 2>&1
    /bin/sh /dev/MAKEDEV -u all
    /bin/sh /etc/rc autoboot

Как видно, первым делом в этом файле выполняется перенаправление вывода последующих команд в консоль `/dev/constty`. Вместо него можно также использовать и `/dev/console`, но поскольку в NetBSD в конфигурации по умолчанию первая строчка в файле `/etc/ttys` использует именно консоль `/dev/constty`, я воспользовался именно ей. В демоне `init`, поставляемом в составе NetBSD, пробуются оба устройства, но предпочтение отдаётся `/dev/constty`.

Также демон `init`, при отсутствии устройств в каталоге `/dev`, самостоятельно запускает скрипт `/dev/MAKEDEV`. Поскольку `sinit` задумывался как минимальная реализация `init`, этот функционал я перенёс в скрипт `/etc/rc.init`.

Ну и в последней строчке скрипта запускается скрипт `/etc/rc` с аргументом `autoboot`, который соответствует многопользовательскому режиму загрузки. `init` из состава NetBSD можно запустить с опцией `-s` и тогда он будет загружаться в однопользовательском режиме без передачи скрипту `/etc/rc` дополнительных аргументов. Если `init` запущен в обычном режиме или переходит в обычный режим после однопользовательского, то скрипту `/etc/rc` передаётся аргумент `autoboot`.

Этот скрипт я поместил в каталог `sysutils/sinit/files`. Кроме того, в этот же каталог я поместил текстовый файл `INSTALL` с примером установки `sinit` вместо `init` из NetBSD:

    How to install sinit instead of NetBSD own init:
    
            mv /sbin/init /sbin/init.bak
            cp @PREFIX@/sbin/sinit /sbin/init
            cp @PREFIX@/share/examples/@PKGBASE@/rc.init /etc/rc.init
            chmod +x /etc/rc.init

Как видно, в этом файле есть шаблоны подстановки вида `@PREFIX@` и `@PKGBASE@`. Для их обработки я добавил в файл `sysutils/sinit/Makefile` следующие правила замены:

    SUBST_CLASSES+=                 install
    SUBST_STAGE.install=            post-patch
    SUBST_MESSAGE.install=          Fixing INSTALL.
    SUBST_FILES.install+=           INSTALL
    SUBST_VARS.install+=            PREFIX PKGBASE

Файлы `rc.init` и `INSTALL` будем устанавливать в каталог `share/examples/sinit`. Добавим этот каталог в опцию `INSTALLATION_DIRS` для создания каталога перед установкой файлов:

    INSTALLATION_DIRS=              share/doc/${PKGBASE} share/examples/${PKGBASE}

Для установки файлов `rc.init` и `INSTALL` доработаем в файле `sysutils/sinit/Makefile` цели `post-extract` и `post-install`

    post-extract:
            ${MV} ${WRKSRC}/config.def.h ${WRKSRC}/config.h
            ${CP} ${FILESDIR}/INSTALL ${WRKSRC}
    
    post-install:
            ${INSTALL_DATA} ${WRKSRC}/LICENSE ${DESTDIR}${PREFIX}/share/doc/${PKGBASE}
            ${INSTALL_DATA} ${WRKSRC}/README ${DESTDIR}${PREFIX}/share/doc/${PKGBASE}
            ${INSTALL_DATA} ${WRKSRC}/INSTALL ${DESTDIR}${PREFIX}/share/examples/${PKGBASE}
            ${INSTALL_DATA} ${FILESDIR}/rc.init ${DESTDIR}${PREFIX}/share/examples/${PKGBASE}

Файл `rc.init` устанавливается из каталога `sysutils/sinit/files` напрямую в каталог `share/examples/sinit`, а файл `INSTALL` устанавливается в два этапа, между которыми к нему применяются правила подстановки в нём шаблонов `@PREFIX@` и `@PKGBASE@`.

Теперь можно попробовать обновить файл `sysutils/sinit/PLIST` и собрать пакет:

    # make stage-install
    # make print-PLIST > PLIST
    # make package

Первая команда может ругнуться на несоответствие списка файлов будущего пакета содержимому файла `sysutils/sinit/PLIST`, но если следующие команды выполнились успешно, то мы получим готовый пакет.

Установка
---------

Установим пакет с помощью команд:

    # cd /usr/pkgsrc/sysutils/sinit
    # make install

Я пользуюсь собственным сборочным сервером, настройка которого описана в статье [[Настройка сборочного сервера NetBSD|netbsd_sysbuild]], с помощью которого поддерживаю собственный репозиторий с готовыми двоичными пакетами, собранными с нужными мне опциями. Поэтому я установил готовый пакет из этого репозитория:

    # pkgin update
    # pkgin -y install sinit

Остаётся воспользоваться командами, описанными нами в файле `INSTALL`:

    # mv /sbin/init /sbin/init.bak
    # cp /usr/pkg/sbin/sinit /sbin/init
    # cp /usr/pkg/share/examples/sinit/rc.init /etc/rc.init
    # chmod +x /etc/rc.init

Перезагружаем систему:

    # reboot

Если возникнут проблемы с загрузкой системы, нужно воспользоваться загрузочным диском, смонтировать корневой каталог системы в режиме чтения-записи и удалить файл `sbin/init` и/или заменить его на резервную копию из файла `sbin/init.bak`. В моём случае последовательность команд была такой:

    # mount -o rw /dev/dk0 /mnt
    # cd /mnt/sbin
    # rm init
    # mv init.bak init
    # reboot
