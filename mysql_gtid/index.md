Нишант Неупан. Как преобразовать обычную репликацию в репликацию GTID в MySQL
=============================================================================

[[!tag mysql gtid]]

Это перевод статьи: [Nishant Neupane. How to convert standard replication to GTID replication in MySQL](https://dba.stackexchange.com/questions/322821/how-to-convert-standard-replication-to-gtid-replication-in-mysql).

План включения GTID в конфигруации ведущий-ведомый без перерыва в работе заключается в том, чтобы разрешить ведомым серверам на некоторое время использовать репликацию как с GTID, так и без GTID, затем включить GTID на ведущем сервере и затем включить GTID на ведомых. Последовательность такова:

На ведущем сервере:

    SET global enforce_gtid_consistency = WARN;

Теперь нужно наблюдать в течение некоторого времени за журналом MySQL, появятся ли предупреждения о транзакциях, не поддерживаемых GTID. Если такие предупреждения есть, нужно доработать приложение так, чтобы оно использовало лишь те возможности, которые совместимы с GTID. Если предупреждений нет, следуем дальше.

На каждом из ведомых серверов:

    SET GLOBAL enforce_gtid_consistency = ON;
    SET GLOBAL gtid_mode = OFF_PERMISSIVE;
    SET GLOBAL gtid_mode = ON_PERMISSIVE;

Теперь на ведущем сервере:

    SET GLOBAL enforce_gtid_consistency = ON;
    SET GLOBAL gtid_mode = OFF_PERMISSIVE;
    SET GLOBAL gtid_mode = ON_PERMISSIVE;

Ждём, пока приведённый ниже запрос не начнёт возвращать 0:

    SHOW STATUS LIKE 'ONGOING_ANONYMOUS_TRANSACTION_COUNT';

Продолжаем на ведущем сервере:

    SET GLOBAL gtid_mode = ON;

На ведомых серверах:

    SET GLOBAL gtid_mode = ON;

Не забудьте добавить эти строки в файл `my.cnf` (на ведущих и на ведомых серверах).

    [mysqld]
    gtid_mode=ON
    enforce_gtid_consistency=ON

Можно оставить ведомые серверы как есть и они будут прекрасно работать, но также можно включить автоматическое позиционирование по GTID с помощью следующей команды:

    CHANGE MASTER TO MASTER_AUTO_POSITION = 1;

Проделайте эту же последовательность в случае, если на ведомых серверах включена многоканальная репликация. Перед включением GTID (`gtid_mode = ON`) на всех ведущих серверах, на ведомых серверах должен быть включен `gtid_mode = ON_PERMISSIVE`. После включения на всех ведущих серверах, включите GTID и на ведомых серверах.
