Настройка mutt
==============

Настройка ssmtp для отправки почты
----------------------------------

* [Mutt, ssmtp и отправка отчетов](https://habr.com/ru/post/82919/)

Настройка просмотра HTML
------------------------

Добавляем в файл ~/.muttrc следующие строки:

    alternative_order text/plain text/html
    auto_view text/html

Первая строка задаёт приоритет типов частей в письмах, состоящих из нескольких частей. Вторая строка настраивает автоматический просмотр, если письмо содержит только часть в формате HTML.

Добавляем в файл ~/.mailcap следующие строки:

    text/html; /usr/bin/chromium %s >/dev/null 2>&1; nametemplate=%s.html; needsterminal
    #text/html; /usr/bin/firefox %s >/dev/null 2>&1; nametemplate=%s.html; needsterminal
    text/html; /usr/bin/elinks -dump -dump-color-mode 1 %s; nametemplate=%s.html; copiousoutput

Печать из mutt в PDF
--------------------

* [Printing to PDF in Mutt](http://terminalmage.net/2011/10/12/printing-to-pdf-in-mutt.html)

Использованные материалы
------------------------

* [google chrome as mutt html viewer](http://enricorossi.org/blog/2010/google_chrome_as_mutt_html_viewer/)
* [How I Read HTML E-mail with Mutt](http://terminalmage.net/2014/03/16/how-i-read-html-email-with-mutt.html)
* [Html to ansi colored terminal text](https://stackoverflow.com/questions/5417376/html-to-ansi-colored-terminal-text#5459537) - раскраска HTML
