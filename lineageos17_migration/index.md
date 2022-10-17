Перенос данных и приложений на новое устройство с помощью adb (LineageOS 17)
============================================================================

Это перевод статьи [Marco Balmer. Migrating data and apps to a new device with adb (LineageOS 17)](https://balmer.name/android/adb-migrating-data-and-apps-lineageos-17/).

[[!tag lineageos android adb backup]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Аннотация
---------

В этой статье описано как перенести приложения и данные со старого смартфона на новый (LineageOS 17.1) с помощью adb pull и adb push.

Требования
----------

При использовании Fairphone и LinageOS 17.1 нужно включить следующие опции:

- Отладка по USB
- Отладка суперпользователем

### Шаг 1,

включить режим суперпользователя в терминале.

    adb root

Снятие резервной копии
----------------------

### Шаг 2,

определить, куда сохранить резервную копию.

    BACKUPDIR="~/"

### Шаг 3,

запустить три задачи adb pull для сохранения трёх видов данных:

- данных пользователя (data/user/0),
- приложений .apk (data/app),
- внутреннего хранилища (mnt/sdcard).

Делается это с помощью следующих команд:

    cd $BACKUPDIR
    adb pull -a data/user/0
    adb pull -a data/app
    adb pull -a mnt/sdcard

### (Необязательный) шаг 4,

Если вам не нужны резервные копии системных приложений, запустите команду:

    rm -rf com.android.* android* com.caf.fmradio org.lineageos* lineageos.platform *qualcomm*

Восстановление из резервной копии
---------------------------------

### Шаг 5,

теперь перейдём к новому устройству, подключив его через кабель USB.

    adb kill-server
    adb root

### Шаг 6,

следующие команды скопируют сохранённое содержимое внутреннего хранилища на новое устройство:

    cd $BACKUPDIR
    adb push sdcard/ /mnt/

### Шаг 7,

следующая команда установит все приложения на новое устройство:

    time find ./app/ -type f -name base.apk -print0 -exec adb install {} \;

### Шаг 8,

следующая команда восстановит данные ваших приложений на новом устройстве:

    adb push 0/ /data/user/

### Шаг 9,

следующие несколько команд исправят права доступа на разделе с данными. Этот шаг необходим потому что мы восстановили данные от имени суперпользователя, но каждое приложение использует собственного пользователя и группу.

    adb shell
    
    # Сгенерируем скрипт для исправления прав доступа по данным из файла /data/system/packages.list:
    cat /data/system/packages.list | awk '{print "chown u0_a" $2-10000 ":u0_a" $2-10000 " /data/data/"$1" -R"}' > /data/media/fix_perms.sh
    sh /data/media/fix_perms.sh
    rm /data/media/fix_perms.sh
    
    exit

### Шаг 10,

перезагрузите устройство и готово.

    adb reboot

Заключительные замечания
------------------------

Восстановить работу некоторых приложений таким образом не получится. Например:

- [Signal](https://signal.org/android/apk)
- [Briar](https://briarproject.org/)
- [Protonmail](https://play.google.com/store/apps/details?id=ch.protonmail.android)

Предлагаем воспользоваться собственными функциями резервного копирования этих приложений.

Сценарий
--------

Пример сценария для съёма полной резервной копии устройства:

    #!/bin/bash
    set -x
    
    if [ -z $1 ];
    then
        echo "Ой!"
        exit 1
    fi
    
    BACKUP_DATE=$(date +%Y-%m-%d-%H%M)
    BACKUPDIR=/srv/backup/shared/${BACKUP_DATE}_backup-fp2-${1}
    
    mkdir -p $BACKUPDIR
    cd $BACKUPDIR || exit $?
    
    # Начинаем
    adb kill-server
    adb start-server
    adb root || exit 1

    BACKUP_SRC_DIRS=(
        'mnt/sdcard'
        'data/app'
        'data/user/0'
    )
    
    i=0
    until [ -z ${BACKUP_SRC_DIRS[i]} ];
    do
        adb pull -a ${BACKUP_SRC_DIRS[i]}
        i=$(( $i + 1 ))
    done

Ссылки
------

- [Преобразование резервной копии .adb в tar-файл](https://stackoverflow.com/questions/15558353/how-can-one-pull-the-private-data-of-ones-own-android-app)
- [Использование adb и смена места установки по умолчанию](https://www.instructables.com/id/Android-The-complete-guide-for-moving-installed-ap/)
- [Пример pm move-package](https://pastebin.com/5HjgmWbJ)
- [Как восстановить права доступа Linux в Android?](https://stackoverflow.com/questions/4831095/how-to-reset-android-data-data-com-xxx-xxx-permissions-linux)
