Марко Алексич. Как использовать Grub Rescue для исправления ошибки загрузки Linux
=================================================================================

Это перевод статьи [Marko Aleksic. How to Use Grub Rescue to Fix Linux Boot Failure](https://phoenixnap.com/kb/grub-rescue).

[[!tag grub]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

[GRUB (Grand Unified Bootloader)](https://phoenixnap.com/kb/what-is-grub) - это [загрузчик](https://phoenixnap.com/glossary/bootloader) по умолчанию для [операционных систем](https://phoenixnap.com/glossary/operating-system) на основе ядра Linux. Хотя он [загружается](https://phoenixnap.com/glossary/boot-definition) первым при включении компьютера, обычные пользователи редко замечают работу GRUB. Он работает автоматически и не требует действий от пользователя.

Однако, если на компьютере с Linux попытаться загрузить другую операционную систему, то загрузчик этой операционной системы может перезаписать GRUB, что приведёт к невозможности загрузить Linux.

**В этой статье описывается, как исправить ошибку загрузки с помощью команд GRUB Rescue и утилиты Boot Repair.**

Предварительные требования
--------------------------

* Учётная запись с правами sudo.
* Доступ к командной строке.

**Примечание:** Приведённая ниже информация написана применительно к GRUB 2 - текущей версии загрузчика GRUB.

Проблемы загрузки GRUB
----------------------

Чаще всего GRUB не загружает операционную систему потому, что загрузчик другой операционной системы перезаписывает загрузочную конфигурацию GRUB. Проблема появлется при попытке двойной загрузки из уже установленного Linux. Другая причина - это неожиданное удаление файлов конфигурации GRUB.

Когда GRUB не может загрузить систему, появляется приглашение GRUB Rescue.

    error: no such partition.
    Entering rescue mode..
    grub rescue> _

В примере выше показана ошибка GRUB "no such partition" перед приглашением **grub rescue**. Другая частая ошибка GRUB - это "unknown filesystem" - "неизвестная файловая система" с тем же приглашением.

    error: unknown filesystem
    Entering rescue mode..
    grub rescue> _

Иногда на экране может отображаться только приглашение **grub**.

    grub> _

Команды GRUB Rescue
-------------------

Ниже приведён список часто используемых команд GRUB Rescue. Приглашение, описанное в предыдущем разделе, предназначено для этих команд.

| Команда        | Описание                                                                                                                                                                                                                              | Пример                                    |
|----------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------|
| **boot**       | Начать загрузку (быстрые клавиши: **F10**, **CTRL + x**).                                                                                                                                                                             | Эта команда вызывается без аргументов.    |
| **cat**        | Записать содержимое файла на стандартный вывод.                                                                                                                                                                                       | **cat (hd0,1)/boot/grub/grub.cfg**        |
| **configfile** | Загрузить файл конфигурации.                                                                                                                                                                                                          | **configfile (hd0,1)/boot/grub/grub.cfg** |
| **initrd**     | Загрузить файл initrd.img.                                                                                                                                                                                                            | **initrd (hd0,1)/initrd.img**             |
| **insmod**     | Загрузить модуль.                                                                                                                                                                                                                     | **insmod (hd0,1)/boot/grub/normal.mod**   |
| **loopback**   | Смонтировать файл образа как устройство.                                                                                                                                                                                              | **loopback loop0 (hd0,1)/iso/image.iso**  |
| **ls**         | Отобразить содержимое каталога или раздела.                                                                                                                                                                                           | **ls (hd0,1)**                            |
| **lsmod**      | Отобразить список загруженных модулей.                                                                                                                                                                                                | Эта команда вызывается без аргументов.    |
| **normal**     | Активировать модуль normal.                                                                                                                                                                                                           | Эта команда вызывается без аргументов.    |
| **search**     | Поиск устройств. С помощью опции **--file** можно искать файлы, с помощью опции **--label** - метки, с помощью опции **--fs-uuid** - искать [UUID](https://phoenixnap.com/glossary/uuid-universal-unique-identifier) файловых систем. | **search -file [имя-файла]**              |
| **set**        | Задат переменную окружения. Если вызвана без аргументов, команда выводит список всех переменных окружения и их значения.                                                                                                              | **set [имя-переменной]=[значение]**       |

Исправление ошибки загрузки
---------------------------

В этой статье описано два способа решения проблем загрузки GRUB: через **приглашение GRUB Rescue** и с помощью **утилиты Boot Repair**.

### Через терминал Grub

1. Воспользуйтесь командой [set](https://phoenixnap.com/kb/linux-set) без аргументов для просмотра [переменных окружения](https://phoenixnap.com/kb/linux-set-environment-variable):

        set

    В примере вывода показаны настройки GRUB для загрузки с раздела **(hd0,msdos3)**:

        grub> set
        ?=0
        color_highlight=black/white
        color_normal=white/black
        default=0
        gfxmode=800x600
        lang=en_US
        locale_dir=(hd0,msdos3)/boot/grub/locale
        pager=
        prefix=(hd0,msdos3)/boog/grub
        root=hd0,msdos3
        grub> _

2. С помощью [команды ls](https://phoenixnap.com/kb/linux-ls-commands) узнайте список доступных разделов на диске.

        ls

    Вывод отображает список разделов.

        grub> ls
        (hd0)  (hd0,msdos3) (hd0,msdos2) (hd0,msdos1)
        grub> _

    Воспользуемся командой **ls** для поиска раздела, содержащего каталог **boot**.

        ls [имя-раздела]

    Из примера видно, что каталог **boot** находится в разделе **(hd0,msdos1)**.

        grub> ls (hd0,msdos1)
        lost+found var/ dev/ run/ etc/ tmp/ sys/ proc/ usr/ bin boot/ home/ lib lib64
        mnt/ opt/ root/ sbin srv/
        grub> _

3. Задайте загрузочный раздел в качестве значения переменной **root**. В примере используется раздел с **(hd0,msdos1)**.

        set root=(hd0,msdos1)

4. Загрузите режим загрузки **normal**.

        insmod normal

5. Перейдите в режим загрузки **normal**.

        normal

    Режим **normal** позволяет вводить более сложные команды.

6. Загрузите ядро Linux с помощью команды **linux**.

        linux /boot/vmlinuz-4.2.0-16-generic root=/dev/sda1 ro

7. Введите команду **boot**.

        boot

    Теперь система грузится должным образом.

С помощью загрузочного диска
----------------------------

Другой способ исправить проблемы с загрузкой GRUB - воспользоваться загрузочным диском с Linux для загрузки со внешнего диска.

1. Загрузите установочный загрузочный образ диска с Linux. В этом примере используется ISO-образ Ubuntu 20.04.

2. Воспользуйтесь утилитой, такой как [Etcher](https://phoenixnap.com/kb/etcher-ubuntu), для записи загрузочного диска Linux на SD-карту или флеш-накопитель.

3. Вставьте загрузочное устройство и включите компьютер.

4. Выберите **Try Ubuntu** на начальном экране.

    ![Начальный экран Ubuntu.](ubuntu-live-cd-welcome-screen.png)

5. Когда система загрузится с диска, подключите интернет.

6. Откройте терминал и введите следующие команды, чтобы добавить репозиторий с утилитой Boot Repair.

        sudo add-apt-repository ppa:yannubuntu/boot-repair

        marko@test-main:~$ sudo add-apt-repository ppa:yannubuntu/boot-repair
         Simple tool to repair frequent boot problems.
        
        Website: https://sourceforge.net/p/boot-repair/home
         More info: https://launchpad.net/~yannubuntu/+archive/ubuntu/boot-repair
        Press [ENTER] to continue or Ctrl-c to cancel adding it.

    Нажмите **Ввод** и подождите, когда добавится репозиторий.

7. Обновите список пакетов, доступных через репозитории.

        sudo apt update

8. Установите утилиту Boot Repair.

        sudo apt install boot-repair

9. Запустите утилиту Boot Repair через терминал.

        boot-repair

10. Выберите пункт **Recommended repair** - рекомендуемое восстановление.

    ![Выбор пункта меню "Recommended repair" на главном экране Boot Repair.](boot-repair-tool-in-ubuntu.png)

    Подождите, когда утилита завершит восстановление загрузчика.

**Примечание:** Утилита Boot Repair доступна в виде [загрузочного образа диска](https://sourceforge.net/projects/boot-repair-cd/), который можно просто загрузить с внешнего диска без использования других загрузочных дисков с операционными системами.

Обновление файла конфигурации GRUB
----------------------------------

Когда система успешно загрузилась, убедитесь в актуальности файла конфигурации GRUB.

Выполните команду:

    update-grub

    marko@test-main:~$ sudo update-grub
    Sourcing file `/etc/default/grub'
    Sourcing file `/etc/default/grub.d/init-select.cfg'
    Generating grub configuration file ...
    Found linux image: /boot/vmlinuz-5.11.0-27-generic
    Found initrd image: /boot/initrd.img-5.11.0-27-generic
    Found linux image: /boot/vmlinuz-5.8.0-59-generic
    Found initrd image: /boot/initrd.img-5.8.0-59-generic
    Found memtest86+ image: /boot/memtest86+.elf
    Found memtest86+ image: /boot/memtest86+.bin
    done
    marko@test-main:~$

Переустановка GRUB
------------------

Следуйте приведённым ниже шагам для переустановки GRUB в вашей системе Linux.

1. Смонтируйте раздел, содержащий установленную операционную систему. Например, смонтируем раздел **/dev/sda1** в каталог **/mnt**.

        sudo mount /dev/sda1 /mnt

2. Свяжите каталоги **/dev**, **/dev/pts**, **/proc** и **/sys** с соответствующими каталогами в подкаталоге **/mnt**.

        sudo mount --bind /dev /mnt/dev &&
        sudo mount --bind /dev/pts /mnt/dev/pts &&
        sudo mount --bind /proc /mnt/proc &&
        sudo mount --bind /sys /mnt/sys

3. Установите GRUB.

        sudo grub-install -root-directory=/mnt/ /dev/sda

        marko@test-main:~$ sudo grub-install /dev/sda
        Installing for i386-pc platform.
        Installation finished. No error reported.
        marko@test-main:~$

4. Размонтируйте каталоги после успешной установки.

        sudo umount /mnt/sys &&
        sudo umount /mnt/proc &&
        sudo umount /mnt/dev/pts &&
        sudo umount /mnt/dev &&
        sudo umount /mnt

Заключение
----------

После прочтения этой статьи у вас должно получиться исправить проблемы в загрузке Linux с помощью GRUB Rescue или Boot Repair. Другой способ исправления проблем с загрузкой описан в статье [Как использовать команду fsck](https://phoenixnap.com/kb/fsck-command-linux).
