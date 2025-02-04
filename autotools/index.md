Использование autotools
=======================

[[!tag c autotools autoscan aclocal autoconf automake configure.ac Makefile.am]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Подготовка заготовки configure.ac
---------------------------------

Первым делом запускаем в каталоге с файлами проекта утилиту `autoscan`:

    $ autoscan

По завершении её работы в текущем каталоге должен появиться файл `configure.auto`. Переименуем его в `configure.ac`:

    $ mv configure.auto configure.ac

Откроем файл `configure.ac` в текстовом редакторе и внесём информацию о проекте, отредактировав строчку `AC_INIT`:

    AC_INIT([view3d], [1.2-sdl2], [vladimir@stupin.su])

Где:

* `view3d` - название проекта,
* `1.2-sdl2` - версия программы,
* `vladimir@stupin.su` - адрес электронной почты сопровождающего проект/программу.

Если в проекте есть отдельный заголовочный файл, в который вынесены все опции для настройки проекта, то имя этого файла нужно вписать в макрос `AC_CONFIG_HEADER`:

    AC_CONFIG_HEADER([config.h])

Если же такого файла нет, то этот макрос нужно удалить.

В макросе `AC_CONFIG_SRCDIR` нужно указать имя главного файла, из которого система сборки `autotools` рекурсивно извлечёт все используемые заголовочные файлы:

    AC_CONFIG_SRCDIR([main.c])

Система сборки `autotools` предназначена прежде всего для сборки программ проекта GNU. У проекта GNU имеется собственный набор стандартных файлов, которые должны быть в каталоге с проектом. Для сборки других программ, не соответствующих стандартам проекта GNU, нужно добавить в макрос `AM_INIT_AUTOMAKE` опцию `foreign`:

    AM_INIT_AUTOMAKE([foreign])

Для того, чтобы в процессе компиляции программы выводились разнообразные сообщения об ошибках, которые помогают выявлять допустимые, но подозрительные, фрагменты кода, я добавляю в макрос `AM_INIT_AUTOMAKE` дополнительные опции:

    AM_INIT_AUTOMAKE([foreign -Wportability -Wall -Werror -Wsyntax])

Подготовка файла Makefile.am
----------------------------

Теперь создадим шаблон для генерации файла `Makefile`. Для начала нужно вернуться к файлу `configure.ac` и добавить в него макрос для формирования файла `Makefile` из будущего файла `Makefile.am`, который мы собираемся создать:

    AC_CONFIG_FILES([Makefile])

Теперь можно приступать непосредственно к созданию файла `Makefile.am`.

### Сборка двоичных файлов

В простейшем случае можно ограничиться двумя строчками:

    bin_PROGRAMS = view3d
    view3d_SOURCES = vmdl.cpp idpo.cpp events.cpp main.cpp

В переменной `bin_PROGRAMS` перечисляются имена выполняемых файлов, которые должны получиться в итоге сборки.

Для каждого исполняемого файла указывается по одной переменной вида `<имя>_SOURCES`, в которой перечисляются все файлы исходных текстов, необходимых для сборки этой программы.

Аналогичным образом при помощи переменной `sbin_PROGRAMS` можно собирать исполняемый файлы для помещения в каталог `sbin`.

### Опции компиляции

Для того, чтобы компилировать двоичный файл с другими опциями, то для каждого из двоичных файлов опции компиляции можно настроить с помощью переменной вида `<имя>_CFLAGS`. Например, в примере ниже одна и та же программа собирается дважды, причём вторая компилируется с опцией компилятора `-DLITE`, а при её сборке не используется файл `master.c`:

    sbin_PROGRAMS = parled12 parled12lite
    
    parled12_SOURCES = client.c daemon.c main.c parport.c server.c config.c evloop.c master.c parports.c slave.c
    
    parled12lite_SOURCES = client.c daemon.c main.c parport.c server.c config.c evloop.c parports.c slave.c
    parled12lite_CFLAGS = -DLITE

### Тесты

Если в программе имеются тесты, то их сборку можно настроить способом, аналогичным сборке исполняемых файлов:

    check_PROGRAMS = test
    test_SOURCES = bin.c test.c
    TESTS = $(check_PROGRAMS)

В переменной `check_PROGRAMS` перечисляются имена выполняемых файлов, которые должны получиться в итоге сборки тестовых программ.

Для каждого исполняемого файла указывается по одной переменной вида `<имя>_SOURCES`, в которой перечисляются все файлы исходных текстов, необходимых для сборки этой программы.

При успешном прохождении теста программа должна завершаться с нулевым кодом возврата.

В переменной `TESTS` перечисляются все программы, которые нужно вызвать для тестирования проекта.

В дальнейшем запустить все тесты можно будет с помощью команды следующего вида:

    $ make check

По окончании тестирования итоги будут сведены в таблицу следующего вида:

    make  check-TESTS
    make[1]: вход в каталог «/home/stupin/old/git/pup»
    make[2]: вход в каталог «/home/stupin/old/git/pup»
    PASS: test
    ============================================================================
    Testsuite summary for pup 1.0
    ============================================================================
    # TOTAL: 1
    # PASS:  1
    # SKIP:  0
    # XFAIL: 0
    # FAIL:  0
    # XPASS: 0
    # ERROR: 0
    ============================================================================
    make[2]: выход из каталога «/home/stupin/old/git/pup»
    make[1]: выход из каталога «/home/stupin/old/git/pup»

### Документация

Если в проекте есть дополнительные файлы с документацией, которую нужно установить в систему (или поместить в двоичный пакет) вместе с собранными двоичными файлами, то их можно можно перечислить в переменной `dist_doc_DATA`:

    dist_doc_DATA = README.md ideas.txt

Учёт зависимостей
-----------------

Для сборки большинства программ требуются дополнительные библиотеки. Перед сборкой программы нужно её скомпилировать, а это не получится сделать, если в системе нет заголовочных файлов этих библиотек. Для проверки наличия в системе необходимых заголовочных файлов предназначен макрос `AC_CHECK_HEADERS`:

    AC_CHECK_HEADERS([fcntl.h limits.h stdlib.h string.h sys/file.h sys/ioctl.h sys/socket.h syslog.h unistd.h])

Для получения полного списка используемых проектом системных и сторонних заголовочных файлов я пользуюсь командами следующего вида:

    $ egrep -h '^#include\s+<' *.h *.c | sort -u

Для поиска библиотек используются макрос `AC_CHECK_LIB`, первым аргументом которого является имя библиотеки, а вторым аргументом - необходимые функции:

    AC_CHECK_LIB([z], [compress2, uncompress])
    AC_CHECK_LIB([m], [sqrt])
    AC_CHECK_LIB([SDL2], [SDL_CreateWindow, SDL_GetError, SDL_GL_CreateContext, SDL_GL_MakeCurrent, SDL_GL_SetAttribute, SDL_GL_SwapWindow, SDL_Init, SDL_PollEvent, SDL_Quit])
    AC_CHECK_LIB([GL], [glClear, glClearDepth, glColor3f, glDepthFunc, glDisable, glEnable, glFinish, glFrustum, glHint, glLightf, glLightfv, glLoadIdentity, glLoadMatrixf, glMat    rixMode, glPolygonMode, glRotatef, glShadeModel, glTexEnvf, glTexParameterf, glTranslatef])

Обратите внимание, что в отличие от других макросов, в этом макросе список функций перечисляется не через пробел, а через запятую!

Генерация файлов configure и Make
---------------------------------

Теперь, когда мы подготовили файлы `configure.ac` и `Makefile.am`, можно приступить к автоматической генерации файлов `configure` и `Makefile`, с помощью которых можно будет настроить и собрать проект.

Сначала вызываем команду `aclocal`, которая создаст файл `aclocal.m4` необходимый для дальнейших действий:

    $ aclocal

Теперь вызываем команду `autoconf`, которая создаст нужный нам файл `configure`:

    $ autoconf

Далее вызываем команду `automake`, которая создаст нужный нам файл `Makefile` для утилиты GNU Make:

    $ automake --add-missing

Опция `--add-missing` создаёт в каталоге с проектом дополнительные файлы, необходимые для обработки `Makefile`.

Сборка проекта
--------------

Теперь у нас имеются файлы `configure` и `Makefile`. Первый файл - это сценарий оболочки, который собирает информацию о системе, в которой выполняется сборка проекта: проверяет наличие необходимых для сборки компилятора, компоновщика, заголовочных файлов, библиотек, функций, определений типов данных, формирует опции для вызова обнаруженных в системе компилятора и сборщика и т.п. Второй файл содержит список возможных целей сборки, информацию о зависимостях между ними и команды преобразования файлов исходных текстов в двоичные объектные файлы.

Вызовем скрипт настройки:

    $ ./configure

Для компиляции и сборки двоичных файлов вызовем GNU Make:

    $ make

Для тестирования можно вызвать GNU Make с целью `check`:

    $ make check

Для сборки архива с исходными текстами и всеми файлами, необходимыми для сборки проекта, можно вызвать GNU Make с целью `dist`:

    $ make dist

Архив должен сформироваться в текущем каталоге.

Использованные материалы
------------------------

* [Использование GNU Autotools. Создание своего скрипта configure и файла Makefile](https://help.ubuntu.ru/wiki/using_gnu_autotools)

Дополнительные материалы
------------------------

* [Autoconf](https://www.gnu.org/savannah-checkouts/gnu/autoconf/manual/autoconf-2.71/html_node/index.html)
* [Automake](https://www.gnu.org/software/automake/manual/html_node/index.html)
* [Diego Elio “Flameeyes” Pettenò. Autotools Mythbuster](https://autotools.info/)
