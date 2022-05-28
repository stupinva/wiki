Установка модуля yaml для PHP5.4 в Debian Wheezy
================================================

Ставим необходимое для сборки:

    # apt-get install php5-dev libyaml-dev

Собираем модуль yaml версии 1.3.0 - успешно соберётся с php5.4 только он:

    # pecl install -f yaml-1.3.0

В противном случае будут выдаваться ошибки следующего вида:

    WARNING: channel "pecl.php.net" has updated its protocols, use "pecl channel-update pecl.php.net" to update
    warning: pecl/yaml requires PHP (version >= 7.0.0-dev), installed version is 5.4.45-ufanet
