Мониторинг PostgreSQL с помощью Zabbix
======================================

[[!tag postgresql zabbix]]

Для мониторинга используется сценарий [[pgsql.sh]], который нужно положить в каталог `/etc/zabbix`, где находится конфигурация Zabbix-агента. Его владельцем можно сделать пользователя `root` и дать права читать и выполнять его всем:

    # chown root:root /etc/zabbix/pgsql.sh
    # chmod u=rwx,go=rx /etc/zabbix/pgsql.sh

Создадим пользователя PostgreSQL с именем `zabbix` и с паролем:

    # createuser -P zabbix

Далее нужно предоставить права `CONNECT` на все базы данных, за исключением `template0`:

    GRANT CONNECT ON DATABASE template1 TO zabbix;

Предоставив права доступа к базе данных `template1` мы обеспечим доступ пользователя `zabbix` ко всем вновь создаваемым базам данных.

Создадим файл `/etc/zabbix/pgpass` следующего вида:

    localhost:5432:*:zabbix:password

Вместо колонки `password` нужно указать пароль, ипользованный при создании пользователя `zabbix`.

Изменим права доступа к файлу в соответствии с требованиями утилиты `psql`:

    # chown zabbix:root /etc/zabbix/pgpass
    # chmod u=rw,go= /etc/zabbix/pgpass

Для проверки пользователя можно попробовать вызвать скрипт опроса следующим образом:

    # /etc/zabbix/pgsql.sh version

Теперь нужно внести в конфигурацию Zabbix-агента в файле `/etc/zabbix/zabbix_agentd.conf` дополнительные настройки:

    UserParameter=pgsql.version,/etc/zabbix/pgsql.sh version
    UserParameter=pgsql.max_connections,/etc/zabbix/pgsql.sh max_connections
    UserParameter=pgsql.active_connections,/etc/zabbix/pgsql.sh active_connections
    UserParameter=pgsql.idle_connections,/etc/zabbix/pgsql.sh idle_connections
    UserParameter=pgsql.idle_trx_connections,/etc/zabbix/pgsql.sh idle_trx_connections
    UserParameter=pgsql.lock_waiting_connections,/etc/zabbix/pgsql.sh lock_waiting_connections
    UserParameter=pgsql.total_connections,/etc/zabbix/pgsql.sh total_connections
    UserParameter=pgsql.slow_queries,/etc/zabbix/pgsql.sh slow_queries
    UserParameter=pgsql.slow_select_queries,/etc/zabbix/pgsql.sh slow_select_queries
    UserParameter=pgsql.slow_dml_queries,/etc/zabbix/pgsql.sh slow_dml_queries
    UserParameter=pgsql.buffers_alloc,/etc/zabbix/pgsql.sh buffers_alloc
    UserParameter=pgsql.buffers_backend,/etc/zabbix/pgsql.sh buffers_backend
    UserParameter=pgsql.buffers_backend_fsync,/etc/zabbix/pgsql.sh buffers_backend_fsync
    UserParameter=pgsql.buffers_checkpoint,/etc/zabbix/pgsql.sh buffers_checkpoint
    UserParameter=pgsql.buffers_clean,/etc/zabbix/pgsql.sh buffers_clean
    UserParameter=pgsql.checkpoints_req,/etc/zabbix/pgsql.sh checkpoints_req
    UserParameter=pgsql.checkpoints_timed,/etc/zabbix/pgsql.sh checkpoints_timed
    UserParameter=pgsql.maxwritten_clean,/etc/zabbix/pgsql.sh maxwritten_clean
    UserParameter=pgsql.discover.databases,/etc/zabbix/pgsql.sh discover_databases
    UserParameter=pgsql.numbackends[*],/etc/zabbix/pgsql.sh numbackends "$1"
    UserParameter=pgsql.temp_files[*],/etc/zabbix/pgsql.sh temp_files "$1"
    UserParameter=pgsql.temp_bytes[*],/etc/zabbix/pgsql.sh temp_bytes "$1"
    UserParameter=pgsql.tup_deleted[*],/etc/zabbix/pgsql.sh tup_deleted "$1"
    UserParameter=pgsql.tup_fetched[*],/etc/zabbix/pgsql.sh tup_fetched "$1"
    UserParameter=pgsql.tup_inserted[*],/etc/zabbix/pgsql.sh tup_inserted "$1"
    UserParameter=pgsql.tup_returned[*],/etc/zabbix/pgsql.sh tup_returned "$1"
    UserParameter=pgsql.tup_updated[*],/etc/zabbix/pgsql.sh tup_updated "$1"
    UserParameter=pgsql.xact_commit[*],/etc/zabbix/pgsql.sh xact_commit "$1"
    UserParameter=pgsql.xact_rollback[*],/etc/zabbix/pgsql.sh xact_rollback "$1"
    UserParameter=pgsql.deadlocks[*],/etc/zabbix/pgsql.sh deadlocks "$1"
    UserParameter=pgsql.cache_hit_ratio[*],/etc/zabbix/pgsql.sh cache_hit_ratio "$1"
    UserParameter=pgsql.commit_ratio[*],/etc/zabbix/pgsql.sh commit_ratio "$1"
    UserParameter=pgsql.db_size,/etc/zabbix/pgsql.sh db_size
    UserParameter=pgsql.db.size[*],/etc/zabbix/pgsql.sh db_size "$1"
    UserParameter=pgsql.discover.tables,/etc/zabbix/pgsql.sh discover_tables
    UserParameter=pgsql.table_size[*],/etc/zabbix/pgsql.sh table_size "$1" "$2" "$3"
    UserParameter=pgsql.seq_scan[*],/etc/zabbix/pgsql.sh seq_scan "$1" "$2" "$3"
    UserParameter=pgsql.idx_scan[*],/etc/zabbix/pgsql.sh idx_scan "$1" "$2" "$3"
    UserParameter=pgsql.idx_scan_ratio[*],/etc/zabbix/pgsql.sh idx_scan_ratio "$1" "$2" "$3"
    UserParameter=pgsql.n_tup_ins[*],/etc/zabbix/pgsql.sh n_tup_ins "$1" "$2" "$3"
    UserParameter=pgsql.n_tup_upd[*],/etc/zabbix/pgsql.sh n_tup_upd "$1" "$2" "$3"
    UserParameter=pgsql.n_tup_del[*],/etc/zabbix/pgsql.sh n_tup_del "$1" "$2" "$3"
    UserParameter=pgsql.n_tup_hot_upd[*],/etc/zabbix/pgsql.sh n_tup_hot_upd "$1" "$2" "$3"
    UserParameter=pgsql.n_tup_hot_upd_ratio[*],/etc/zabbix/pgsql.sh n_tup_hot_upd_ratio "$1" "$2" "$3"

Как вариант, указанные выше строчки можно прописать в один из файлов в каталоге `/etc/zabbix/zabbix_agentd.d` или `/etc/zabbix/zabbix_agentd.conf.d` или создать новый файл с указанными выше строками.

Для применения настроек Zabbix-агента нужно перезапустить при помощи одной из следующих команд:

    # systemctl restart zabbix-agent
    # /etc/init.d/zabbix-agent restart

Если у вас есть доступ к Zabbix-серверу или Zabbix-прокси, который осуществялет опрос Zabbix-агента, то проверить правильность настройки Zabbix-агента можно с помощью команд следующего вида:

    $ zabbix_get -s postgresql.core.ufanet.ru -k pgsql.version

После этого можно назначить наблюдаемому узлу шаблон [[Template_App_PostgreSQL_Active.xml]] для контроля общих показателей производительности и исправности.

Если следить за показателями производительности не требуется, то можно ограничиться шаблоном [[Template_App_PostgreSQL_process_Active.xml]]. Для использования этого шаблона описанная выше процедура настройки Zabbix-агента не требуется.

При необходимости вместо этих шаблонов можно воспользоваться одним из двух других, в которых вместо активного Zabbix-агента используется пассивный: [[Template_App_PostgreSQL.xml]], [[Template_App_PostgreSQL_process.xml]].
