Настройка SOCKS4/5-прокси сервера Dante
=======================================

Для настройки прокси сервера нам понадобится:

* пакет dante-server, содержащий сам прокси-сервер,
* пакет libpam-pwdfile, содержащий модуль PAM для проверки пользователей и их паролей по списку в текстовом файле,
* пакет whois, содержащий утилиту mkpasswd для генерирования хешей паролей.

Установим в систему необходимые пакеты:

    # apt-get install dante-server libpam-pwdfile whois

Создадим файл /etc/pam.d/danted, содержащий настройки для сервиса danted:

    auth required pam_pwdfile.so pwdfile /etc/danted.passwd
    account required pam_permit.so

В файле указано, что аутентификация пользователей сервиса будет производиться по текстовому файлу /etc/danted.passwd.

Сформируем хэш пароля первого пользователя. Для хэширования паролей воспользуемся алгоритмом SHA-512:

    $ mkpasswd -m sha-512

Создадим файл /etc/dante.passwd и впишем в него одну строку, в которой имя пользователя отделено от пароля двоеточием:

    stupin:$6$SdBQ5DXnx3e$f2qi/6/J/opIsl2buCUKvn1rlyZT92siRCHZ1uWCIyEEJaRBa2JduBu9.wmQm4SUac8otQ5JCXkO67CAahzI2/

Сменим права доступа к файлу, чтобы этот файл мог читать только пользователь root:

    # chmod o= /etc/danted.passwd

Наконец, настроим сам прокси-сервер. Вот краткая выжимка из моего файла /etc/dante.conf:

    logoutput: syslog
    # Внутренний интерфейс и порт, на котором будут приниматься подключения клиентов
    internal: vlan3 port = 3128
    # Внешний интерфейс, через который будут устанавливаться исходящие подключения и
    # на котором будут прослушиваться порты, запрошенные клиентами
    external: ppp0
    # Аутентификация через подсистему PAM
    socksmethod: pam.username
    user.privileged: proxy
    user.unprivileged: nobody
    user.libwrap: nobody
    
    # Разрешаем подключения клиентов с любых адресов на любой адрес,
    # прослушиваемый прокси-сервером
    client pass {
      from: 0.0.0.0/0 port 1-65535 to: 0.0.0.0/0
    }
    # Запрещаем подключаться клиентам к интерфейсу lo
    client block {
      from: 0.0.0.0/0 to: lo
    }
    
    # Подключенным клиентам разрешаем обмен трафиком в любом направлении
    socks pass {
      from: 0.0.0.0/0 to: 0.0.0.0/0
    }
    # Но запрещаем подключаться к интерфейсу lo
    socks block {
      from: 0.0.0.0/0 to: lo0
      log: connect error
    }
    # И запрещаем открывать порты на прослушивание
    socks block {
      from: 0.0.0.0/0 to: 0.0.0.0/0
      command: bind
      log: connect error
    }

Осталось запустить сервер и включить его в автозагрузку:

    # systemctl start danted.service
    # systemctl enable danted.service
  
Использованные материалы
------------------------

* [SOCKS-прокси с авторизацией по логину и паролю](https://www.ylsoftware.com/news/698)
