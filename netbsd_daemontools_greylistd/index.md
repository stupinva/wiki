Запуск greylistd в NetBSD с помощью daemontools
===============================================

Создаём каталог сервиса `/service/.greylistd/`:

    # mkdir -p /service/.greylistd/

Создадим внутри него файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -f /usr/pkg/etc/greylistd/config ]
    then
            echo "Missing /usr/pkg/etc/greylistd/config"
            exit 1
    fi
    
    exec \
    /usr/pkg/sbin/greylistd

И сделаем его исполняемым:

    # chmod +x /service/.greylistd/run

Создадим каталог `/service/.greylistd/log/`:

    # mkdir /service/.greylistd/log/

Создадим внутри него скрипт run со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/greylistd/

И сделаем его исполняемым:

    # chmod +x /service/.greylistd/log/run

Теперь создадим каталог `/var/log/greylistd`, в котором `multilog` будет вести журналы работы сервиса:

    # mkdir /var/log/greylistd/

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/greylistd/

Запустим сервис средствами daemontools, переименовав каталог сервиса:

    # mv /service/.greylistd /service/greylistd
