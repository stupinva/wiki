Резервное копирование по SSH
============================

Сервер резервного копирования
-----------------------------

Генерируем на системе, которая будет осуществлять резервное копирование, пару SSH-ключей:

    $ ssh-keygen
    Generating public/private rsa key pair.
    Enter file in which to save the key (/home/stupin/.ssh/id_rsa): 
    Created directory '/home/stupin/.ssh'.
    Enter passphrase (empty for no passphrase): 
    Enter same passphrase again: 
    Your identification has been saved in /home/stupin/.ssh/id_rsa.
    Your public key has been saved in /home/stupin/.ssh/id_rsa.pub.
    The key fingerprint is:
    97:98:ec:fd:76:f7:ff:a7:e7:e1:39:ad:34:e8:86:8c stupin@fstu
    The key's randomart image is:
    +--[ RSA 2048]----+
    |                 |
    |                 |
    |                 |
    |       . o .     |
    |        S o      |
    |       . o   .   |
    |        .o... o..|
    |        E ooo.ooB|
    |           oo.oO@|
    +-----------------+

В домашнем каталоге пользователя, в подкаталоге .ssh будут созданы файлы ключей id_rsa и id_rsa.pub.

Первый ключ - приватный, с его помощью будет осуществляться аутентификация сервера резервного копирования на резервируемых системах. Не следует хранить этот ключ где-бы то ни было, кроме компьютера, занятого резервным копированием. Сам этот компьютер желательно выделить только для целей резервного копирования и не запускать на нём никаких сервисов, потому что взломав уязвимый сервис взломщик получит доступ к приватному ключу, к резервируемым системам и к резервным копиям этих систем. Думаю, что не стоит объяснять, чем это может быть чревато.

Второй ключ можно свободно размещать в публично, т.к. с его помощью нельзя попасть на компьютер, а можно лишь разрешить подключаться компьютеру, обладающему приватным ключом.

Резервируемые системы
---------------------

Создаём на удалённой системе пользователя, от имени которого будет производиться резервное копирование:

    # useradd -c "User for backup purposes" -d /home/rbackup -U -m -s /bin/sh rbackup
  
    # mkdir /home/rbackup/.ssh
    # chown rbackup:rbackup /home/rbackup/.ssh
    # cat <<END > /home/rbackup/.ssh/authorized_keys
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDwsITVgCQrwuSC0cNA8c/TCIkJ0U0vT3bf8d1hoVzTOP8WtdRfGdPqGoo5+f8iudtSZN+8EokEk+ZfvE4fs020jG3Y86dL7roVGx+fuDcxCdpIlI/PVJOAK/o/V7z9xOjqbP0iFkqp6YYojH+b7ixqw1mUC5zksXqdXsW7RF6PDZ5dlSyqW5/55J3+UZ8Gl5isGEAdcLfT3PF6OcYbyLLsWzlKTKTRobuS01I1h1FuMl1IA0MLXlGCY+yWJk71cQV+kaePhSCXyOIiSAxvMsQpME+Z3quW9h8p5H9I9jXz2I9Ybms/tTTCAg6kvnbGxkzU26yNV7seIdUwiN3/tssh rbackup@srv.domain.tld
    END
    # chown rbackup:rbackup /home/rbackup/.ssh/authorized_keys

Текст от ssh-rsa и до rbackup@srv.domain.tld следует взять из файл сгенерированного публичного ключа `~/.ssh/id_rsa.pub`.

Теперь установим на резервируемой системе sudo:

    # apt-get install sudo

И разрешим при помощи команды visudo пользователю rbackup выполнять несколько команд:

    rbackup ALL=(ALL) NOPASSWD:/usr/bin/rsync --server --sender -vlogDtpre.iLsf . /mnt/, \
                               /usr/bin/rsync --server --sender -logDtpre.iLsf . /mnt/, \
                               /sbin/lvdisplay --noheadings -Co lv_size /dev/vg0/*, \
                               /sbin/lvcreate -L1G -n /dev/vg0/copy -s /dev/vg0/*, \
                               /sbin/lvremove -f /dev/vg0/copy, \
                               /bin/mount /dev/vg0/copy /mnt, \
                               /bin/umount -f /mnt

Команды позволяют сделать снимок LVM-раздела, смонтировать его, скопировать его содержимое, а затем демонтировать и удалить его. В примере предполагается, что на удалённой системе есть только одна группа томов - vg0, снимок всегда будет иметь название copy, а для хранения изменяющихся экстентов основного том LVM будет выделен 1 гигабайт. Если раздел на удалённой системе в процессе резервного копирования будет интенсивно изменяться, выделенного гигабайта может не хватить. В этом случае снимок может досрочно удалиться и резервное копирование завершится ошибкой. При необходимости измените это значение, если разделы на ваших удалённых системах большие и интенсивно меняются.

Не забудем также добавить при помощи visudo опцию, разрешающую запускать команды через sudo скриптам, работающим без виртуального терминала:

    Defaults        !requiretty

Скрипт резервного копирования разделов
--------------------------------------

Скрипт удалённого резервного копирования LVM-томов с удалённой системы виртуализации Xen будет иметь следующий вид:

    #!/bin/sh
  
    backup()
    {
      # Удалённых сервер виртуализации и хост на нём
      XEN=$1
      HOST=$2
  
      # Исходный LVM-раздел и его снимок
      SDISK=/dev/vg0/$HOST-disk
      SSNAP=/dev/vg0/copy
  
      # Целевой LVM-раздел и его снимок
      TDISK=/dev/vg0/$HOST-disk
      TSNAP=/dev/vg0/$HOST-disk-new
  
      printf "%-20s    %-15s    " $XEN $HOST
  
      # Готовим снимок на удалённой системе, заодно узнавая его раздел
      size=`/usr/bin/ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa_backup rbackup@$XEN " \
              /usr/bin/sudo /bin/umount -f /mnt >/dev/null 2>/dev/null ; \
              /usr/bin/sudo /sbin/lvremove -f $SSNAP >/dev/null 2>/dev/null ; \
              /usr/bin/sudo /sbin/lvdisplay --noheadings -Co lv_size $SDISK 2>/dev/null && \
              /usr/bin/sudo /sbin/lvcreate -L1G -n $SSNAP -s $SDISK >/dev/null 2>/dev/null && \
              /usr/bin/sudo /bin/mount $SSNAP /mnt >/dev/null 2>/dev/null"`
      if [ $? -ne 0 ]
      then
        echo "Cannot prepare snapshot"
        /usr/bin/ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa_backup rbackup@$XEN " \
          /usr/bin/sudo /bin/umount -f /mnt >/dev/null 2>/dev/null ; \
          /usr/bin/sudo /sbin/lvremove -f $SSNAP >/dev/null 2>/dev/null"
        return 1
      fi
  
      # Готовим локальный раздел
      /bin/umount -f /mnt >/dev/null 2>/dev/null
      /sbin/lvremove -f $TSNAP >/dev/null 2>/dev/null
      if [ -e $TDISK ]
      then
        /sbin/lvcreate -L1G -n $TSNAP -s /dev/vg0/$2-disk >/dev/null 2>/dev/null && \
        /bin/mount $TSNAP /mnt >/dev/null 2>/dev/null
      else
        /sbin/lvcreate -L$size -n $TSNAP >/dev/null 2>/dev/null && \
        /sbin/mkfs.ext4 $TSNAP >/dev/null 2>/dev/null && \
        /bin/mount $TSNAP /mnt >/dev/null 2>/dev/null
      fi
      if [ $? -ne 0 ]
      then
        echo "Cannot prepare target partition"
        /bin/umount -f /mnt >/dev/null 2>/dev/null
        /sbin/lvremove -f $TSNAP >/dev/null 2>/dev/null
        return 1
      fi
  
      # Копируем снимок с удалённой системы на локальный раздел
      /usr/bin/rsync -e '/usr/bin/ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa_backup' \
        --rsync-path="/usr/bin/sudo /usr/bin/rsync" \
        -a rbackup@$XEN:/mnt/ /mnt/
      if [ $? -ne 0 ]
      then
        echo "Cannot copy snapshot"
        /sbin/lvremove -f $TSNAP >/dev/null 2>/dev/null
        return 1
      fi
  
      /usr/bin/rsync -e '/usr/bin/ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa_backup' \
        rbackup@$XEN:/etc/xen/$HOST.cfg /etc/xen/$HOST.cfg
      if [ $? -ne 0 ]
      then
        echo "Cannot copy config"
        return 1
      fi
  
      # Подчищаем всё за собой на удалённой системе
      /usr/bin/ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa_backup rbackup@$XEN " \
        /usr/bin/sudo /bin/umount -f /mnt >/dev/null 2>/dev/null ; \
        /usr/bin/sudo /sbin/lvremove -f $SSNAP >/dev/null 2>/dev/null"
  
      # Подчищаем всё за собой на локальной системе
      /bin/umount -f /mnt >/dev/null 2>/dev/null
      if [ -e $TDISK ]
      then
        /sbin/lvconvert --merge $TSNAP >/dev/null 2>/dev/null
      else
        /sbin/lvrename $TSNAP $TDISK >/dev/null 2>/dev/null
      fi
  
      echo "OK"
      return 0
    }
  
    date "+%Y-%m-%d %H:%M:%S"
  
    backup xen1.domain.tld mon1
    backup xen1.domain.tld db1-mon
    backup xen1.domain.tld configs
    backup xen1.domain.tld info-db
  
    backup xen2.domain.tld mon2
    backup xen2.domain.tld db2-mon
    backup xen2.domain.tld mgw
    backup xen2.domain.tld info
  
    date "+%Y-%m-%d %H:%M:%S"

Этот скрипт копирует разделы и конфигурацию восьми виртуальных машин с двух серверов виртуализации Xen. При необходимости можно переделать скрипт под другие нужды. При первом запуске скрипт копирует снимок в новый раздел, а при последующих запусках копирует снимок в снимок при помощи rsync, поэтому время резервного копирования должно быть минимальным.
