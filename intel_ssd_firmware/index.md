Обновление прошивок твердотельных накопителей Intel
===================================================

[[!tag ssd intel firmware debian]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

Для обновления фирменного программного обеспечения на твердотельных накопителях Intel существует утилита Intel SSD Firmware Update Tool:

* [Intel® SSD Firmware Update Tool](https://www.intel.com/content/www/us/en/download/17903/intel-ssd-firmware-update-tool.html)

Однако, не так давно Intel продала направление бизнеса твердотельных накопителей подразделению Solidigm компании SK Hynix:

* [Intel продает бизнес SSD подразделению SK Hynix Solidigm](https://www.hardwareluxx.ru/index.php/news/hardware/festplatten/52418-intel-prodaet-biznes-ssd-podrazdeleniyu-sk-hynix-solidigm.html)
* [SK Hynix выделила бывшее подразделение твердотельников Intel в бренд Solidigm](https://habr.com/ru/news/599091/)

И теперь для работы с этими твердотельными накопителями, а также для обновления их фирменного программного обеспечения выпускается новая утилита:

* [Solidigm™ Storage Tool](https://www.solidigm.com/us/en/support-page/drivers-downloads/ka-00085.html)

Установка утилиты
-----------------

Для установки утилиты в операционной системе Debian можно скачать zip-архив с deb-пакетом по ссылке:

    $ wget https://sdmsdfwdriver.blob.core.windows.net/files/kba-gcc/drivers-downloads/ka-00085--sst/sst--1-9/sst-cli-linux-deb--1-9.zip

Распакуем архив, в котором помимо deb-пакета также можно найти документы pdf с инструкциями по установке и использованию утилиты:

    $ unzip sst-cli-linux-deb--1-9.zip

Установим deb-пакет в систему:

    # dpkg -i sst_1.9.251-0_amd64.deb

Посмотреть, что находится внутри пакета, можно с помощью следующей команды:

    $ dpkg -L sst

Просмотр списка накопителей
---------------------------

Посмотреть список накопителей, имеющихся в системе, с помощью утилиты можно следующим образом:

    # sst show -ssd
    
    - WD-WX72A90JDX4C -
    
    Capacity : 500.11 GB (500,107,862,016 bytes)
    DevicePath : /dev/sg0
    DeviceStatus : Unknown
    Firmware : 01.01A01
    FirmwareUpdateAvailable : Please contact Customer Support for further assistance at the following website: https://www.solidigm.com/support-page.html.
    Index : 0
    MaximumLBA : 976773167
    ModelNumber : WDC WD5000LPSX-00A6WT0
    SMARTEnabled : True
    SectorDataSize : 512
    SerialNumber : WD-WX72A90JDX4C
    
    - PHYG103402N71P9DGN -
    
    Capacity : 1.92 TB (1,920,383,410,176 bytes)
    DevicePath : /dev/sg1
    DeviceStatus : Healthy
    Firmware : XCV10132
    FirmwareUpdateAvailable : XCV10165
    Index : 1
    MaximumLBA : 3750748847
    ModelNumber : INTEL SSDSC2KG019T8
    PercentOverProvisioned : 100.00
    ProductFamily : Intel SSD DC S4610 Series
    SMARTEnabled : True
    SectorDataSize : 512
    SerialNumber : PHYG103402N71P9DGN
    
    - BTYG02110CY61P9DGN -
    
    Capacity : 1.92 TB (1,920,383,410,176 bytes)
    DevicePath : /dev/sg2
    DeviceStatus : Healthy
    Firmware : XCV10120
    FirmwareUpdateAvailable : XCV10165
    Index : 2
    MaximumLBA : 3750748847
    ModelNumber : INTEL SSDSC2KG019T8
    PercentOverProvisioned : 100.00
    ProductFamily : Intel SSD DC S4610 Series
    SMARTEnabled : True
    SectorDataSize : 512
    SerialNumber : BTYG02110CY61P9DGN
    
    - WD-WX22A425H0DP -
    
    Capacity : 500.11 GB (500,107,862,016 bytes)
    DevicePath : /dev/sg3
    DeviceStatus : Unknown
    Firmware : 01.01A01
    FirmwareUpdateAvailable : Please contact Customer Support for further assistance at the following website: https://www.solidigm.com/support-page.html.
    Index : 3
    MaximumLBA : 976773167
    ModelNumber : WDC WD5000LPSX-22A6WT0
    SMARTEnabled : True
    SectorDataSize : 512
    SerialNumber : WD-WX22A425H0DP
    
    - PHYG050602X61P9DGN -
    
    Capacity : 1.92 TB (1,920,383,410,176 bytes)
    DevicePath : /dev/sg4
    DeviceStatus : Healthy
    Firmware : XCV10132
    FirmwareUpdateAvailable : XCV10165
    Index : 4
    MaximumLBA : 3750748847
    ModelNumber : INTEL SSDSC2KG019T8
    PercentOverProvisioned : 100.00
    ProductFamily : Intel SSD DC S4610 Series
    SMARTEnabled : True
    SectorDataSize : 512
    SerialNumber : PHYG050602X61P9DGN
    
    - BTYG02110GKL1P9DGN -
    
    Capacity : 1.92 TB (1,920,383,410,176 bytes)
    DevicePath : /dev/sg5
    DeviceStatus : Healthy
    Firmware : XCV10120
    FirmwareUpdateAvailable : XCV10165
    Index : 5
    MaximumLBA : 3750748847
    ModelNumber : INTEL SSDSC2KG019T8
    PercentOverProvisioned : 100.00
    ProductFamily : Intel SSD DC S4610 Series
    SMARTEnabled : True
    SectorDataSize : 512
    SerialNumber : BTYG02110GKL1P9DGN
    
    - PHYG103402PJ1P9DGN -
    
    Capacity : 1.92 TB (1,920,383,410,176 bytes)
    DevicePath : /dev/sg6
    DeviceStatus : Healthy
    Firmware : XCV10132
    FirmwareUpdateAvailable : XCV10165
    Index : 6
    MaximumLBA : 3750748847
    ModelNumber : INTEL SSDSC2KG019T8
    PercentOverProvisioned : 100.00
    ProductFamily : Intel SSD DC S4610 Series
    SMARTEnabled : True
    SectorDataSize : 512
    SerialNumber : PHYG103402PJ1P9DGN
    
    - PHYG051000V11P9DGN -
    
    Capacity : 1.92 TB (1,920,383,410,176 bytes)
    DevicePath : /dev/sg7
    DeviceStatus : Healthy
    Firmware : XCV10132
    FirmwareUpdateAvailable : XCV10165
    Index : 7
    MaximumLBA : 3750748847
    ModelNumber : INTEL SSDSC2KG019T8
    PercentOverProvisioned : 100.00
    ProductFamily : Intel SSD DC S4610 Series
    SMARTEnabled : True
    SectorDataSize : 512
    SerialNumber : PHYG051000V11P9DGN
    
Накопители, для которых имеется обновление программного обеспечения, можно определить по строчкам следующего вида:

    Firmware : XCV10132
    FirmwareUpdateAvailable : XCV10165

Если же на накопителе установлено актуальное программное обеспечение, то эти строчки будут иметь следующий вид:

    Firmware : XCV10165
    FirmwareUpdateAvailable : The selected drive contains current firmware as of this tool release.

Обновление программного обеспечения накопителей
-----------------------------------------------

Обновим программное обеспечение накопителей, указывая в качестве идентификатора очередного накопителя значение из пол "Index":

    # sst load -ssd 4
    WARNING! You have selected to update the drives firmware! 
    Proceed with the update? (Y|N): Y
    Checking for firmware update...
    
    - Intel SSD DC S4610 Series PHYG050602X61P9DGN -
    
    Status : Firmware updated successfully. Please reboot the system.
    
    # sst load -ssd 5
    WARNING! You have selected to update the drives firmware! 
    Proceed with the update? (Y|N): Y
    Checking for firmware update...
    
    - Intel SSD DC S4610 Series BTYG02110GKL1P9DGN -
    
    Status : Firmware updated successfully. Please reboot the system.
    
    # sst load -ssd 6
    WARNING! You have selected to update the drives firmware! 
    Proceed with the update? (Y|N): Y
    Checking for firmware update...
    
    - Intel SSD DC S4610 Series PHYG103402PJ1P9DGN -
    
    Status : Firmware updated successfully. Please reboot the system.
    
    # sst load -ssd 7
    WARNING! You have selected to update the drives firmware! 
    Proceed with the update? (Y|N): Y
    Checking for firmware update...
    
    - Intel SSD DC S4610 Series PHYG051000V11P9DGN -
    
    Status : Firmware updated successfully. Please reboot the system.

После установки обновлений необходимо перезагрузить сервер:
    
    # reboot
