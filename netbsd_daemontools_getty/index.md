Запуск getty в NetBSD с помощью daemontools
===========================================

[[!tag netbsd daemontools sinit]]

Содержание
----------

[[!toc levels=4 startlevel=2]]

Введение
--------

В NetBSD терминалы запускаются не при помощи rc-скриптов, а самим демоном `init`, который руководствуется списком терминалов из файла `/etc/ttys`. Первым делом заглянем в файл `/etc/ttys` и посмотрим, какие терминалы включены по умолчанию:

    console "/usr/libexec/getty Pc"         wsvt25  off secure
    constty "/usr/libexec/getty Pc"         wsvt25  on  secure
    ttyE0   "/usr/libexec/getty Pc"         wsvt25  off secure
    ttyE1   "/usr/libexec/getty Pc"         wsvt25  on  secure
    ttyE2   "/usr/libexec/getty Pc"         wsvt25  on  secure
    ttyE3   "/usr/libexec/getty Pc"         wsvt25  on  secure
    ...

В четвёртой колонке находится переключатель, позволяющий включить или отключить указанный терминал. Если в колонке указан текст `on`, то `init` будет запускать соответствующий терминал, а в случае текста `off` терминал запускаться не будет.

Существует концепция минимального демона инициализации, выдвинутая автором библиотеки musl libc Ричем Фелькером (Rich Felker), согласно которой минимальный процесс init должен лишь вызывать при запуске скрипт `/etc/rc.init`, усыновлять осиротевшие процессы и вызывать скрипт `/etc/rc.shutdown` при получении соответствующих сигналов. Эта концепция была воплощена в демоне `sinit`, исходные тексты которого распространяются проектом [suckless.org](https://suckless.org), через репозиторий [git://git.suckless.org/sinit](https://git.suckless.org/sinit/files.html).

После настройки запуска консолей с помощью `daemontools` становится возможным заменить `init` из NetBSD на `sinit` и получить операционную систему с простой и надёжной системой инициализации.

Ручная настройка сервиса
------------------------

Создадим скрытый подкаталог, соответствующий имени консоли из первой колонки файла `/etc/ttys`, в каталоге `/service/`:

    # mkdir /service/.constty/

Создадим внутри каталога сервиса файл `run` со следующим содержимым::

    #!/bin/sh
    
    exec 2>&1
    
    echo "Setting tty flags."
    /sbin/ttyflags /dev/constty
    
    exec \
    /usr/libexec/getty Pc constty

И сделаем его исполняемым:

    # chmod +x /service/.constty/run

Создадим каталог `/service/.constty/log/`:

    # mkdir /service/.constty/log/

Создадим внутри него скрипт `run` со следующим содержимым::

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/constty/

И сделаем его исполняемым:

    # chmod +x /service/.constty/log/run

Теперь создадим каталог `/var/log/constty`, в котором `multilog` будет вести журналы работы сервиса::

    # mkdir /var/log/constty/

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/constty/

Отключим запуск `getty` для `constty`, поменяв переключатель `on` на `off` в четвёртой колонке строчки, соответствующей терминалу `constty` в файле `/etc/ttys`. Далее нужно найти с помощью команды `ps` процесс `getty`, связанный с этим терминалом, и завершить его при помощи команды `kill`, после чего можно запустить `getty`:

    # mv /service/.constty /service/constty

Скрипт для настройки сервисов
-----------------------------

Поскольку в NetBSD по умолчанию настроено четыре терминала, а мне предстояло перенастроить термианлы почти на десятке систем, то ручная перенастройка заняла бы сликом много времени. Я решил автоматизировать процесс перенастройки и написал скрипт для настройки терминалов:

    #!/bin/sh
    
    install_getty() {
            SERVICE="$1"
            DEVICE="$2"
    
            mkdir -p /service/$SERVICE/log/
    
            cat > /service/$SERVICE/run <<END
    #!/bin/sh
    
    exec 2>&1
    
    echo "Setting tty flags."
    /sbin/ttyflags /dev/$DEVICE
    
    exec \\
    /usr/libexec/getty Pc $DEVICE
    END
    
            cat > /service/$SERVICE/log/run <<END
    #!/bin/sh
    
    exec \\
    setuidgid multilog \\
    multilog t /var/log/$SERVICE/
    END
    
            chmod +x /service/$SERVICE/run
            chmod +x /service/$SERVICE/log/run
            mkdir -p /var/log/$SERVICE/
            chown multilog:multilog /var/log/$SERVICE/
    
            awk -v DEVICE="$DEVICE" '
                    {
                            if ($1 == DEVICE) {
                                    match($0, /[\t ]on[\t ]/);
                                    print substr($0, 1, RSTART) "off" substr($0, RSTART + 3, RSTART + RLENGTH - 1);
                            } else {
                                    print $0;
                            }
                    }' /etc/ttys > /etc/ttys.new && \
            cat /etc/ttys.new > /etc/ttys && \
            rm /etc/ttys.new
    }
    
    install_getty constty constty
    install_getty ttyE1 ttyE1
    install_getty ttyE2 ttyE2
    install_getty ttyE3 ttyE3

Остаётся только запустить этот скрипт на каждой из систем и завершить работу всех уже запущенных процессов `getty`.
