Обновление BIOS и BMC на сервере Supermicro SYS-110P-WR
=======================================================

[[!tag firmware]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Скачивание прошивок
-------------------

Переходим на официальный [сайт Supermicro](https://www.supermicro.com/en/).

Открываем выпадающее меню Support в верхнем правом углу и выпбираем пункт [Resources & Downloads](https://www.supermicro.com/en/support/resources/downloadcenter/swdownload).

В поле "Quick search for your product resources" вводим модель сервера "SYS-110P-WR" и нажимаем кнопку "Submit".

Откроется страница [Product Resource](https://www.supermicro.com/en/support/resources/downloadcenter/SYS-110P-WR), соответствующая серверу модели "SYS-110P-WR":

С этой страницы можно перейти на страницы загрузки [BIOS Downloads](https://www.supermicro.com/en/support/resources/downloadcenter/firmware/SYS-110P-WR/BIOS) и [BMC Firmware Downloads](https://www.supermicro.com/en/support/resources/downloadcenter/firmware/SYS-110P-WR/BMC).

С этих страниц можно скачать архивы с прошивками, утилитой для прошивки и инструкциями по прошиванию:

* [[BIOS_X12SPW-1B62_20231128_1.8_STDsp.zip]]
* [[BMC_X12AST2600-ROT-5201MS_20231220_01.03.11_STDsp.zip]]

Распаковка архивов
------------------

Распакуем архив с прошивкой BIOS:

    $ unzip BIOS_X12SPW-1B62_20231128_1.8_STDsp.zip

В каталоге `BIOS_X12SPW-1B62_20231128_1.8_STDsp` появятся файлы:

* `BIOS_X12SPW-1B62_20231128_1.8_STDsp.bin` - сама прошивка,
* `README.txt` - инструкции по прошивке,
* `SUM.efi` - утилита для прошивки для запуска через UEFI.

Распакуем архив с прошивкой для BMC:

    $ unzip -d BMC_X12AST2600-ROT-5201MS_20231220_01.03.11_STDsp BMC_X12AST2600-ROT-5201MS_20231220_01.03.11_STDsp.zip

В каталоге `BMC_X12AST2600-ROT-5201MS_20231220_01.03.11_STDsp` появятся файлы:

* `BMC_X12AST2600-ROT-5201MS_20231220_01.03.11_STDsp.bin` - сама прошивка,
* `Firmware Update & Recovery for the X12_B12_H12_BH12_ Motherboards_User's Guide_1.0.pdf` - инструкции по прошивке в виде документа PDF,
* `README.txt` - инструкции по прошивке,
* `SUM.efi` - утилита для прошивки для запуска через UEFI.

Подготовка флеш-накопителя
--------------------------

Утилита `SUM.efi` в обоих архивах идентична. Скопируем утилиту и два файла с прошивками на флеш-накопитель:

    $ cp BIOS_X12SPW-1B62_20231128_1.8_STDsp/BIOS_X12SPW-1B62_20231128_1.8_STDsp.bin BMC_X12AST2600-ROT-5201MS_20231220_01.03.11_STDsp/BMC_X12AST2600-ROT-5201MS_20231220_01.03.11_STDsp.bin BMC_X12AST2600-ROT-5201MS_20231220_01.03.11_STDsp/SUM.efi /media/stupin/USB\ DISK/

Прошивка из UEFI
----------------

Для прошивки нужно узнать пароль для доступа к BMC сервера, который можно найти на наклейке на корпусе рядом с текстом `PWD`. В примерах ниже в качестве пароля используются символы `SYDFROESSS`.

Вставим флешку в сервер и загрузим его в оболочку UEFI.

Список файловых систем, доступных UEFI, можно узнать с помощью команды `map`. Как правило, флешка будет фигурировать в этом списке под именем FS0.

В таком случае команды для прошивки BMC и BIOS будут выглядеть следующим образом:

    SUM.efi -I Redfish_HI -u ADMIN -p SYDFROESSS -c UpdateBmc --file FS0:\BMC_X12AST2600-ROT-5201MS_20231220_01.03.11_STDsp.bin
    SUM.efi -I Redfish_HI -u ADMIN -p SYDFROESSS -c UpdateBios --file FS0:\BIOS_X12SPW-1B62_20231128_1.8_STDsp.bin

Пример прошивки BMC:

![Снимок экрана при прошивании BMC](flashing_bmc.jpg)

После прошивки BMC необходимо подождать около 6 минут для загрузки обновлённой системы.

Пример прошивки BIOS:

![Снимок экрана при прошивании BIOS](flashing_bios.jpg)

После прошивки BIOS необходимо перезагрузить сам сервер, например, нажатием кнопки питания. Как вариант - можно добавить к команде прошивки BIOS опцию `--reboot`, которая по завершении процедуры прошивки перезагрузит сервер автоматически.

Использованные материалы
------------------------

* [How to Use UEFI Interactive Shell and Its Common Commands](https://www.sys-hint.com/3893-How-to-Use-UEFI-Interactive-Shell-and-Its-Common-Commands)
