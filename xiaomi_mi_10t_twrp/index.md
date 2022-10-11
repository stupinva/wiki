Прошивка TWRP на Xiaomi Mi 10T
==============================

TWRP - это инструмент восстановления операционной системы. К сожалению, [официальной версии TWRP для смартфона Xiaomi Mi 10T нет](https://twrp.me/Devices/Xiaomi/), но есть неофициальный.

Неофициальный TWRP самой свежей версии 3.6.2 на момент написания статьи можно взять по ссылке [(update) unofficial twrp 3.6.2 for Xiaomi Mi 10T (Apollo)](https://unofficialtwrp.com/twrp-3-6-2-for-xiaomi-mi-10t-apollo/).

Находим на странице и скачиваем два файла:

* [vbmeta.zip](https://unofficialtwrp.com/wp-content/uploads/2019/11/vbmeta.zip)
* [twrp_3.6.2_Apollo_unofficialtwrp.img](https://mega.nz/file/5fEkESaa#O1zCKE2oumNiGL3LrTERYdg3fWTPKFcGfEN0CTSRqyI)

Перед прошивкой TWRP необходимо разблокировать загрузчик устройства. Как это сделать, описано в статье [[Разблокировка загрузчика Xiaomi|xiaomi_bootloader_unlock]].

Для прошивки обновления нам понадобится персональный компьютер и USB-кабель. Подсоединяем устройство к компьютеру с помощью USB-кабеля и переводим устройство в режим загрузчика Fastboot. Для этого выключаем устройство, после чего включаем одновременным нажатием кнопки включения и кнопки убавления громкости.

Я пользуюсь компьютером под управлением операционной системы Debian GNU/Linux, поэтому опишу процедуру проверки применительно к этой системе.

Устанавливаем в систему пакет `fastboot`:

    # apt-get install fastboot

Распаковываем файл `vbmeta.zip`:

    $ unzip vbmeta.zip

После распаковки в текущем каталоге должен появиться файл `vbmeta.img`.

Отключаем `Android Verified Boot`:

    $ fastboot flash vbmeta vbmeta.img
    $ fastboot erase userdata

Прошиваем TWRP:

    $ fastboot flash recovery twrp_3.6.2_Apollo_unofficialtwrp.img

Отправляем устройство в перезагрузку:

    $ fastboot reboot

В моём случае процедура прошивки выглядела следующим образом:

    $ unzip vbmeta.zip 
    Archive:  vbmeta.zip
      inflating: vbmeta.img              
    $ fastboot flash vbmeta vbmeta.img 
    Sending 'vbmeta' (4 KB)                            OKAY [  0.009s]
    Writing 'vbmeta'                                   OKAY [  0.011s]
    Finished. Total time: 0.028s
    $ fastboot erase userdata
    ******** Did you mean to fastboot format this f2fs partition?
    Erasing 'userdata'                                 OKAY [  0.399s]
    Finished. Total time: 0.406s
    $ fastboot flash recovery twrp_3.6.2_Apollo_unofficialtwrp.img 
    Sending 'recovery' (131072 KB)                     OKAY [  3.476s]
    Writing 'recovery'                                 OKAY [  0.405s]
    Finished. Total time: 4.027s
    $ fastboot reboot
    Rebooting                                          OKAY [  0.000s]
    Finished. Total time: 0.201s

Теперь для того, чтобы попасть в установленный TWRP, нужно выключить смартфон, а затем включить его одновременным нажатием кнопок включения и прибавления громкости.

После установки TWRP загружается с установленным по умолчанию китайским языком. Включить английский язык можно следующим образом, изображённым на видео:

[[twrp_chinese_to_english.mp4]]

Использованные материалы
------------------------

* [(update) unofficial twrp 3.6.2 for Xiaomi Mi 10T (Apollo)](https://unofficialtwrp.com/twrp-3-6-2-for-xiaomi-mi-10t-apollo/)
* [TWRP for Xiaomi Mi 10i / Mi 10T Lite / Redmi Note 9 Pro 5G](https://twrp.me/xiaomi/xiaomimi10i.html)
