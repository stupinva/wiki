Разблокировка загрузчика Xiaomi
===============================

[[!tag fastboot android xiaomi miui]]

Введение
--------

На смартфоны Xiaomi производитель устанавливает собственную операционную систему MIUI, основанную на операционной системе Android. С помощью штатного функционала операционной системы можно установить обновления, но нельзя установить новый релиз операционной системы или другую операционную систему. Для этого приходится прибегать к функциям загрузчика, который может взаимодействовать с персональным компьютером через шнур USB. Однако при помощи загрузчика можно легко повредить операционную систему и поэтому производитель блокирует доступ к загрузчику.

Однако производитель позволяет разблокировать загрузчик, если вы готовы лишиться гарантии и взять ответственность за исправность устройства на себя. Для этого нужно зарегистрироваться на официальном сайте производителя и привязать устройство к своей учётной записи, после чего появляется возможность разблокировать устройство при помощи специальной утилиты.

Для начала проверим, заблокирован ли загрузчик.

Проверка состояния загрузчика
-----------------------------

Проверить, заблокирован ли загрузчик, можно одним из трёх способов.

### Способ 1

Сначала включим режим разработчика:

1. Открываем настройки,
2. Выбираем пункт "О телефоне",
3. Пять раз нажимаем на строчку "Версия MIUI".

Если всё было сделано правильно, то на экране должно появиться всплывающее сообщение "Вы успешно стали разработчиком".

Для проверки, заблокирован ли загрузчик, делаем следующее:

1. Открываем настройки,
2. Выбираем пункт "Расширенные настройки",
3. Выбираем пункт "Для разработчиков",
4. Выбираем пункт "Статус Mi Unlock".

Вы попадёте на экран статуса блокировки загрузчика, который выглядит следующим образом в случаях, когда загрузчик заблокирован и разблокирован соответственно:

[[xiaomi_bootloader_status.jpg]]

### Способ 2

Выключаем устройство. Включаем снова и внимательно следим за происходящим на экране. Если загрузчик заблокирован или разблокирован, то в процессе загрузки устройства на экране можно будет наблюдать одну из двух соответствующих картин:

[[xiaomi_reload_bootloader_status.jpg]]

### Способ 3

Для этого способа проверки нам понадобится персональный компьютер и USB-кабель. Подсоединяем устройство к компьютеру с помощью USB-кабеля и переводим устройство в режим загрузчика Fastboot. Для этого выключаем устройство, после чего включаем одновременным нажатием кнопки включения и кнопки убавления громкости.

Я пользуюсь компьютером под управлением операционной системы Debian GNU/Linux, поэтому опишу процедуру проверки применительно к этой системе.

Устанавливаем в систему пакет `fastboot`:

    # apt-get install fastboot

Далее воспользуемся следующей командой:

    # fastboot oem device-info

В моём случае экран выглядел следующим образом:

[[xiaomi_fastboot_oem_device-info.png]]

Приведённые ниже две строчки говорят о том, что загрузчик разблокирован:

    (bootloader) Device unlocked: true
    (bootloader) Device critical unlocked: true

Разблокировка загрузчика
------------------------

Для разблокировки загрузчика нам понадобится создать учётную запись Mi, привязать к ней устройство и разблокировать его с помощью Windows-программы.

### Шаг 1. Создание учётной записи Mi

Для создания учётной записи понадобится доступ в интернет. Действуем следующим образом:

1. Заходим в настройки,
2. Выбираем "Mi аккаунт",
3. Заполняем предложенные поля, привязывая учётную запись к номеру телефона или ящику электронной почты.

### Шаг 2. Привязка устройства к учётной записи Mi

Сначала включим режим разработчика:

1. Открываем настройки,
2. Выбираем пункт "О телефоне",
3. Пять раз нажимаем на строчку "Версия MIUI".

Если всё было сделано правильно, то на экране должно появиться всплывающее сообщение "Вы успешно стали разработчиком".

Для проверки, заблокирован ли загрузчик, делаем следующее:

1. Открываем настройки,
2. Выбираем пункт "Расширенные настройки",
3. Выбираем пункт "Для разработчиков",
4. Выбираем пункт "Статус Mi Unlock",
5. Следуем указаниям для привязки устройства к учётной записи Mi.

Если всё было сделано верно, в итоге появится сообщение об успешной привязке устройства к учётной записи.

### Шаг 3. Разблокировка загрузчика

Нам понадобится персональный компьютер под упавлением Windows 7 или новее, а также USB-кабель. Подсоединяем устройство к компьютеру с помощью USB-кабеля и переводим устройство в режим загрузчика Fastboot. Для этого выключаем устройство, после чего включаем одновременным нажатием кнопки включения и кнопки убавления громкости.

Скачиваем утилиту [Mi Flash Unlock Tool версии 5.5.224.55](https://xiaomitools.com/download/mi-flash-unlock-tool-v5-5-224-55/) для операционной системы Windows. Другие версии утилиты, в том числе более новые, могут отказаться разблокировать устройство.

Далее распаковываем архив и запускаем файл `miflash_unlock.exe`. Входим в учётную запись Mi, выбираем Unlock. Попытка разблокировки может завершиться одним из трёх исходов.

Я пробовал разблокировать устройство при помощи самой свежей утилиты, скачанной с официального сайта Xiaomi и получил сообщение о необходимости подождать 131 час:

[[xiaomi_unlock_131_hours_later.jpg]]

>Couldn't unlock. Please unlock 131 hours later. And do not add your acoount in MIUI again, otherwise you will wait from scratch

По истечении указанного времени я попытался разблокировать устройство снова и на этот раз получил сообщение об ошибке:

[[xiaomi_could_not_unlock.jpg]]

>Couldnt't unlock. Please use the common user tool on the official website.

Когда же я воспользовался утилитой указанной выше версии 5.5.224.55, то получил следующее сообщение:

[[xiaomi_unlocked_successfully.jpg]]

>Unlocked successfully

После перезагрузки устройства все данные на нём были удалены, а настройки сброшены. Устройство предлагало настроить доступ в интернет через WiFi и пройти процедуру настройки, которую я уже проходил при первом включении устройства.

Использованные материалы
------------------------

* [Как разблокировать и заблокировать загрузчик Xiaomi: расширенные инструкции пользователя](https://digitalsquare.ru/ctati/kak-razblokirovat-i-zablokirovat-zagruzchik-xiaomi.html)
* [Разблокировка загрузчиков XIAOMI](https://4pda.to/forum/index.php?showtopic=721838)
