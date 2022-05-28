Установка и настройка Gitea в NetBSD
====================================

В прошлом я уже описывал [Установку и настройку Gitea](https://vladimir-stupin.blogspot.com/2019/08/gitea.html) в Debian. Теперь попробуем проделать то же самое в NetBSD.

Установка и предварительная настройка
-------------------------------------

К счастью, в pkgsrc уже есть Gitea. Установим её:

    # cd /usr/pkgsrc/www/gitea
    # make install

Скопируем пример скрипта инициализации:

    # cp /usr/pkg/share/examples/rc.d/gitea /etc/rc.d/

Отредактируем скопированный файл /etc/rc.d/gitea, перенаправив вывод сообщений в /dev/null:

    command_args="--config /usr/pkg/etc/gitea/conf/app.ini web >/dev/null 2>&1 &"

Теперь скопируем пример файла конфигурации туда, где его ожидает найти скрипт инициализации:

    # cp /usr/pkg/share/examples/gitea/app.ini.sample /usr/pkg/etc/gitea/conf/app.ini

Меняем в файле конфигурации /usr/pkg/etc/gitea/conf/app.ini в секции server следующие настройки:

    DOMAIN        = stupin.su
    HTTP_ADDR     = 127.0.0.1
    ROOT_URL      = https://stupin.su/git/

И разблокируем возможность настройки через веб-интерфейс:

    INSTALL_LOCK = false

По умолчанию Gitea выводит сообщения уровня info и сообщения обо всех обращениях к страницам. Чтобы включит вывод сообщений только об ошибках и отключить сообщения об обращениях к страницам, нужно прописать в файле конфигурации в секции log следующие настройки:

    LEVEL     = error
    DISABLE_ROUTER_LOG = 1

Разблокируем возможность запуска Gitea, вписав в файл /etc/rc.conf соответствующую строчку:

    gitea=YES

Запускаем gitea при помощи следующей команды:

    # /etc/rc.d/gitea start

Настройка проксирования через nginx
-----------------------------------

Gitea работает от имени пользователя git и поэтому её не получится запустить для обслуживания запросов на портах ниже 1024, т.к. открывать порты с такими номерами имеют право только процессы, запущенные от имени пользователя root.

Кроме того, в Gitea отсутствует реализация протокола HTTPS и недостаёт многих других настроек, характерных для веб-сервера, поскольку фактически она является сервером-приложений, работающим по протоколу HTTP, а само приложение встроено в этот сервер.

Итак, для решения этих проблем, нам понадобится веб-сервер. Воспользуемся nginx. Для начала отключим все ненужные опции, оставив только поддержку ssl. Для этого впишем в файл /etc/mk.conf следующие опции сборки nginx:

    PKG_OPTIONS.nginx=      -array-var -auth-request -dav -debug -echo -encrypted-session -flv -form-input -geoip -gtools -gzip -headers-more -http2 -image-filter -luajit -mail-proxy -memcache -naxsi -njs -pcre -perl -push -realip -rtmp -secure-link -set-misc -slice -status -stream-ssl-preread -sub -uwsgi ssl

Тепрь воспользуемся pkgsrc для сборки и установки веб-сервера nginx с нужными нам опциями:

    # cd /usr/pkgsrc/www/nginx/
    # make install

Если приложение планируется запускать на выделенном домене, то для настройки проксирования внешних запросов с https на локальный адрес http при помощи nginx в общем случае нужно прописать в файле /usr/pkg/etc/nginx/nginx.conf вовнутрь секции http следующую конфигурацию:

    server {
        listen 80;
        server_name example.com;
        return 302 https://$server_name$request_uri;
    }
    
    server {
        listen 443 ssl;
        server_name example.com;
        
        ssl_certificate /path/to/certificate.crt;
        ssl_certificate_key /path/to/certificate_key.key;
        
        location / {
            proxy_set_header X-Real-IP $remote_addr;
            proxy_pass http://localhost:3000;
        }
    }

Я же разместил приложение на одном домене с другими приложениями, в отдельном каталоге, для чего вписал в имеющуюся секцию server настройки проксирования запросов с адреса https://stupin.su/git/ на адрес http://127.0.0.1/git/:

    # Gitea
    location /git/ {
        proxy_redirect off;
        proxy_bind 127.0.0.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass http://127.0.0.1:3000/;
    }

Настройка приложения
--------------------

Теперь можно перейти на страницу настройки https://stupin.su/git/, которую указали в переменной ROOT_URL и на странице настроек указать желаемые настройки:

    Настройки базы данных
      Тип базы данных: SQLite3
      Путь: /var/db/gitea/gitea.db
    
    Основные настройки
      Название сайта: Исходные тексты программ Владимира Ступина
      Путь корня репозитория: /var/db/gitea/gitea-repositories
      Корневой путь Git LFS: /var/db/gitea/data/lfs
      Запуск от имени пользователя: git
      Домен SSH сервера: stupin.su
      Порт SSH сервера: 22
      Gitea HTTP порт: 3000
      Базовый URL-адрес Gitea: https://stupin.su/git/
      Путь к журналу: /var/log/gitea
    
    Расширенные настройки
      Настройки Email
        Узел SMTP: mail.stupin.su:587
        Отправлять Email от имени: gitea@stupin.su
        SMTP логин: gitea@stupin.su
        SMTP пароль: mailbox_password
        Требовать подтверждения по электронной почте для регистрации: Да
        Разрешить почтовые уведомления: Да
      Сервер и настройки внешних служб
        Включить локальный режим: Нет
        Отключить Gravatar: Да
        Включить федеративные аватары: Нет
        Включение входа через OpenID: Нет
        Отключить самостоятельную регистрацию: Да
        Разрешить регистрацию только через сторонние сервисы: Нет
        Включить саморегистрацию OpenID: Нет
        Включить CAPTCHA: Нет
        Требовать авторизации для просмотра страниц: Нет
        Скрывать адреса электронной почты по умолчанию: Нет
        Разрешить создание организаций по умолчанию: Да
        Включение отслеживания времени по умолчанию:  Да
      Скрытый почтовый домен:
      Настройки учётной записи администратора
        Логин администратора: stupin
        Пароль: 
        Подтвердить пароль:
        Адрес эл. почты: vladimir@stupin.su

После сохранения этих настроек файл /usr/pkg/etc/gitea/conf/app.ini, за исключением комментариев, примет следующий вид:

    APP_NAME = Исходные тексты программ Владимира Ступина
    RUN_USER = git
    RUN_MODE = prod
    
    [database]
    DB_TYPE  = sqlite3
    HOST     = 127.0.0.1:3306
    NAME     = gitea
    PASSWD   = 
    PATH     = /var/db/gitea/gitea.db
    SSL_MODE = disable
    USER     = root
    SCHEMA   = 
    CHARSET  = utf8
    
    [indexer]
    ISSUE_INDEXER_PATH = /var/db/gitea/indexers/issues.bleve
    
    [log]
    ROOT_PATH = /var/log/gitea
    MODE      = file
    LEVEL     = info
    
    [mailer]
    ENABLED = true
    HOST    = mail.stupin.su:587
    FROM    = gitea@stupin.su
    USER    = gitea@stupin.su
    PASSWD  = mail_password
    
    [picture]
    AVATAR_UPLOAD_PATH      = /var/db/gitea/data/avatars
    DISABLE_GRAVATAR        = true
    ENABLE_FEDERATED_AVATAR = false
    
    [repository]
    ROOT        = /var/db/gitea/gitea-repositories
    SCRIPT_TYPE = sh
    
    [repository.upload]
    TEMP_PATH = /var/db/gitea/data/tmp/uploads
    
    [security]
    INSTALL_LOCK   = true
    INTERNAL_TOKEN = xxx
    SECRET_KEY     = xxx
    
    [session]
    PROVIDER        = file
    PROVIDER_CONFIG = /var/db/gitea/data/sessions
    
    [server]
    DOMAIN           = stupin.su
    HTTP_ADDR        = 127.0.0.1
    HTTP_PORT        = 3000
    ROOT_URL         = https://stupin.su/git/
    DISABLE_SSH      = false
    SSH_DOMAIN       = stupin.su
    SSH_PORT         = 22
    OFFLINE_MODE     = false
    APP_DATA_PATH    = /var/db/gitea/data
    LFS_START_SERVER = true
    LFS_CONTENT_PATH = /var/db/gitea/data/lfs
    LFS_JWT_SECRET   = xxx
    
    [service]
    REGISTER_EMAIL_CONFIRM            = true
    ENABLE_NOTIFY_MAIL                = true
    DISABLE_REGISTRATION              = true
    ENABLE_CAPTCHA                    = false
    REQUIRE_SIGNIN_VIEW               = false
    ALLOW_ONLY_EXTERNAL_REGISTRATION  = false
    DEFAULT_KEEP_EMAIL_PRIVATE        = false
    DEFAULT_ALLOW_CREATE_ORGANIZATION = true
    DEFAULT_ENABLE_TIMETRACKING       = true
    NO_REPLY_ADDRESS                  = 
    
    [oauth2]
    JWT_SECRET = xxx
    
    [openid]
    ENABLE_OPENID_SIGNIN = false
    ENABLE_OPENID_SIGNUP = false
