Настройка ikiwiki
=================

Оглавление
----------

[[!toc startlevel=2 levels=3]]

Настройка внешнего вида
-----------------------

По умолчанию Ikiwiki выглядит довольно консервативно. К счастью, для настройки внешнего вида страниц не обязательно создавать собственную тему оформления с шаблонами страниц. Достаточно создать в каталоге с исходными файлами файл с дополнительными CSS-стилями - `local.css`. Например, я прописал в этот файл следующие стили:

    body { margin-left: 10%; margin-right: 10%; background: url(https://stupin.su/blog/background.jpeg) repeat; }
    table { border-collapse: collapse; margin: auto; }
    td, th { border-style: solid; border-width: 1px; padding: 5px; }
    pre code { background-color: black; color: white; display: inline-block; padding: 10px; }
    blockquote { border-color: black; border-style: solid; border-left-width: 3px; border-right-width: 0px; border-top-width: 0px; border-bottom-width: 0px; padding-left: 5px; }
    img { max-width: 100%; max-height: 480px; margin: auto; display: block; padding: 10px; }

Этот стиль:

* добавляет на страницу поля по 10 процентов слева и справа, а также фоновую картинку,
* выравнивает таблицы по середине текста, добавляет тонкие чёрные бордюры и слега отодвигает бордюры от содержимого ячеек,
* выводит фрагменты кода белыми буквами на чёрном фоне подходящей ширины,
* добавляет к цитатам слева вертикальную черту,
* выводит картинки по середине текста, ограничивает их размеры и добавляет отступы вокруг картинки.

После добавления стиля нужно как обычно выполнить обновление HTML-страниц, чтобы добавленный файл стилей появился в каталоге с HTML-страницами:

    $ ikiwiki --setup src/.ikiwiki/ikiwiki.setup

Оформление страницы в целом и таблицы:

![local.css, страница и таблица на ней](local_css_table.png)

Оформление блока кода:

![Блок кода](pre_code.png)

Оформление цитаты:

![Цитата](blockquote.png)

Плагины
-------

Список плагинов, включенных по умолчанию, можно найти в исходном коде ikiwiki. В файле `/usr/pkg/lib/perl5/vendor_perl/5.34.0/Ikiwiki.pm` я нашёл следующий фрагмент кода:

    default_plugins => {
            type => "internal",
            default => [qw{mdwn link inline meta htmlscrubber passwordauth
                            openid signinedit lockedit conditional
                            recentchanges parentlinks editpage
                            templatebody}],
            description => "plugins to enable by default",
            safe => 0,
            rebuild => 1,
    },

По умолчанию включены следующие плагины:

* [mdwn](https://ikiwiki.info/plugins/mdwn/)
* [link](https://ikiwiki.info/plugins/link/)
* [inline](https://ikiwiki.info/plugins/inline/)
* [meta](https://ikiwiki.info/plugins/meta/)
* [htmlscrubber](https://ikiwiki.info/plugins/htmlscrubber/)
* [passwordauth](https://ikiwiki.info/plugins/passwordauth/)
* [openid](https://ikiwiki.info/plugins/openid/)
* [signinedit](https://ikiwiki.info/plugins/signinedit/)
* [lockedit](https://ikiwiki.info/plugins/lockedit/)
* [conditional](https://ikiwiki.info/plugins/conditional/)
* [recentchanges](https://ikiwiki.info/plugins/recentchanges/)
* [parentlinks](https://ikiwiki.info/plugins/parentlinks/)
* [editpage](https://ikiwiki.info/plugins/editpage/)
* [templatebody](https://ikiwiki.info/plugins/templatebody/)

Для подключения дополнительных плагинов нужно добавлять их к опции `add_plugins` в файле конфигурации. Я использую возможности YML для более наглядного форматирования списка следующим образом:

    add_plugins:
      - toc
      - attachment
      - websetup
      - tag

### websetup

Этот плагин позволяет редактировать файл конфигурации прямо через веб-браузер.

### toc

Этот плагин добавляет поддержку директивы `toc`, с помощью которой можно добавить на страницу оглавление. У директивы есть две опции: `startlevel` и `levels` указывают минимальную и максимальную глубину заголовков в иерархии, которые будут добавлены в оглавление.

Например, чтобы исключить из оглавление заголовок первого уровня, которому соответствует HTML-тег `h1`, и не помещать в оглавление заголовки уровне 4-6, которым соответствуют HTML-теги `h4`-`h6`, можно использовать следующую директиву:

    [[!toc startlevel=2 levels=3]]

Результат можно увидеть на картинке:

![Сгенерированное оглавление документа](toc.png)

### attachments

Этот плагин позволяет добавлять к статьям вложенные файлы, например - картинки. Вложенные файлы загружаются в каталог, который называется так же, как и статья, к которой они относятся. Если в настройках включена опция `indexpages`, то исходный текст статьи и сам находится в этом же каталоге под именем `index`.

При включении плагина рядом с кнопками под окном редактирования страницы появляется дополнительная ссылка:

![Кнопки и меню](attachments1.png)

При нажатии на ссылку появляется список уже загруженных вложений и дополнительные кнопки:

![Дополнительные кнопки и список вложений](attachments2.png)

### remove

Этот плагин позволяет удалять файлы, к которым пользователь имеет доступ на редактирование.

Дополнительная кнопка под окном редактирования для удаления страниц:

![Кнопка удаления страниц](remove1.png)

![Кнопка удаления вложений](remove2.png)

### rename

Этот плагин позволяет переименовывать файлы и страницы, к которым пользователь имеет доступ на редактирование. Кроме того, при переименовании пытается исправить все ссылки, указывающие на переименованный файл.

![Кнопка переименования страниц](rename1.png)

![Кнопка переименования вложений](rename2.png)

### tag

### taglink

### Интеграция с git

Для интеграции ikiwiki с git-репозиторием нужно поместить исходный каталог в репозиторий git и настроить его для беспрепятственного выполнения команды `git push`.

Предположим, что путь к каталогу с исходными файлами - `/home/wiki/src/`. Тогда для настройки репозитория нужно выполнить следующие команды:

    $ cd /home/wiki/src
    $ git init
    $ git config --local --add user.email wiki@stupin.su
    $ git config --local --add user.name stupin.su/wiki

Добавим в репозиторий все файлы и сделаем первую фиксацию:

    $ git add *
    $ git commit -m "Начальное размещение файлов"

Для того, чтобы изменения отслеживались не только в локальном репозитории, но и в удалённом, нужно добавить ссылку на удалённый репозиторий, содержащий учётные данные пользователя для доступа по протоколу HTTP или HTTPS, либо настроить доступ к репозиторию по SSH с помощью SSH-ключа. Я воспользуюсь первым способом:

    $ git remote add origin https://wiki:p4$$w0rd@stupin.su/git/stupin/wiki.git

В моём случае репозиторий размещается в системе Gitea. Gitea позволяет сгенерировать для пользователя ключ, который можно использовать вместо пароля. Именно его я и поместил в ссылку

Отправим локальные фиксации в ветку `master` репозитория `origin`:

    $ git push -u origin master

Теперь можно включить в файле конфигурации `src/.ikiwiki/ikiwiki.setup` использование git:

    rcs: 'git'

При помощи опции `git_wrapper_background_command` можно настроить команду для отправки изменений из локального репозитория в удалённый:

    git_wrapper_background_command: 'git push'

Для применения настроек нужно вызвать `ikiwiki` с новым файлом конфигурации:

    $ ikiwiki --setup src/.ikiwiki/ikiwiki.setup

Если всё хорошо, то изменения страниц должны фиксироваться в локальном и удалённом репозиториях. Под формой редактирования текста появится поле "Optional description of this change:" для ввода описания изменений, а в строке меню появится ссылка "RecentChanges", по которой можно будет отслеживать последние изменения:

[[git.png]]

Кроме того, можно указать опцию `historyurl` для добавления возможности просмотра изменений отдельной страницы:

    historyurl: 'https://stupin.su/git/stupin/wiki/commits/branch/master/\[[file]]'

Имя страницы, историю изменения которой нужно посмотреть, будет подставляться вместо текста `\[[file]]`. Для применения новых настроек нужно вызвать `ikiwiki` с новым файлом конфигурации:

    $ ikiwiki --setup src/.ikiwiki/ikiwiki.setup

После этого в строке меню при просмотре страницы появится ссылка "History", ведущая в git-репозиторий с историей изменения файла текущей страницы. Выглядит это следующим образом:

[[git_history.png]]

Дополнительные материалы
------------------------

* [Self-hosting an Ikiwiki blog](https://feeding.cloud.geek.nz/posts/self-hosting-ikiwiki-blog/)
* [Настройка Ikiwiki в Debian](https://vitus-wagner.dreamwidth.org/716209.html)
* [Self-hosting an Ikiwiki blog](https://feeding.cloud.geek.nz/posts/self-hosting-ikiwiki-blog/)
