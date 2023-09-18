Обновление Percona XtraDB Cluster
=================================

[[!tag mysql]]

Это перевод статьи: [Upgrading Percona XtraDB Cluster](https://docs.percona.com/percona-xtradb-cluster/5.7/howtos/upgrade_guide.html).

Содержание
----------

[[!toc startlevel=2 levels=4]]

В этом руководстве описана процедура обновления Percona XtraDB Cluster без перерыва в обслуживании (скользящее обновление) до самоей последней версии 5.7. "Скользящее обновление" означает, что оно не потребует полного отключения кластера в процессе обновления.

Этим способом можно выполнять обновления и старшей (с 5.6 до 5.7) и младшей (с 5.7.x до 5.7.y) версий. Скользящие обновления до версии 5.7 с версий до 5.6 не поддерживается. Поэтому если используется Percona XtraDB Cluster версии 5.5, рекомендуется выключить все узлы, удалить и создать кластер с нуля. Или можно выполнить [скользящее обновление с PXC версии 5.5 до версии 5.6](https://www.percona.com/doc/percona-xtradb-cluster/5.6/upgrading_guide_55_56.html), а затем воспользоваться описанной тут процедурой для обновления с версии 5.6 до версии 5.7.

В перечисленных ниже документах содержатся подробности, относящиеся к изменениям в ветке 5.7 MySQL и Percona Server. Перед обновлением до Percona XtraDB Cluster версии 5.7 убедитесь, что разобрались со всеми несовместимостями и переменными, перечисленными в этих документах.

* [Изменения в Percona Server версии 5.7](https://www.percona.com/doc/percona-server/5.7/changed_in_57.html)
* [Обновление MySQL](https://dev.mysql.com/doc/refman/5.7/en/upgrading.html)
* [Обновление с MySQL версии 5.6 до версии 5.7](https://dev.mysql.com/doc/refman/5.7/en/upgrading-from-previous-series.html)

Обновление старшей версии
-------------------------

Для обновления кластера воспользуйтесь следующей последовательностью действий на каждом из узлов:

Убедитесь, что все узлы синхронизированы.

Остановите сервис `mysql`:

    $ sudo service mysql stop

Удалите существующие пакеты Percona XtraDB Cluster и Percona XtraBackup, затем установите пакеты с Percona XtraDB Cluster версии 5.7. За дополнительной информацией обратитесь к документу [Установка Percona XtraDB Cluster](https://docs.percona.com/percona-xtradb-cluster/5.7/install/index.html#install).

Например, если настроены репозитории с программным обеспечением Percona, то можно воспользоваться следующими командами:

В CentOS или RHEL:

    $ sudo yum remove percona-xtrabackup* Percona-XtraDB-Cluster*
    $ sudo yum install Percona-XtraDB-Cluster-57

В Debian или Ubuntu:

    $ sudo apt remove percona-xtrabackup* percona-xtradb-cluster*
    $ sudo apt install percona-xtradb-cluster-57

В случае с Debian или Ubuntu служба `mysql` после установки запустится автоматически. Остановите службу:

    $ sudo service mysql stop

Сохраните резервную копию файла `grastate.dat`, чтобы восстановить его, если он будет повреждён или очищен из-за проблем с сетью.

Запустите узел вне кластера (в автономном режиме), переключив переменную [wsrep_provider](https://docs.percona.com/percona-xtradb-cluster/5.7/wsrep-system-index.html#wsrep_provider) в значение `none`.

Например:

    $ sudo mysqld --skip-grant-tables --user=mysql --wsrep-provider='none'

Примечание:

> Начиная с Percona XtraDB Cluster версии 5.7.6, опция `--skip-grant-tables` не требуется.

Примечание:

> Для предотвращения доступа со стороны пользователей к этому узлу на время проведения работ можно добавить опцию [--skip-networking](https://dev.mysql.com/doc/refman/5.7/en/server-system-variables.html#sysvar_skip_networking) к опциям при запуске и использовать локальный сокет для подключения, или можно перевести трафик приложений на другие узлы.

Откройте другой сеанс и запустите `mysql_upgrade`.

После завершения обновления остановите процесс `mysqld`. Вы можете либо запустить `sudo kill` с идентификатором процесса `mysqld`, либо `sudo mysqladmin shutdown` с учётными данными пользователя root в MySQL.

Примечание:

> В CentOS файл конфигурации `my.cnf` будет переименован в `my.cnf.rpmsave`. Убедитесь, что восстановили файл перед тем, как вернуть обновлённый узел в кластер.

Теперь можно вернуть обновлённый узел в кластер.

В большинстве случаев для запуска узла в предыдущей конфигурации достаточно запустить сервис `mysql`:

    $ sudo service mysql start

За дополнительной информацией обратитесь к документу [Добавление узлов в кластер](https://docs.percona.com/percona-xtradb-cluster/5.7/add-node.html#add-node).

Примечание:

> Начиная с версии 5.7 Percona XtraDB Cluster по умолчанию запускается со включенным [строгим режимом PXC](https://docs.percona.com/percona-xtradb-cluster/5.7/features/pxc-strict-mode.html#pxc-strict-mode). Этот режим запрещает выполнять любые неподдерживаемые операции и при возникновении ошибок может привести к остановке сервера.

> Если нет уверенности, рекомендуется сначала запустить узел с переменной [pxc_strict_mode](https://docs.percona.com/percona-xtradb-cluster/5.7/wsrep-system-index.html#pxc_strict_mode), выставленной в значение `PERMISSIVE` в файле конфигурации MySQL `my.cnf`.

> После проверки журнала на использование экспериментальных или неподдерживаемых возможностей и исправления обнаруженных несовместимостей, можно вернуть переменной значение `ENFORCING` во время работы:

> `mysql> SET pxc_strict_mode=ENFORCING;`

> А также можно вернуть значение ENFORCING путём перезапуска узла после изменения файла `my.cnf`.

Повторите эти действия для следующего узла кластера, пока не обновите все узлы.

Для повторного ввода узла в кластер важно, чтобы узел синхронизировался с использованием [IST](https://docs.percona.com/percona-xtradb-cluster/5.7/glossary.html#ist). Для этого лучше, чтобы узел не покидал кластер в процессе обновления на длительный период времени. Подробнее об этом написано ниже.

При проведении любого из обновлений (старшей или младшей версии), после того, как сервер был некоторое время отключен, присоединяющийся узел инициирует [SST](https://docs.percona.com/percona-xtradb-cluster/5.7/glossary.html#sst). После завершения [SST](https://docs.percona.com/percona-xtradb-cluster/5.7/glossary.html#sst) структуру каталога с данными будет нужно обновить (с помощью `mysql_upgrade`) один или более раз для того, чтобы быть уверенным в совместимости с более новыми версиями двоичных файлов.

Примечание:

> В случае синхронизации [SST](https://docs.percona.com/percona-xtradb-cluster/5.7/glossary.html#sst), журнал ошибок содержит выражения следующего вида: "Check if state gap can be serviced using IST … State gap can’t be serviced using IST. Switching to SST" ("Проверка возможности устранения разрыва с помощью IST... Разрыв не может быть устранён с помощью IST. Переключение на SST") вместо строк вида "Receiving IST: …" ("Приём IST: ...") в случае синхронизации [IST](https://docs.percona.com/percona-xtradb-cluster/5.7/glossary.html#sst).

Обновление младшей версии
-------------------------

Для обновления кластера воспользуйтесь следующей последовательностью действий на каждом из узлов:

Убедитесь, что все узлы синхронизированы.

Остановите службу `mysql`:

    $ sudo service mysql stop

Обновите пакеты Percona XtraDB Cluster и Percona XtraBackup. За дополнительной информацией обратитесь к документу [Установка Percona XtraDB Cluster](https://docs.percona.com/percona-xtradb-cluster/5.7/install/index.html#install).

Например, если настроены репозитории с программным обеспечением Percona, то можно воспользоваться следующими командами:

В CentOS или RHEL:

    $ sudo yum update Percona-XtraDB-Cluster-57

В Debian или Ubuntu:

    $ sudo apt install --only-upgrade percona-xtradb-cluster-57

В случае с Debian или Ubuntu служба `mysql` после установки запустится автоматически.

Остановите службу:

    $ sudo service mysql stop

Сохраните резервную копию файла `grastate.dat`, чтобы восстановить его, если он будет повреждён или очищен из-за проблем с сетью.

Запустите узел вне кластера (в автономном режиме), переключив переменную [wsrep_provider](https://docs.percona.com/percona-xtradb-cluster/5.7/wsrep-system-index.html#wsrep_provider) в значение `none`.

Например:

    $ sudo mysqld --skip-grant-tables --user=mysql --wsrep-provider='none'

Примечание:

> Начиная с Percona XtraDB Cluster версии 5.7.6, опция `--skip-grant-tables` не требуется.

Примечание:

> Для предотвращения доступа со стороны пользователей к этому узлу на время проведения работ можно добавить опцию [--skip-networking](https://dev.mysql.com/doc/refman/5.7/en/server-system-variables.html#sysvar_skip_networking) к опциям при запуске и использовать локальный сокет для подключения, или можно перевести трафик приложений на другие узлы.

Откройте другой сеанс и запустите `mysql_upgrade`.

После завершения обновления остановите процесс `mysqld`. Вы можете либо запустить `sudo kill` с идентификатором процесса `mysqld`, либо `sudo mysqladmin shutdown` с учётными данными пользователя root в MySQL.

Примечание:

> В CentOS файл конфигурации `my.cnf` будет переименован в `my.cnf.rpmsave`. Убедитесь, что восстановили файл перед тем, как вернуть обновлённый узел в кластер.

Теперь можно вернуть обновлённый узел в кластер.

В большинстве случаев для запуска узла в предыдущей конфигурации достаточно запустить сервис `mysql`:

    $ sudo service mysql start

За дополнительной информацией обратитесь к документу [Добавление узлов в кластер](https://docs.percona.com/percona-xtradb-cluster/5.7/add-node.html#add-node).

Примечание:

> Начиная с версии 5.7 Percona XtraDB Cluster по умолчанию запускается со включенным [строгим режимом PXC](https://docs.percona.com/percona-xtradb-cluster/5.7/features/pxc-strict-mode.html#pxc-strict-mode). Этот режим запрещает выполнять любые неподдерживаемые операции и при возникновении ошибок может привести к остановке сервера.

> Если нет уверенности, рекомендуется сначала запустить узел с переменной [pxc_strict_mode](https://docs.percona.com/percona-xtradb-cluster/5.7/wsrep-system-index.html#pxc_strict_mode), выставленной в значение PERMISSIVE в файле конфигурации MySQL my.cnf.

> После проверки журнала на использование экспериментальных или неподдерживаемых возможностей и исправления обнаруженных несовместимостей, можно вернуть переменной значение ENFORCING во время работы:

> `mysql> SET pxc_strict_mode=ENFORCING;`

> А также можно вернуть значение ENFORCING путём перезапуска узла после изменения файла my.cnf.

Повторите эти действия для следующего узла кластера, пока не обновите все узлы.

Использование синхронизации IST/SST при обновлении
--------------------------------------------------

Для повторного ввода узла в кластер важно, чтобы узел синхронизировался с использованием [IST](https://docs.percona.com/percona-xtradb-cluster/5.7/glossary.html#ist). Для этого лучше, чтобы узел не покидал кластер в процессе обновления на длительный период времени. Подробнее об этом написано ниже.

При проведении любого из обновлений (старшей или младшей версии), после того, как сервер был некоторое время отключен, присоединяющийся узел инициирует [SST](https://docs.percona.com/percona-xtradb-cluster/5.7/glossary.html#sst). После завершения [SST](https://docs.percona.com/percona-xtradb-cluster/5.7/glossary.html#sst) структуру каталога с данными будет нужно обновить (с помощью mysql_upgrade) один или более раз для того, чтобы быть уверенным в совместимости с более новыми версиями двоичных файлов.

Примечание:

> В случае синхронизации SST, журнал ошибок содержит выражения следующего вида: "Check if state gap can be serviced using IST … State gap can’t be serviced using IST. Switching to SST" ("Проверка возможности устранения разрыва с помощью IST... Разрыв не может быть устранён с помощью IST. Переключение на SST") вместо строк вида "Receiving IST: …" ("Приём IST: ...") в случае синхронизации [IST](https://docs.percona.com/percona-xtradb-cluster/5.7/glossary.html#ist).

Для обновления структуры каталога данных после SST нужно проделать следующие дополнительные действия (после обычных действий по обновлению старшей или младшей версии):

Выключить узел, который повторно присоединился к кластеру с использованием [SST](https://docs.percona.com/percona-xtradb-cluster/5.7/glossary.html#sst):

    $ sudo service mysql stop

Запустить узел вне кластера (в автономном режиме), переключив переменную [wsrep_provider](https://docs.percona.com/percona-xtradb-cluster/5.7/wsrep-system-index.html#wsrep_provider) в значение `none`, например:

    $ sudo mysqld --skip-grant-tables --user=mysql --wsrep-provider='none'

Запустить `mysql_upgrade`

Перезапустить узел в режиме кластера (например, выполнив `sudo service mysql start`) и убедиться, что он вернулся в кластер с помощью [IST](https://docs.percona.com/percona-xtradb-cluster/5.7/glossary.html#ist).
