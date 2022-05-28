Установка и настройка Dovecot
=============================

Оглавление
----------

[[!toc startlevel=2 levels=3]]

Установка пакета
----------------

Перед установкой пакета dovecot, содержащего поддержку серверов POP3 и IMAP, пропишем в файле /etc/mk.conf опции пакета, которые нам понадобятся и отключим ненужные:

    PKG_OPTIONS.dovecot=    ssl kqueue -pam -tcpwrappers

Установим пакет dovecot, содержащий поддержку серверов POP3 и IMAP:

    # cd /usr/pkgsrc/mail/dovecot2
    # make install

Настройка протоколов и прослушиваемого адреса
---------------------------------------------

Отредактируем файл /usr/pkg/etc/dovecot/dovecot.conf, настроив нужные нам протоколы и прослушиваемые IP-адреса:

    protocols = imap pop3
    listen = *

После редактирования файл должен принять следующий вид:

    # egrep -v '^ *(#|$)' /usr/pkg/etc/dovecot/dovecot.conf
    protocols = imap pop3
    listen = *
    dict {
    }
    !include conf.d/*.conf
    !include_try local.conf

Настройка журналирования
------------------------

Изменим форматирование отметок времени, вписав в файл /usr/pkg/etc/dovecot/conf.d/10-logging.conf следующую настройку:

    log_timestamp = "%Y-%m-%d %H:%M:%S "

Содержимое файла должно принять следующий вид:

    # egrep -v '^ *(#|$)' /usr/pkg/etc/dovecot/conf.d/10-logging.conf 
    plugin {
    }
    log_timestamp = "%Y-%m-%d %H:%M:%S "

На время отладки также можно включить другие опции из этого файла:

    auth_verbose = yes
    auth_verbose_passwords = yes
    auth_debug = yes
    mail_debug = yes

Настройка хранилища почты
-------------------------

Создадим группу и пользователя vmail, от имени которого будет работать Dovecot и дадим этому пользователю доступ к каталогу, в котором будет храниться почта пользователей почтовой системы. На серверах для размещения почтовых ящиков, как и другой часто меняющейся информации, обычно используется раздел /var, который заранее делается достаточно большим:

    # groupadd -g 120 vmail
    # useradd -g 120 -u 120 vmail
    # mkdir /var/vmail
    # chown vmail:vmail /var/vmail
    # chmod u=rwx,g=rx,o= /var/vmail

В файле /usr/pkg/etc/dovecot/conf.d/10-mail.conf настроим путь к почтовым ящикам, а также пользователя и группу, от имени которых dovecot будет работать с ящиками:

    mail_location = maildir:/home/vmail/%Ld/%Ln
    mail_uid = vmail
    mail_gid = vmail
    first_valid_uid = 120
    last_valid_uid = 120
    first_valid_gid = 120
    last_valid_gid = 120

После настройки файл должен принять следующий вид:

    # egrep -v '^ *(#|$)' /usr/pkg/etc/dovecot/conf.d/10-mail.conf 
    mail_location = maildir:/var/vmail/%Ld/%Ln
    namespace inbox {
      inbox = yes
    }
    mail_uid = vmail
    mail_gid = vmail
    first_valid_uid = 120
    last_valid_uid = 120
    first_valid_gid = 120
    last_valid_gid = 120
    protocol !indexer-worker {
    }

Настройка базы данных учётных записей
-------------------------------------

Я буду использовать защищённые версии протоколов IMAP и POP3, поэтому настрою в файле /usr/pkg/etc/dovecot/conf.d/10-auth.conf механизмы PLAIN и LOGIN, чтобы хранить пароли в базе данных в хэшированном виде. В результате настройки файл /usr/pkg/etc/dovecot/conf.d/10-auth.conf без комментариев и пустых строк должен принять следующий вид:

    # egrep -v '^ *#|^ *$' /usr/pkg/etc/dovecot/conf.d/10-auth.conf
    disable_plaintext_auth = no
    auth_default_realm = domain.tld
    auth_mechanisms = plain login
    !include auth-passwdfile.conf.ext

Настроим в файле в файле /etc/dovecot/conf.d/auth-passwdfile.conf.ext использование учётных данных из файла /usr/pkg/etc/dovecot/users, который по своей внутренней структуре подобен файлу /etc/passwd. В результате настройки файл должен принять следующий вид:

    # egrep -v '^ *(#|$)' /usr/pkg/etc/dovecot/conf.d/auth-passwdfile.conf.ext
    passdb {
      driver = passwd-file
      args = scheme=CRYPT username_format=%u /usr/pkg/etc/dovecot/users
    }
    userdb {
      driver = passwd-file
      args = username_format=%u /usr/pkg/etc/dovecot/users
      default_fields = uid=vmail gid=vmail home=/var/vmail/%Ld/%Ln
    }

Создадим в каталоге /usr/pkg/etc/dovecot файл users и проставим права доступа:

    # cd /usr/pkg/etc/dovecot
    # touch users
    # chown root:dovecot users
    # chmod u=rw,g=r,o= users

В файле /etc/dovecot/users могут быть следующие поля:

    user:{plain}password:uid:gid:gecos:home:shell:extra_fields

Назначение полей:

* user - почтовый ящик (в данном случае - вместе с доменом),
* password - пароль (можно явным образом указывать алгоритм хэширования пароля),
* uid - системный идентификатор владельца файлов почты,
* gid - системный идентификатор группы владельца файлов почты,
* gecos - справочная информация о почтовом ящике (игнорируется),
* home - путь к каталогу почты,
* shell - интерпретатор (игнорируется),
* extra_fields - дополнительные настройки (квота, например).

Любое из полей может быть не определено в файле, если в настройках Dovecot указаны значения этих полей по умолчанию. Имеется возможность зафиксировать часть настроек почтового ящика при помощи настройки override_fields, так что значения из файла будут игнорироваться.

Подробнее о формате файла и других настройках можно прочитать на официальной wiki-странице Dovecot: [Passwd-file](https://doc.dovecot.org/configuration_manual/authentication/passwd_file/)

Первый запуск
-------------

Скопируем пример сценария для запуска сервиса в соответствующий каталог:

    # cp /usr/pkg/share/examples/rc.d/dovecot /etc/rc.d/

Разрешим запуск сервиса dovecot, прописав в файл /etc/rc.conf следующую опцию:

    dovecot=YES

Попробуем запустить сервис при помощи команды:

    # /etc/rc.d/dovecot start
    Starting dovecot.
    doveconf: Fatal: Error in configuration file /usr/pkg/etc/dovecot/conf.d/10-ssl.conf line 12: ssl_cert: Can't open file /etc/ssl/certs/dovecot.pem: No such file or directory

Отключим пока что SSL. Для этого закомментируем в файле /usr/pkg/etc/dovecot/conf.d/10-ssl.conf опции и отключим поддержку SSL в целом:

    ssl = no
    #ssl_cert = </etc/ssl/certs/dovecot.pem
    #ssl_key = </etc/ssl/private/dovecot.pem

После редактирования файл примет следующий вид:

    # egrep -v '^ *(#|$)' /usr/pkg/etc/dovecot/conf.d/10-ssl.conf
    ssl = no

Попробуем запустить сервис снова:

    # /etc/rc.d/dovecot start
    Starting dovecot.

Убедимся, что Dovecot запущен и ожидает подключений на TCP-портах 110 (POP3) и 143 (IMAP4):

    # netstat -anf inet
    Active Internet connections (including servers)
    Proto Recv-Q Send-Q  Local Address          Foreign Address        State
    tcp        0      0  *.143                  *.*                    LISTEN
    tcp        0      0  *.110                  *.*                    LISTEN
    tcp        0      0  169.254.252.12.22      169.254.252.1.42606    ESTABLISHED
    tcp        0      0  *.22                   *.*                    LISTEN

Настройка пространств имён
--------------------------

В файле /usr/pkg/etc/dovecot/conf.d/10-mail.conf прописываем следующие настройки:

    namespace inbox {
      type = private
      separator = /
      prefix =
      inbox = yes
    }

Эти настройки описывают пространства имён, в котором хранится личная почта пользователя. В следующем разделе мы настроим ещё одно пространство имён. На этом этапе файл конфигурации примет следующий вид:

    netbsd# egrep -v '^ *(#|$)' /usr/pkg/etc/dovecot/conf.d/10-mail.conf
    mail_location = maildir:/var/vmail/%Ld/%Ln
    namespace inbox {
      type = private
      separator = /
      prefix = 
      inbox = yes
    }
    mail_uid = vmail
    mail_gid = vmail
    first_valid_uid = 120
    last_valid_uid = 120
    first_valid_gid = 120
    last_valid_gid = 120
    protocol !indexer-worker {
    }

Настройка имён специальных папок
--------------------------------

Проверим содержимое файла /usr/pkg/etc/dovecot/conf.d/15-mailboxes.conf у достоверимся, что в нём уже описано назначение каталогов личной почты пользователей:
    namespace inbox {
      mailbox Drafts {
        special_use = \Drafts
      }
      mailbox Junk {
        special_use = \Junk
      }
      mailbox Trash {
        special_use = \Trash
      }
      mailbox Sent {
        special_use = \Sent
      }
    }

Современные почтовые программы смогут прямо по протоколу IMAP узнать назначение каждого из специальных каталогов, вне зависимости от их названия. Это бывает полезно, если каталог имеет нестандартное название или название на языке пользователя ящика, например "Входящие" или "Спам".

Назначение каталогов:

* Drafts - каталог черновиков,
* Junk - каталог для спама,
* Trash - каталог для удалённых писем,
* Sent - каталог для отправленных писем.

Мне никаких дополнительных настроек прописывать не пришлось, т.к. в этом файле конфигурации уже были прописаны необходимые настройки:

    # egrep -v '^ *(#|$)' /usr/pkg/etc/dovecot/conf.d/15-mailboxes.conf 
    namespace inbox {
      mailbox Drafts {
        special_use = \Drafts
      }
      mailbox Junk {
        special_use = \Junk
      }
      mailbox Trash {
        special_use = \Trash
      }
      mailbox Sent {
        special_use = \Sent
      }
      mailbox "Sent Messages" {
        special_use = \Sent
      }
    }

Настройка плагина acl
---------------------

Плагин acl позволяет пользователям предоставлять друг другу доступ к папкам в своих почтовых ящиках. Это может быть полезно для корпоративных пользователей. Например, для директора и его заместителя. Или для директора и его секретаря. Или для сотрудников из одного отдела, которые подменяют друг друга на время обеда или отпуска. Эта возможность, естественно, доступна только при использовании протокола IMAP.

В файле /usr/pkg/etc/dovecot/conf.d/10-mail.conf включаем использование плагина:

    mail_plugins = acl

В файле /usr/pkg/etc/dovecot/conf.d/10-mail.conf дописываем пространство имён для разделяемых папок:

    namespace {
      type = shared
      separator = /
      prefix = shared/%%u/
      location = maildir:%%h:INDEX=%h/shared/%%u
      subscriptions = yes
      list = children
    }

Поясню смысл настроек location для пространства имён общих каталогов:

* maildir:%%h - означает место расположения чужого почтового ящика в формате Maildir,
* %%h - полный путь к Maildir-каталогу чужого ящика,
* INDEX=%h/shared/%%u - задаёт каталог, в который как бы монтируются каталоги чужой почты, к которым её владелец дал нам доступ,
* %h - путь к Maildir-каталогу нашего ящика,
* %%u - имя другого пользователя в виде box@domain.tld.

После настройки файл /usr/pkg/etc/dovecot/conf.d/10-mail.conf приобретёт следующий вид:

    # egrep -v '^ *(#|$)' /usr/pkg/etc/dovecot/conf.d/10-mail.conf
    mail_location = maildir:/var/vmail/%Ld/%Ln
    namespace inbox {
      type = private
      separator = /
      prefix = 
      inbox = yes
    }
    namespace {
      type = shared
      separator = /
      prefix = shared/%%u/
      location = maildir:%%h:INDEX=%h/shared/%%u
      subscriptions = yes
      list = children
    }
    mail_uid = vmail
    mail_gid = vmail
    first_valid_uid = 120
    last_valid_uid = 120
    first_valid_gid = 120
    last_valid_gid = 120
    mail_plugins = acl
    protocol !indexer-worker {
    }

В файле /usr/pkg/etc/dovecot/conf.d/20-imap.conf включаем использование плагина в IMAP-сервере:

    protocol imap {
      mail_plugins = $mail_plugins imap_acl
    }

Поскольку в этом файле нет других настроек, то он будет иметь указанный выше вид:

    # egrep -v '^ *(#|$)' /usr/pkg/etc/dovecot/conf.d/20-imap.conf
    protocol imap {
      mail_plugins = $mail_plugins imap_acl
    }

В файл /usr/pkg/etc/dovecot/conf.d/90-acl.conf прописываем настройки плагина:

    plugin {
      acl = vfile
      acl_shared_dict = file:/usr/vmail/shared-mailboxes
    }

Значение vfile предписывает создавать внутри почтового ящика файл dovecot-acl, в котором и будут прописываться права доступа к нему со стороны других пользователей.

Значение acl_shared_dict указывает путь к файлу словаря, который позволит пользователям узнавать, к каким каталогам в чужих почтовых ящиках у них имеется доступ. В данном случае будет создан общий файл словаря, что позволяет делиться папками с пользователями из других доменов на этом же сервере.

Файл конфигурации примет следующий вид:

    # egrep -v '^ *(#|$)' /usr/pkg/etc/dovecot/conf.d/90-acl.conf
    plugin {
      acl = vfile
    }
    plugin {
      acl_shared_dict = file:/var/vmail/shared-mailboxes
    }

Чтобы настройки плагина acl вступили в силу, нужно перезапустить Dovecot:

    # /etc/rc.d/dovecot restart

Больше информации по настройке плагина ACL можно почитать в официальной документации:  

* [Mailbox sharing between users](https://wiki.dovecot.org/SharedMailboxes/Shared)
* [Access Control Lists](https://doc.dovecot.org/settings/plugin/acl/)
* [acl plugin](https://doc.dovecot.org/settings/plugin/aclPlugins/)

Настройка плагина quota
-----------------------

Плагин quota позволяет назначить для почтового ящика ограничения на объём хранящихся в нём писем или даже на их общее количество. На мой взгляд, ограничение на общее количество писем имеет довольно мало смысла. Единственная польза, которая мне приходит на ум - это возможность защититься от исчерпания inode'ов в файловой системе, если кто-то намеренно решит отправить огромное количество мелких писем в ящики пользователей, с целью нарушить работу почтовой системы.

Мы настроим плагин так, чтобы он использовал значения квот, указанные в интерфейсе Postfixadmin. Эти квоты ограничивают только максимальный объём писем в ящике.

Включим использование плагина в файле /usr/pkg/etc/dovecot/conf.d/10-mail.conf:

    mail_plugins = acl quota

Значимые строки файла конфигурации /usr/pkg/etc/dovecot/conf.d/10-mail.conf примут следующий вид:

    # egrep -v '^ *(#|$)' /usr/pkg/etc/dovecot/conf.d/10-mail.conf
    mail_location = maildir:/var/vmail/%Ld/%Ln
    namespace inbox {
      type = private
      separator = /
      prefix = 
      inbox = yes
    }
    namespace {
      type = shared
      separator = /
      prefix = shared/%%u/
      location = maildir:%%h:INDEX=%h/shared/%%u
      subscriptions = yes
      list = children
    }
    mail_uid = vmail
    mail_gid = vmail
    first_valid_uid = 120
    last_valid_uid = 120
    first_valid_gid = 120
    last_valid_gid = 120
    mail_plugins = acl quota
    protocol !indexer-worker {
    }

В файл /usr/pkg/etc/dovecot/conf.d/15-lda.conf впишем, что в случае превышения квоты Dovecot должен сообщать о временной ошибке, но не отклонять письмо окончательно. Почтовый сервер отправителя (или наш MTA) будет периодически предпринимать повторные попытки в надежде на то, что адресат почистит свой ящик от ненужных писем:

    quota_full_tempfail = yes

В результате файл /usr/pkg/etc/dovecot/conf.d/15-lda.conf должен принять следующий вид:

    # egrep -v '^ *(#|$)' /usr/pkg/etc/dovecot/conf.d/15-lda.conf 
    quota_full_tempfail = yes
    protocol lda {
    }

В файл /usr/pkg/etc/dovecot/conf.d/20-imap.conf добавим поддержку квот в IMAP-сервере:

    protocol imap {
      mail_plugins = $mail_plugins imap_acl imap_quota
    }

Этот плагин позволит почтовым клиентам, работающим по протоколу IMAP, узнавать квоту почтового ящика и её текущее использование.

После редактирования файл /usr/pkg/etc/dovecot/conf.d/20-imap.conf должен принять следующий вид:

    # egrep -v '^ *(#|$)' /usr/pkg/etc/dovecot/conf.d/20-imap.conf
    protocol imap {
      mail_plugins = $mail_plugins imap_acl imap_quota
    }

Укажем в файле /usr/pkg/etc/dovecot/conf.d/90-quota.conf, что значения квот берутся из словаря и зададим пустое правило по умолчанию:

    plugin {
      quota = dict:User quota::file:%h/dovecot-quota
      quota_rule = *:
    }

После редактирования файл /usr/pkg/etc/dovecot/conf.d/90-quota.conf примет следующий вид:

    # egrep -v '^ *(#|$)' /usr/pkg/etc/dovecot/conf.d/90-quota.conf 
    plugin {
      quota_rule = *:
    }
    plugin {
    }
    plugin {
      quota = dict:User quota::file:%h/dovecot-quota
    }
    plugin {
    }

Откроем файл /usr/pkg/etc/dovecot/conf.d/auth-passwdfile.conf.ext и пропишем в него правило, действующее по умолчанию на всех пользователей:

    default_fields = uid=vmail gid=vmail home=/var/vmail/%Ld/%Ln userdb_quota_rule=*:storage=1G

После редактирования файл /usr/pkg/etc/dovecot/conf.d/auth-passwdfile.conf.ext примет следующий вид:

    # egrep -v '^ *(#|$)' /usr/pkg/etc/dovecot/conf.d/auth-passwdfile.conf.ext 
    passdb {
      driver = passwd-file
      args = scheme=CRYPT username_format=%u /usr/pkg/etc/dovecot/users
    }
    userdb {
      driver = passwd-file
      args = username_format=%u /usr/pkg/etc/dovecot/users
      default_fields = uid=vmail gid=vmail home=/var/vmail/%Ld/%Ln userdb_quota_rule=*:storage=1G
    }

При этом для настройки квот отдельных пользователей можно будет воспользоваться файлом /usr/pkg/etc/dovecot/users, вписав нужное правило в последнюю колонку строчки пользователя, вот так:

    zabbix@stupin.su:{plain}$ecretP4$$w0rd:::Zabbix:::userdb_quota_rule=*:storage=100M

Настройка плагина закончена, осталось перезапустить Dovecot, чтобы настроенный плагин начал работать:

    # /etc/rc.d/dovecot restart
    Stopping dovecot.
    Starting dovecot.

В каталоге каждого почтового ящика будет создаваться файл dovecot-data, внутри которого будет вестись учёт текущего количества сообщений в ящике и их объёма.

Для пересчёта квоты одного пользователя можно воспользоваться такой командой:

    # doveadm quota recalc -u zabbix@stupin.su

Чтобы принудительно пересчитать квоты всех почтовых ящиков, можно воспользоваться следующей командой:

    # doveadm quota recalc -A

Для просмотра текущей квоты пользователя можно воспользоваться командой следующего вида:  

    # doveadm quota get -u zabbix@stupin.su
    Quota name Type    Value  Limit                                            %
    User quota STORAGE     5 102400                                            0
    User quota MESSAGE     2      -                                            0

При помощи следующей команды можно посмотреть квоты всех пользователей:

    # dovecot quota get -A

Использованные материалы:

* [Quota](https://doc.dovecot.org/configuration_manual/quota/)
* [Quota/Configuration](https://wiki.dovecot.org/Quota/Configuration)
* [Dictionary quota](https://wiki.dovecot.org/Quota/Dict)

Настройка плагина expire
------------------------

Этот плагин не поддерживает работу со словарями, хранящимися не в базах данных, поэтому здесь его настройка не описывается.

Для периодической очистки почтовых ящиков от устаревших сообщений можно добавить в планировщик задач выполнение, например, такой команды:

    # doveadm expunge -A mailbox Spam savedbefore 2w

Эта команда найдёт в почтовых ящиках пользователей каталоги Spam и удалит из них те сообщения, которые были сохранены в ящик более двух недель назад. Подобным образом можно очищать и другие каталоги, например - Trash.

Например, чтобы выполнять эту команду раз в сутки, в 4 часа ночи, выполним под пользователем root команду crontab -e и впишем в открывшийся файл такую строчку:

    0       4       *       *       *       /usr/pkg/bin/doveadm -A mailbox Spam savedbefore 2w

Настройка SSL
-------------

Получение самоподписанных сертификатов или сертификатов удостоверяющего центра Let's Encrypt выходит за рамки этой статьи. Далее считаем, что сертификат и приватный ключ к нему уже имеются.

Включим поддержку SSL в файле /usr/pkg/etc/dovecot/conf.d/10-ssl.conf и укажем в нём пути к файлу сертификата и приватного ключа:

    ssl = yes
    ssl_cert = </etc/openssl/certs/mail.stupin.su.pem
    ssl_key = </etc/openssl/private/mail.stupin.su.pem

В этом фале нет других настроек, отличных от настроек по умолчанию, поэтому содержимое файла без пустых строк и комментариев будет совпадать с указанным выше.

Стоит убедиться, что к приватному ключу имеет доступ на чтение только пользователь dovecot, а на чтение и редактирование - только пользователь root. Превентивно выставим необходимые права доступа к приватному ключу:

    # chown root:dovecot /etc/openssl/private/mail.stupin.su.pem
    # chmod u=rw,g=r,o=r /etc/openssl/private/mail.stupin.su.pem
  
Почтовый сервер предоставляет свой сертификат всем подключающимся сетевым клиентам, поэтому здесь требования менее строгие: читать его можно всем, но изменять его имеет право только пользователь root. Группа в принципе может быть какой уг
одно, т.к. права доступа группы будут совпадать с правами доступа всех остальных пользователей в системе. В качестве группы-владельца файла с сертификатом можно выставить, например wheel или dovecot. Выставим соответствующие права:

    # chown root:dovecot /etc/openssl/certs/mail.stupin.su.pem
    # chmod u=rw,g=r,o=r /etc/openssl/certs/mail.stupin.su.pem

После настройки SSL нужно перезапустить Dovecot, чтобы изменения вступили в силу:

    # /etc/rc.d/dovecot restart

После перезапуска должны открыться на прослушивание TCP-порты 993 (IMAPS) и 995 (POP3S), в чём можно убедиться при помощи следующей команды:

    # netstat -anf inet
    Active Internet connections (including servers)
    Proto Recv-Q Send-Q  Local Address          Foreign Address        State
    tcp        0      0  *.993                  *.*                    LISTEN
    tcp        0      0  *.143                  *.*                    LISTEN
    tcp        0      0  *.995                  *.*                    LISTEN
    tcp        0      0  *.110                  *.*                    LISTEN
    tcp        0      0  169.254.252.12.22      169.254.252.1.43790    ESTABLISHED
    tcp        0      0  *.22                   *.*                    LISTEN

Настройка плагина sieve
-----------------------

Sieve - это скрипты фильтрации почты, которые выполняются агентом локальной доставки (LDA) в момент получения письма от почтового сервера (MTA). Скрипты позволяют раскладывать письма в разные папки, ориентируясь на их содержимое - тему письма, получателей, отправителей и т.п. Можно удалить письмо, переслать его на другой ящик или отправить уведомление отправителю, причём использовать можно любое поле заголовка или содержимое тела письма.

Главное преимущество Sieve заключается в том, что пользователю не нужно настраивать правила фильтрации в каждом из используемых им почтовых клиентов - правила едины для всех почтовых клиентов сразу. Кроме того, фильтрация происходит вообще без участия клиента. Клиент, подключившись к почтовому ящику, имеет возможность работать уже с отсортированной почтой. Кроме того, отправка уведомлений о получении или пересылка писем на другой ящик вообще может происходить без участия почтового клиента.

Конечно, в наши времена больших почтовых сервисов типа Gmail или Яндекс-почты, этим никого не удивишь. Но тут плюс заключается в том, что перед нами не стоит дилемма "удобство" - "безопасность". Мы можем хранить почту у себя, не делясь ею с посторонними компаниями, имея над ней полный контроль, и в то же время можем пользоваться удобствами, характерными для больших почтовых сервисов.

Установим пакет Pigeonhole, который содержит в себе плагин для агента доставки Dovecot и сервис для управления скриптами Sieve:

    # cd /usr/pkgsrc/mail/dovecot2-pigeonhole
    # make install

Включим использование плагина в файле /usr/pkg/etc/dovecot/conf.d/15-lda.conf:

    protocol lda {
      mail_plugins = $mail_plugins sieve
    }

В результате на этом этапе настройки файл приобретёт следующий вид:

    # egrep -v '^ *($|#)' /usr/pkg/etc/dovecot/conf.d/15-lda.conf
    quota_full_tempfail = yes
    protocol lda {
      mail_plugins = $mail_plugins sieve
    }

Укажем настройки плагина в файле /usr/pkg/etc/dovecot/conf.d/90-sieve.conf:

    plugin {
      sieve = file:/var/vmail/%Ld/%n/sieve;active=/var/vmail/%Ld/%n/active.sieve # Каталог для скриптов и активный скрипт
      sieve_max_script_size = 1M                                                 # Максимальный размер одного скрипта
    }

Каждый пользователь может обладать собственным набором Sieve-скриптов, из которых в любой момент времени активным может быть только один. Скрипты располагаются в указанном каталоге, а на активный скрипт указывает символическая ссылка с указанным именем.

После настройки содержимое файла /usr/pkg/etc/dovecot/conf.d/90-sieve.conf будет таким:

    # egrep -v '^(\t| )*($|#)' /usr/pkg/etc/dovecot/conf.d/90-sieve.conf
    plugin {
      sieve = file:/var/vmail/%Ld/%n/sieve;active=/var/vmail/%Ld/%n/active.sieve
      sieve_max_script_size = 1M
    }

Теперь нужно перезапустить Dovecot, чтобы изменения вступили в силу:

    # /etc/rc.d/dovecot restart

Использованные материалы:

* [Sieve](http://ru.wikipedia.org/wiki/Sieve) - статья о скриптах Sieve на Wikipedia
* [Pigeonhole/Sieve/Configuration](https://wiki2.dovecot.org/Pigeonhole/Sieve/Configuration) - настройка плагина к Dovecot

Настройка сервиса managesieve
-----------------------------

Плагин sieve не был бы столь полезным, если бы Sieve-скриптами нельзя было бы управлять прямо из почтового клиента. Именно эту функцию и реализует сервис ManageSieve, который устанавливается вместе с плагином. Этот сервис ожидает подключений клиентов на отдельном TCP-порту 4190 и позволяет клиентам управлять Sieve-скриптами в своих почтовых ящиков. Для аутентификации на сервисе используется та же учётная запись, которая используется для доступа к почтовому ящику.

Включим его, раскомментировав в файле конфигурации /usr/pkg/etc/dovecot/conf/20-managesieve.conf строчку:

    protocols = $protocols sieve

Файл /usr/pkg/etc/dovecot/conf.d/20-managesieve.conf будет содержать следующие существенные строки:

    # egrep -v '^ *($|#)' /usr/pkg/etc/dovecot/conf.d/20-managesieve.conf
    protocols = $protocols sieve
    protocol sieve {
    }

Теперь можно перезапустить Dovecot, чтобы запустить сервис:

    # /etc/rc.d/dovecot restart
    Stopping dovecot.
    Starting dovecot.

После перезапуска должен открыться на прослушивание TCP-порт 4190:

    # netstat -anf inet
    Active Internet connections (including servers)
    Proto Recv-Q Send-Q  Local Address          Foreign Address        State
    tcp        0      0  *.993                  *.*                    LISTEN
    tcp        0      0  *.143                  *.*                    LISTEN
    tcp        0      0  *.995                  *.*                    LISTEN
    tcp        0      0  *.110                  *.*                    LISTEN
    tcp        0      0  *.4190                 *.*                    LISTEN
    tcp        0      0  169.254.252.12.22      169.254.252.1.50436    ESTABLISHED
    tcp        0      0  *.22                   *.*                    LISTEN

Теперь можно вернуться к настройке плагина sieve в файле /usr/pkg/etc/dovecot/conf.d/90-sieve.conf и добавить дополнительные опции для сервиса ManageSieve:

    plugin {
        sieve_quota_max_scripts = 50 # Максимальное количество скриптов
        sieve_quota_max_storage = 1M # Максимальный общий объём скриптов
    }

Содержимое файла /usr/pkg/etc/dovecot/conf.d/90-sieve.conf без пустых строк и комментариев примет следующий вид:

    # egrep -v '^ *($|#)' /usr/pkg/etc/dovecot/conf.d/90-sieve.conf
    plugin {
      sieve = file:/var/vmail/%Ld/%n/sieve;active=/var/vmail/%Ld/%n/active.sieve
            # still discarded as it would be when no discard script is configured.
      sieve_max_script_size = 1M
      sieve_quota_max_scripts = 50
      sieve_quota_max_storage = 1M
    }

Перезапустим Dovecot, чтобы применить новые настройки:

    # /etc/rc.d/dovecot restart
    Stopping dovecot.
    Starting dovecot.

В следующих заметках фильтрация писем при помощи Sieve будет рассмотрена подробнее - я покажу, как им пользоваться в почтовых клиентах.

Настройка LMTP
--------------

LMTP - это сервер доставки почты в почтовые ящики пользователей. Он принимает от SMTP-сервера входящие письма для получателей и кладёт их в почтовые ящики. Сервер LMTP по сути является агентом локальной доставки LDA, доступным по сети. Поэтому он использует для работы настройки LDA и дополнительно может принимать настройки, касающиеся работы в сети.

Добавим в файл /usr/pkg/etc/dovecot/dovecot.conf дополнительный протокол - LMTP:

    protocols = imap pop3 lmtp

Содержимое файла /usr/pkg/etc/dovecot/dovecot.conf на этом этапе настройки примет следующий вид:

    # egrep -v '^ *($|#)' /usr/pkg/etc/dovecot/dovecot.conf
    protocols = imap pop3 lmtp
    listen = *
    dict {
    }
    !include conf.d/*.conf
    !include_try local.conf

Теперь отредактируем файл /usr/pkg/etc/dovecot/conf.d/10-master.conf, приведя секцию service lmtp к следующему виду:

    service lmtp {
      user = vmail
      #unix_listener lmtp {
        #mode = 0666
      #}
      inet_listener lmtp {
        port = 24
      }
    }

Здесь мы указали, что процесс сервера LMTP должен запускаться с правами пользователя vmail. Если бы мы не использовали виртуальные почтовые ящики, то процесс LMTP должен был бы работать с привилегиями пользователя root, чтобы иметь доступ к почтовым ящикам получателей. Но в нашем случае почтовыми ящиками всех получателей почты является пользователь vmail, поэтому безопаснее запускать сервер LMTP с его привилегиями, которых LMTP-серверу должно быть вполне достаточно.

Я закомментировал настройки Unix-сокета lmtp, чтобы отключить его использование. Отключить его таким способом, однако, не получилось.

Я настраиваю Dovecot на виртуальной машине, недоступной напрямую из сети Интернет. SMTP-сервер будет работать на другой виртуальной машине, поэтому мне необходимо включить ожидание входящих подключений на TCP-порту. Обычно для LMTP-сервера используют 24 порт. Кроме порта можно также указать прослушиваемые IP-адреса в опции address. Т.к. на моей виртуальной машине всего один интерфейс, недоступный из Интернета, опция address в моём случае оказалась невостребованной.

После настройки содержимое файла примет следующий вид:

    service imap-login {
      inet_listener imap {
      }
      inet_listener imaps {
      }
    }
    service pop3-login {
      inet_listener pop3 {
      }
      inet_listener pop3s {
      }
    }
    service submission-login {
      inet_listener submission {
      }
    }
    service lmtp {
      user = vmail
      inet_listener lmtp {
        port = 24
      }
    }
    service imap {
    }
    service pop3 {
    }
    service submission {
    }
    service auth {
      unix_listener auth-userdb {
      }
    }
    service auth-worker {
    }
    service dict {
      unix_listener dict {
      }
    }

Теперь вернёмся к настройкам плагина Quota в файле /usr/pkg/etc/dovecot/conf.d/90-quota.conf и укажем дополнительную опцию lmtp_rcpt_check_quota, которая позволяет отклонять входящее сообщение на этапе, когда SMTP-сервер сообщает LMTP-серверу адрес получателя:

    plugin {
      quota_rule = *:
      lmtp_rcpt_check_quota = yes
    }

После этих манипуляций файл примет следующий вид:

    # egrep -v '^ *($|#)' /usr/pkg/etc/dovecot/conf.d/90-quota.conf
    plugin {
      quota_rule = *:
      lmtp_rcpt_check_quota = yes
    }
    plugin {
    }
    plugin {
      quota = dict:User quota::file:%h/dovecot-quota
    }
    plugin {
    }

Перезапустим Dovecot, чтобы новые настройки вступили в силу:

    # /etc/rc.d/dovecot restart
    Stopping dovecot.
    Starting dovecot.

Убедимся, что указанный нами TCP-порт 24 LMTP-сервера ожидает подключений:

    # netstat -anf inet
    Active Internet connections (including servers)
    Proto Recv-Q Send-Q  Local Address          Foreign Address        State
    tcp        0      0  *.993                  *.*                    LISTEN
    tcp        0      0  *.143                  *.*                    LISTEN
    tcp        0      0  *.24                   *.*                    LISTEN
    tcp        0      0  *.995                  *.*                    LISTEN
    tcp        0      0  *.110                  *.*                    LISTEN
    tcp        0      0  *.4190                 *.*                    LISTEN
    tcp        0      0  169.254.252.12.22      169.254.252.1.49656    ESTABLISHED
    tcp        0      0  *.22                   *.*                    LISTEN

Использованные материалы:

* [LMTP Server](https://doc.dovecot.org/configuration_manual/protocols/lmtp_server/)

Проверка работы LMTP-сервера
----------------------------

Для проверки воспользуемся утилитой telnet. Подключимся к 24 порту TCP виртуальной машины с LMTP-сервером:

    $ telnet mda.vm.stupin.su 24
    Trying 169.254.252.12...
    Connected to mda.vm.stupin.su.
    Escape character is '^]'.
    220 mda.vm.stupin.su Dovecot ready.

Отправим команду LHLO, которая в LMTP используется вместо аналогичных команд HELO и EHLO из SMTP:

    LHLO mail.stupin.su
    250-mda.vm.stupin.su
    250-8BITMIME
    250-CHUNKING
    250-ENHANCEDSTATUSCODES
    250-PIPELINING
    250 STARTTLS

Сообщим адрес отправителя письма:

    MAIL FROM:<vladimir@stupin.su>
    250 2.1.0 OK

Стоит обратить внимание на то, что после двоеточия в команде нет пробелов, а адрес почтового ящика отправителя должен быть заключён в угловые скобки.

Теперь сообщим адрес получателя письма:

    RCPT TO:<vladimir@stupin.su>
    250 2.1.5 OK

Отправим команду DATA, сообщающую о нашем намерении начать передачу содержимого письма:

    DATA
    354 OK

Сервер готов принять письмо. Вводим содержимое письма, а по окончании отправляем строчку с одной точкой:

    test
    
    test
    
    test
    .
    250 2.0.0 <vladimir@stupin.su> vQsON/ak0F8IAwAAfuT4vQ Saved

Сервер сообщил, что сохранил переданное ему письмо в почтовом ящике получателя. Теперь можно дать команду QUIT для отключения:

    QUIT
    221 2.0.0 Bye

Теперь найдём на сервере наше письмо, для чего перейдём в каталог с новыми письмами в почтовом ящике:

    mda# cd /var/vmail/stupin.su/vladimir/new/

Выведем список файлов в каталоге:

    mda# ls
    1607509268.M720210P776.mda.vm.stupin.su,S=287,W=299

Откроем файл на просмотр:

    mda# less 1607509268.M720210P776.mda.vm.stupin.su,S\=287,W\=299 

В файле можно будет увидеть содержимое письма с заголовками и телом:

    Return-Path: <vladimir@stupin.su>
    Delivered-To: vladimir@stupin.su
    Received: from mail.stupin.su ([169.254.252.1])
            by mda.vm.stupin.su with LMTP
            id vQsON/ak0F8IAwAAfuT4vQ
            (envelope-from <vladimir@stupin.su>)
            for <vladimir@stupin.su>; Wed, 09 Dec 2020 15:20:38 +0500
    test
    
    test
    
    test

Итак, сервер LMTP работает.

Использованные материалы:

* [Local Mail Transfer Protocol](https://en.wikipedia.org/wiki/Local_Mail_Transfer_Protocol)
* [RFC2033](https://tools.ietf.org/html/rfc2033)

Настройка сервиса submission
----------------------------

Сервис submission - это SMTP-сервер, предназначенный исключительно для отправки писем от аутентифицированных владельцев почтовых ящиков через основной SMTP-сервер. При этом отправленные письма также сохраняются в папку отправленных писем почтового ящика.

Откроем файл /usr/pkg/etc/dovecot/dovecot.conf и впишем протокол submission в список включенных протоколов:

    protocols = imap pop3 lmtp submission

После редактирования существенные строки этого файла станут такими:

    mda# egrep -v '^ *(#|$)' /usr/pkg/etc/dovecot/dovecot.conf 
    protocols = imap pop3 lmtp submission
    listen = *
    dict {
    }
    !include conf.d/*.conf
    !include_try local.conf

Откроем файл /usr/pkg/etc/dovecot/conf.d/20-submission.conf и впишем в него следующие настройки:

    hostname = mail.stupin.su
    submission_max_mail_size = 30M
    submission_max_recipients = 5
    submission_relay_host = mta.vm.stupin.su
    submission_relay_port = 25
    submission_relay_trusted = yes
    submission_relay_ssl = no

Опция hostname указывает имя почтового сервера, которое будет использовать сервис submission в ответе на приветствии HELO/EHLO. Опции submission_max_mail_size и submission_max_recipients ограничивают максимальный размер письма и максимальное количество его получателей. В остальных опциях указаны настройки подключения к основному SMTP-серверу. В частности в них указано, на какой адрес и порт необходимо установить подключение, указано что сервер не требует проходить процедуру аутентификации и работает без SSL.

После настройки в файле будут фигурировать следующие значимые строки:

    mda# egrep -v '^ *(#|$)' /usr/pkg/etc/dovecot/conf.d/20-submission.conf
    hostname = mail.stupin.su
    submission_max_mail_size = 30M
    submission_max_recipients = 5
    submission_relay_host = mta.vm.stupin.su
    submission_relay_port = 25
    submission_relay_trusted = yes
    submission_relay_ssl = no
    protocol submission {
    }

Перезапустим dovecot, чтобы его новые настройки вступили в силу:

    mda# /etc/rc.d/dovecot restart
    Stopping dovecot.
    Starting dovecot.

После перезапуска должен открыться на прослушивание TCP-порт 587 сервиса submission:

    mda# netstat -anf inet
    Active Internet connections (including servers)
    Proto Recv-Q Send-Q  Local Address          Foreign Address        State
    tcp        0      0  *.993                  *.*                    LISTEN
    tcp        0      0  *.143                  *.*                    LISTEN
    tcp        0      0  *.24                   *.*                    LISTEN
    tcp        0      0  *.995                  *.*                    LISTEN
    tcp        0      0  *.110                  *.*                    LISTEN
    tcp        0      0  *.587                  *.*                    LISTEN
    tcp        0      0  *.4190                 *.*                    LISTEN
    tcp        0      0  169.254.252.12.22      169.254.252.1.49726    ESTABLISHED
    tcp        0      0  *.22                   *.*                    LISTEN
    udp        0      0  169.254.252.12.65524   169.254.252.1.123

Проверка работы submission-сервера
----------------------------------

Проверим работу сервиса submission. Для этого приготовим строчку для аутентификации по методу PLAIN, закодировав логин и пароль, предварённые символами с нулевым кодом, с помощью алгоритма base64:

    $ printf '\0test@stupin.su\0p4$$w0rd' | base64
    AHRlc3RAc3R1cGluLnN1AHA0JCR3MHJk

Для проверки воспользуемся утилитой telnet. Подключимся к 587 порту TCP виртуальной машины с submission-сервером:

    $ telnet mda.vm.stupin.su 587
    Trying 192.168.252.12...
    erase character is '^H'.
    Connected to mda.vm.stupin.su.
    Escape character is '^]'.
    220 mail.stupin.su Dovecot ready.

Отправим команду EHLO:

    EHLO stupin.su
    250-mail.stupin.su
    250-8BITMIME
    250-AUTH PLAIN LOGIN
    250-BURL imap
    250-CHUNKING
    250-ENHANCEDSTATUSCODES
    250-SIZE 31457280
    250-STARTTLS
    250 PIPELINING

Пройдём аутентификацию по методу PLAIN, воспользовавшись заранее заготовленной строкой аутентификации:

    AUTH PLAIN
    334 
    AHRlc3RAc3R1cGluLnN1AHA0JCR3MHJk
    235 2.7.0 Logged in.

Сообщим адрес отправителя письма:

    MAIL FROM:<test@stupin.su>
    250 2.1.0 OK

Стоит обратить внимание на то, что после двоеточия в команде нет пробелов, а адрес почтового ящика отправителя должен быть заключён в угловые скобки.

Теперь сообщим адрес получателя письма:

    RCPT TO:<vladimir@stupin.su>
    250 2.0.0 Accepted

Отправим команду DATA, сообщающую о нашем намерении начать передачу содержимого письма:

    DATA
    354 OK

Сервер готов принять письмо. Вводим содержимое письма, а по окончании отправляем строчку с одной точкой:

    test
    
    test
    
    test
    .
    250-2.0.0  221 byte chunk, total 222
    250 2.0.0 OK id=1mwMds-00063I-S2

Сервер сообщил, что сохранил переданное ему письмо в почтовом ящике получателя. Теперь можно дать команду QUIT для отключения:

    QUIT
    221 2.0.0 Bye

Теперь найдём на сервере наше письмо, для чего перейдём в каталог с новыми письмами в почтовом ящике:

    mda# cd /var/vmail/stupin.su/vladimir/new/

Выведем список файлов в каталоге:

    mda# ls
    1639307025.M10912P29512.mda.vm.stupin.su,S\=750,W\=775

Откроем файл на просмотр:

    mda# less 1639307025.M10912P29512.mda.vm.stupin.su,S\=750,W\=775

В файле можно будет увидеть содержимое письма с заголовками и телом:

    Return-Path: <test@stupin.su>
    Delivered-To: vladimir@stupin.su
    Received: from mail.stupin.su ([192.168.252.13])
            (using TLSv1.3 with cipher TLS_AES_256_GCM_SHA384 (256/256 bits))
            by mail.stupin.su with LMTPS
            id CIeJABHXtWFIcwAAfuT4vQ
            (envelope-from <test@stupin.su>)
            for <vladimir@stupin.su>; Sun, 12 Dec 2021 16:03:45 +0500
    Received: from [192.168.252.12] (helo=mail.stupin.su)
            by mail.stupin.su with esmtp (Exim 4.95)
            (envelope-from <test@stupin.su>)
            id 1mwMds-00063I-S2
            for vladimir@stupin.su;
            Sun, 12 Dec 2021 16:03:44 +0500
    Received: from stupin.su ([192.168.252.1])
            by mail.stupin.su with ESMTPA
            id yaOvIwDXtWETFwAAfuT4vQ
            (envelope-from <test@stupin.su>)
            for <vladimir@stupin.su>; Sun, 12 Dec 2021 16:03:28 +0500
    
    test
    
    test
    
    test

Итак, сервер Submission работает.

Использованные материалы:

* [Submission Server](https://doc.dovecot.org/admin_manual/submission_server/)

Нужно сделать
-------------

* Нужно написать статью про использование [acme-tiny](https://github.com/diafygi/acme-tiny) для получения и обновления SSL-сертификатов.
* Написать статью про использование ACL, просмотр квот и использование Sieve в RoundCube и/или RaindLoop.
