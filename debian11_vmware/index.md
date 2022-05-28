Настройка виртуальной машины с Debian 11 под управлением VMware
===============================================================

Настройка репозиториев
----------------------

Прописываем репозитории в файл /etc/apt/sources.list:

    deb http://mirror.yandex.ru/debian/ bullseye main contrib non-free
    deb http://mirror.yandex.ru/debian/ bullseye-updates main contrib non-free
    deb http://mirror.yandex.ru/debian/ bullseye-proposed-updates main contrib non-free
    deb http://mirror.yandex.ru/debian-security/ bullseye-security main contrib non-free

Отключаем установку предлагаемых зависимостей, создав файл /etc/apt/apt.conf.d/suggests со следующим содержимым:

    APT::Install-Suggests "false";

Отключаем установку рекомендуемых зависимостей, создав файл /etc/apt/apt.conf.d/recommends со следующим содержимым:

    APT::Install-Recommends "false";

Система apt сохраняет скачанные пакеты в каталоге /var/cache/apt/archives/, чтобы при необходимости не скачивать их снова. Файлы в этом каталоге по умолчанию не удаляются, что может привести к переполнению диска. Чтобы отключить размер файлов в этом каталоге 200 мегабайтами, создадим файл /etc/apt/apt.conf.d/cache со следующим содержимым:

    APT::Cache-Limit "209715200";

Создадим файл /etc/apt/apt.conf.d/timeouts с настройками таймаутов обращения к репозиториям:

    Acquire::http::Timeout "5";
    Acquire::https::Timeout "5";
    Acquire::ftp::Timeout "5";

При необходимости, если репозитории доступны через веб-прокси, можно создать файл /etc/apt/apt.conf.d/proxy, прописав в него прокси-серверы для протоколов HTTP, HTTPS и FTP:

    Acquire::http::Proxy "http://10.0.25.3:8080";
    Acquire::https::Proxy "http://10.0.25.3:8080";
    Acquire::ftp::Proxy "http://10.0.25.3:8080";

После этого можно попробовать обновить список пакетов, доступных через репозитории:

    # apt-get update

И если репозитории доступны, можно установить обновления для имеющихся в системе пакетов:

    # apt-get upgrade

Установка базовых пакетов
-------------------------

После установки системы в минимальной конфигурации я обычно устанавливаю минимально необходимый мне список пакетов:

    # apt-get install acpi-support-base vim less apt-file binutils sysstat tcpdump file dnsutils telnet psmisc traceroute net-tools man-db bzip2 ca-certificates apt-transport-https wget unzip

Также могут понадобиться и некоторые другие пакеты, которые я обычно устанавливаю на серверы:

    # apt-get install screen rsync iptables ipset vlan

Установка X-сервера и менеджера дисплеев
----------------------------------------

В виртуальной машине под управлением VMWare имеется виртуальный видеоадаптер, который определяется как VMWare SVGA II Adapter. Драйвер для X-сервера, работающий с этим видеоадаптером, находится в пакете xserver-xorg-video-vmware. Драйверы клавиатуры и мыши для X-сервера находятся в пакете xserver-xorg-input-evdev. В качестве дисплейного менеджера я обычно использую lightdm. Для того, чтобы в дисплейном менеджере были активны кнопки перезагрузки и выключения компьютера, понадобится также установить пакет policykit-1. Установим указанные пакеты:

    # apt-get install xserver-xorg-video-vmware xserver-xorg-input-evdev lightdm policykit-1

Установка рабочего стола XFCE4
------------------------------

Установим окружение рабочего стола XFCE4 с минимальным набором приложений, включающим в себя средство для создания снимков экрана, терминал, индикатор переключения клавиатуры, простейший текстовый редактор, файловый менеджер и менеджер томов для файлового менеджера. Для этого воспользуемся следующей командой:

    # apt-get install xfce4 xfce4-screenshooter xfce4-terminal xfce4-xkb-plugin mousepad gnome-calculator thunar thunar-volman

Установка прочих программ
-------------------------

Для установки локализованной версии Firefox можно воспользоваться следующей командой:

    # apt-get install firefox-esr firefox-esr-l10n-ru

Для блокировки экрана я пользуюсь xtrlock:

    # apt-get install xtrlock

Для регулирования громкости звука и проверки работы звуковых карт я пользуюсь утилитами alsamixer и aplay из пакета alsa-utils:

    # apt-get install alsa-utils

Для генерации случайных паролей установим pwgen:

    # apt-get install pwgen

Для подключения к базам данных PostgreSQL установим клиента psql для командной строки:

    # apt-get install postgresql-client-13 postgresql-client-common

Установка VMware Tools
----------------------

Для удобной интеграции виртуальной машины с операционной системой компьютера можно установить в виртуальную машину дополнительные пакеты open-vm-tools и open-vm-tools-desktop:

    # apt-get install open-vm-tools open-vm-tools-desktop
