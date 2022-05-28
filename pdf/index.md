Работа с файлами PDF
====================

Чтобы разделить PDF-файл на страницы, можно воспользоваться утилитой из Image Magick:

    $ convert -density 300 docs.pdf image_%02d.png
