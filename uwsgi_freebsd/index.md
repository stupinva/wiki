uWSGI под FreeBSD
=================

Установим uwsgi из порта www/uwsgi:

    # cd /usr/ports/www/uwsgi
    # make install

В файле /etc/rc.conf прописываем пару строчек:

    uwsgi_enable="YES"
    uwsgi_flags="--ini /usr/local/etc/uwsgi.ini"

Создадим файл /usr/local/etc/uwsgi.ini с настройками запуска Django-приложения:

    [uwsgi]
    
    procname = uwsgi-tok
    procname-master = uwsgi-tok-master
    
    chdir = /usr/local/www/tok
    module = wsgi:application
    #plugin = python27
    master = true
    processes = 2

Добавим секцию в файл конфигурации /usr/local/etc/nginx/nginx.conf:

    location /tok/ {
      uwsgi_pass unix:/tmp/uwsgi.sock;
      uwsgi_modifier1 30;
      include uwsgi_params;
      uwsgi_param SCRIPT_NAME /tok;
    }
    
    location /tok/static/ {
      alias /usr/local/www/tok/static/;
    }

Запустим uwsgi и применим изменения в конфигурации nginx:

    # /usr/local/etc/rc.d/uwsgi start
    # /usr/local/etc/rc.d/nginx reload

Ошибки и отладочные сообщения можно увидеть в журнале /var/log/uwsgi.log

При перезапуске uwsgi в журнале /var/log/uwsgi.log могут возникать ошибки следующего вида:

    lock engine: ipcsem
    semget(): No space left on device [core/lock.c line 507]
    semctl(): Invalid argument [core/lock.c line 602]

Для их исправления можно воспользоваться рекомендациями по ссылке [python uwsgi semget(): No space left on device](http://forum.lissyara.su/viewtopic.php?t=36308).

Чтобы исправить ошибку без перезагрузки, нужно выполнить такую команду, которая удалит все семафоры, принадлежащие пользователю www:

    # ipcs -s | awk '$5 == "www" {print $2}' | xargs -n1 ipcrm -s

Но при перезапуске демона uwsgi проблема может повториться. Чтобы проблема больше не проявлялась, пропишем в файл /etc/loader.conf следующие строки:

    # For uwsgi
    # Number of semaphore identifiers
    kern.ipc.semmni=64
    # Maximum number of semaphores in the system
    kern.ipc.semmns=128
    # Maximum number of undo structures in the system
    kern.ipc.semmnu=128

Чтобы настройки вступили в силу, нужно перезагрузить систему.
