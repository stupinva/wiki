Установка greylistd в NetBSD
============================

[[!tag pkgsrc greylistd]]

Содержание
----------

[[!toc levels=4 startlevel=2]]

Введение
--------

greylistd - это демон, написанный на языке программирования Python. С его помощью можно добавить в почтовый сервер Exim функции фильтрации писем по серым спискам. Мне понадобилось установить его в NetBSD, но в pkgsrc нет greylistd, поэтому пришлось добавить его в pkgsrc самостоятельно. На всякий случай решил описать процесс, т.к. до этого я только дорабатывал только чужие pkgsrc, а этот pkgsrc был моим первым, созданным самостоятельно.

Написание pkgsrc
----------------

Т.к. до этого я пользовался greylistd в Debian, то решил собрать такую же версию, которая есть в официальных репозиториях Debian. На момент написания этой заметки это была версия 0.9.0.2. Оказалось, что сейчас разработка greylistd ведётся одним из разработчиков Debian и [git-репозиторий проекта находится на GitLab-сервере Debian](https://salsa.debian.org/debian/greylistd/). Нашёл ссылку на скачивание [архива исходных текстов версии 0.9.0.2](https://salsa.debian.org/debian/greylistd/-/archive/master/greylistd-master.tar.bz2) и с помощью утилиты `url2pkg` сгенерировал заготовку:

    $ url2pkg https://salsa.debian.org/debian/greylistd/-/archive/master/greylistd-master.tar.bz2

Сразу же поправил в `Makefile` информацию о сопровождающем пакета, лицензии и прописал ссылку на домашний сайт проекта:

    MAINTAINER=             vladimir@stupin.su
    HOMEPAGE=               https://salsa.debian.org/debian/greylistd/
    COMMENT=                Greylisting daemon for use with Exim 4
    LICENSE=                gnu-gpl-v2

В этот же файл предпоследней строчкой добавил зависимость от языка программирования Python:

    .include "../../lang/python/egg.mk"

Заменил автоматически сгенерированное содержимое файла `DESCR` на простую строчку с описанием назначения программы:

    Greylisting daemon for use with Exim 4

На этом этапе можно было выполнить распаковку проекта с помощью команды `make extract`, но сборка не выполнялась, т.к. для сборки проектов на Python требуется файл `setup.py`, которого не оказалось в исходных текстах, т.к. разработчики Debian собирают сразу пакет для Debian.

Вооружившись [статьёй, в которой описано, как писать файлы `setup.py`](https://docs.python.org/3/distutils/setupscript.html), написал такой файл:

    #!/usr/bin/env python
    
    from distutils.core import setup
    
    setup(name='Greylistd',
          version='0.9.0.2',
          maintainer='Vladimir Stupin',
          maintainer_email='vladimir@stupin.su',
          url='https://salsa.debian.org/debian/greylistd/',
          description='Greylisting daemon for use with Exim 4',
          keywords=['mail'],
          license='GPLv2+',
          classifiers=['License :: OSI Approved :: GNU General Public License v2 or later (GPLv2+)',
                       'Programming Language :: Python',
                       'Topic :: Communications :: Email :: Filters'],
          packages=['greylistd'],
          package_dir={'greylistd': 'program'},
          data_files=[('bin', ['program/greylist']),
                      ('sbin', ['program/greylistd-setup-exim4',
                                'program/greylistd']),
                      ('share/examples/greylistd', ['doc/examples/exim4-acl-example.txt',
                                                    'doc/examples/whitelist-hosts']),
                      ('etc/greylistd', ['config/config',
                                         'config/whitelist-hosts']),
                      ('man/man1', ['doc/man1/greylist.1']),
                      ('man/man8', ['doc/man8/greylistd.8',
                                    'doc/man8/greylistd-setup-exim4.8']),
                      ]
          )

Этот файл сохранил под именем `files/setup.py`.

Для того, чтобы файл попадал в каталог с исходными текстами перед сборкой, прописал в `Makefile` дополнительное правило:

    post-extract:
            ${CP} ${FILESDIR}/setup.py ${WRKSRC}/setup.py

Теперь сборка командой `make` выполнилась успешно.

Осталось наполнить файл `PLIST` правильным списком файлов, входящих в состав пакета. Для этого я выполнил две команды:

    $ make package
    $ make print-PLIST > PLIST

В получившемся пакете исполняемые файлы не имеют бита исполнимости. Чтобы исправить это, добавим в правило `post-extract` в `Makefile` дополнительные команды:

        ${RUN}${CHMOD} +x ${WRKSRC}/program/greylist
        ${RUN}${CHMOD} +x ${WRKSRC}/program/greylistd
        ${RUN}${CHMOD} +x ${WRKSRC}/program/greylistd-setup-exim4

Но этого не достаточно. Поскольку исполняемые файлы являются скриптами, для их запуска используется интерпретатор. Путь к интерпретатору содержится в первой строке исполняемого файла и начинается с символов `#!`. Изменить путь к интерпретатору языка Python можно с помощью опции `REPLACE_PYTHON`, в качестве значения которой нужно указать все скрипты на языке Python, в которых нужно исправить путь к интерпретатору:

    REPLACE_PYTHON=         program/greylist program/greylistd program/greylistd-setup-exim4

Если заглянуть в файл `program/greylistd`, то можно заметить, что для его запуска требуется Python версии 3.6 или выше:

    # Ensure that we can run this program
    if sys.version_info.major < 3 or sys.version_info.minor < 6:
        sys.stderr.write("This program requires Python 3.6 or newer\n")
        sys.exit(1)

Проверим, какие версии Python доступны из pkgsrc:

    # cd /usr/pkgsrc/lang
    # ls -d python*
    python    python27  python310 python311 python37  python38  python39

Версии 3.7, 3.8, 3.9, 3.10, 3.11 совместимы с greylistd, а версия 2.7 - нет. Добавим в Makefile список несовместимых версий Python:

    PYTHON_VERSIONS_INCOMPATIBLE=   27

Для поддержки этой опции в конец `Makefile` перед прочими директивами `.include` нужно добавить ещё одну:

    .include "../../lang/python/application.mk"

В исполняемых файлах и файлах конфигурации указаны пути к файлам конфигурации, к Unix-сокету, к файлам базы данных демона. Нужно откорректировать пути ко всем этим файлам так, чтобы они соответствовали настройкам, заданным при сборке пакета из pkgsrc. Для этого воспользуемся функционалом `SUBST` из pkgsrc и пропишем в `Makefile` следующие настройки:

    SUBST_CLASSES+=         paths
    SUBST_STAGE.paths=      pre-configure
    SUBST_MESSAGE.paths=    Fixing absolute paths.
    SUBST_FILES.paths=      config/config program/greylist program/greylistd program/greylistd-setup-exim4 doc/man8/greylistd.8
    SUBST_SED.paths=        -e 's,/etc/,${PREFIX}/etc/,g'
    SUBST_SED.paths+=       -e 's,/var/lib/greylistd/,${VARBASE}/db/greylistd/,g'
    SUBST_SED.paths+=       -e 's,/var/run/greylistd/socket,${VARBASE}/run/greylistd.sock,g'
    SUBST_VARS.paths=       PREFIX VARBASE

В указанных выше настройках есть только одна группа замен, которая называется `paths`. Выполняются замены на этапе `pre-configure`. Пути к изменяемым файлам перечислены в переменной `SUBST_FILES`. Далее следуют три правила замены, в которых используются значения переменных `PREFIX` и `VARBASE`. Имена переменных, участвующих в замене, перечислены в переменной `SUBST_VARS`.

Для запуска greylistd нужны пользователь и группа greylist, т.к. они используются в качестве владельца Unix-сокета. Добавим в `Makefile` настройки:

    GREYLIST_USER?=        greylist
    GREYLIST_GROUP?=       greylist

Добавим в `Makefile` опции, преписывающие создать необходимых для работы пакета группу и пользователя:

    PKG_GROUPS+=           ${GREYLIST_GROUP}
    PKG_USERS+=            ${GREYLIST_USER}:${GREYLIST_GROUP}

И добавим в `Makefile` замену пользователя и группы владельца Unix-сокета в исходном тексте greylistd:

    SUBST_CLASSES+=                user_group
    SUBST_STAGE.user_group=        pre-configure
    SUBST_MESSAGE.user_group=      Replacing user and group.
    SUBST_FILES.user_group=        program/greylistd
    SUBST_SED.user_group=          -e 's,SOCKOWNER: "greylist:greylist",SOCKOWNER: "${GREYLIST_USER}:${GREYLIST_GROUP}",g'
    SUBST_VARS.user_group=         GREYLIST_USER GREYLIST_GROUP

Для работы greylistd нужен доступ в каталог `/var/db/greylistd`, в котором он хранит статистику, белые, чёрные и серые списки. Для создания этого каталога с соответсвующими правами доступа добавим в файл `Makefile` такую строку:

    OWN_DIRS_PERMS+=               ${VARBASE}/db/greylistd/ ${GREYLIST_USER} ${GREYLIST_GROUP} 0766

Кроме этого, как оказалось, при запуске greylistd от имени пользователя greylist, ему не удаётся создать Unix-сокет в каталоге `/var/run/` из-за нехватки прав. Поэтому изменим путь к Unix-сокету, переместив его в каталог с файлами данных greylistd. Для этого найдём ранее добавленную в `Makefile` строчку:

    SUBST_SED.paths+=       -e 's,/var/run/greylistd/socket,${VARBASE}/run/greylistd.sock,g'

И заменим её на такую строчку:

    SUBST_SED.paths+=       -e 's,/var/run/greylistd/socket,${VARBASE}/db/greylistd/socket,g'

В системе pkgsrc для корректной работы с файлами конфигурации предусмотрена опция `CONF_FILES`. Она позволяет устанавливать файлы конфигурации при установке пакета в соответствующий каталог `etc`, если этих файлов ещё нет, и автоматически удалять не изменившиеся файлы при удалении пакета. К сожалению, нельзя просто указать, какие из устанавливаемых файлов являются файлами конфигурации - возможно только указать путь к примерам файлов конфигурации и к месту их установки. В нашем случае это может выглядеть, например, следующим образом:

    CONF_FILES+=                   ${PREFIX}/share/examples/greylistd/config ${PKG_SYSCONFDIR}/greylistd/config
    CONF_FILES+=                   ${PREFIX}/share/examples/greylistd/whitelist-hosts ${PKG_SYSCONFDIR}/greylistd/whitelist-hosts

Остаётся только положить в каталог `${PREFIX}/share/examples/greylistd/` нужные файлы. Но в нашем случае в этом каталоге уже лежит файл `whitelist-hosts` и он отличается от нужного, т.к. происходит из файла `${WRKSRC}/doc/examples/whitelist-hosts`. Этот файл предназначен для использования с Exim, поэтому переименуем его в `exim4-whitelist-hosts`, добавив в правило `post-extract` действие по переименованию этого файла:

    ${MV} ${WRKSRC}/doc/examples/whitelist-hosts ${WRKSRC}/doc/examples/exim4-whitelist-hosts

Вернёмся к файлу `files/setup.py`, с которого мы начинали сборку пакета, и поменяем место установки файлов конфигруации так, чтобы они устанавливались в каталог с примерами файлов конфигурации:

      data_files=[('bin', ['program/greylist']),
                  ('sbin', ['program/greylistd-setup-exim4',
                            'program/greylistd']),
                  ('share/examples/greylistd', ['doc/examples/exim4-acl-example.txt',
                                                'doc/examples/exim4-whitelist-hosts',
                                                'config/config',
                                                'config/whitelist-hosts']),
                  ('man/man1', ['doc/man1/greylist.1']),
                  ('man/man8', ['doc/man8/greylistd.8',
                                'doc/man8/greylistd-setup-exim4.8']),
                  ]

И добавим ещё одно правило для создания каталога для файлов конфигурации:

    OWN_DIRS_PERMS+=               ${PKG_SYSCONFDIR}/greylistd/ ${GREYLIST_USER} ${GREYLIST_GROUP} 0766

Так как после изменений, внесённых в файлы `Makefile` и `files/setup.py`, изменилось место установки файлов конфигруации, нужно обновить и файл `PLIST`. Для этого снова выполним две команды:

    $ make package
    $ make print-PLIST > PLIST

Внесём ещё одно небольшое изменение. Пакет использует для хранения собственых файлов каталог `${VARBASE}/db/greylistd/`, для размещения файлов конфигруации каталог `${PKG_SYSCONFDIR}/greylistd/`, а для размещения примеров файлов конфигурации - каталог ` ${PREFIX}/share/examples/greylistd/`. Как видно, самый последний подкаталог имеет имя `greylistd`. Гипотетически может произойти так, что появится две несовместимые между собой версии `greylistd`, которые может потребоваться использовать одновременно, как, например, это происходило с различными версиями apache, php-fpm и т.п. Согласен, звучит натянуто, однако чисто теоретически это возможно. В таких случаях принято вместо жёстко прописанного имени использовать переменную `${PKGBASE}`. Заменим в файле `Makefile` все эти каталоги с учётом возможности использования `${PKGBASE}`. Изменить придётся не так много строк:

    SUBST_SED.paths+=              -e 's,/var/lib/greylistd/,${VARBASE}/db/${PKGBASE}/,g'
    SUBST_SED.paths+=              -e 's,/var/run/greylistd/socket,${VARBASE}/db/${PKGBASE}/socket,g'
    CONF_FILES+=                   ${PREFIX}/share/examples/${PKGBASE}/config ${PKG_SYSCONFDIR}/${PKGBASE}/config
    CONF_FILES+=                   ${PREFIX}/share/examples/${PKGBASE}/whitelist-hosts ${PKG_SYSCONFDIR}/${PKGBASE}/whitelist-hosts
    OWN_DIRS_PERMS+=               ${VARBASE}/db/${PKGBASE}/ ${GREYLIST_USER} ${GREYLIST_GROUP} 0766
    OWN_DIRS_PERMS+=               ${PKG_SYSCONFDIR}/${PKGBASE}/ ${GREYLIST_USER} ${GREYLIST_GROUP} 0766

До полноценного пакета для NetBSD не хватает скрипта инициализации, но этот вопрос меня не интересует, т.к. я собираюсь запускать greylistd под управлением daemontools. Возможно в pkgsrc понадобится добавить ещё некоторые доработки, чтобы поменять пути к файлам конфигурации, путь к месту размещения базы данных демона и т.п.

Я добавил получившийся порт для сборки на свой [сборочный сервер](https://stupin.su/wiki/netbsd_sysbuild/), чтобы в дальнейшем готовый пакет можно было установить с помощью pkgin из репозитория.

Использованные материалы
------------------------

* [salsa.debian.org/debian/greylistd/](https://salsa.debian.org/debian/greylistd/) - актуальный git-репозиторий `greylistd`, поддерживаемый разработчиками Debian,
* [github.com/eurovibes/greylistd](https://github.com/eurovibes/greylistd) - устаревшее ответвление git-репозитория `greylistd`,
* [The pkgsrc developer's guide](https://www.netbsd.org/docs/pkgsrc/developers-guide.html) - руководство разработчика pgsrc,
* [Writing the Setup Script](https://docs.python.org/3/distutils/setupscript.html) - написание скрипта `setup.py`.
