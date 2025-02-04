Использование megacli
=====================

[[!tag megacli]]

Оглавление
----------

[[!toc startlevel=2 levels=3]]

Общие опции
-----------

Универсальные опции, используемые во многих командах:

* `-a<контроллер>` - указание номера RAID-контроллера. Можно указать номер одного контроллера, несколько номеров через запятую или ключевое слово `All` для указания всех имеющихся контроллеров,
* `-L<диск>` - указание номер логического диска. Здесь тоже можно указать номер одного диска, нескольких дисков через запятую или ключевое слово `All` для указания всех имеющихся логических дисков,
* `-PysDrv[<корзина>:<диск>]` - указание физического диска. 

Получение информации об утилите
-------------------------------

Показать список всех команд:

    # megacli -h
    # megacli -help
    # megacli -?

Показать версию утилиты:

    # megacli -v

Показать карткую информацию о системе:

    # megacli -ShowSummary -aAll

Просмотр свойств контроллера
----------------------------

Показать количество RAID-контроллеров:

    # megacli -AdpCount

Показать информацию о RAID-контроллере:

    # megacli -AdpAllinfo -aAll

Показать значение указанного свойства RAID-контроллера (имеется большой список свойств, включая: `BatWarnDsbl` - включено ли предупреждение о неисправности батареи, `AlarmDsply` - включен ли звуковой сигнал при проблемах):

    # megacli -AdpGetProp свойство -aAll

Задать значение указанного свойства RAID-контроллера (имеется большой список свойств, включая `BatWarnDsbl` - отключение предупреждений о состоянии батарее, `AlarmEnbl` - включение звукового сигнала при проблемах, `AlarmDsbl` - отключение звукового сигнала при проблемах, AlarmSilence - отключение звукового сигнала до появления новых проблем):

    # megacli -AdpSetProp -свойство -значение -aAll

Показать информацию об автоматическом перестроении (кроме отображения имеются другие опции):

    # megacli -AdpAutoRbld -Dsply -aAll

Записать кэш контроллера на диски:

    # megacli -AdpCacheFlush -aAll

Установить дату и время:

    # megacli -AdpSetTime ГГГГММДД чч:мм:сс -aAll

Показать настройки BIOS (кроме отображения есть и другие опции):

    # megacli -AdpBIOS -Dsply -aAll

Выставить заводские настройки по умолчанию:

    # megacli -AdpFacDefSet -aAll

Показать дату и время:

    # megacli -AdpGetTime -aAll

Свойства контроллера, относящиеся к патрульному чтению
------------------------------------------------------

Задать опции патрульного чтения (имеется много опций, среди которых: `-Dsbl` - отключить полностью, `-EnblAuto` - включить автоматически, `-EnblMan` - включить вручную, `-Start` - начать, `-Suspend` - приостановить, `-Resume` - возобновить, `-Stop` - закончить, `-Info` - посмотреть текущие настройки):

    # megacli -AdpPR -Info -aAll

Задать интервал задержки патрульного чтения:

    # megacli -AdpPR SetDelay значение -aAll

Опции, относящиеся к BIOS
-------------------------

Показать идентификатор загрузочного виртуального диска:

    # megacli -AdpBootDrive -Get -aAll

Добавить виртуальный диск в список загрузочных:

    # megacli -AdpBootDrive -Set -Lx -aAll

Исключить виртуальный диск из списка загрузочных:

    # megacli -AdpBootDrive -Unset -Lx -aAll

Добавить физический диск в списко загрузочных:

    # megacli -AdpBootDrive -Set -physdrv[E0:S0] -aAll

Исключить физический диск из списка загрузочных:

    # megacli -AdpBootDrive -Unset -physdrv[E0:S0] -aAll

Задать опции состояния BIOS (имеется много команд, среди которых: `-Enbl` - включить BIOS контроллера, `-Dsbl` - выключить BIOS контроллера, `EnblAutoSelectBootLd` - включить автоматический выбор загрузочного логического диска, `DsblAutoSelectBootLd` - выключить автоматический выбор загрузочного логического диска, `-Dsply` - показать текущие настройки):

    # megacli -AdpBIOS -Dsply -aAll

Опции, относящиеся к батарейному модулю
---------------------------------------

Показать информацию о батарейном модуле:

    # megacli -AdpBbuCmd -aALL

Показать информацию о состоянии батарейного модуля:

    # megacli -AdpBbuCmd -GetBbuStatus -aAll

Показать информацию о ёмкости батареи:

    # megacli -AdpBbuCmd -GetBbuCapacityInfo -aAll

Показать информацию о конструкции батарейного модуля:

    # megacli -AdpBbuCmd -GetBbuDesignInfo -aAll

Показать свойства батарейного модуля:

    # megacli -AdpBbuCmd -GetBbuProperties -aAll

Запустить цикл обучения батарейного модуля (цикл обучения заключается в калибровке батарей, запускается контроллером автоматически примерно раз в три месяца):

    # megacli -AdpBbuCmd -BbuLearn -aAll

Переключить батарейный модуль в режим пониженного энергопотребления (модуль выйдет из этого режима через 5 секунд):

    # megacli -AdpBbuCmd -BbuMfgSleep -aAll

Заблокировать запись в ЭСПЗУ газового датчика:

    # megacli -AdpBbuCmd -BbuMfgSeal -aAll

Показать список доступных режимов обучения батареи (среди них могут быть: 4 - обычный 48-часовой режим с видимыми циклами обучения, 1 - 12-часовой с невидимыми циклами обучения, 3 - 24-часовой с невидимыми циклами обучения):

    # megacli -AdpBbuCmd -GetBbuModes -aAll

Задать свойства обучения батареи из файла:

    # megacli -AdpBbuCmd -SetBbuProperties -f<имя_файла> -aAll

Файл со свойствами должен иметь вид:

    autoLearnPeriod : 1800Sec
    nextLearnTime : 12345678Sec seconds past 1/1/2000
    learnDelayInterval: 24hours – Not greater than 7 days
    autoLearnMode: 0
    bbuMode: Mode 3

Где:

* `autoLearnPeriod` - период автообучения,
* `nextLearnTime` - количество секунд с 1 января 2000 года, время начала следующего цикла обучения,
* `learnDelayInterval` - длительность цикла обучения в часах, не более 7 суток,
* `autoLearnMode` - режим автоматического обучения: 0 – включен, 1 - выключен, 2 – выводить предупреждения в журнал событий,
* `bbuMode` - режим обучения батареи (см. выше команду `GetBbuModes` для получения списка доступных режимов).

Команда не документирована, скорее всего задаёт область защиты ЭСПЗУ газового датчика:

    # megacli -AdpBbuCmd -GetGGEEPData Offset [<шестнадцатеричный-адрес>] NumBytes <количество-байт> -aAll

Показать информацию о цикле обучения батареи:

    # megacli -AdpBbuCmd -ScheduleLearn -Info -aAll

Отключить цикл обучения батареи:

    # megacli -AdpBbuCmd -ScheduleLearn -Dsbl -aAll

Задать время начала следующего цикла обучения, указав количество суток и часов до запуска:

    # megacli -AdpBbuCmd -ScheduleLearn -StartTime <сутки> <часы> -aAll

Использованные материалы
------------------------

* [[Intel RAID Controller Command Line Tool 2 User Guide|megacli.pdf]]
* [[MegaRAID SAS Software User Guide|megaraid_sas_software_user_guide.pdf]]
