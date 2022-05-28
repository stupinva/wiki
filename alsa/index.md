Приоритеты звуковых карт в ALSA
===============================

В моём компьютере есть две встроенные аудиокарты:

    $ lspci | grep Audio
    08:00.1 Audio device: Advanced Micro Devices, Inc. [AMD/ATI] Cape Verde/Pitcairn HDMI Audio [Radeon HD 7700/7800 Series]
    0a:00.4 Audio device: Advanced Micro Devices, Inc. [AMD] Device 1487

Первая выводит звук через разъём HDMI, а вторая - на разъёмы "мини-джек". По умолчанию звук воспроизводится через HDMI.

Посмотрим список карт в звуковой подсистеме ALSA:

    $ cat /proc/asound/cards
     0 [HDMI           ]: HDA-Intel - HDA ATI HDMI
                          HDA ATI HDMI at 0xfcf60000 irq 60
     1 [Generic        ]: HDA-Intel - HD-Audio Generic
                          HD-Audio Generic at 0xfc900000 irq 62
     2 [e1300          ]: USB-Audio - eFace 1300
                          eFace 1300 eFace 1300 at usb-0000:0a:00.3-3, high speed

Узнаем строковые идентификаторы звуковых карт:

    $ cat /proc/asound/card0/id
    HDMI
    $ cat /proc/asound/card1/id
    Generic
    $ cat /proc/asound/card2/id
    e1300

Пропишем индексы карт в файл /etc/modprobe.d/alsa-base.conf:

    options snd-hda-intel id=Generic index=0
    options snd-hda-intel id=HDMI index=1
    options snd-usb-audio id=e1300 index=2

Если указанный в конфигурации индекс звуковой карты окажется уже назначенным другой звуковой карте, то звуковая карта с явно указанным индексом не определится. Чтобы не попасть в подобную ситуацию, лучше прописать идентификаторы всех имеющихся звуковых карт, в том числе постоянно подключенных веб-камер с USB-разъёмом, как это сделано в примере выше.

Источник: [[SOLVED] Wrong sound card order in alsa](https://www.linuxquestions.org/questions/linux-hardware-18/wrong-sound-card-order-in-alsa-4175544059/?__cf_chl_jschl_tk__=bc7faa22b8a90d0411d45f700f7a3383a23248f4-1624725240-0-AYUO7DieZAQFvFcCa84kDa1iG8sOPduh9IFNjDQMbx9-RRvua-nvMWkmFR8jxLevxsNNkCRJmCuPlaObbFsLCbtnuPZArRR0i0-AaVOAj7_77HfMY7-JL9xjz7FeU1VQzhVX7yv8poKljiDCrN5wmjsED3VvHanp9suOl373ZJJYd90KNbq1klze9ffXz84ik1GCv19v07SaZ9LVvRKkr9hhuu09Y3EP7GMXrtHTzzePrBeun9tCkkOC-tlk2ylYtBq7lUChVbR05O2ZRNEjlPd-8wrtpoeL6swlqXbe_GaqtUquSJfaQFHLkGw5snmmZUc5Uzvr7J-uy3z7whlqON6kJy62ZPdrJRmIWXFHt6XVNB0D2hsYUXIf44QMn52LpRq5chH-My3mWL3ST6vMKj5W7jBmCBYOJe-ul1KziLwQ6X5tkxjV22E1VStW-PeEBWebxaD9CsmMM7BVRoTyuslx0uhoqlEt9xprlzNNYL15iFTbpd3sSDZ6n3gIKbd-KkbQOadKTRf6dL_oKhutOmv4SRHxhOYoGPG_-p4IsDmk)
