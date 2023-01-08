Запуск nginx в NetBSD с помощью daemontools
===========================================

[[!tag netbsd daemontools nginx]]

Создаём каталог сервиса /service/.nginx/:

    # mkdir -p /service/.nginx/

Создадим внутри каталога сервиса файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -f /usr/pkg/etc/nginx/nginx.conf ]
    then
            echo "Missing /usr/pkg/etc/nginx/nginx.conf"
            exit 1
    fi
    
    exec \
    softlimit -o 2048 \
    /usr/pkg/sbin/nginx -g "daemon off; error_log stderr warn;" -c /usr/pkg/etc/nginx/nginx.conf

И сделаем его исполняемым:

    # chmod +x /service/.nginx/run

Создадим каталог `/service/.nginx/log/`:

    # mkdir /service/.nginx/log/

Создадим внутри него скрипт `run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/nginx/error

И сделаем его исполняемым:

    # chmod +x /service/.nginx/log/run

Теперь создадим каталог `/var/log/nginx`, в котором `multilog` будет вести журналы работы сервиса:

    # mkdir /var/log/nginx/error/

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/nginx/error/

Остановим `nginx`, если он уже запущен с помощью скрипта `/etc/rc.d/nginx`:

    # /etc/rc.d/nginx stop

Запустим сервис:

    # mv /service/.nginx /service/nginx

В такой конфигурации через `multilog` пропускается только журнал ошибок, но хотелось бы через него пропускать ещё и журнал доступа. Для этого в `nginx` настроим запись журналов в именованный канал и настроим ещё один сервис, который назовём `nginx-access`, который будет читать строки из этого канала. Если нужно, например, писать для разных доменов отдельные журналы доступа, таких сервисов можно настроить несколько.

Создаём каталог сервиса `/service/.nginx-access/`:

    # mkdir -p /service/.nginx-access/

Создадим внутри каталога сервиса файл `run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/nginx/access/ < /var/log/nginx/access.pipe

И сделаем его исполняемым:

    # chmod +x /service/.nginx-access/run

Создадим именованный канал, в который nginx будет писать журналы доступа:

    # mkfifo /var/log/nginx/access.pipe

И поменяем его владельца и группу владельца на `nginx`:

    # chown nginx:nginx /var/log/nginx/access.pipe

Теперь создадим каталог `/var/log/nginx/access`, в котором `multilog` будет вести журналы доступа:

    # mkdir /var/log/nginx/access/

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/nginx/access/

Запустим новый сервис:

    # mv /service/.nginx-access /service/nginx-access

Теперь нужно прописать в файле конфигурации `/usr/pkg/etc/nginx/nginx.conf` вместо имени файла журнала имя именованного канала:

    access_log  /var/log/nginx/access.pipe;

Осталось только сообщить `nginx`, чтобы он перечитал свой файл конфигурации и начал писать журнал в новый файл:

    # svc -h /service/nginx
