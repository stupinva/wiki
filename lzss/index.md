Варианты реализации алгоритма LZSS
==================================

Вариант 1
---------

Вариант 2
---------

Реализацию декодировщика можно найти по ссылке [lzss.py](https://github.com/magical/nlzss/blob/master/lzss.py).

1. Читаем из потока байт флагов. В этом байте биты в порядке от старшего к младшему расшифровываются следующим образом:
* 0 - из входного потока прочитать байт и поместить его в выходной поток и в скользящее окно,
* 1 - прочитать из входного потока байт-команду,
2. Сопоставить прочитанный байт-команду с шаблоном 0x, 1x или Xx:
* если прочитан байт 0x, то читаем ещё два байта Yy Zz, вычисляем count = xY + 0x11, offset = yZz,
* если прочитан байт 1x, то читаем ещё три байта Yy Zz Ww, вычисляем count = xYyZ + 0x111, offset = zWw,
* если прочитан байт Xx, то читаем ещё один байт Yy, вычисляем count = X + 1, offset = xYy.
* offset указывает на позицию копируемых байтов в скользящем окне, count указывает на количество байт, которые нужно скопировать из скользящего окна в выходной поток и в скользящее окно,
3. Если флаги ещё остались, продолжить их обработку, если нет - перейти к началу и повторить.
