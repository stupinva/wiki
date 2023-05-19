Настройка Linux для MySQL
=========================

Рекомендации по настройке Linux для MySQL:

- использовать свежие ядра Linux,
- использовать опции монтирования `noatime` и `nodiratime`,
- поменять планировщик ввода-вывода с Completely Fair Queueing (CFQ) на Noop или Deadline,
- установить swapinnes в 1 для снижения использования подкачки (выставлять в 0 не рекомендуется),
- удостовериться, что MySQL не будет уходить в область подкачки (путём настройки подходящих размеров буфера, общий объём которых не будет превышать объём оперативной памяти и включения опции `innodb_flush_method = O_DIRECT`).

Использованные материалы
------------------------

* [Muhammad Irfan. InnoDB Performance Optimization Basics](https://www.percona.com/blog/2013/09/20/innodb-performance-optimization-basics-updated/)
