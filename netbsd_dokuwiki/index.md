Установка и настройка Dokuwiki в NetBSD
=======================================

Статья не доделана. В PHP 7.3 изменилась обработка регулярных выражений Perl, из-за чего в DokuWiki стали неправильно отображаться ссылки. Воспользовался этим обстоятельством для того, чтобы попробовать Ikiwiki.

Установка и настройка PHP-FPM
-----------------------------

На момент написания этой статьи в pkgsrc уже есть PHP версии 8.0. Но на официальном сайте Dokuwiki указано, что с PHP версии 8.0 Dokuwiki пока не работает. Поэтому будем использовать PHP версии 7.3.

Впишем в файл /etc/mk.conf следующие опции для отключения ненужных возможностей в PHP версии 7.3 и необходимых ему зависимостях:

	PKG_OPTIONS.bison=              -nls
	PKG_OPTIONS.gmake=              -nls
	PKG_OPTIONS.libfetch=           -inet6 openssl
	PKG_OPTIONS.libxml2=            -icu -inet6
	PKG_OPTIONS.pcre2=              pcre2-jit
	PKG_OPTIONS.perl=               -debug -dtrace -mstats -threads -64bitall -64bitint -64bitmore -64bitnone 64bitauto
	PKG_OPTIONS.php73=              -argon2 disable-filter-url -inet6 -maintainer-zts -php-embed -readline -ssl

Установим PHP версии 7.3 из pkgsrc:

	# cd /usr/pkgsrc/lang/php73
	# make install

Для работы Dokuwiki также нужно установить расширение php-json:

	# cd /usr/pkgsrc/textproc/php-json
	# make install

Установим php-fpm:

	# cd /usr/pkgsrc/www/php-fpm
	# make install

В каталоге /usr/pkg/etc/php-fpm.d/ находятся файлы конфигурации пулов. По умолчанию есть файл конфигурации www.conf. Рассмотрим настройку пула на примере dokuwiki. Переименуем файл www.conf в wiki.conf. После настройки может получиться файл, содержащий следующие настройки:

	# egrep -v '^(;.*|)$' wiki.conf
	[wiki]
	user = fpm
	group = www
	listen = /var/run/php-fpm.wiki.sock
	listen.owner = fpm
	listen.group = www
	listen.mode = 0660
	pm = ondemand
	pm.max_children = 2
	pm.process_idle_timeout = 300s
	pm.max_requests = 500
	access.log = /var/log/$pool.access.log
	chdir = /srv/stupin.su/wiki/
	php_flag[log_errors] = On
	php_value[error_log] = /var/log/$pool.error.log
	php_value[error_reporting] = E_ALL & ~E_NOTICE
	php_value[date.timezone] = Asia/Yekaterinburg
	php_value[always_populate_post_raw_data] = -1

Создадим файл wiki.error.log вручную, т.к. процессы из пула wiki не имеют прав создавать файлы в каталоги /var/log/:

	# touch /var/log/wiki.error.log
	# chown fpm:www /var/log/wiki.error.log
	# chmod u=rw,g=r,o= /var/log/wiki.error.log

Теперь впишем в файл /etc/newsyslog.conf настройки ротации файлов журналов PHP-FPM:

	/var/log/php-fpm.log                            640  7    *    *    BZ /var/run/php-fpm.pid SIGUSR1
	/var/log/wiki.access.log                        640  7    *    *    BZ /var/run/php-fpm.pid SIGUSR1
	/var/log/wiki.error.log         fpm:www         640  7    *    *    BZ /var/run/php-fpm.pid SIGUSR1

Скопируем пример скрипта инициализации из состава пакета:

	# cp /usr/pkg/share/examples/rc.d/php_fpm /etc/rc.d/php_fpm

Разрешим запуск PHP-FPM, вписав в файл /etc/rc.conf следующую опцию:

	php_fpm=YES

Запустим PHP-FPM:

	# /etc/rc.d/php_fpm restart
	Starting php_fpm.

Убедимся, что PHP-FPM он начал прослушивать Unix-сокет

	# netstat -anf inet | grep 9000
	# ls -l /var/run/php-fpm.wiki.sock 
	srw-rw----  1 fpm  www  0 May 18 15:03 /var/run/php-fpm.wiki.sock

Установка и настройка nginx
---------------------------

Я буду настраивать nginx только для проксирования запросов к статическим файлам и к FastCGI-серверу PHP-FPM. Из всех опций мне понадобится только опция pcre. Пропишем в файл /etc/mk.conf необходимые нам опции сборки, отключив ненужные:

	PKG_OPTIONS.nginx=              -array-var -auth-request -cache-purge -dav -debug -echo -encrypted-session -flv -form-input -geoip -gtools -gzip -headers-more -http2 -image-filter -luajit -mail-proxy -memcache -naxsi -njs pcre -perl -push -realip -rtmp -secure-link -set-misc -slice -ssl -status -stream-ssl-preread -sub -uwsgi

Переходим в каталог и запускаем сборку и установку:

	# cd /usr/pkgsrc/www/nginx
	# make install

В случае, если Dokuwiki будет работать на выделенном домене, впишем в секцию server файла /usr/pkg/etc/nginx/nginx.conf следующие настройки:

	location / {
	  alias /srv/stupin.su/wiki/;
	  index index.php;
	}

	location ~ ^/.+\.php$ {
	  root /srv/stupin.su/wiki/;

	  include fastcgi.conf;

	  fastcgi_pass unix:/var/run/php-fpm.wiki.sock;
	  fastcgi_split_path_info ^(/.+\.php)(.*)$;
	}

	location ~ ^/(data|conf|bin|inc)/ {
	  deny all;
	}

	#location ~ ^/data/ {
	#  internal;
	#}

	location ~ ^/.*\.ht(access|passwd)$ {
	  deny all;
	}

Мне также понадобилось закомментировать в файле следующий фрагмент:

	#location / {
	#    root   share/examples/nginx/html;
	#    index  index.html index.htm;
	#}

Cкопируем пример скрипта инициализации nginx из пакета в каталог /etc/rc.d:

	# cp /usr/pkg/share/examples/rc.d/nginx /etc/rc.d/

И пропишем в файл /etc/newsyslog.conf следующие строки:

	/var/log/nginx/access.log       nginx:nginx     640  7    *    24   ZB /var/run/nginx.pid SIGUSR1
	/var/log/nginx/error.log        nginx:nginx     640  7    *    24   ZB /var/run/nginx.pid SIGUSR1

Для того, чтобы nginx смог обращаться к Unix-сокету PHP-FPM, нужно добавить пользователя nginx в группу www и перезапустить:

	# usermod -G www nginx
	# /etc/rc.d/nginx start

Пропишем в файл /etc/rc.conf опцию, разрешающую запускать nginx:

	nginx=YES

И запустим сам nginx:

	# /etc/rc.d/nginx start
	Starting nginx.

Убедиться, что nginx запустился, можно следующим образом:

	# netstat -anf inet | fgrep 80
	tcp        0      0  *.80                   *.*                    LISTEN

Установка и настройка Dokuwiki
------------------------------

Переходим на [страницу загрузки Dokuwiki](https://download.dokuwiki.org/), отмечаем нужные опции и жмём кнопку "Start Download". Я выбрал стабильную версию и русский язык. У меня браузер предложил начать скачивание, но я его отменил и скопировал со страницы ссылку на архив для скачивания.

Создадим каталог для скачивания архива, скачаем его и распакуем:

	# mkdir -p /srv/stupin.su/wiki/
	# cd /srv/stupin.su/wiki/
	# ftp https://download.dokuwiki.org/out/dokuwiki-5805c5df42aef176c25c9f5ebfa018f5.tgz
	# tar xjvf dokuwiki-5805c5df42aef176c25c9f5ebfa018f5.tgz

Удалим архив и переместим распакованные файлы:

	# rm dokuwiki-5805c5df42aef176c25c9f5ebfa018f5.tgz
	# mv dokuwiki/* .
	# rmdir dokuwiki

Выставим права доступа к файлам только на чтение:

	# chown -R root:www *
	# chmod -R o= *

Владельцем каталогов conf и data сделаем пользователя fpm, чтобы можно было изменять настройки и наполнять wiki:

	# chown -R fpm conf
	# chown -R fpm data

Переходим на страницу настройки https://domain.tld/install.php и выставляем настройки:

![Установка DokuWiki](dokuwiki_installer.png)
