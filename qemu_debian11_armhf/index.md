Debian 11 в виртуальной машине Qemu на архитектуре ARM
======================================================

Первый этап формирования корневой файловой системы
--------------------------------------------------

Установим утилиту для формирования образа корневой файловой системы Debian:

    # apt-get install debootstrap

Запустим debootstrap для формирования заготовки будущей корневой файловой системы в каталоге debian-bullseye-armhf:

    # debootstrap --foreign --arch=armhf bullseye debian-bullseye-armhf http://mirror.yandex.ru/debian/

Где:

* `--foreign` - выполнить только первый этап подготовки файловой системы,
* `--arch=armhf` - требуемая архитектура,
* `bullseye` - требуемый выпуск Debian,
* `debian-bullseye-armhf` - каталог, в который будут скачаны и распакованы необходимые deb-пакеты,
* `http://mirror.yandex.ru/debian/` - зеркало репозиториев с deb-пакетами.

debootstrap скачает из указанного репозитория deb-пакеты, составляющие основу операционной системы, указанной архитектуры и распакует их в каталог debian-bullseye-armhf.

Второй этап формирования корневой файловой системы
--------------------------------------------------

Установим эмулятор qemu и пакет поддержки интерпретаторов двоичных форматов:

    # apt-get install qemu-user-static binfmt-support

qemu-user-static - эмулятор, позволяющий запускать Linux-программы, собранные для одной архитектуры процессора, на процессорах другой архитектуры.

binfmt-support - утилита, определяющая подходящий интерпретатор для запуска программы по сигнатуре файла, а также утилита для управления списком соответствий.

    # chroot debian-bullseye-armhf
    # debootstrap/debootstrap --second-stage

После этого можно выполнить дополнительные действия по настройке будущей системы: добавить пользователей, задать имя узла, прописать настройки сети и т.п. Я ограничусь лишь сменой пароля пользователя root, т.к. всё остальное можно будет поменять, войдя в систему под ним:

    # passwd

Для уменьшения итогового образа файловой системы можно очистить каталог /var/cache/apt/archives от deb-пакетов, использованных для развёртывания системы и от списка пакетов, доступных из репозиториев:

    # cd /var/cache/apt/archives
    # rm *.deb
    # cd /var/lib/apt/lists
    # find . -type f -delete

Когда настройка будет завершена, можно покинуть среду chroot командой exit или нажатием Ctrl-D.

Формирование загрузочного образа
--------------------------------

Оценим размер будущей файловой системы:

    $ du -sh debian-bullseye-armhf

Делаем архив получившейся файловой системы и удаляем исходный каталог:

    # tar cjvf debian-bullseye-armhf.tbz -C debian-bullseye-armhf .
    # rm -R debian-bullseye-armhf

Сейчас нам пригодится оценка размера файловой системы. Нужно создать для образа будущей файловой системы пустой файл такого размера, чтобы в него уместились файлы. Например, для файлов объёмом 172 мегабайта я создаю пустой файл размером 256 мегабайт:

    # dd if=/dev/zero bs=1M count=256 of=debian-bullseye-armhf.ext4

Отформатируем этот файл для размещения файловой системы в формте ext4:

    # mkfs.ext4 -F debian-bullseye-armhf.ext4

Смонтируем пустую файловую систему, распакуем в неё файлы и размонтируем файловую систему:

    # mount debian-bullseye-armhf.ext4 /mnt/
    # tar xjvf debian-bullseye-armhf.tbz -C /mnt/
    # umount /mnt/

Подготовка ядра Linux
---------------------

Установим инструменты, необходимые для компиляции ядра:

    # apt-get install bison flex bc libncurses-dev

Для кросс-компиляции понадобится также кросс-компилятор под соответствующую платформу:

    # apt-get install crossbuild-essential-armhf

Скачаем архив с исходными текстами стабильной версии ядра Linux с официального сайта и распакуем их:

    $ wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.14.15.tar.xz
    $ tar xJvf linux-5.14.15.tar.xz

Перейдём в каталог с распакаованными исходными текстами

    $ cd linux-5.14.15

В каталоге arch/arm/configs/ можно найти готовые конфигурации для различных устройств. Для запуска в qemu без проблем подошёл файл конфигруации vexpress_defconfig. Выберем его:

    $ ARCH=arm make vexpress_defconfig

Этот файл конфигурации сохранится под именем .config. Поменять опции в файле конфигурации .config через удобный ncurses-интерфейс можно следующим образом:

    $ ARCH=arm make menuconfig

Для сборки ядра нужной нам конфигурации воспользуемся кросс-компиляцией:

    $ ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- make

Тестирование ядра Linux
-----------------------

Проверим возможность запуска ядра Linux в виртуальной машине, для чего нам понадобятся файлы zImage с образом самого ядра и vexpress-v2p-ca9.dtb с информацией о системе для ядра:

    $ qemu-system-arm -nodefaults -nographic -machine vexpress-a9 -m 256 -kernel linux-5.14.15/arch/arm/boot/zImage -dtb linux-5.14.15/arch/arm/boot/dts/vexpress-v2p-ca9.dtb -append "console=ttyAMA0" -serial stdio

Т.к. ядру не была указана корневая файловая система для загрузки, то запуск должен завершиться ошибкой. В одной из последних строчек сообщений об ошибке можно будет найти сообщение такого вида:

    Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)

Загрузка системы
----------------

Теперь запустим ядро с указанием образа корневой файловой системы:

    $ qemu-system-arm -nodefaults -nographic -machine vexpress-a9 -m 256 -kernel linux-5.14.15/arch/arm/boot/zImage -dtb linux-5.14.15/arch/arm/boot/dts/vexpress-v2p-ca9.dtb -append "console=ttyAMA0 root=/dev/mmcblk0 rootfstype=ext4 ro" -serial stdio -drive if=sd,format=raw,file=debian-bullseye-armhf.ext4

Виртуальная машина через virt-manager
-------------------------------------

Для удобства можно настроить виртуальную машину через virt-manager, а образ SD-диска поместить на логический том LVM.

Общие настройки:

[[debian11-arm-general.png]]

Настройки центрального процессора:

[[debian11-arm-cpu.png]]

Настройки загрузки системы:

[[debian11-arm-boot.png]]

Настройки SD-карты:

[[debian11-arm-sd.png]]

Настройки сети:

[[debian11-arm-net.png]]

Консоль загруженной системы:

[[debian11-arm-console.png]]

Использованные материалы
------------------------

* [RISC'овый Debian под QEMU](https://habr.com/ru/post/278159/)
* [Build Your ARM Image for QEMU](https://medicineyeh.wordpress.com/2016/03/29/buildup-your-arm-image-for-qemu/)
* [Embedded Linux в двух словах. Первое](https://habr.com/ru/post/551972/)
* [Embedded Linux в двух словах. Второе](https://habr.com/ru/post/552216/)
