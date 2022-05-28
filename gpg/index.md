Использование GPG
=================

Проверка подписи файла
----------------------

Проверить подпись файла можно следующим образом:

    $ gpg --verify twrp-3.3.1-2-river.img.asc twrp-3.3.1-2-river.img
    gpg: keybox '/home/ufanet/.gnupg/pubring.kbx' created
    gpg: Signature made Ср 13 ноя 2019 05:15:06 +05
    gpg:                using RSA key 95707D42307C9D41D09BF7091D8597D7891A43DF
    gpg: Can't check signature: Нет открытого ключа

Если вы получили такую же ошибку об отсутствии открытого ключа, то его можно скачать с серверов ключей. Попробуем для начала сервер pgp.mit.edu:

    $ gpg --keyserver pgp.mit.edu --receive-key 95707D42307C9D41D09BF7091D8597D7891A43DF
    gpg: keyserver receive failed: Нет данных

Не получилось. Пробуем сервер keys.gnupg.net:

    $ gpg --keyserver keys.gnupg.net --receive-key 95707D42307C9D41D09BF7091D8597D7891A43DF
    gpg: key 1D8597D7891A43DF: 2 duplicate signatures removed
    gpg: key 1D8597D7891A43DF: 55 signatures not checked due to missing keys
    gpg: /home/ufanet/.gnupg/trustdb.gpg: trustdb created
    gpg: key 1D8597D7891A43DF: public key "TeamWin <admin@teamw.in>" imported
    gpg: no ultimately trusted keys found
    gpg: Total number processed: 1
    gpg:               imported: 1

Получилось. Теперь проверяем подпись файла:

    $ gpg --verify twrp-3.3.1-2-river.img.asc twrp-3.3.1-2-river.img
    gpg: Signature made Ср 13 ноя 2019 05:15:06 +05
    gpg:                using RSA key 95707D42307C9D41D09BF7091D8597D7891A43DF
    gpg: Good signature from "TeamWin <admin@teamw.in>" [unknown]
    gpg: WARNING: This key is not certified with a trusted signature!
    gpg:          There is no indication that the signature belongs to the owner.
    Primary key fingerprint: 9570 7D42 307C 9D41 D09B  F709 1D85 97D7 891A 43DF

Подпись совпала, однако мы ещё не доверяем этому ключу. Исправим это. Запускаем утилиту gpg для редактирования ключа почтового ящика admin@teamw.in, в диалоге вводим команду trust, отвечаем на вопрос цифрой 5 (неограниченно доверяем), затем выходим из диалога командой quit:

    $ gpg --edit-key admin@teamw.in
    gpg (GnuPG) 2.1.18; Copyright (C) 2017 Free Software Foundation, Inc.
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.
    
    
    pub  rsa4096/1D8597D7891A43DF
         created: 2016-11-27  expires: never       usage: SC  
         trust: unknown       validity: unknown
    sub  rsa4096/0B3927333518CAF7
         created: 2016-11-27  expires: never       usage: E   
    [ unknown] (1). TeamWin <admin@teamw.in>
    
    gpg> trust
    pub  rsa4096/1D8597D7891A43DF
         created: 2016-11-27  expires: never       usage: SC  
         trust: unknown       validity: unknown
    sub  rsa4096/0B3927333518CAF7
         created: 2016-11-27  expires: never       usage: E   
    [ unknown] (1). TeamWin <admin@teamw.in>
    
    Please decide how far you trust this user to correctly verify other users' keys
    (by looking at passports, checking fingerprints from different sources, etc.)
  
      1 = I don't know or won't say
      2 = I do NOT trust
      3 = I trust marginally
      4 = I trust fully
      5 = I trust ultimately
      m = back to the main menu
    
    Your decision? 5
    Do you really want to set this key to ultimate trust? (y/N) y
    
    pub  rsa4096/1D8597D7891A43DF
         created: 2016-11-27  expires: never       usage: SC  
         trust: ultimate      validity: unknown
    sub  rsa4096/0B3927333518CAF7
         created: 2016-11-27  expires: never       usage: E   
    [ unknown] (1). TeamWin <admin@teamw.in>
    Please note that the shown key validity is not necessarily correct
    unless you restart the program.
    
    gpg> quit

Проверяем подпись файла ещё раз:

    $ gpg --verify twrp-3.3.1-2-river.img.asc twrp-3.3.1-2-river.img
    gpg: Signature made Ср 13 ноя 2019 05:15:06 +05
    gpg:                using RSA key 95707D42307C9D41D09BF7091D8597D7891A43DF
    gpg: checking the trustdb
    gpg: marginals needed: 3  completes needed: 1  trust model: pgp
    gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
    gpg: Good signature from "TeamWin <admin@teamw.in>" [ultimate]

Как видно, подпись у файла совпадает и теперь gpg не ругается на то, что открытого ключа нет в списке доверенных.

Серверы ключей:

* sks-keyservers.net - пул серверов ключей, серверы синхронизируются друг с другом
* keyserver.pgp.com - глобальный каталог PGP
* keys.openpgp.org - автономный сервер PGP, не синхронизируется с другими и не является частью какого-либо пула
* pgp.mit.edu стал частью пула sks
* keys.gnupg.net является псевдонимом пула sks

Ссылки:

* [Краткое руководство по GPG](https://vladimir-stupin.blogspot.com/2017/08/gpg.html)
* [Ana Guerrero López - GPG](http://ekaia.org/blog/2009/05/10/creating-new-gpgkey/)
* [GPG Change Passphrase Secret Key Password Command](https://www.cyberciti.biz/faq/linux-unix-gpg-change-passphrase-command/)
* [Использование PGP/GPG, руководство для нетерпеливых](https://eax.me/gpg/)
* [Где загрузить открытый ключ PGP? KeyServers все еще выживают?](https://qastack.ru/superuser/227991/where-to-upload-pgp-public-key-are-keyservers-still-surviving)
