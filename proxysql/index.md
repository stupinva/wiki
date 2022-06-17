Настройка ProxySQL
==================

Оглавление
----------

[[!toc startlevel=2 levels=4]]

Настройка репозиториев
----------------------

Заглядываем в файл `/etc/debian_version` или `/etc/lsb-release`, определяем кодовое имя релиза.

Открываем страницу [repo.percona.com/percona/apt/](http://repo.percona.com/percona/apt/) и находим там пакет `percona-release_latest.bionic_all.deb`, где `bionic` - кодовое имя релиза. Копируем ссылку на пакет и скачиваем в систему, где нужно установить ProxySQL:

    $ wget http://repo.percona.com/percona/apt/percona-release_latest.bullseye_all.deb

Установим пакет в систему:

    # dpkg -i percona-release_latest.bullseye_all.deb

Подключаем репозитории с ProxySQL:

    # percona-release enable proxysql

Обновляем список пакетов, доступных через репозитории:

    # apt-get update

Установка
---------

Устанавливаем необходимые пакеты:

    # apt-get install proxysql2

Предварительная настройка
-------------------------

У ProxySQL многоуровневая система конфигураций, которая сильно запутывает работу с ним: есть используемая конфигурация, конфигурация в оперативной памяти, конфигурация в базе данных SQLite3 на диске и конфигурация из файла конфигурации `/etc/proxysql.cnf`. Для того, чтобы не запутаться во всём этом многообразии, я буду использовать только конфигурацию из файла конфигурации `/etc/proxysql.cnf`. К сожалению, при перезапуске ProxySQL конфигурация из базы данных имеет приоритет над конфигурацией из файла `/etc/proxysql.cnf`. Чтобы при перезапуске конфигурация всегда бралась из файла `/etc/proxysql.cnf`, я добавлю в service-файл дополнительную опцию `--initial`.

Кроме того, в конфигруации по умолчанию ProxySQL нужно указать пользователя MySQL, с помощью которого он будет проверять доступность СУБД. В моём случае сервер MySQL всего один и при его недоступности переводить нагрузку некуда, поэтому эта функциональность избыточна. Отключить проверки можно с помощью опции `--no-monitor`, которую тоже внесём в обновлённый service-файл.

Скопируем service-файл из пакета в каталог для собственных и изменённых service-файлов:

    # cp /lib/systemd/system/proxysql.service /etc/systemd/system

Откроем файл `/etc/systemd/system/proxysql.service` в текстовом редакторе и отредактируем строчку с командой запуска ProxySQL следующим образом:

    ExecStart=/usr/bin/proxysql --initial --no-monitor -c /etc/proxysql.cnf

Для того, чтобы информировать систему инициализации systemd об изменениях в service-файлах, вызовем команду:

    # systemctl daemon-reload

Также мне не понравилось расположение журналов работы сервиса, настроенное по умолчанию. Журналы находятся в каталоге `/var/lib/proxysql`, а не в более привычном `/var/log/proxysql`. Исправим это.

Откроем в редакторе файл конфигурации `/etc/proxysql.cnf` и отредактируем строчку:

    errorlog="/var/log/proxysql/proxysql.log"

Откроем в редакторе файл ротации журналов `/etc/logrotate.d/proxysql-logrotate` и поменяем путь к журналам в нём:

    /var/log/proxysql/*.log {

Переместим сам журнал:

    # mkdir /var/log/proxysql/
    # chown proxysql:proxysql /var/log/proxysql/
    # mv /var/lib/proxysql/proxysql.log /var/log/proxysql/

Настройка интерфейса администрирования
--------------------------------------

ProxySQL по умолчанию настраивается на прослушивание двух TCP-портов: 6032 и 6033. Первый порт используется для администрирования системы, а на втором принимаются подключения от клиентов. Номер порта 6033 соответствует номеру порта MySQL по умолчанию 3306, цифры которого переставлены в ообратном порядке. По умолчанию порт 6032 доступен со всех адресов и подключиться к нему можно с помощью логина "admin" и пароля "admin", что не очень безопасно.

Разрешим подключение только к локальному интерфейсу и зададим более сложный пароль, отредактировав секцию `admin_variables` в файле `/etc/proxysql.cnf`:

    admin_variables=
    {
        admin_credentials="root:p4$$w0rd"
        mysql_ifaces="127.0.0.1:6032"
    }

Настройка проксирования
-----------------------

В секции `mysql_variables` я оставил нетронутыми все настройки, за исключением адреса, на котором принимаются входящие подключения, исключив приём подключений на Unix-сокете:

    interfaces="0.0.0.0:6033"

В секции `mysql_servers` нужно настроить серверы MySQL, на которые будут проксироваться входящие подключения. В моём случае это только один локальный сервер, проксировать подключения будем только в Unix-сокет, а количество подключений к серверу ограничим двадцатью:

    mysql_servers =
    (
        {
            address = "/var/run/mysqld/mysqld.sock"
            port = 0
            hostgroup = 0
            max_connections = 20
        },
    )

В секции `mysql_users` нужно перечислить всех пользователей, входящие подключения от которых будут проксироваться на серверы MySQL:

    mysql_users =
    (
        {
            username = "user"
            password = "p4$$w0rd"
            default_hostgroup = 0
            active = 1
            max_connections = 1500
            fast_forward = 1
        },
    )

В опции `password` можно указать как сам пароль, так и его хэш-функцию, выдаваемую функцией `PASSWORD()` из MySQL. Для получения хэша можно воспользоваться запросом такого вида:

    SELECT PASSWORD('p4$$w0rd');

Стоит обратить внимание на опции `hostgroup` и `default_hostgroup` у серверов и клиентов. Они определяют соответствие между клиентами и серверами, так что запросы от клиентов из определённой группы можно распределять между несколькими серверами MySQL той же группы, а клиенты и серверы из разных групп при этом будут оставаться изолированными друг от друга.

Опция `fast_forward` позволяет отключить анализ запросов для выбора сервера, на который нужно отправить запрос, в соответствии с правилами в разделе `mysql_query_rules_fast_routing` и кэширование результатов выполнения запросов для снятия нагрузки с серверов MySQL от повторяющихся запросов в соответствии с правилами в разделе `mysql_query_rules`. Запросы направляются сразу на сервер из группы, соответствующей группе клиента, что позволяет снизить нагрузку на процессор.

Изменение конфигурации без перезапуска
--------------------------------------

Для изменения конфигурации без перезапуска ProxySQL нужно отредактировать файл конфигурации `/etc/proxysql.cnf` и выполнить команды через интерфейс администрирования:

    $ mysql -uroot -p -h127.0.0.1 -P6032 -e 'LOAD ADMIN VARIABLES TO RUNTIME; LOAD ADMIN VARIABLES FROM CONFIG; LOAD MYSQL VARIABLES TO RUNTIME; LOAD MYSQL VARIABLES FROM CONFIG; LOAD MYSQL SERVERS TO RUNTIME; LOAD MYSQL SERVERS FROM CONFIG; LOAD MYSQL USERS TO RUNTIME; LOAD MYSQL USERS FROM CONFIG; LOAD MYSQL QUERY RULES TO RUNTIME; LOAD MYSQL QUERY RULES FROM CONFIG; LOAD SCHEDULER TO RUNTIME; LOAD SCHEDULER FROM CONFIG;'

Для удобства можно доработать service-файл `/etc/systemd/system/proxysql.service`, в который прописать правило перезагрузки сервиса:

    ExecReload=/usr/bin/mysql --defaults-file=/root/.my.cnf -h127.0.0.1 -P6032 -e 'LOAD ADMIN VARIABLES TO RUNTIME; LOAD ADMIN VARIABLES FROM CONFIG; LOAD MYSQL VARIABLES TO RUNTIME; LOAD MYSQL VARIABLES FROM CONFIG; LOAD MYSQL SERVERS TO RUNTIME; LOAD MYSQL SERVERS FROM CONFIG; LOAD MYSQL USERS TO RUNTIME; LOAD MYSQL USERS FROM CONFIG; LOAD MYSQL QUERY RULES TO RUNTIME; LOAD MYSQL QUERY RULES FROM CONFIG; LOAD SCHEDULER TO RUNTIME; LOAD SCHEDULER FROM CONFIG;'

Для применения нового service-файла нужно сообщить об этом `systemd`:

    # systemctl daemon-reload

В строке перезагрузки упоминается файл `/root/.proxysql.cnf` с настройками клиента `mysql`. Создадим его:

    [client]
    user = root
    password = p4$$w0rd
    host = 127.0.0.1
    port = 6032

Чтобы содержимое файла не увидели посторонние, выставим владельца, группу и права доступа:

    # chown root:root /root/.proxysql.cnf
    # chmod u=rw,go= /root/.proxysql.cnf

Теперь применять конфигурацию ProxySQL без остановки можно очевидным для системного администратора образом:

    # systemctl reload proxysql

Тонкая настройка
----------------

### Простаивающие потоки

ProxySQL обрабатывает каждое входящее подключение отдельным потоком, который называется рабочим. Большое количество простаивающих подключений приводит к напрасной трате ресурсов системы, поскольку каждое подключение удерживает рабочий поток и ресурсы, выделенные для его работы. Для экономии ресурсов в ProxySQL были введены так называемые дополнительные потоки, которые тратят на обработку подключения гораздо меньше ресурсов, поскольку их функция сводится к ожиданию активности в простаивающих подключениях. Когда рабочий поток обнаруживает, что подключение перешло в режим простоя, он передаёт его на попечение дополнительному потоку. Дополнительный поток при появлении активности в подключении возвращает его рабочему потоку.

Для того, чтобы включить использование дополнительных потоков, нужно отредактирвоать файл `/etc/systemd/system/proxysql.service` в текстовом редакторе и прописать в команду запуска ProxySQL опцию `--idle-threads` следующим образом:

    ExecStart=/usr/bin/proxysql --initial --no-monitor --idle-threads -c /etc/proxysql.cnf

Для того, чтобы информировать систему инициализации systemd об изменениях в service-файлах, вызовем команду:

    # systemctl daemon-reload

Для применения настроек необходимо перезапустить ProxySQL:

    # systemctl restart proxysql

### Настройки мультиплексирования подключений

При выполнении запросов `INSERT` или `UPDATE` сервер MySQL возвращает вместе с ответом последнее значение автоинкрементного поля, использованное при исполнении запроса. То же самое значение можно узнать с помощью функции `LAST_INSERT_ID()`. ProxySQL отключает простаивающие входящие подключения от подключений к серверу и при появлении активности может соединить входящее подключение с другим подключением к серверу MySQL, из-за чего функция `LAST_INSERT_ID()` может вернуть значение из другого подключения.

Для того, чтобы такие приложения продолжали работать корректно, ProxySQL отслеживает запросы `INSERT` или `UPDATE` во входящих подключениях и удерживает соответствие подключению к серверу на `connection_delay_multiplex_ms` миллисекунд (по умолчанию - 0) и действует на последующие `auto_increment_delay_multiplex` запросов (по умолчанию - 5), но не дольше, чем на `auto_increment_delay_multiplex_timeout_ms` (по умолчанию - 10000). Последняя опция была добавлена в ProxySQL версии 2.4.0.

Если приложение не использует функцию `LAST_INSERT_ID()`, то изменение настроек по умолчанию может существенно уменьшить использование подключений к серверу MySQL. Отключим удержание подключений, для чего добавим в секцию `mysql_variables` файла конфигурации `/etc/proxysql.cnf` следующие опции:

    mysql_variables = 
    {
        auto_increment_delay_multiplex=0
        connection_delay_multiplex_ms=0
        auto_increment_delay_multiplex_timeout_ms=0
    }

При настройке этих опций следует учитывать, что они глобальные и поэтому влияют на всех группы серверов и пользователей сразу. Также стоит учитывать, что мультиплексирование работает только если в настройках клиента не включена опция `fast_forward`.

Для применения настроек нужно выполнить команду:

    # systemctl reload proxysql

Использованные материалы
------------------------

* [ProxySQL / Documentation / Main (runtime tables definition)](https://proxysql.com/documentation/main-runtime/)
* [MySQL auxiliary threads](https://proxysql.com/documentation/proxysql-threads/#mysql-auxiliary-threads)
* [Art van Scheppingen. The ProxySQL multiplexing wild goose chase](https://mysqlquicksand.wordpress.com/2019/11/28/the-proxysql-multiplexing-wild-goose-chase/)
