Настройка Roundcube для использования SQLite
============================================

Установка
---------

Добавляем в файл /etc/apt/sources.list репозиторий с бэкпортами для Wheezy:

    deb http://mirror.ufanet.ru/debian wheezy-backports main contrib non-free

Прописываем общий приоритет для репозитория с бэкпортами в файле /etc/apt/preferences.d/backports:

    Package: *
    Pin: release n=wheezy-backports, origin "mirror.ufanet.ru"
    Pin-Priority: 502
  
    Package: *
    Pin: release n=wheezy-backports, origin "mirror.yandex.ru"
    Pin-Priority: 501

Прописываем приоритеты для нужных нам пакетов из только что добавленного репозитория c бэкпортами в файл /etc/apt/preferences.d/roundcube:

    Package: roundcube-core
    Pin: version 0.9.5-1~bpo70+1
    Pin-Priority: 1003
  
    Package: roundcube
    Pin: version 0.9.5-1~bpo70+1
    Pin-Priority: 1003
  
    Package: roundcube-sqlite3
    Pin: version 0.9.5-1~bpo70+1
    Pin-Priority: 1003
  
    Package: roundcube-plugins
    Pin: version 0.9.5-1~bpo70+1
    Pin-Priority: 1003
  
    Package: roundcube-plugins-extra
    Pin: version 0.9.2-20130819~bpo70+1
    Pin-Priority: 1003

Устанавливаем необходимые пакеты из добавленного репозитория:

    # apt-get install roundcube-core roundcube roundcube-sqlite3 roundcube-plugins roundcube-plugins-extra php5-sqlite

Настройка
---------

Вписываем в файл /etc/roundcube/debian-db.php настройки базы данных:

    $basepath='/etc/roundcube';
    $dbname='roundcube.sqlite';
    $dbtype='sqlite3';

В файле /etc/roundcube/main.inc.php редактируем необходимый для работы минимум настроек:

    $rcmail_config['default_host'] = array("tls://mail.stupin.su:143");
    $rcmail_config['smtp_server'] = 'tls://mail.stupin.su:587';
  
    $rcmail_config['username_domain'] = '%t';
    $rcmail_config['mail_domain'] = '%t';
  
    $rcmail_config['smtp_user'] = '%u';
    $rcmail_config['smtp_pass'] = '%p';
  
    $rcmail_config['force_https'] = true;

Настройка плагинов
------------------

Прописываем в тот же файл использование плагинов:

    $rcmail_config['plugins'] = array('acl', 'dkimstatus', 'sieverules');
  
Вписываем настройки плагина sieverules в файл /etc/roundcube/plugins/sieverules/config.inc.php:

    $rcmail_config['sieverules_host'] = 'mail.stupin.su';
    $rcmail_config['sieverules_port'] = 4190;
    $rcmail_config['sieverules_usetls'] = TRUE;

Настройка php5-fpm
------------------

Если ещё не настроен php5-fpm, то можно воспользоваться имеющимся пулом, а можно создать новый в файле /etc/php5/fpm/pool.d/roundcube.conf. Поскольку для roundcube нужны несколько специфичных настроек, это как раз пригодиться. Я настраиваю пул, процессы которого будут запускаться только при необходимости:

    [roundcube]
    user = www-data
    group = www-data
    listen = /var/run/roundcube.sock
  
    listen.owner = www-data
    listen.group = www-data
    listen.mode = 0660
  
    pm = ondemand
    pm.max_children = 2
    pm.process_idle_timeout = 10m;
  
    access.log = /var/log/roundcube.access.log
  
    php_value[upload_max_filesize] = 30M
    php_value[post_max_size] = 6M
    php_value[mbstring.func_overload] = 0

Попросим php5-fpm перечитать конфигурацию:

    # /etc/init.d/php5-fpm reload

Настройка nginx
---------------

Теперь можно настроить nginx. Для этого создадим отдельный файл /etc/nginx/sites-available/mail:

    server {
      listen 80;
      listen 443 ssl;
  
      ssl_certificate /etc/ssl/mail.stupin.su.pem;
      ssl_certificate_key /etc/ssl/mail.stupin.su.pem;
  
      server_name mail.stupin.su mail.mailover.ru mail.hostever.ru;
  
      # Roundcube
  
      root /var/lib/roundcube;
      index index.php;
  
      location /program/js/tiny_mce {
        alias /usr/share/tinymce/www;
      }
  
      location /favicon.ico {
        alias /usr/share/roundcube/skins/default/images/favicon.ico;
      }
  
      location /config {
        deny all;
      }
  
      location /temp {
        deny all;
      }
  
      location /logs {
        deny all;
      }
  
      location ~ \.php$ {
        fastcgi_pass unix:/var/run/roundcube.sock;
        fastcgi_index index.php;
  
        include fastcgi_params;
      }
    }

И включим использование этого файла при помощи следующих команд:

    # cd /etc/nginx/sites-enabled/
    # ln -l /etc/nginx/sites-available/mail .

Осталось попросить nginx перечитать конфигурацию:

    # /etc/init.d/nginx reload

Решение проблем после обновления до Debian Buster с PHP-7.3
-----------------------------------------------------------

Открывалась пустая страница, в журналах была ошибка 500. Доустановил недостающие пакеты:

    # apt-get install php7.3-imap php7.3-sqlite3 php7.3-mbstring php7.3-xml 
