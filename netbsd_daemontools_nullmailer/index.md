Запуск nullmailer в NetBSD с помощью daemontools
================================================

В этой статье предполагается, что в системе NetBSD уже установлен и настроен `nullmailer`, который запускается с помощью скрипта `/etc/rc.d/nullmailer`. Подробнее о настройке `nullmailer` в NetBSD можно почитать в статье [[Настройка nullmailer в NetBSD|netbsd_nullmailer]].

Также в этой статье предполагается, что в системе уже установлен и настроен пакет `daemontools`. Установка и настройка пакета описана в главе [[Установка daemontools|netbsd_daemontools_gitea#daemontools]] статьи [[Запуск Gitea в NetBSD с помощью daemontools|netbsd_daemontools_gitea]].

Создаём каталог сервиса `/service/.nullmailer`:

    # mkdir -p /service/.nullmailer/

Создадим внутри него файл run со следующим содержимым:

    #!/bin/sh
    
    exec 2>&1
    
    if [ ! -f /usr/pkg/etc/nullmailer/remotes ]
    then
            echo "Missing /usr/pkg/etc/nullmailer/remotes"
            exit 1
    fi
    
    if [ ! -d /var/spool/nullmailer/queue ]
    then
            echo "No /var/spool/nullmailer/queue"
            exit 2
    fi
    
    if [ ! -d /var/spool/nullmailer/tmp ]
    then
            echo "No /var/spool/nullmailer/tmp"
            exit 3
    fi
    
    exec \
    setuidgid nullmail \
    /usr/pkg/libexec/nullmailer/nullmailer-send

И сделаем его исполняемым:

    # chmod +x /service/.nullmailer/run

Создадим каталог `/service/.nullmailer/log/`:

    # mkdir /service/.nullmailer/log/

Создадим внутри него скрипт `run` со следующим содержимым:

    #!/bin/sh
    
    exec \
    setuidgid multilog \
    multilog t /var/log/nullmailer/

И сделаем его исполняемым:

    # chmod +x /service/.nullmailer/log/run

Теперь создадим каталог `/var/log/nullmailer`, в котором `multilog` будет вести журналы работы сервиса:

    # mkdir /var/log/nullmailer/

Установим пользователя и группу `multilog` владельцами этого каталога:

    # chown multilog:multilog /var/log/nullmailer/

Остановим `nullmailer`, запущенный с помощью скрипта `/etc/rc.d/nullmailer`:

    # /etc/rc.d/nullmailer stop

Запустим сервис средствами `daemontools`, переименовав каталог сервиса:

    # mv /service/.nullmailer /service/nullmailer

Для совместимости с родной системной инициализации NetBSD можно поступить так, как описано в главе [[Совместимость с rc|netbsd_daemontools_gitea#rc]] статьи [[Запуск Gitea в NetBSD с помощью daemontools|netbsd_daemontools_gitea]], то есть создать символическую ссылку на описанный в этой главе скрипт `/etc/rc.daemontools`:

    # ln -s /etc/rc.daemontools /etc/rc.d/nullmailer
