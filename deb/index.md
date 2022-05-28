Репозитории и пакеты Debian
===========================

Репозитории
-----------

Список репозиториев /etc/apt/sources.list:

    deb http://mirror.ufanet.ru/debian wheezy main contrib non-free
    deb http://mirror.ufanet.ru/debian wheezy-updates main contrib non-free
    deb http://mirror.ufanet.ru/debian wheezy-proposed-updates main contrib non-free
  
    deb http://mirror.yandex.ru/debian wheezy main contrib non-free
    deb http://mirror.yandex.ru/debian wheezy-updates main contrib non-free
    deb http://mirror.yandex.ru/debian wheezy-proposed-updates main contrib non-free
    deb http://mirror.yandex.ru/debian wheezy-backports main contrib non-free
  
    deb http://mirror.yandex.ru/debian-security wheezy/updates main

Если репозиторий не подписан, но нужно разрешить использовать его, то можно указать trusted=yes:

    deb [trusted=yes] http://manpages.stupin.su/repo/ jessie main

### Zabbix

Скачиваем ключ репозитория:

    # wget http://repo.zabbix.com/zabbix-official-repo.key -O - | apt-key add -

Добавляем репозиторий Zabbix к списку репозиториев /etc/apt/sources.list:

    deb http://repo.zabbix.com/zabbix/2.2/debian wheezy main

### RAID-контроллеры

Существует [репозиторий](http://hwraid.le-vert.net/wiki/DebianPackages) с различными утилитами для управления и просмотра состояния RAID-контроллеров. Добавляем его в /etc/apt/sources.list:

    deb http://hwraid.le-vert.net/debian wheezy main

И устанавливаем ключ репозитория:

    # wget http://hwraid.le-vert.net/debian/hwraid.le-vert.net.gpg.key -O - | apt-key add -

Список доступных утилит:

|Утилита                        |Версия                      |Контроллер                    |amd64|i386|
|-------------------------------|----------------------------|------------------------------|-----|----|
|3ware-status                   |0.4                         |3Ware Eskalad 7000/8000/9000  |X    |X   |
|tw-cli                         |2.00.11.020+10.2.1-1        |3Ware Eskalad 7000/8000/9000  |X    |X   |
|3dm2                           |2.11.00.019+10.2.1+KB16625-1|3Ware Eskalad 7000/8000/9000  |X    |X   |
|aacraid-status                 |0.19                        |Adaptec AACRaid               |X    |X   |
|adaptec-storage-manager-agent  |7.31.18856-1                |Adaptec AACRaid               |X    |X   |
|adaptec-storage-manager-common |7.31.18856-1                |Adaptec AACRaid               |X    |X   |
|adaptec-storage-manager-gui    |7.31.18856-1                |Adaptec AACRaid               |X    |X   |
|arcconf                        |7.31.18856-1                |Adaptec AACRaid               |X    |X   |
|hrconf                         |7.31.18856-1                |Adaptec AACRaid               |X    |X   |
|adaptec-universal-storage-snmpd|7.31.18856-1                |Adaptec AACRaid               |X    |X   |
|adaptec-universal-storage-mib  |7.31.18856-1                |Adaptec AACRaid               |X    |X   |
|cciss-vol-status               |1:1.09-2hwraid1             |HP/Compaq SmartArray          |X    |X   |
|hpacucli                       |9.20.9.0-1                  |HP/Compaq SmartArray          |X    |X   |
|megaraid-status                |0.10                        |LSI MegaRAID / MegaRAID SAS   |X    |X   |
|megactl                        |0.4.1+svn20090725.r6-1      |LSI MegaRAID / MegaRAID SAS   |X    |X   |
|megamgr                        |5.20-3                      |LSI MegaRAID                  |X    |X   |
|dellmgr                        |5.31-1                      |LSI MegaRAID (Dell cards only)|X    |X   |
|megaclisas-status              |0.9                         |LSI MegaRAID SAS              |X    |X   |
|megacli                        |8.04.07-1                   |LSI MegaRAID SAS              |X    |X   |
|megaide-status                 |0.2                         |LSI MegaIDE                   |X    |X   |
|megaide-spyd                   |7.24.26-3                   |LSI MegaIDE                   |     |X   |
|mpt-status                     |1.2.0-4.2.hwraid1           |LSI FusionMPT                 |X    |X   |
|lsiutil                        |1.60-1                      |LSI FusionMPT                 |X    |X   |
|lsiutil                        |1.60-1                      |LSI FusionMPT                 |X    |X   |
|sas2ircu                       |16.00.00.00-1               |LSI FusionMPT SAS2            |X    |X   |
|sas2ircu-status                |0.5                         |LSI FusionMPT SAS2            |X    |X   |

Настройки APT
-------------

Не устанавливать рекомендуемые зависимости /etc/apt/apt.conf.d/install-recommends:

    APT::Install-Recommends "false";

Не устанавливать предлагаемые зависимости /etc/apt/apt.conf.d/install-suggests:

    APT::Install-Suggests "false";

Использовать прокси-сервер для скачивания пакетов /etc/apt/apt.conf.d/proxy:

    Acquire::http::Proxy "http://proxy.domain.tld:port/";
    Acquire::https::Proxy "http://proxy.domain.tld:port/";
    Acquire::ftp::Proxy "http://proxy.domain.tld:port/";

Для ограничения кэша пакетов, хранящегося в каталоге /var/cache/apt/archives/, можно создать файл /etc/apt/apt.conf.d/cache с настройкой, ограничивающей размер кэша 200 мегабайтами:

    APT::Cache-Limit "209715200";

Иногда apt не может подключиться к репозиторию и приходится долго-долго ждать, пока он не перейдёт к следующему источнику. Чтобы уменьшить время мучительного ожидания, можно настроить таймауты в файле /etc/apt/apt.conf.d/timeouts:

    Acquire::http::Timeout "5";
    Acquire::https::Timeout "5";
    Acquire::ftp::Timeout "5";

Для того, чтобы по команде `apt-get remove <пакет>` фактически выполнялись действия, выполняемые по команде `apt-get purge <пакет>`, можно создать файл /etc/apt/apt.conf.d/purge со следующим содержимым:

    APT::Get::Purge "true";

При удалении пакета будут автоматически удаляться его файлы конфигруации и файлы с данными.

apt-file
--------

Для поиска пакета по имени файла или просмотра списка файлов в пакете, не установленном в систему, можно воспользоваться утилитой apt-file:

    # apt-get install apt-file

Перед первым использованием нужно обновить базу данных о файлах в пакетах из репозиториев:

    $ apt-file update

Для поиска пакета по имени файла:

    $ apt-file search file

или

    $ apt-file find file

Для просмотра списка файлов в пакете, который не установлен в системе, можно воспользоваться следующей командой:

    $ apt-file list package

Для установленных в системе пакетов то же самое можно сделать при помощи dpkg. Для поиска пакета по имени файла:

    $ dpkg -S file

Для просмотра списка файлов в пакете:

    $ dpkg -L package

Для просмотра списка файлов в не установленном пакете:

    $ dpkg -c ./package-version_architecture.deb

Сборка из deb-src
-----------------

Установка инструментов для сборки:

    # apt-get install dpkg-dev devscripts fakeroot build-essential debhelper quilt equivs

Установка сборочных зависимостей для dsc-файла:

    # mk-build-deps -t 'apt-get --no-install-recommends -y' -i <whatever>.dsc

Или так:

    # apt-get build-dep <whatever>

Распаковка исходников в каталог:

    # dpkg-source -x <whatever>.dsc

Если нужно пропатчить код, вносим изменения.

Описываем, что поменяли:

    # dch -i

Формируем патч к пакету с исходными текстами:

    # dpkg-source --commit

В процессе работы команда спросит желаемое имя патча и поместит его в каталог debian/patches/

Теперь осталось собрать пакеты:

    # dpkg-buildpackage -us -uc -rfakeroot

Если после сборки выяснилось, что патч был не совсем корректен, правим исходный текст снова и обновляем патч:

    # quilt refresh

После этого можно опять собрать пакет при помощи dpkg-buildpackage.

Установка пакетов как на другом компьютере
------------------------------------------

На исходном компьютере:

    $ dpkg --get-selections > selections

Копируем файл selections со старого компьютера на новый.

На новом компьютере:

    # apt-get update
    # apt-get install dselect
    # dpkg --set-selections < selections
    # dselect update
    # dselect install

Очистка системы от ненужных или устаревших пакетов
--------------------------------------------------

Утилита deborphan из одноимённого пакета позволяет находить пакеты с библиотеками, которые не используются ни одним другим пакетом. Все найденные пакеты можно удалить без опаски что-то сломать.

Установим утилиту:

    # apt-get install deborphan

И несколько раз выполним команду, до тех пор, пока она не перестанет удалять пакеты:

    # apt-get remove `deborphan`

Чтобы найти пакеты, которые недоступны через репозиторий, можно воспользоваться утилитой apt-show-versions из одноимённого пакета. Установим его:

    # apt-get install apt-show-versions

И посмотрим на список установленных пакетов, не доступных через репозитории:

    # apt-show-versions | grep 'No avail'

Чтобы удалить все пакеты, кроме указанных вами явно и тех пакетов, от которых они зависят, можно воспользоваться утилитой debfoster из одноимённого пакета. Установим её:

    # apt-get install debfoster

Запустим утилиту:

    # debfoster

Утилита найдёт пакеты, от которых не зависят другие пакеты и спросит, нужны ли вам эти пакеты. Все ненужные пакеты она удалит, а если в результате этого удаления найдутся новые пакеты, от которых ничего не зависит, утилита повторит процедуру - снова задаст вопросы и удалит ненужное. Завершится утилита тогда, когда в системе останутся только нужные пакеты и пакеты, от которых зависят нужные.

Аудит изменений файлов из пакетов
---------------------------------

Чтобы найти файлы, которые были установлены из пакетов, но изменены по сравнению с начальным содержимым:

    $ dpkg --verify

Для проверки используется контрольная сумма, вычисленная по алгоритму md5 и файлы md5sums, идущие в составе пакета.

Решение проблем при обновлениях
-------------------------------

Если обновление пакетов завершается ошибкой:

    При обработке следующих пакетов произошли ошибки:
     grub-pc
    E: Sub-process /usr/bin/dpkg returned an error code (1)

Эту проблему можно решить одной из двух команд:

    # apt-get install -f

Или, если не помогает предыдущая:

    # dpkg --configure --pending

Добавление недостающего ключа репозитория
-----------------------------------------

Если при обновлении списка пакетов, доступных через репозитории, команда apt-get update ругается на недоступность ключа с определённым идентификатором, то установить его можно при помощи команды:

    # apt-key adv --recv-keys --keyserver http://keys.gnupg.net <идентификатор-ключа>

После установки ключа рекомендую сначала проверить данные ключа:

    # apt-key list <идентификатор-ключа>

Если ключ не вызывает сомнений, то можно повторить попытку обновления списка пакетов, доступных через репозитории:

    # apt-get update

Если же ключ кажется вам подозрительным, то его можно удалить при помощи такой команды:

    # apt-get del <идентификатор-ключа>
