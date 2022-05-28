Настройка IPMI
==============

Для начала нужно загрузить в ядро модули для работы с IPMI:

    # modprobe ipmi_si
    # modprobe ipmi_devintf
    # modprobe ipmi_msghandler

Если в файловой системе появилось устройство /dev/ipmi0, значит IPMI-контроллер успешно определился операционной системой. Для того, чтобы необходимые модули загружались автоматически при загрузке системы, нужно добавить их имена в файл /etc/modules:

    ipmi_si
    ipmi_devintf
    ipmi_msghandler

Минимальная настройка
---------------------

    ipmitool lan print 1
    ipmitool lan set 1 ipaddr 192.168.1.2
    ipmitool lan set 1 netmask 255.255.255.0
    ipmitool lan set 1 defgw ipaddr 192.168.1.1
  
    ipmitool lan set 1 password myPaSsW0rD
    ipmitool lan set 1 user
    ipmitool lan set 1 access on

    echo "myPaSsW0rD" > .pwd

    ipmitool -H 192.168.1.2 -f .pwd sdr type 'Power Supply'

С ограниченными привилегиями
----------------------------

    # Просмотр настроек интерфейса 1
    ipmitool lan print 1
  
    # Выставляем настройки интерфейса
    ipmitool lan set 1 ipaddr 192.168.1.4
    ipmitool lan set 1 netmask 255.255.255.0
    ipmitool lan set 1 defgw ipaddr 192.168.1.1
  
    # Выставляем доступные методы аутентификации для каждого уровня привилегий
    ipmitool lan set 1 auth callback ''
    ipmitool lan set 1 auth user md5
    ipmitool lan set 1 auth operator ''
    ipmitool lan set 1 auth admin ''
  
    # Отключаем неиспользуемых пользователей
    ipmitool channel setaccess 1 1 privilege=15
    ipmitool channel setaccess 1 4 privilege=15
    ipmitool channel setaccess 1 5 privilege=15
  
    # Меняем пароль у пользователя root, которого нельзя отключить
    ipmitool user set password 2 xxxxxx
  
    # Пользователя 3 переименовываем в mon, выставляем пароль
    ipmitool user set name 3 mon
    ipmitool user set password 3 yyyyyy
    ipmitool user enable 3
  
    # Даём пользователю 3 доступ через интерфейс 1 с привилегиями user (только чтение)
    ipmitool channel setaccess 1 3 ipmi=off privilege=2
  
    # Включаем доступ через интерфейс
    ipmitool lan set 1 access on
