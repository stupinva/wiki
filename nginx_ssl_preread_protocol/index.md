Реми Ван Элст. nginx 1.15.2, ssl_preread_protocol, совмещение HTTPS и SSH на одном порту
========================================================================================

[[!tag nginx ssl tls ssh]]

Это перевод статьи: [Remy van Elst. nginx 1.15.2, ssl_preread_protocol, multiplex HTTPS and SSH on the same port](https://raymii.org/s/tutorials/nginx_1.15.2_ssl_preread_protocol_multiplex_https_and_ssh_on_the_same_port.html).

Содержание
----------

[[!toc startlevel=2 levesl=4]]

Введение
--------

В блоге NGINX недавно была [хорошая статья о новой возможности NGINX 1.15.2 - предварительном чтении протокола SSL](http://web.archive.org/web/20180806131633/https://www.nginx.com/blog/running-non-ssl-protocols-over-ssl-port-nginx-1-15-2/). Она позволяет совмещать HTTPS и другие протоколы SSL на одном порту или, по утверждениям в блоге, "различать SSL/TLS и другие протоколы при перенаправлении трафика через TCP-прокси (stream)". Этим можно воспользоваться для запуска SSH и HTTPS на одном порту (или любого другого протокола SSL вместо HTTPS). Запустив SSH и HTTPS на одном порту, можно обойти ограничения фаервола. Если сеанс выглядит как HTTPS, nginx обработает его, а если выглядит как что-то другое, он перенаправит его в другую программу. Раньше я пользовался для этого [SSLH](https://github.com/yrutschle/sslh), но теперь можно воспользоваться веб-сервером nginx.

Нужно воспользоваться NGINX в режиме прокси. Это означает, что nginx будет действовать как балнсировщик нагруки или прокси-сервер перед приложением (таким как Django, Rails и т.п.).

- Обновление от 12-01-2020: добавлена команда apt-key add. Добавлен пример настройки SSH и HTTPS на одном сервере.

Установка последней версии NGINX
--------------------------------

nginx предоставляет [репозитории](http://nginx.org/en/linux_packages.html#mainline) для дистрибутивов CentOS, Debian/Ubuntu и SUSE. В этом примере используется Ubuntu.

Скачайте ключ для проверки цифровой подписи:

    wget http://nginx.org/keys/nginx_signing.key

Добавьте ключ в доверенные:

    apt-key add nginx_signing.key

Добавьте репозиторий:

    echo "deb http://nginx.org/packages/mainline/ubuntu/ bionic nginx" > /etc/apt/sources.list.d/nginx.list
    echo "deb-src http://nginx.org/packages/mainline/ubuntu/ bionic nginx" >> /etc/apt/sources.list.d/nginx.list

Замените bionic на используемую версию Ubuntu (для определения версии воспользуйтесь командой `lsb_release -a`).

Установите nginx из только что добавленного репозитория:

    apt-get update
    apt-get install nginx

Настройка nginx для предварительного чтения протокола SSL
---------------------------------------------------------

Согласно [блогу nginx](http://web.archive.org/web/20180806131633/https://www.nginx.com/blog/running-non-ssl-protocols-over-ssl-port-nginx-1-15-2/):

Следующий шаблон конфигурации использует переменную `$ssl_preread_protocol` в блоке `map` для назначения значения переменной `$upstream`, которое используется в качестве имени группы `upstream`, соответствующей протоколу, подходящему для подключения. Директива `proxy_pass` передаёт запрос в выбранную группу `upstream`. Отметим, что для работы переменной `$ssl_preread_protocol` необходимо вставить директиву `ssl_preread on` в блок `server`.

Указанный ниже фрагмент конфигурации нужно поместить в корень конфигурации nginx, а не в блок server.

    stream {
        upstream ssh {
            server 192.0.2.10:22;
        }
        
        upstream https {
            server 192.0.2.20:443;
        }
        
        map $ssl_preread_protocol $upstream {
            default ssh;
            "TLSv1.3" https;
            "TLSv1.2" https;
            "TLSv1.1" https;
            "TLSv1.0" https;
        }
        
        # SSH и SSL на одном порту
        server {
            listen 443;
            proxy_pass $upstream;
            ssl_preread on;
        }
    }

В приведённой конфигурации, если обнаружен протокол TLSv1.2, считается что это трафик HTTPS, который направляется на сервер HTTPS (`192.0.2.20`). В противном случае трафик направляется на узел SSH (`192.0.2.10`).

SSH и HTTPS на одном сервере

Если нужно разделить SSH и HTTPS на одном сервере, конфигурация будет немного другой. Сначала нужно убедиться в отсутствии веб-сайтов, ожидающих подключений на порту 443, потому что nginx будет использовать этот порт для проксирования.

Ни один другой сайт в nginx не должен использовать порт 443. Поменяйте блоки `listen` для использования, например, порта 8443:

    listen [::]:8443 http2;
    listen 8443 http2;

Конфигурацию для SSH/SSL нужно поместить не в директиву server, а в корень конфигурации nginx:

    stream {
        upstream ssh {
            server 127.0.0.1:22;
        }
        
        upstream https {
            server 127.0.0.1:8443;
        }
        
        map $ssl_preread_protocol $upstream {
            default ssh;
            "TLSv1.2" https;
            "TLSv1.3" https;
            "TLSv1.1" https;
            "TLSv1.0" https;
        }
        
        # SSH и SSL на одном порту
        server {
            listen 443;
            proxy_pass $upstream;
            ssl_preread on;
        }
    }

Другие прелести ssl_preread
---------------------------

Модуль `ssl_preread` умеет определять не только протокол. Также поддерживается определение имени сервера SNI, что позволяет прокси направлять трафик к разным серверам на основании запрошенного имени узла SSL. [Процитирую документацию](http://web.archive.org/web/20180806133249/https://nginx.org/en/docs/stream/ngx_stream_ssl_preread_module.html):

    map $ssl_preread_server_name $name {
        backend.example.com backend;
        default backend2;
    }
    
    upstream backend {
        server 192.168.0.1:12345;
        server 192.168.0.2:12345;
    }
    
    upstream backend2 {
        server 192.168.0.3:12345;
        server 192.168.0.4:12345;
    }
    server {
        listen 12346;
        proxy_pass $name;
        ssl_preread on;
    }

Учтите, что здесь необходима версия nginx новее, чем распространяемая по умолчанию с выпусками Ubuntu 16.04 или 18.04.
