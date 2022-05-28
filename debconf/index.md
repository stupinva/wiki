Использование debconf
=====================

При установке некоторых пакетов выводится диалог настройки. Для перенастройки пакета, если ранее он уже был установлен и настроен, можно воспользоваться командой dpkg-reconfigure:

    # dpkg-reconfigure postfix

Просмотр настроек, используемых пакетом postfix:

    # debconf-show postfix
      postfix/recipient_delim: +
      postfix/root_address:
      postfix/sqlite_warning:
      postfix/not_configured:
    * postfix/main_mailer_type: Satellite system
      postfix/relay_restrictions_warning:
      postfix/tlsmgr_upgrade_warning:
    * postfix/mailname: bm7.core.ufanet.ru
      postfix/mailbox_limit: 0
      postfix/dynamicmaps_conversion_warning:
      postfix/protocols: all
      postfix/rfc1035_violation: false
      postfix/destinations: $myhostname, bm7.core.ufanet.ru, localhost.core.ufanet.ru, localhost
      postfix/bad_recipient_delimiter:
      postfix/mydomain_warning:
      postfix/compat_conversion_warning: true
      postfix/lmtp_retired_warning: true
      postfix/kernel_version_warning:
      postfix/main_cf_conversion_warning: true
      postfix/newaliases: false
      postfix/chattr: false
      postfix/mynetworks: 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
      postfix/retry_upgrade_warning:
      postfix/procmail: false
    * postfix/relayhost: mail.ufanet.ru

В выводе звёздочками отмечены значения, отличающиеся от значений по умолчанию.

Для просмотра определённых значений настройки можно воспользоваться командами следующего вида:

    # echo "get postfix/main_mailer_type" | debconf-communicate 
    0 Satellite system

Для задания нового значения можно воспользоваться командами следующего вида:

    # echo "set postfix/main_mailer_type Sattelite system" | debconf-communicate 
    0 value set

Если установить пакет debconf-utils, то можно выгружать настройки в текстовый файл при помощи debconf-get-selections:

    # apt-get install debconf-utils

    # debconf-get-selections | grep postfix > debconf_postfix

    # debconf-set-selections < debconf_postfix

Использованные материалы:

* [Manipulating debconf settings on the command line](https://feeding.cloud.geek.nz/posts/manipulating-debconf-settings-on/)
