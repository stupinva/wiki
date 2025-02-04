Установка Microsoft Edge в Debian
=================================

[[!tag supermicro edge debian bookworm]]

Введение
--------

При попытке получить веб-доступ к BMC на сервере Supermicro SYS-110P-WR с помощью браузеров Firefox и Chromium в Debian 12 Bookworm можно столкнуться с проблемой - поверх некоторых страниц выводится анимация ожидания обновления страницы, которая никогда не завершается:

[[circles.png]]

Большинство подобных проблем решается отключением блокировки рекламы и средств сбора информации, таких как uBlock Origin или Ghostery.

Однако некоторые страницы так и продолжают выводить анимацию ожидания. Если нажатием клавишы F12 на такой странице перейти в отладчик, то можно увидеть в отладочной консоли ошибку "Uncaught TypeError: IPMIRoot is undefined".

Кроме этого можно увидеть в отладочной консоли несколько предупреждений:

* Предупреждение "Некоторые куки неправильно используют рекомендованный атрибут «SameSite»" для 5 кук,

* Предупреждение "Synchronous XMLHttpRequest on the main thread is deprecated because of its detrimental effects to the end user’s experience. For more help http://xhr.spec.whatwg.org/",

* 22 предупрежения об ошибке скачивания map-файлов следующего вида:

        Ошибка карты кода: Error: request failed with status 404
        URL ресурса: https://kvm.postgresql-replica.core.ufanet.ru/js/coreui.min.js
        URL карты кода: coreui.min.js.map

Поиски настроек безопасности Firefox, которые можно было бы отключить для того, чтобы веб-страницы начали исправно обновляться, не увенчались успехом.

В то же время эти страницы успешно открываются в Windows в браузере Microsoft Edge, а этот браузер был портирован в Linux, то появилась идея установить этот браузер.

Скачивание
----------

Переходим на сайт [microsoft.com](https://www.microsoft.com/ru-ru/), находим на странице ссылку [Microsoft Edge](https://www.microsoft.com/ru-ru/edge?form=MI13F3&OCID=MI13F3), при переходе на которой открывается страница с кнопкой "Скачать Edge".

Нажимаем на кнопку, поверх страницы открывается всплывающее окно с лицензионным согланием и кнопкой "Принять и скачать".

Нажимаем на кнопку, после чего автоматически начнётся скачивание deb-пакета.

Выбрать вариант для определённой операционной системы можно на странице [Download Microsoft Edge](https://www.microsoft.com/en-us/edge/download?form=MA13FJ). На этой странице можно найти строку следующего вида:

    Microsoft Edge is now available on Linux. Download for Linux (.deb) | Linux (.rpm)

При нажатии на ссылки "Linux (.deb)" или "Linux (.rpm)" откроется то же самое диалоговое окно принятия лицензионного соглашения, после чего автоматически начнётся скачивание пакета выбранного формата.
[Download Microsoft Edge](https://www.microsoft.com/en-us/edge/download?form=MA13FJ)

Установка
---------

Скачанный deb-пакет устанавливаем в систему следующим образом:

    # dpkg -i microsoft-edge-stable_121.0.2277.113-1_amd64.deb
    # apt-get install -f
