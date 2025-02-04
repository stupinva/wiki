Проверка IP-адреса по чёрным спискам DNS
========================================

Для проверки попадания почтового сервера в чёрные списки можно воспользоваться множеством различных веб-сервисов вроде [2ip.ru/spam/](https://2ip.ru/spam/). Однако к веб-сервисам обычно приходится обращаться, когда почта уже не уходит. Лучше было бы проверять наличие IP-адреса почтового сервера в таких списках периодически, скриптом, запускаемым через планировщик задач или систему мониторинга.

Скрипт
------

Я подготовил такой скрипт, который можно взять по ссылке [[dnsbl.sh|dnsbl.sh]]. Достаточно вызвать скрипт, указав ему в качестве аргумента проверяемый IP-адрес:

    ./dnsbl.sh 188.234.148.179

Если скрипт ничего не вывел, значит проверяемого IP-адреса нет в проверяемых скриптом чёрных списках. В противном случае в каждой строчке будет выведена ссылка на веб-страницу чёрного списка и имя чёрного списка, по которому можно определить причину блокировки.

Добавление нового чёрного списка
--------------------------------

Добавить новый чёрный список в скрипт можно следующим образом. В качестве примера возьмём чёрный список `b.barracudacentral.org`. Во-первых, добавим его к перечню всех проверяемых чёрных списков:

    dnsbl_list="$dnsbl_list b.barracudacentral.org"

Теперь заменим в доменном имени чёрного списка все точки и знаки минуса на символы подчёркивания, так что получится строка `b_barracudacentral_org`.

Добавим к получившейся строке слева текст `dns_url_` и определим переменную, в которой записана веб-страница с описанием чёрного списка:

    dnsbl_url_b_barracudacentral_org="http://www.barracudacentral.org/"

Большинство чёрных списков при наличии IP-адреса в списке блокировки возвращают в ответ IP-адрес `127.0.0.2`. Но некоторые списки кроме стандарного ответа могут возвращать один или больше IP-адресов вида `127.0.0.x`. В таком случае по значению IP-адреса можно определить, за что именно был заблокирован искомый IP-адрес.

Переставим октеты IP-адреса из ответа и заменим точки на символы подчёркивания. Получившуюся строку через можно совместить со строкой домена и префиксом `dnsb_response_` вот так:

    "dnsb_response_" + "b_barracudacentral" + "2_0_0_127"

Переменной с таким именем можно присвоить описание причины блокировки, вот так:

    dnsbl_response_b_barracudacentral_org_2_0_0_127="BARRACUDACENTRAL"

Отключение чёрного списка
-------------------------

Некоторые чёрные списки просто пропадают и перестают отвечать на запросы, а некоторые уходят с шумом, возвращая ответ о наличии в нём любого IP-адреса.

Для временного отключени проверки по списку достаточно закомментировать одну только строку вида `dnsbl_list="$dnsbl_list DNSBL"`, добавив к ней слева символ решётке.

Для окончательного удаления чёрного списка нужно удалить указанную строку и все связанные с ней строки вида `dnsbl_url_DNSBL` и `dnsbl_response_DNSBL_*`.

Дополнительные материалы
------------------------

На сайте [www.dnsbl.com](https://www.dnsbl.com/) публикуются новости о пропавших без вести и закрывшихся списках блокировки, а также о новых списках.
