Создание своего репозитория Debian при помощи reprepro
======================================================

[[!tag wheezy gpg apt]]

Содержание
----------

[[!toc levels=4 startlevel=2]]

Настройка reprepro
------------------

Перейдём в каталог `/home/ufanet` и создадим в нём подкаталог `repo` для размещения файлов будущего репозитория:

    $ cd /home/ufanet
    $ mkdir repo

Создадим каталог с файлом конфигруации:

    $ mkdir conf

Поместим в него конфигурацию репозитория:

    $ cat > conf/distribution <<END
    Codename: wheezy
    Architectures: amd64 source
    Components: main
    AlsoAcceptFor: UNRELEASED
    SignWith: default
    END

Опция `AlsoAcceptFor` со значением UNRELEASED позволит добавлять в репозиторий файлы с расширением .changes, в которых вместо имени репозитория указано UNRELEASED.

Подготовка ключа репозитория
----------------------------

Сгенерируем ключ, указав в качестве владельца ключа "Division of software development and maintenance (ufanet)", а в качестве почтового ящика - "site@ufanet.ru". Ниже приведён полный диалог с командой `gpg` в процессе генерации новых ключей:

    # gpg --gen-key
    gpg (GnuPG) 1.4.12; Copyright (C) 2012 Free Software Foundation, Inc.
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.
    
    Please select what kind of key you want:
       (1) RSA and RSA (default)
       (2) DSA and Elgamal
       (3) DSA (sign only)
       (4) RSA (sign only)
    Your selection? 
    RSA keys may be between 1024 and 4096 bits long.
    What keysize do you want? (2048) 
    Requested keysize is 2048 bits
    Please specify how long the key should be valid.
             0 = key does not expire
          <n>  = key expires in n days
          <n>w = key expires in n weeks
          <n>m = key expires in n months
          <n>y = key expires in n years
    Key is valid for? (0) 
    Key does not expire at all
    Is this correct? (y/N) y
    
    You need a user ID to identify your key; the software constructs the user ID
    from the Real Name, Comment and Email Address in this form:
        "Heinrich Heine (Der Dichter) <heinrichh@duesseldorf.de>"
    
    Real name: Division of software development and maintenance (ufanet)
    Email address: site@ufanet.ru
    Comment: 
    You selected this USER-ID:
        "Division of software development and maintenance (ufanet) <site@ufanet.ru>"
    
    Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? O
    You need a Passphrase to protect your secret key.
    
    You don't want a passphrase - this is probably a *bad* idea!
    I will do it anyway.  You can change your passphrase at any time,
    using this program with the option "--edit-key".
    
    We need to generate a lot of random bytes. It is a good idea to perform
    some other action (type on the keyboard, move the mouse, utilize the
    disks) during the prime generation; this gives the random number
    generator a better chance to gain enough entropy.
    
    Not enough random bytes available.  Please do some other work to give
    the OS a chance to collect more entropy! (Need 273 more bytes)
    +++++                                                                                                           
    ......+++++
    We need to generate a lot of random bytes. It is a good idea to perform
    some other action (type on the keyboard, move the mouse, utilize the
    disks) during the prime generation; this gives the random number
    generator a better chance to gain enough entropy.
    
    Not enough random bytes available.  Please do some other work to give
    the OS a chance to collect more entropy! (Need 61 more bytes)
    +++++
    ........+++++
    gpg: key 1FCF0B50 marked as ultimately trusted
    public and secret key created and signed.
    
    gpg: checking the trustdb
    gpg: 3 marginal(s) needed, 1 complete(s) needed, PGP trust model
    gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
    pub   2048R/1FCF0B50 2024-03-20
          Key fingerprint = 700D 7827 6E63 BE82 C8FF  D47F 9F6E 3E4C 1FCF 0B50
    uid                  Division of software development and maintenance (ufanet) <site@ufanet.ru>
    sub   2048R/D4B37046 2024-03-20

Экспортируем публичный ключ будущего репозитория:

    $ gpg --export -a site@ufanet.ru > repo.key

Добавим в репозиторий файлы с расширением `.changes` из каталога `/home/stupin`:

    $ ls -1 /home/stupin/*.changes | xargs -n1 reprepro include wheezy

Аналогичным образом добавим в репозиторий файлы с расширением `.deb`:

    $ ls -1 /home/stupin/*.deb | xargs -n1 reprepro includedeb wheezy

И добавим файлы с расширением `.dsc`, с которыми связаны исходные тексты для сборки пакетов:

    $ ls -1 /home/stupin/*.dsc | xargs -n1 reprepro includedsc wheezy

Осталось опубликовать репозиторий:

    $ reprepro export wheezy

Настройка веб-сервера
---------------------

Для того, чтобы к репозиторию можно было обращаться из сети, установим веб-сервер `nginx`:

    # apt-get install nginx-light

Создадим файл `/etc/nginx/sites-available/repo.lo.ufanet.ru` с конфигурацией сайта `repo.lo.ufanet.ru`:

    server {
            root /srv/repo;
            index index.html index.htm;
    
            server_name repo.lo.ufanet.ru;
    
            location / {
                    try_files $uri $uri/ /index.html;
                    autoindex on;
            }
    
            location /conf {
                    deny all;
            }
            location /db {
                    deny all;
            }
    }

Включим эту конфигурацию:

    # ln -s /etc/nginx/sites-available/repo.lo.ufanet.ru /etc/nginx/sites-enable/repo.lo.ufanet.ru
    # /etc/init.d/nginx reload

Использование репозитория
-------------------------

Пропишем в списки репозиториев в файле `/etc/apt/sources.list` новый репозиторий:

    deb http://repo.lo.ufanet.ru/ wheezy main

Установим ключ репозитория:

    # wget --quiet -O - http://repo.lo.ufanet.ru/repo.key | apt-key add -

Далее можно использовать пакеты из репозитория привычным образом. Например, можно получить свежий актуальынй список пакетов из репозитория и установить из него обновлённые пакеты:

    # apt-get update
    # apt-get upgrade
