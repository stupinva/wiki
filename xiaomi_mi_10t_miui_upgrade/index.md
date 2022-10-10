Обновление операционной системы MIUI на Xiaomi Mi 10T
=====================================================

На купленном мной смартфоне Xiaomi Mi 10 была установлена операционная система MIUI 12 на базе Android 10. В этой статье рассматривается процедура обновления операционной системы до MIUI 13 на базе Android 12.

Перед обновлением операционной системы необходимо разблокировать загрузчик устройства. Как это сделать, описано в статье [[Разблокировка загрузчика Xiaomi|xiaomi_bootloader_unlock]].

Для прошивки обновления нам понадобится персональный компьютер и USB-кабель. Подсоединяем устройство к компьютеру с помощью USB-кабеля и переводим устройство в режим загрузчика Fastboot. Для этого выключаем устройство, после чего включаем одновременным нажатием кнопки включения и кнопки убавления громкости.

Я пользуюсь компьютером под управлением операционной системы Debian GNU/Linux, поэтому опишу процедуру проверки применительно к этой системе.

Устанавливаем в систему пакет fastboot:

    # apt-get install fastboot

Далее заходим на страницу [Прошивки Xiaomi Mi 10T / 10T Pro](https://miuirom.org/ru/phones/mi-10t-and-mi-10t-pro) и переходим в раздел с [прошивками для России](https://miuirom.org/ru/phones/mi-10t-and-mi-10t-pro#Russia) и скачиваем файл Fastboot ROM с расширением tgz.

Распаковываем скачанный архив:

    $ tar xzvf apollo_ru_global_images_V13.0.3.0.SJDRUXM_20220712.0000.00_12.0_global_14d45eae7f.tgz

Переходим в каталог с распакованными файлами и запускаем скрипт `flash_all.sh`:

    $ cd apollo_ru_global_images_V13.0.3.0.SJDRUXM_20220712.0000.00_12.0_global
    $ ./flash_all.sh

В процессе работы скрипта выводятся сообщения о перезаписываемых разделах флеш-памяти устройства:

    product: apollo
    Erasing 'boot'                                     OKAY [  0.018s]
    Finished. Total time: 0.023s
    Sending 'crclist' (0 KB)                           OKAY [  0.010s]
    Writing 'crclist'                                  OKAY [  0.004s]
    Finished. Total time: 0.046s
    Sending 'xbl_4' (3458 KB)                          OKAY [  0.097s]
    Writing 'xbl_4'                                    OKAY [  0.167s]
    Finished. Total time: 0.325s
    Sending 'xbl_config_4' (99 KB)                     OKAY [  0.012s]
    Writing 'xbl_config_4'                             OKAY [  0.009s]
    Finished. Total time: 0.044s
    Sending 'xbl_5' (3482 KB)                          OKAY [  0.095s]
    Writing 'xbl_5'                                    OKAY [  0.183s]
    Finished. Total time: 0.335s
    Sending 'xbl_config_5' (99 KB)                     OKAY [  0.008s]
    Writing 'xbl_config_5'                             OKAY [  0.009s]
    Finished. Total time: 0.028s
    Sending 'abl' (204 KB)                             OKAY [  0.009s]
    Writing 'abl'                                      OKAY [  0.009s]
    Finished. Total time: 0.042s
    Sending 'tz' (3112 KB)                             OKAY [  0.091s]
    Writing 'tz'                                       OKAY [  0.115s]
    Finished. Total time: 0.268s
    Sending 'hyp' (434 KB)                             OKAY [  0.017s]
    Writing 'hyp'                                      OKAY [  0.018s]
    Finished. Total time: 0.084s
    Sending 'devcfg' (52 KB)                           OKAY [  0.011s]
    Writing 'devcfg'                                   OKAY [  0.003s]
    Finished. Total time: 0.028s
    Sending 'storsec' (20 KB)                          OKAY [  0.007s]
    Writing 'storsec'                                  OKAY [  0.002s]
    Finished. Total time: 0.030s
    Sending 'bluetooth' (412 KB)                       OKAY [  0.022s]
    Writing 'bluetooth'                                OKAY [  0.018s]
    Finished. Total time: 0.067s
    Sending 'cmnlib' (387 KB)                          OKAY [  0.014s]
    Writing 'cmnlib'                                   OKAY [  0.018s]
    Finished. Total time: 0.050s
    Sending 'cmnlib64' (500 KB)                        OKAY [  0.025s]
    Writing 'cmnlib64'                                 OKAY [  0.021s]
    Finished. Total time: 0.075s
    Sending 'modem' (278828 KB)                        OKAY [  7.460s]
    Writing 'modem'                                    OKAY [ 10.668s]
    Finished. Total time: 24.228s
    Sending 'dsp' (65536 KB)                           OKAY [  1.740s]
    Writing 'dsp'                                      OKAY [  2.473s]
    Finished. Total time: 5.649s
    Sending 'keymaster' (257 KB)                       OKAY [  0.011s]
    Writing 'keymaster'                                OKAY [  0.013s]
    Finished. Total time: 0.076s
    Sending 'logo' (60788 KB)                          OKAY [  1.627s]
    Writing 'logo'                                     OKAY [  2.312s]
    Finished. Total time: 5.257s
    Sending 'featenabler' (84 KB)                      OKAY [  0.010s]
    Writing 'featenabler'                              OKAY [  0.002s]
    Finished. Total time: 0.039s
    Sending 'misc' (8 KB)                              OKAY [  0.008s]
    Writing 'misc'                                     OKAY [  0.001s]
    Finished. Total time: 0.028s
    Sending 'aop' (198 KB)                             OKAY [  0.014s]
    Writing 'aop'                                      OKAY [  0.009s]
    Finished. Total time: 0.040s
    Sending 'qupfw' (52 KB)                            OKAY [  0.012s]
    Writing 'qupfw'                                    OKAY [  0.019s]
    Finished. Total time: 0.051s
    Sending 'uefisecapp' (121 KB)                      OKAY [  0.006s]
    Writing 'uefisecapp'                               OKAY [  0.007s]
    Finished. Total time: 0.039s
    Sending 'multiimgoem' (32 KB)                      OKAY [  0.003s]
    Writing 'multiimgoem'                              OKAY [  0.009s]
    Finished. Total time: 0.033s
    Sending sparse 'super' 1/9 (727228 KB)             OKAY [ 34.879s]
    Writing 'super'                                    OKAY [  0.001s]
    Sending sparse 'super' 2/9 (760304 KB)             OKAY [ 26.524s]
    Writing 'super'                                    OKAY [  0.001s]
    Sending sparse 'super' 3/9 (786336 KB)             OKAY [ 25.783s]
    Writing 'super'                                    OKAY [  0.001s]
    Sending sparse 'super' 4/9 (786352 KB)             OKAY [ 23.892s]
    Writing 'super'                                    OKAY [  0.001s]
    Sending sparse 'super' 5/9 (786328 KB)             OKAY [ 24.863s]
    Writing 'super'                                    OKAY [  0.001s]
    Sending sparse 'super' 6/9 (782168 KB)             OKAY [ 24.032s]
    Writing 'super'                                    OKAY [  0.001s]
    Sending sparse 'super' 7/9 (769232 KB)             OKAY [ 23.052s]
    Writing 'super'                                    OKAY [  0.001s]
    Sending sparse 'super' 8/9 (767692 KB)             OKAY [ 21.911s]
    Writing 'super'                                    OKAY [  0.001s]
    Sending sparse 'super' 9/9 (716072 KB)             OKAY [ 21.691s]
    Writing 'super'                                    OKAY [  0.001s]
    Finished. Total time: 228.347s
    Sending 'exaid' (1 KB)                             OKAY [  0.009s]
    Writing 'exaid'                                    OKAY [  0.001s]
    Finished. Total time: 11.584s
    Sending 'vbmeta' (4 KB)                            OKAY [  0.003s]
    Writing 'vbmeta'                                   OKAY [  0.001s]
    Finished. Total time: 0.022s
    Sending 'dtbo' (32768 KB)                          OKAY [  0.928s]
    Writing 'dtbo'                                     OKAY [  1.252s]
    Finished. Total time: 2.754s
    Sending 'vbmeta_system' (4 KB)                     OKAY [  0.010s]
    Writing 'vbmeta_system'                            OKAY [  0.001s]
    Finished. Total time: 0.031s
    Sending 'cache' (152 KB)                           OKAY [  0.011s]
    Writing 'cache'                                    OKAY [  0.008s]
    Finished. Total time: 0.037s
    Erasing 'metadata'                                 OKAY [  0.002s]
    Finished. Total time: 0.009s
    Sending 'userdata' (772684 KB)                     OKAY [ 23.254s]
    Writing 'userdata'                                 OKAY [ 27.029s]
    Finished. Total time: 50.462s
    Sending 'recovery' (131072 KB)                     OKAY [  3.490s]
    Writing 'recovery'                                 OKAY [  4.983s]
    Finished. Total time: 25.246s
    Sending 'cust' (471880 KB)                         OKAY [ 13.624s]
    Writing 'cust'                                     OKAY [ 16.506s]
    Finished. Total time: 30.247s
    Sending 'boot' (131072 KB)                         OKAY [  3.551s]
    Writing 'boot'                                     OKAY [  5.073s]
    Finished. Total time: 19.285s
    Rebooting                                          OKAY [  0.000s]
    Finished. Total time: 0.201s

После установки обновления убеждаемся, что на смартфоне установлена операционная система MIUI 13 на базе Android 12:

[[xiaomi_miui13.jpg]]
