Установка и настройка openntpd в NetBSD
=======================================

Для установки выполним следующие команды:

    # cd /usr/pkgsrc/net/openntpd
    # make install

Скопируем пример файла инициализации в каталог /etc/rc.d/:

    # cp /usr/pkg/share/examples/rc.d/openntpd /etc/rc.d/

По умолчанию этот файл включается через переменную openntpd файла /etc/rc.conf, но использует настройки из переменных ntpd_*. Исправим это, для чего отредактируем скопированный файл /etc/rc.d/openntpd. Изменим значение переменной name и переменной command следующим образом:

    name="openntpd"
    command="/usr/pkg/sbin/ntpd"

Отредактируем файл конфигурации /usr/pkg/etc/ntpd.conf следующим образом:

    server 169.254.252.1

Теперь пропишем в файл /etc/rc.conf следующие строчки:

    openntpd=YES
    openntpd_flags="-s"

Первая строка разрешает запуск openntpd, вторая содержит опцию, разрешающую изменять время скачком при запуске демона.

Теперь всё готово, осталось только запустить сам демон:

    # /etc/rc.d/openntpd start

Проверим, что демон запустился успешно:

    # netstat -anf inet | fgrep 123
    udp        0      0  169.254.252.16.65523   169.254.252.1.123

В файле /var/log/messages можно увидеть сообщения такого типа:

    May  2 16:12:27 wiki ntpd[4373]: creating new /var/db/openntpd/ntpd.drift
    May  2 16:12:27 wiki ntpd[2255]: ntp engine ready
    May  2 16:15:34 wiki ntpd[18643]: ntp engine ready
    May  2 16:33:20 wiki ntpd[25563]: set local clock to Sun May  2 16:33:20 +05 2021 (offset 1065.607360s)
    May  2 16:33:42 wiki ntpd[18643]: peer 169.254.252.1 now valid

При помощи команды управления демоном ntpctl можно проверить его текущее состояние:

    # ntpctl -s all
    1/1 peers valid, clock synced, stratum 4
    
    peer
       wt tl st  next  poll          offset       delay      jitter
    169.254.252.1 
     *  1 10  3   12s   31s        -0.111ms     0.507ms     0.571ms
