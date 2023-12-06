Эд Хармоуш. OpenSSL 3.x и устаревшие провайдеры
===============================================

Это перевод статьи: [Ed Harmoush. OpenSSL 3.x and Legacy Providers](https://www.practicalnetworking.net/practical-tls/openssl-3-and-legacy-providers/)

[[!tag openssl ssl tls перевод]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

OpenSSL версии 3.0 вышла в сентябре 2021 года и одним из главных изменений было:

> Архитектура на основе провайдеров. Они заменяют старый интерфейс "движков", предоставляя больший уровень гибкости и возможнсоть для сторонних авторов добавлять криптографические алгоритмы в OpenSSL.
>
> [https://www.openssl.org/blog/blog/2021/06/17/OpenSSL3.0ReleaseCandidate/](https://www.openssl.org/blog/blog/2021/06/17/OpenSSL3.0ReleaseCandidate/)

Проще говоря, "старый" способ, когда OpenSSL устанавливается со всеми известными алгоритмами, заменяется на возможность выбирать провайдеров (то есть наборов поддерживаемых алгоритмов) в каждой конкретной системе.

А если говорить о практических последствиях, то **сертификаты и ключи в форматах PFX или PEM, созданные в OpenSSL версии 1.1** или более ранних, **могут быть закодированы с помощью алгоритмов, которые более не поддерживаются в OpenSSL 3.0**.

Из-за этого можно столкнуться такими сообщениями об ошибках:

    $ openssl pkcs12 -in sam.com.PFX -nodes
    Enter Import Password:
    Error outputting keys and certificates
    805B7CDE0A7F0000:error:0308010C:digital envelope routines:inner_evp_generic_fetch:unsupported:../crypto/evp/evp_fetch.c:349:Global default library context, Algorithm (RC2-40-CBC : 0), Properties ()

Первый вариант - использовать аргумент `-legacy`, чтобы OpenSSL использовал более старые/устаревшие алгоритмы для интерпретации файла:

    $ openssl pkcs12 -in sam.com.PFX -legacy -nodes
    Enter Import Password:
    Bag Attributes
    localKeyID: 10 E7 30 27 86 6B 79 2A 7D 73 D7 68 D4 E8 9B 89 70 11 43 93
    subject=C = US, ST = Middle Earth, L = The Shire, O = Hobbits, CN = sam.com
    issuer=C = US, ST = Middle Earth, L = Rivendell, O = White Council, OU = Grey, CN = Gandalf the CA
    --BEGIN CERTIFICATE--
    MIIE0TCCArmgAwIBAgIUWnRxP6npEv7jDcayOF1BBWkukv0wDQYJKoZIhvcNAQEL
    ...

Если аргумент `-legacy` не принимается, в некоторых руководствах рекомендуется также попробовать воспользоваться `-provider legacy`.

Хотя всё это может работать, можно зафиксировать исправление: **сообщить в конфигурации OpenSSL, что нужно использовать и новых и устаревших провайдеров**.

Постоянное исправление - всегда загружать устаревших провайдеров
----------------------------------------------------------------

В случае OpenSSL 3.x можно воспользоваться командой `openssl list -providers`, чтобы увидеть активных провайдеров:

$ openssl list -providers
Providers:
  default
    name: OpenSSL Default Provider
    version: 3.0.2
    status: active

Приведённый выше вывод соответствует настройкам OpenSSL по умолчанию и указывает на то, что **устаревшие провайдеры НЕ включены**.

Чтобы поменять это, внесём в файл конфигурации OpenSSL *два* изменения.

Поиск файла конфигурации OpenSSL
--------------------------------

Чтобы найти каталог с файлом конфигурации, воспользуемся командой `openssl version -d`:

    $ openssl version -d
    OPENSSLDIR: “/usr/lib/ssl”

В указанном каталоге должен быть файл `openssl.cnf`, в котором хранятся все настройки по умолчанию для данной системы.

    $ ls /usr/lib/ssl
    certs misc openssl.cnf private

Нужно внести изменения в два раздела этого файла.

Изменение 1 - раздел загрузки устаревших провайдеров
----------------------------------------------------

В этом разделе перечисляются загружаемые провайдеры. Фактически в нём перечисляются другие разделы, в которых описываются загружаемые провайдеры. Изначально он выглядит следующим образом:

    # List of providers to load (список загружаемых провайдеров)
    [provider_sect]
    default = default_sect 

Добавим строчку:

    # List of providers to load (список загружаемых провайдеров)
    [provider_sect]
    default = default_sect
    legacy = legacy_sect

Таким образом OpenSSL попытается загрузить **legacy_sect** (раздел устаревших провайдеров), который будет добавлен далее.

Изменение 2 - включение устаревшего провайдера и провайдера по умолчанию
------------------------------------------------------------------------

Прокрутим файл конфигурации OpenSSL далее до следующих строк:

    [default_sect]
    # activate = 1

По умолчанию, если загружается только один набор провайдеров, он автоматически считается включенным. Но при добавлении другого провайдера нужно указать, что включены оба.

Удалите символ # для раскомментирования директивы `activate = 1`. Затем добавим и включим `legacy_sect`:

    [default_sect]
    activate = 1
    
    [legacy_sect]
    activate = 1

Проверка, что оба провайдера загружаются по умолчанию
-----------------------------------------------------

С помощью той же приведённой выше команды `openssl list -providers` можно убедиться в успешности изменения настроек. В этот раз в выводе команды должно быть несколько провайдеров:

    $ openssl list -providers
    Providers:
      default
        name: OpenSSL Default Provider
        version: 3.0.7
        status: active
      legacy
        name: OpenSSL Legacy Provider
        version: 3.0.7
        status: active

Теперь должна появиться возможность просмотра/декодирования файлов с помощью обычной команды, а OpenSSL получит доступ к любому алгоритму, входящему в набор из устаревшего провайдера и провайдера по умолчанию 3.0:

    $ openssl pkcs12 -in sam.com.PFX -nodes
    Enter Import Password:
    Bag Attributes
    localKeyID: 10 E7 30 27 86 6B 79 2A 7D 73 D7 68 D4 E8 9B 89 70 11 43 93
    subject=C = US, ST = Middle Earth, L = The Shire, O = Hobbits, CN = sam.com
    issuer=C = US, ST = Middle Earth, L = Rivendell, O = White Council, OU = Grey, CN = Gandalf the CA
    --BEGIN CERTIFICATE--
    MIIE0TCCArmgAwIBAgIUWnRxP6npEv7jDcayOF1BBWkukv0wDQYJKoZIh
    ...
