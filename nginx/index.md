Настройка nginx
===============

Cacti
-----

Из каталога /cacti/:

    location /cacti/ {
      alias /usr/share/cacti/site/;
      index index.php;
    }
  
    location ~ ^/cacti/.+\.php$ {
      root /usr/share/cacti/site/;
        
      include fastcgi.conf;
        
      fastcgi_pass unix:/var/run/default.sock;
      fastcgi_split_path_info ^/cacti(/.+\.php)(.*)$;
    }
  
    location ~ /cacti/(scripts|lib|install)/ {
      deny all;
    }

Dokuwiki
--------

Из каталога /wiki/:

    location /wiki/ {
      alias /usr/share/dokuwiki/;
      index index.php;
    }
  
    location ~ ^/wiki/.+\.php$ {
      root /usr/share/dokuwiki/;
  
      include fastcgi.conf;
  
      fastcgi_pass unix:/var/run/default.sock;
      fastcgi_split_path_info ^/wiki(/.+\.php)(.*)$;
    }
  
    location ~ ^/wiki/(bin|inc)/ {
      deny all;
    }
  
    location ~ \.ht(access|passwd) {
      deny all;
    }

Redmine
-------

Из каталога /redmine/:

    location /redmine/ {
      alias /usr/share/redmine/public/;
      try_files $uri @redmine;
    }
  
    location @redmine {
      include uwsgi_params;
  
      uwsgi_pass unix:/var/run/uwsgi/app/redmine/socket;
      uwsgi_modifier1 7;
    }

Roundcube
---------

Из каталога /mail/:

    location /mail/ {
      alias /var/lib/roundcube/;
      index index.php;
    }
  
    location ~ ^/mail/.+\.php$ {
      root /var/lib/roundcube/;
  
      include fastcgi.conf;
  
      fastcgi_pass unix:/var/run/default.sock;
      fastcgi_split_path_info ^/mail(/.+\.php)(.*)$;
    }
  
    location /mail/program/js/tiny_mce {
      alias /usr/share/tinymce/www;
    }
  
    location /mail/favicon.ico {
      alias /usr/share/roundcube/skins/default/images/favicon.ico;
    }
  
    location ~ ^/mail/(config|temp|logs)/ {
      deny all;
    }

Wordpress
---------

Из корня сайта:

    server {
      listen 80;
  
      server_name domain.tld;
  
      root /usr/share/wordpress/;
      index index.php;
  
      location / {
        try_files $uri $uri/ /index.php?$args; # permalinks
      }
  
      location ~ \.php$ {
        include fastcgi.conf;
        fastcgi_pass unix:/var/run/default.sock;
      }
    }

Zabbix
------

Из каталога /zabbix/:

    location /zabbix/ {
      alias /usr/share/zabbix/;
      index index.php;
    }
  
    location ~ ^/zabbix/.+\.php$ {
      root /usr/share/zabbix/;
  
      include fastcgi.conf;
  
      fastcgi_pass unix:/var/run/default.sock;
      fastcgi_split_path_info ^/zabbix(/.+\.php)(.*)$;
    }
  
    location ~ ^/zabbix/(conf|api|include|include/classes)/ {
      deny all;
    }
