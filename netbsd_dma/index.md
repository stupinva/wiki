Локальный SMTP-ретранслятор dma в NetBSD
========================================

После Postfix для отправки писем с серверов администратору я нашёл и стал пользоваться более легковесной альтернативой - nullmailer. Но и nullmailer не является образцом минимализма, т.к. зависит от нескольких других пакетов. Мне хотелось найти более лёгкую замену nullmailer, вроде программ ssmtp или esmtp, но с поддержкой очереди писем, т.к. я не хотел терять письма при недоступности удалённого SMTP-сервера. Наиболее подходящей альтернативной мне показался dma.

dma - это минимальный почтовый сервер, разработанный для операционной системы Dragonfly BSD. Полное имя этого почтового сервера - Dragonfly Mail Agent. Этот почтовый сервер способен доставлять почту в mbox-файлы локальных пользователей или пересылать её на внешний SMTP-сервер. Фактически, dma зависит только от openssl и, в отличие от nullmailer, написан на чистом Си, а не на C++.

Установка
---------

Установить dma можно из pkgsrc wip/dma:

    # cd /usr/pkgsrc/wip/dma
    # make install

dma не имеет зависимостей от каких-либо других пакетов и для его работы достаточно средств, имеющихся в базовой системе NetBSD.

Устранение проблем
------------------

В нынешнем pkgsrc неправильно выставлены права доступа к исполняемому файлу /usr/pkg/sbin/dma. Подсмотреть правильные права доступа можно в системе ports FreeBSD в файле [pkg-plist](https://cgit.freebsd.org/ports/plain/mail/dma/pkg-plist). Исправить их можно следующим образом:

    # chown root:dma /usr/pkg/sbin/dma
    # chmod =rx,g+s /usr/pkg/sbin/dma

Если этого не сделать, то можно столкнуться с ситуацией нехватки прав доступа к каталогу `/var/spool/dma`, в котором находится очередь писем, описанной по ссылке [
dragonfly mail agent (dma): dpkg-reconfigure dma causes permissions of /var/spool/dma to change ](https://bugs.launchpad.net/ubuntu/+source/dma/+bug/1430983), которая проявляется в виде ошибок следующего вида:

    $ echo test | mail -s test root
    sendmail: can not create temp file in `/var/spool/dma': Permission denied

Я уже отправил [[заплатку|dma.patch]] для pkgsrc wip/dma его автору - Кристиану Коху. После применения заплатки необходимость в устранении проблем должна пропасть.

Настройка
---------

После установки в каталоге `/usr/pkg/etc/dma` появятся примеры файлов конфигурации `dma.conf` и `auth.conf`. Первым делом скроем файл `auth.conf` с учётными данными для подключения к SMTP-серверу:

    # chmod o= /usr/pkg/etc/dma/auth.conf

Отредактируем настройки в файле `/usr/pkg/etc/dma/dma.conf`, например, следующим образом:

    SMARTHOST mail.stupin.su
    PORT 587
    ALIASES /etc/mail/aliases
    AUTHPATH /usr/pkg/etc/dma/auth.conf
    SECURETRANSFER
    STARTTLS
    MAILNAME sysbuild.vm.stupin.su
    MASQUERADE sysbuild@stupin.su

Теперь отредактируем файл `/usr/pkg/etc/dma/dma.conf` следующим образом:

    sysbuild@stupin.su|mail.stupin.su:secret_p4$$w0rd

И, наконец, осталось прописать в файл /etc/mailer.conf следующие строки:

    sendmail        /usr/pkg/sbin/dma
    send-mail       /usr/pkg/sbin/dma
    mailq           /usr/pkg/sbin/dma

В файле `/etc/mail/aliases` для доставки писем на почтовый ящик системного администратора нужно прописать этот почтовый ящик для пользователей `root` и `operator`:

    root: vladimir@stupin.su
    operator: vladimir@stupin.su

Программа не преобразует файл `/etc/mail/aliases` в какое-либо двоичное представление, поэтому в файле `/etc/mailer.conf` не нужно настраивать подмену для программы `newaliases`.

Обработка очереди
-----------------

Новые письма помещаются в очередь в каталоге `/var/spool/dma/`, сразу после чего происходит попытка отправить на удалённый SMTP-сервер все письма из очереди. Если письмо не удалось отправить сразу, то следующая попытка отправить его произойдёт при добавлении в очередь нового письма. Чтобы письма не застревали в очереди надолго, можно добавить в планировщик задачу обработки очереди. Для этого запустим `crontab -e` от имени пользователя `root` и добавим задачу для ежечасного повтора обработки очереди:

    @hourly /usr/pkg/sbin/dma -q

Если требуется доставлять письма как можно скорее после восстановления доступности удалённого SMTP-сервера, можно увеличить частоту запуска задачи, например, до раза в 5 минут:

    */5 * * * * /usr/pkg/sbin/dma -q

Или до раза в минуту:

    * * * * * /usr/pkg/sbin/dma -q

Проверка
--------

Проверить работу настроенной почтовой системы можно, например, следующим образом:

    $ echo test | mail -s test root

Дополнительные материалы
------------------------

* [wip/dma](https://pkgsrc.se/wip/dma), автор - [Christian Koch](mailto:cfkoch@edgebsd.org)
* [Setting up the best null client ever! (DMA)](https://pub.nethence.com/mail/dma)
* [dma: mailwrapper: no mapping in /etc/mail/mailer.conf](https://forums.freebsd.org/threads/dma-mailwrapper-no-mapping-in-etc-mail-mailer-conf.61810/)
