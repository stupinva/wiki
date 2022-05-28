Редактор Vim
============

Настройки для Python
--------------------

В ~/.vimrc для редактирования исодных файлов Python можно добавить:

    set tabstop=4
    set softtabstop=4
    set shiftwidth=4
    set expandtab

Для автоматической настройки отступов (и кодировки файла) в зависимости от расширения открываемого файла можно прописать в ~/.vimrc настройки следующего вида:

    autocmd FileType c,cpp
    \ setlocal fileencoding=cp1251 |
    \ set tabstop=5 |
    \ set shiftwidth=5

Плагины/утилиты:

* ctags - индексация функций, объектов, структур проекта,
* cscope - то же самое,
* [NERD Tree](http://www.vim.org/scripts/script.php?script_id=1658) — удобная навигация по дереву файлов и каталогов,
* [TagBar](http://majutsushi.github.io/tagbar/)  — удобная навигация по списку функций, объявленных в файле.
* [EasyGrep](https://github.com/dkprice/vim-easygrep) — Показывает/Заменяет где упоминается объект поиска. Аналог grep'a, не выходя из vim'a.

Книги
-----

* [Learn Vimscript the Hard Way](https://learnvimscriptthehardway.stevelosh.com/)
