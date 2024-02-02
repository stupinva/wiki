Делаем pkgsrc для сервера Minecraft
===================================

[[!tag pkgsrc minecraft]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Скачивание jar
--------------

Скачать сервер Minecraft можно на официальном сайте: [www.minecraft.net](https://www.minecraft.net). Внизу сайта нужно найти ссылку [Загрузить](https://www.minecraft.net/ru-ru/download). На странице [Серверное ПО - Сервер Java Edition](https://www.minecraft.net/download/server) находим и копируем ссылку [Загрузи minecraft_server..jar](https://piston-data.mojang.com/v1/objects/8dd1a28015f51b1803213892b50b7b4fc76e594d/server.jar).

Создание заготовки pkgsrc
-------------------------

Создадим каталог нового pkgsrc в имеющемся дереве:

    $ cd /usr/pkgsrc/games
    $ mkdir minecraft-server
    $ cd minecraft-server

Сгенерируем заготовку pkgsrc из ссылки:

    $ url2pkg https://piston-data.mojang.com/v1/objects/8dd1a28015f51b1803213892b50b7b4fc76e594d/server.jar

В текущем каталоге открываем на редактирование файл `DESCR` и вписываем в него краткое описание сервера Minecraft, взятое из статьи Wikipedia, найденной через поисковый сервис по тексту "minecraft server":

>A Minecraft server is a player-owned or business-owned multiplayer game server for the 2009 Mojang Studios video game Minecraft. In this context, the term "server" often colloquially refers to a network of connected servers, rather than a single machine.

Открываем файл `Makefile` и вводим описание будущего пакета:

    MAINTAINER=     vladimir@stupin.su
    HOMEPAGE=       https://minecraft.fandom.com/wiki/Server
    COMMENT=        A multiplayer game server for video game Minecraft
    LICENSE=        eula

В качестве домашней страницы программы я указал wiki-страницу сервера на сайте фанатов игры Minecraft, т.к. не нашёл официальной страницы с подробной документацией. В качестве лицензии указал eula, хотя такой лицензии нет среди списка типовых лицензий pkgsrc.

Коррекция скачивания
--------------------

Затем я откорректировал имя пакета, имя архива с исходными текстами, в роли которого в данном случае выступает скомпилированный архив с расширением `jar`, ссылку на скачивание этого архива:

    PKGNAME=                minecraft-server-1.20.4
    CATEGORIES=             games
    DISTFILE_TAG=           8dd1a28015f51b1803213892b50b7b4fc76e594d
    DISTNAME=               ${PKGNAME}-${DISTFILE_TAG}
    EXTRACT_SUFX=           .jar
    MASTER_SITES=           -https://piston-data.mojang.com/v1/objects/${DISTFILE_TAG}/server.jar

Хэш, кодирующий версию архива, я вынес в отдельную переменную для того, чтобы не указывать её в ссылке на скачивание архива и в имени скачанного архива.

После того, как имя архива изменилось с `server.jar` на `minecraft-server.jar`, нужно обновить имя этого файла и его контрольную сумму в файле `distinfo`. Для этого выполним соответствующую команду:

    $ make distinfo

Зависимость от Java
-------------------

Добавляем в `Makefile` фреймворк для обработки Java-приложений перед последней строчкой:

    .include "../../mk/java-vm.mk"

И отмечаем в `Makefile`, что Java требуется только для запуска пакета, а не для его запуска:

    USE_JAVA=               run

Отмечаем, что требуется Java не ниже версии 17:

    USE_JAVA2=              17

Благодаря этой строчке в зависимости пакета пропишется пакет с Java Runtime Environment. Если вместо ключевого слова `run` указать `yes`, то в сборочные зависимости пакета пропишется пакет с Java Development Kit.

Сборка
------

Поскольку собирать из исходных текстов ничего не нужно, то файл с расширением `jar` можно сразу установить в систему. На этапе, соответствующем сборке двоичных файлов из архива с исходными текстами, я выполню переименование файла с расширением `jar`. Для этого я поместил в `Makefile` такие строки:

    do-build:
            ${MV} ${WRKSRC}/${DISTNAME}${EXTRACT_SUFX} ${WRKSRC}/${PKGBASE}${EXTRACT_SUFX}

Создаём подкаталог `files` и помещаем в него файл `LICENSE` с текстом, взятым по ссылке [eula](https://www.minecraft.net/en-us/eula).

Установка
---------

Теперь нам остаётся только переместить двоичный файл с расширением `jar` и текст лицензии в соответствующие каталоги. Для этого я добавил в `Makefile` переменную со списокм каталогов, в которые будет выполняться установка файлов:

    INSTALLATION_DIRS=      share/doc/${PKGBASE} lib/${PKGBASE}

И добавил в `Makefile` правило установки файлов пакета в систему:

    do-install:
            ${INSTALL_DATA} ${FILESDIR}/LICENSE ${DESTDIR}${PREFIX}/share/doc/${PKGBASE}/
            ${INSTALL_LIB} ${WRKSRC}/${PKGBASE}${EXTRACT_SUFX} ${DESTDIR}${PREFIX}/lib/${PKGBASE}/

Сборка пакета
-------------

Попробуем собрать пакет:

    $ make package

Поскольку файл `PLIST` ещё пуст, предыдущая команда сообщит о несоответствии файлов, полученных в результате сборки, списку файлов, указанных в файле `PLIST`. Исправим файл `PLIST`, внеся в него актуальный список файлов:

    $ make print-PLIST > PLIST

Теперь можно ещё раз попробовать собрать пакет:

    $ make package

Использованные материалы
------------------------

* [The pkgsrc guide / Part II. The pkgsrc developer's guide](https://www.netbsd.org/docs/pkgsrc/developers-guide.html)
* [NetBSD can also run a Minecraft server](https://rubenerd.com/netbsd-can-also-run-a-minecraft-server/)
