Использование basepkg для сборки пакетов с базовой системой NetBSD
==================================================================

Установить утилиту можно из pkgsrc wip/basepkg. Я просто добавил сборку этой утилиты в pkg_comp и установил её из самосборного репозитория с помощью pkgin.

При запуске утилите нужно указать пути к файлам, из которых она будет собирать пакеты, а также указать платформу, архитектуру и список исходных архивов, из которых нужно сформировать пакеты.

Для сборки пакетов из архивов базовой системы выполним следующие команды:

    # cd /usr/pkg/basepkg
    # ./basepkg.sh --arch i386 \
                   --category "base comp etc games man misc modules rescue text" \
                   --destdir /home/sysbuild/i386/destdir/ \
                   --machine i386 \
                   --obj /home/sysbuild/i386/obj/home/sysbuild/src/ \
                   --releasedir /home/sysbuild/release/ \
                   --src /home/sysbuild/src/ \
                   pkg

Для сборки архивов с ядром системы запустим такую команду:

    # cd /usr/pkg/basepkg
    # ./basepkg.sh --arch i386 \
                   --destdir /home/sysbuild/i386/destdir/ \
                   --machine i386 \
                   --obj /home/sysbuild/i386/obj/home/sysbuild/src/ \
                   --releasedir /home/sysbuild/release/ \
                   --src /home/sysbuild/src/ \
                   kern

Сборка архивов с системой X не предусмотрена.

В результате в каталоге `/home/sysbuild/release/packages/9.2_STABLE/i386` сформируются пакеты, пригодные для установки с помощью `pkg_add`.

Стоит отметить, что многие из собранных пакетов могут не содержать устанавливаемых файлов, если в файле конфигруации `/etc/mk.conf` сборка соответствующих компонентов отключена, как я это описывал в статье [[Пересборка базовой системы NetBSD|netbsd_base]].
