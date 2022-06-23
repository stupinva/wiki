Сборка и использование декомпилятора pyc-файлов
===============================================

[[!tag python]]

Сборка deb-пакета
-----------------

Для сборки декомпилятора понадобятся пакеты `git`, `gc++`, `cmake` и `make`. Для сборки deb-пакета в изолированном окружении нам также понадоятся пакеты `fakeroot` и `checkinstall`. Установим их:

    # apt-get install git g++ cmake make

Склонируем git-репозиторий с исходными текстами утилиты `pycdc`:

    $ git clone https://github.com/zrax/pycdc

Переходим в каталог с исходными текстами и выполняем генерацию файла `Makefile`:

    $ cd pycdc
    $ cmake CMakeLists.txt

Создадим описание будущего deb-пакета:

    $ echo -n "C++ python bytecode disassembler and decompiler " > description-pak

В git-репозитории нет ни веток, ни меток, по которым можно было бы определить версию программы. В качестве версии используем отметку времени последней фиксации в git-репозитории, которую просмотрим с помощью следующей команды:

    $ git log

Выполняем сборку deb-пакета, подставив в опцию `--pkgversion` отметку времени последней фиксации в репозитории git:

    $ fakeroot checkinstall --pkgname=pycdc --pkgversion=20220616094500 --pkgrelease=debian-buster-1 --maintainer=vladimir@stupin.su --pkglicense=GPL-3.0 --requires='libstdc++6, libgcc-s1, libc6' -y -D --install=no --fstrans=yes make install

В текущем каталоге появится пакет [[pycdc_20220616094500-debian-buster-1_amd64.deb]].

Установка пакета
----------------

Для установки пакета в систему воспользуемся следующей командой:

    # dpkg -i pycdc_20220616094500-debian-buster-1_amd64.deb

Использование декомпилятора
---------------------------

Для примера попробуем декомпилировать такой файл:

    $ cat __init__.py
    try:
        from .local import *
    except ImportError:
        from .base import *

Запускаем команду для декомпиляции pyc-файла и получаем практически идентичный результат:

    $ pycdc __init__.pyc 
    # Source Generated with Decompyle++
    # File: __init__.pyc (Python 2.7)
    
    
    try:
        from local import *
    except ImportError:
        from base import *
    
