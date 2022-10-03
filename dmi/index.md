Определение модели сервера
==========================

Для определения модели сервера нужно определить модель материнской платы.

В Linux для этого можно воспользоваться следующей командой:

    $ cat /sys/devices/virtual/dmi/id/board_vendor /sys/devices/virtual/dmi/id/board_name
    Intel Corporation
    S3420TH

Если указанная команда сообщила об отсутствии файлов, то можно попробовать установить пакет `dmidecode` с одноимённой утилитой и посмотреть в начало вывода следующей команды:

    # dmidecode | grep -E 'Manufacturer|Product Name'

Во FreeBSD эту же информацию можно извлечь такой командой:

    $ kenv smbios.system.maker ; kenv smbios.system.product
    Intel Corporation
    S1200BTL

Далее при помощи таблицы по модели материнской платы определяем модель сервера:

|Модель материнской платы   |Модель сервера                                |
|---------------------------|----------------------------------------------|
|Intel Corporation S5500WB  |Intel Server System SR1690WB                  |
|Intel Corporation S1200BTL |Intel Server System R1304BTLSHBN              |
|Intel Corporation S3000AH  |Intel Server System SR1530AH                  |
|Intel Corporation S3420GP  |Intel Server System SR1630GP                  |
|Intel Corporation S3420TH  |Intel Server System ST1604TH                  |
|Intel Corporation S2600GZ  |Intel Server System R1208GZ4GC / R2312GZ4GC4  |
|Intel Corporation S2600WTTR|Intel Server System R2308WTTYSR               |
|Intel Corporation S2600WFT |Intel Server System R1208WFTYS                |

Если определилась материнская плата Intel Corporation S3420TH, то это сервер модели Intel Server System ST1604TH, в который вставлено 2 материнские платы Intel Spare Board FSR1640BRD, каждая из которых логически делится на две независимые материнские платы модели Intel Corporation S3420TH. На этом физическом сервере может работать 4 логически независимых сервера.
