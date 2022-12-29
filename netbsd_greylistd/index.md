Установка greylistd в NetBSD
============================

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

До полноценного пакета для NetBSD не хватает скрипта инициализации, но этот вопрос меня не интересует, т.к. я собираюсь запускать greylistd под управлением daemontools. Возможно в pkgsrc понадобится добавить ещё некоторые доработки, чтобы поменять пути к файлам конфигурации, путь к месту размещения базы данных демона и т.п.

Я добавил получившийся порт для сборки на свой [сборочный сервер](https://stupin.su/wiki/netbsd_sysbuild/), чтобы в дальнейшем готовый пакет можно было установить с помощью pkgin из репозитория.

Использованные материалы
------------------------

* [salsa.debian.org/debian/greylistd/](https://salsa.debian.org/debian/greylistd/) - актуальный git-репозиторий `greylistd`, поддерживаемый разработчиками Debian,
* [github.com/eurovibes/greylistd](https://github.com/eurovibes/greylistd) - устаревшее ответвление git-репозитория `greylistd`,
* [The pkgsrc developer's guide](https://www.netbsd.org/docs/pkgsrc/developers-guide.html) - руководство разработчика pgsrc,
* [Writing the Setup Script](https://docs.python.org/3/distutils/setupscript.html) - написание скрипта `setup.py`.
