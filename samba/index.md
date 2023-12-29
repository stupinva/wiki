Жизнь в Windows-сети
====================

Пользователю Linux в Windows-сети придётся столкнуться с рядом трудностей, самыми главными из которых будут усмешки со стороны пользователей Windows и их предложения "поставить нормальную систему". С остальными трудностями, как правило, бывает справиться гораздо проще.

Монтирование общих папок
------------------------

Для монтирования сетевых ресурсов нужно сначала установить пакет `cifs-utils`, в котором, в частности, находится утилита `mount.cifs`:

    # apt-get install cifs-utils

Теперь можно вписать в /etc/fstab строчку следующего вида:

    //server.domain.tld/share/ /mnt/server/share/ cifs credentials=/etc/cifs.conf,ip=192.168.145.29,uid=1000,gid=1000,file_mode=0660,dir_mode=0770,rw 0 0

Где:

* `server.domain.tld` - полное доменное имя сетевого сервера с общей папкой,
* `share` - имя общей папки на сетевом сервере,
* `/mnt/server/share/` - каталог компьютера, в который будет смонтирована общая папка,
* `/etc/cifs.conf` - файл с учётными данными пользователя, имеющего доступ к общей папке,
* `192.168.145.29` - IP-адрес сетевого сервера,
* `uid=1000,gid=1000` - идентификатор локальной группы и локального пользователя, которые станут локальными владельцами файлов в общей папке,
* `file_mode=0660,dir_mode=0770` - локальные права доступа к файлам и каталогам в общей папке,
* `rw` - указание на необходимость монтирования в режиме чтения-записи.

Файл с учётными данными `/etc/cifs.conf` должен иметь следующий вид:

    username=stupin_va
    password=P4$$w0rd
    domain=domain

Где:

* `username` - имя сетевого пользователя,
* `password` - его пароль,
* `domain` - его домен.

После создания файла с учётными данными нужно сразу выставить права доступа к нему, чтобы никто, кроме пользователя root, не имел возможность ни посмотреть его содержимое, ни отредактировать:

    # chown root:root /etc/cifs.conf
    # chmod u=rw,go= /etc/cifs.conf

Осталось смонтировать все общие папки из файла /etc/fstab командой:

    # mount -at cifs

Изменение доменного пароля
--------------------------

Обычно администраторы домена Active Directory настраивают политику периодической смены паролей пользователей. Чтобы поменять пароль доменной учётной записи, нам понадобится утилита `smbpasswd` из пакета `samba-common-bin`.

Установим пакет:

    # apt-get install samba-common-bin

Чтобы поменять пароль, нужно выполнить следующую команду:

    # smbpasswd -r domain.tld -U stupin_va

Команда запросит старый пароль и попросит дважды ввести новый пароль.

Не забудьте вписать новый пароль в файл `/etc/cifs.conf` для доступа к общим папкам. Перемонтировать общие папки с новым паролем можно, например, так:

    # umount -at cifs
    # mount -at cifs

Поиск информации о пользователе в домене
----------------------------------------

Иногда бывало нужно найти информацию о пользователе в домене. Зацепкой обычно служили либо доменный логин пользователя, либо его почтовый ящик. Для поиска подобной информации я использовал небольшой скрипт на python:

    #!/usr/bin/python
    # -*- coding: UTF-8 -*-
  
    import ldap
  
    def search_by_username(bind_username, bind_password, username):
        login, domain = username.split('@')
  
        base_dn = domain.split('.')
        base_dn = map(lambda x: 'dc=' + x, base_dn)
        base_dn = ','.join(base_dn)
  
        l = ldap.initialize('ldap://' + domain)
        l.simple_bind_s(bind_username, bind_password)
        l.set_option(ldap.OPT_REFERRALS, 0)
        result = l.search_s(base_dn,
                            ldap.SCOPE_SUBTREE,
                            '(&(sAMAccountName=%s)(objectClass=user)(!(UserAccountControl:1.2.840.113556.1.4.803:=2)))' % login,
                            None)
        user, data = result[0]
        # закрываем соединение
        l.unbind_s()
  
        if user:
            print 'mail', data.get('mail', [''])[0]
            print 'sn', data.get('sn', [''])[0].decode('UTF-8')
            print 'givenName', data.get('givenName', [''])[0].decode('UTF-8')
            print 'middleName', data.get('middleName', [''])[0].decode('UTF-8')
        else:
            print 'Not found'
  
    def search_by_mail(bind_username, bind_password, mail):
        login, domain = bind_username.split('@')
  
        base_dn = domain.split('.')
        base_dn = map(lambda x: 'dc=' + x, base_dn)
        base_dn = ','.join(base_dn)
  
        l = ldap.initialize('ldap://' + domain)
        l.simple_bind_s(bind_username, bind_password)
        l.set_option(ldap.OPT_REFERRALS, 0)
        result = l.search_s(base_dn,
                            ldap.SCOPE_SUBTREE,
                            '(&(mail=%s)(objectClass=user)(!(UserAccountControl:1.2.840.113556.1.4.803:=2)))' % mail,
                            None)
        user, data = result[0]
        # закрываем соединение
        l.unbind_s()
  
        if user:
            print 'sAMAccountName', data.get('sAMAccountName', [''])[0]
            print 'sn', data.get('sn', [''])[0].decode('UTF-8')
            print 'givenName', data.get('givenName', [''])[0].decode('UTF-8')
            print 'middleName', data.get('middleName', [''])[0].decode('UTF-8')
        else:
            print 'Not found'

Способ использования, на мой взгляд, очевиден. Если нужно найти информацию о пользователе по его доменному логину `username@domain.tld`, вызываем функцию `search_by_username`:

    search_by_username('stupin_va@domain.tld', 'password', 'username@domain.tld')

Если нужно найти инфорацию о пользователе по его почтовому ящику `mailbox@domain.tld`, то вызываем функцию `search_by_mail`:

    search_by_mail('stupin_va@domain.tld', 'password', 'mailbox@domain.tld')

Печать на сетевые принтеры
--------------------------

Для печати на сетевые принтеры можно воспользоваться cups. В принципе, с добавлением принтера всё должно быть понятно. Первая сложность, с которой мне пришлось столкнуться - это узнать имя сетевого принтера:

Для того, чтобы узнать имя сетевого принтера, подключенного к компьютеру с известным именем или IP-адресом, можно воспользоваться такой командой:

    $ smbclient -W domain -U stupin_va -L printserver.domain.tld

Где:

* `stupin_va` - имя доменного пользователя,
* `domain` - домен Active Directory,
* `printserver.domain.tld` - доменное имя принт-сервера.

Команда запросит пароль пользователя, который нужно будет ввести. Также можно указать пароль после имени пользователя через знак процента или указать опцию `-A /etc/cifs.conf` (формат файла `/etc/cifs.conf` был описан выше).

Вторая сложность - нужно правильно закодировать пробелы и круглые скобки в URL принтера. Сделать это можно по следующим правилам:

* пробел кодируется символами `%20`,
* открывающаяся круглая скобка кодируется символами `%28`,
* закрывающаяся круглая скобка кодируется симвлоами `%29`.

Например, если смонтировать сетевой принтер с именем `HPLJM1536dnf (NCC)`, который подключен к принт-серверу `printserver.domain.tld`, то в файле `/etc/cups/printers.conf` опция с путём к сетевому принтеру будет выглядеть следующим образом:

    DeviceURI smb://stupin_va:P4$$w0rd@domain/printserver.domain.tld/HPLJM1536dnf%20%28NCC%29

Где:

* `stupin_va` - имя доменного пользователя,
* `P4$$w0rd` - пароль этого пользователя,
* `domain` - домен Active Directory,
* `printserver.domain.tld` - доменное имя принт-сервера,
* `HPLJM1536dnf%20%28NCC%29` - закодированное имя сетевого принтера `HPLJM1536dnf (NCC)`.

Настройка принтера Kyocera Ecosys M2040d
----------------------------------------

Для печати на принтер `Kyocera Ecosys M2040dn` могут потребоваться драйверы, которых нет в репозиториях операционной системы. Их можно найти на сайте производителя

Для установки драйверов:

1. зайдите на [сайт производителя](https://www.kyoceradocumentsolutions.us/en/support/downloads.name-L3VzL2VuL21mcC9FQ09TWVNNMjA0MERO.html#tab=driver),

2. перейдите по ссылке "Linux Print Driver (9.3)",

3. распакуйте скачанный архив KyoceraLinuxPackages-20230720.tar.gz:

        $ tar xzvf KyoceraLinuxPackages-20230720.tar.gz

4. установите в систему пакет `Debian/Global/kyodialog_amd64/kyodialog_9.3-0_amd64.deb` из архива:

        # dpkg -i Debian/Global/kyodialog_amd64/kyodialog_9.3-0_amd64.deb

Далее для настройки принтера:

1. откройте [веб-интерфейс CUPS](https://localhost:631/),
2. перейдите в раздел [Администрирование](http://localhost:631/admin),
3. нажмите кнопку "Добавить принтер",
4. выберите пункт "Windows Printer via SAMBA",
5. введите ссылку к принтеру "smb://stupin_va:P4$$w0rd@domain/printserver.domain.tld/KM2040dn%28magi%29",
6. введите в текстовое поле "Название" название принтера, например, magi,
7. введите в текстовое поле "Описание" текст, поясняющий, какой именно принтер имеется в виду, например, название модели принтера Kyocera ECOSYS M2040dn,
8. выберите в выпадающем списке "Создать" производителя принтера - "kyocera",
9. нажмите кнопку "Продолжить",
10. в поле "Модель" выберите модель "Kyocera ECOSYS M2040dn",
11. нажмите кнопку "Добавить принтер".
