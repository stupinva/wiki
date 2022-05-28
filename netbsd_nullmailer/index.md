Настройка nullmailer в NetBSD
=============================

nullmailer - это программа, с помощью которой можно организовать отправку писем с сервера по протоколу SMTP на удалённый почтовый сервер в почтовый ящик администратора. Программа предназначена только для выполнения этой задачи и, в отличие от многих аналогов, таких как ssmtp или msmtp, поддерживает очередь писем. То есть при недоступности удалённого SMTP-сервера письма не пропадают, а остаются в очереди и дожидаются восстановления доступности SMTP-сервера. Как следствие простоты, программа зависит от небольшого количества других пакетов.

Установим nullmailer из pkgsrc:

    # cd /usr/pkgsrc/mail/nullmailer
    # make install

Прописываем в файл конфигурации `/usr/pkg/etc/nullmailer/me` имя сетевого узла, которое будет подставляться в SMTP-команду `HELO`/`EHLO`:

    git.vm.stupin.su

Прописываем в файл конфигурации `/usr/pkg/etc/nullmailer/allmailfrom` почтовый ящик отправителя, который будет подставляться в поле `From` конверта писем:

    git@stupin.su

Прописываем в файл конфигурации `/usr/pkg/etc/nullmailer/adminaddr` почтовый ящик получателя, который будет получать письма с компьютера, где запущен nullmailer:

    vladimir@stupin.su

И наконец, прописываем в файл конфигурации `/usr/pkg/etc/nullmailer/remotes` почтовый сервер, используемый им протокол и дополнительные настройки для отправки писем:

    mail.stupin.su smtp port=587 starttls user='git@stupin.su' pass='$ecretP4$$w0rd'

Меняем права доступа к файлу `/usr/pkg/etc/nullmailer/remotes`, чтобы скрыть пароль от почтового ящика от остальных пользователей системы:

    # chown root:nullmail /usr/pkg/etc/nullmailer/remotes
    # chmod u=rw,g=r,o= /usr/pkg/etc/nullmailer/remotes

Заменяем Postfix на nullmailer:

    # /etc/rc.d/postfix stop
    # cat /usr/pkg/share/examples/nullmailer/mailer.conf > /etc/mailer.conf

В файле `/etc/rc.conf` отключаем автозапуск Postfix при загрузке системы, включаем вместо него автозапуск nullmailer:

    postfix=NO
    nullmailer=YES

Теперь можно запустить nullmailer:

    # /etc/rc.d/nullmailer start

И т.к. настройки и файлы Postfix нам больше не понадобятся, их можно удалить:

    # rm -R /usr/pkg/etc/postfix
    # rm -R /var/spool/postfix
    # rm -R /var/db/postfix

Проверить отправку писем можно, например, с помощью такой команды:

    $ echo test | mail -s test root

Если в почтовом ящике не появилось письмо, то скорее всего оно застряло в очереди писем, просмотреть которую можно с помощью следующей команды:

    $ mailq

Сама очередь писем находится в каталоге `/var/spool/nullmailer` и при необходимости застрявшие письма можно удалить оттуда вручную.
