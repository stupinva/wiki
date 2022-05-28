Сборка PPPoE-сервера с модулем ядра
===================================

Установим пакеты, необходимые для сборки:

    # apt-get install ppp-dev devscripts

Скачиваем из репозиториев исходные тексты пакета pppoe, распаковываем их и переходим в каталог с распакованными файлами:

    # apt-get source pppoe
    # cd rp-pppoe-3.12/

Открываем файл debian/rules, находим в нём следующую строчку:

    test -f src/Makefile || (cd src && PPPD=/usr/sbin/pppd ./configure)

И добавляем опцию для сборки плагина, без сборки которого попытки включить поддержку PPPoE со стороны ядра не предпринимаются:

    test -f src/Makefile || (cd src && PPPD=/usr/sbin/pppd ./configure --enable-plugin)

При попытке скомпилировать получаем от компилятора множество ошибок вида:

    In file included from pppoe.h:134:0,
                     from plugin.c:31:
    /usr/include/linux/in.h:28:3: error: redeclaration of enumerator ‘IPPROTO_IP’
       IPPROTO_IP = 0,  /* Dummy protocol for TCP  */
       ^
    /usr/include/netinet/in.h:42:5: note: previous definition of ‘IPPROTO_IP’ was here
         IPPROTO_IP = 0,    /* Dummy protocol for TCP.  */
         ^~~~~~~~~~

Компилятор ругается на то, что в заголовочном файле linux/in.h повторяются объявления, которые уже имеются в файле netinet/in.h. Исправим файл src/configure.in, удалив из исходного текста теста строчку с заголовочным файлом netinet/in.h.

Аналогичные изменения понадобится внести в файл src/pppoe.h.

Зафиксируем изменения в пакете:

    # dpkg-source --commit

В ответ на запрос имени патча введём, например, pppoe-server-kernel-support, а открывшемся текстовом редакторе отредактируем описание патча, доведя его до следующего вида:

    Description: Fixed PPPoE kernel support for pppoe-server
    Fixed PPPoE kernel support for pppoe-server
     .
     rp-pppoe (3.12-1.2) unstable; urgency=low
    Author: Vladimir Stupin <vladimir@stupin.su>
    Last-Update: 2018-09-17
  
  --- rp-pppoe-3.12.orig/src/configure.in
    +++ rp-pppoe-3.12/src/configure.in
    @@ -168,7 +168,6 @@ fi
     AC_TRY_RUN([#include <sys/socket.h>
     #include <net/ethernet.h>
     #include <linux/if.h>
  -#include <netinet/in.h>
     #include <linux/if_pppox.h>
     int main()
     {
  --- rp-pppoe-3.12.orig/src/pppoe.h
    +++ rp-pppoe-3.12/src/pppoe.h
    @@ -131,8 +131,6 @@ typedef unsigned long UINT32_t;
     #include <linux/if_ether.h>
     #endif
  
  -#include <netinet/in.h>
  -
     #ifdef HAVE_NETINET_IF_ETHER_H
     #include <sys/types.h>

Отметим изменения в журнале изменений пакета. Для этого выполним следующую команду:

    # dch -i

И введём описание изменений:

    rp-pppoe (3.12-1.2) UNRELEASED; urgency=medium
  
      * Non-maintainer upload.
      * Fixed PPPoE kernel support for pppoe-server
  
     -- Vladimir Stupin <vladimir@stupin.su>  Mon, 17 Sep 2018 23:12:00 +0500

Осталось собрать исправленный пакет:

    # dpkg-buildpackage -us -uc -rfakeroot

Цель была в том, чтобы добиться поддержки PPPoE хоть тушкой, хоть чучелом. И это-таки получилось - в выводе предыдущей команды можно заметить такие строчки:

    checking for Linux 2.4.X kernel-mode PPPoE support... no
    *** Your kernel does not appear to have built-in PPPoE support,
    *** but I will build the kernel-mode plugin anyway.

Переходим в вышестоящий каталог и устанавливаем собранный пакет:

    # cd ..
    # dpkg -i pppoe_3.12-1.2_amd64.deb

Пробуем запустить PPPoE-сервер с поддержкой PPPoE со стороны ядра:

    # pppoe-server -I eth0 -k

Сервер нормально воспринял опцию `-k` и, видимо, успешно создал специальный сокет, поддерживаемый модулем ядра pppoe.
