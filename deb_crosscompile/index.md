Кросскомпиляция deb-пакетов
===========================

Добавляем архитектуру, для которой будем кросскомпилировать пакеты:

    # dpkg --add-architecture armhf

И обновляем после этого репозитории:

    # apt-get update

Устанавливаем всё необходимое для обычной сборки:

    # apt-get install build-essential crossbuild-essential-armhf autoconf automake bison debhelper dh-apparmor libssl-dev dpkg-dev fakeroot

Устанавливаем пакет для кросс-сборки под интересующую нас архитектуру:

    # apt-get install crossbuild-essential-armhf

Скачиваем и распаковываем исходники пакета, который будем кросскомпилировать:

    $ apt-get source openntpd
    $ dpkg-source -x openntpd_6.2p3-4.2.dsc

Переходим в каталог с распакованными исходниками пакета и выполняем кросс-сборку:

    $ cd openntpd-6.2p3
    $ dpkg-buildpackage -us -uc --host-arch armhf

Теперь переходим в каталог выше, там должны сформироваться пакеты, собранные под интересующую нас архитектуру:

    $ cd ..
    $ ls -1 *.deb
    openntpd_6.2p3-4.2_armhf.deb
    openntpd-dbgsym_6.2p3-4.2_armhf.deb
