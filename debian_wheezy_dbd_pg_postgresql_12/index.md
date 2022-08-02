Исправление DBD::Pg из Debian Wheezy для поддержки PostgreSQL 12 и выше
=======================================================================

Постановка задачи
-----------------

После обновления PostgreSQL 9.6 до PostgreSQL 12 появились ошибки следующего вида:

    column d.adsrc does not exist at character 333

Ошибки порождались запросами следующего вида:

    SELECT a.attname, i.indisprimary, pg_catalog.pg_get_expr(adbin,adrelid)
    FROM pg_catalog.pg_index i, pg_catalog.pg_attribute a, pg_catalog.pg_attrdef d
     WHERE i.indrelid = 719060 AND d.adrelid=a.attrelid AND d.adnum=a.attnum
      AND a.attrelid = 719060 AND i.indisunique IS TRUE
      AND a.atthasdef IS TRUE AND i.indkey[0]=a.attnum
     AND d.adsrc ~ '^nextval'

Эти запросы порождал модуль `DBD::Pg` из приложения, работающего в Debian Wheezy.

Аналогичная проблема описана по ссылке: [Autodoc fails on PostgreSQL 12 #19](https://github.com/cbbrowne/autodoc/issues/19).

Там же можно найти выдержку из официальной документации к выпуску PostgreSQL 12:

>Remove obsolete pg_attrdef.adsrc column (Peter Eisentraut)
>    
>This column has been deprecated for a long time, because it did not update in response to other catalog changes (such as column renamings). The recommended way to get a text version of a default-value expression from pg_attrdef is pg_get_expr(adbin, adrelid).

Суть решения сводится к замене поля `adsrc` в запросах к таблице `pg_attrdef` на выражение `pg_get_expr(adbin, adrelid)`. Если обратить внимание на проблемный запрос, то можно увидеть, что первая строчка запроса уже исправлена, но не исправлена последняя строчка.

Итак, нужно собрать пакет с модулем `DBD::Pg` для Debian Wheezy, в котором проблемный запрос будет исправлен так, чтобы модуль работал с PostgreSQL версий 12 и выше.

