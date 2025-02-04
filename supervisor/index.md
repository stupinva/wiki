Установка, настройки и управление supervisord
=============================================

С точки зрения системного администратора supervisord является избыточной сущностью, все функции которой может с успехом заменить система инициализации Linux, которая в настоящее время стала фактическим стандартом для большинства дистрибутивов - systemd. Однако, по непонятным мне причинам, supervisrod очень популярен среди программистов на Python. Наверное системные средства пугают программистов на Python, т.к. разнятся от системы к системе. Скорее всего именно по этой причине программисты на Python избегают использования системных пакетных менеджеров вроде dpkg и apt, зато охотно используют pip, да ещё и в сочетании с virtualenv. В общем, здесь царит своя атмосфера.

Установка supervisord
---------------------

Тут всё просто, нужно установить всего один пакет:

    # apt-get install supervisor

Настройка supervisord
---------------------

supervisord использует файлы конфигурации, находящиеся в каталоге /etc/supervisor/conf.d/. Файлы имеют формат ini-файлов Windows. Рассмотрим для начала прмер настройки процесса:

    [program:ufa]
    directory=/home/telemetry/collector/
    command=/home/telemetry/collector/collector2_linux_amd64 -config /home/telemetry/collector/config_ufa.yml
    autostart=true
    autorestart=true
    user=telemetry
    redirect_stderr=true
    stdout_logfile=/home/telemetry/collector/logs/collector_ufa.stdout.log
    stdout_logfile_maxbytes=10MB
    stdout_logfile_backups=7
    stderr_logfile=/home/telemetry/collector/logs/collector_ufa.stderr.log
    stderr_logfile_maxbytes=10MB
    stderr_logfile_backups=7

Здесь настроен процесс ufa. Смысл опций понятен из их названий, поэтому останавливаться на них подробно не стану.

Процессы можно объединять в группы. Ниже приведён пример настройки группы collectors, в которую входят процессы ufa и okt:

    [group:collectors]
    programs=ufa,okt

Подробнее о других настройках можно почитать в текстовом файле /usr/share/doc/supervisor/examples/sample.conf.gz, который входит в состав пакета.

Более подробную документацию можно найти на сайте проекта [supervisord.org](http://supervisord.org/). В частности, там есть раздел, посвящённый файлу конфигурации [supervisord.org/configuration.html](http://supervisord.org/configuration.html).

Управление supervisord
----------------------

Управление производится при помощи утилиты supervisorctl. Можно как указывать команды утилите прямо в командной строке, так и запустить её в диалоговом режиме и вводить их в ответ на приглашение утилиты.

Например, для просмотра состояния запущенных процессов можно указать команду status в аргументах:

    # supervisorctl status

Или можно запустить утилиту в диалоговом режиме и ввести команду status в ответ на приглашение:

    # supervisorctl
    supervisor> status
    collectors:okt                   RUNNING   pid 2721, uptime 0:00:07
    collectors:ufa                   RUNNING   pid 2551, uptime 0:02:04

Наиболее полезные команды управления:

* status <группа:процесс> - просмотр состояния процесса в группе,
* start <группа:процесс> - запуск процесса в группе,
* stop <группа:процесс> - останов процесса в группе,
* restart <группа:процесс> - перезапуск процесса в группе,
* reread - перечитать файл конфигурации из файловой системы, не выполняя никаких других действий,
* update - перечитать файл конфигурации из файловой системы, остановить и удалить пропавшие группы и процессы, добавить и запустить новые группы и процессы.

Для выполнения одной команды надо всеми процессами группы вместо имени процесса можно указать звёздочку. Если процесс не состоит в группе, то можно указать его имя. Если не указывать группу или процесс, то команда будет выполнена надо всеми процессами в группе или надо всеми процессами.
