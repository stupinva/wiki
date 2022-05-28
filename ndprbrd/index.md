Сборка ndprbrd
==============

Ссылки на требуемые проекты на github:

- [ndprbrd](https://github.com/google/ndprbrd)
- [cpp-subprocess](https://github.com/tsaarni/cpp-subprocess/tree/123275d83e782eda42e0a8d4d0083f5dafb051c5)
- [cxxopts](https://github.com/jarro2783/cxxopts/tree/1be5f10daf6f08296eff399e82aa94d16800ef4e)

Установка инструментов для сборки ndprbrd:

    # apt-get install unzip g++ make cmake

Скачивание исходников:

    $ wget https://github.com/google/ndprbrd/archive/master.zip
    $ wget https://github.com/tsaarni/cpp-subprocess/archive/123275d83e782eda42e0a8d4d0083f5dafb051c5.zip -O cpp-subprocess.zip
    $ wget https://github.com/jarro2783/cxxopts/archive/1be5f10daf6f08296eff399e82aa94d16800ef4e.zip -O cxxopts.zip

Распаковка исходников:

    $ unzip master.zip
    $ cd ndprbrd-master/third_party/
    $ unzip ../../cpp-subprocess.zip
    $ mv cpp-subprocess-*/ cpp-subprocess/
    $ unzip ../../cxxopts.zip
    $ mv cxxopts-*/ cxxopts/

Сборка ndprbrd:

    $ cmake CMakeLists.txt
    $ make

В текущем каталоге образуется файл ndprbrd.
