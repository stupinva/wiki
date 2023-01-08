Запуск spawn-fcgi и fcgiwrap в NetBSD с помощью daemontools
===========================================================

[[!tag netbsd daemontools fastcgi]]

К сожалению spawn-fcgi умеет порождать несколько процессов только отключаясь от терминала, поэтому через daemontools можно запустить только в однопроцессном режиме. Запустить несколько процессов можно в fcgiwrap, но если так сделать, то эти процессы отделяются от spawn-fcgi и при остановке сервиса останавливается только головной процесс, а остальные продолжают работать в фоне, удерживая сокет-файл. При этом обработка CGI-запросов фактически продолжается, а запустить spawn-fcgi снова не получается, т.к. сокет-файл уже существует и занят процессами, работающими в фоне.

Таким образом, можно запустить только один процесс spawn-fcgi, который заменится одним процессом fcgiwrap. К счастью, в моём случае это не является проблемой, т.к. для обслуживания запросов от ikiwiki, с которой работаю я один, больше одного процесса понадобиться и не может.

Создаём каталог сервиса `/service/.spawnfcgi/`:

    # mkdir /service/.spawnfcgi/

Создадим внутри каталога сервиса файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    exec \
    /usr/pkg/bin/spawn-fcgi -u stupin -g users -s /var/run/ikiwiki.sock -U nginx -G nginx -M 0600 -d /home/stupin/dst/ -n -- \
    /usr/pkg/sbin/fcgiwrap -f

И сделаем его исполняемым:

    # chmod +x /service/.spawnfcgi/run

Создадим каталог `/service/.spawnfcgi/log/`:

    # mkdir /service/.spawnfcgi/log/

Создадим внутри него скрипт `run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/spawnfcgi/

И сделаем его исполняемым:

    # chmod +x /service/.spawnfcgi/log/run

Теперь создадим каталог `/var/log/spawnfcgi`, в котором `multilog` будет вести журналы работы сервиса:

    # mkdir /var/log/spawnfcgi/

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/spawnfcgi/

Запустим сервис средствами `daemontools`, переименовав каталог сервиса:

    # mv /service/.spawnfcgi /service/spawnfcgi
