Установка Oracle JDK 1.8 в Debian
=================================

[[!tag supermicro debian bookworm java]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Введение
--------

После [[установки Microsoft Edge в Debian|debian_installing_edge]] появляется возможность удалённо подключиться к консоли сервера через веб-браузер Microsoft Edge с помощью одного из двух вариантов клиентов: HTML 5 или Java.

[[html5_java.png]]

Однако, при использовании удалённой консоли в варианте HTML 5 необходима лицензия для монитрования носителей данных. При использовании удалённой консоли в варианте Java лицензия не нужна, однако JNLP-приложение не работает с OpenJDK 17, поставляемом в штатных репозиториях Debian 12 Bookworm.

    $ javaws launch.jnlp 
    WARNING: package sun.applet not in java.desktop
    WARNING: package com.sun.net.ssl.internal.ssl not in java.base
    WARNING: A command line option has enabled the Security Manager
    WARNING: The Security Manager is deprecated and will be removed in a future release
    WARNING: A terminally deprecated method in java.lang.System has been called
    WARNING: System::setSecurityManager has been called by net.sourceforge.jnlp.runtime.JNLPRuntime
    WARNING: Please consider reporting this to the maintainers of net.sourceforge.jnlp.runtime.JNLPRuntime
    WARNING: System::setSecurityManager will be removed in a future release
    Не удалось использовать параметры прокси Firefox. В качестве типа прокси используется "DIRECT".
    WARNING: package sun.applet not in java.desktop
    WARNING: package com.sun.net.ssl.internal.ssl not in java.base
    WARNING: A command line option has enabled the Security Manager
    WARNING: The Security Manager is deprecated and will be removed in a future release
    WARNING: A terminally deprecated method in java.lang.System has been called
    WARNING: System::setSecurityManager has been called by net.sourceforge.jnlp.runtime.JNLPRuntime
    WARNING: Please consider reporting this to the maintainers of net.sourceforge.jnlp.runtime.JNLPRuntime
    WARNING: System::setSecurityManager will be removed in a future release
    Не удалось использовать параметры прокси Firefox. В качестве типа прокси используется "DIRECT".
    JAR https://kvm.postgresql-replica.core.ufanet.ru:443/iKVM__V1.69.53.0x0.jar not found. Continuing.
    JAR https://kvm.postgresql-replica.core.ufanet.ru:443/liblinux_x86_64__V1.0.22.jar not found. Continuing.
    JAR https://kvm.postgresql-replica.core.ufanet.ru:443/iKVM__V1.69.53.0x0.jar not found. Continuing.
    JAR https://kvm.postgresql-replica.core.ufanet.ru:443/liblinux_x86_64__V1.0.22.jar not found. Continuing.
    netx: Ошибка инициализации: Не удалось инициализировать приложение. (Критическая: Ошибка инициализации: Неизвестный атрибут Main-Class. Не удалось определить основной класс для этого приложения.)
    net.sourceforge.jnlp.LaunchException: Критическая: Ошибка инициализации: Не удалось инициализировать приложение. Приложение не было инициализировано. Для получения дополнительных сведений выполните в командной строке команду javaws.
            at java.desktop/net.sourceforge.jnlp.Launcher.createApplication(Launcher.java:823)
            at java.desktop/net.sourceforge.jnlp.Launcher.launchApplication(Launcher.java:531)
            at java.desktop/net.sourceforge.jnlp.Launcher$TgThread.run(Launcher.java:946)
    Caused by: net.sourceforge.jnlp.LaunchException: Критическая: Ошибка инициализации: Неизвестный атрибут Main-Class. Не удалось определить основной класс для этого приложения.
            at java.desktop/net.sourceforge.jnlp.runtime.JNLPClassLoader.initializeResources(JNLPClassLoader.java:775)
            at java.desktop/net.sourceforge.jnlp.runtime.JNLPClassLoader.<init>(JNLPClassLoader.java:337)
            at java.desktop/net.sourceforge.jnlp.runtime.JNLPClassLoader.createInstance(JNLPClassLoader.java:420)
            at java.desktop/net.sourceforge.jnlp.runtime.JNLPClassLoader.getInstance(JNLPClassLoader.java:494)
            at java.desktop/net.sourceforge.jnlp.runtime.JNLPClassLoader.getInstance(JNLPClassLoader.java:467)
            at java.desktop/net.sourceforge.jnlp.Launcher.createApplication(Launcher.java:815)
            ... 2 more

Поиск решения с репозиториями Debian
------------------------------------

Если заглянуть внутрь файла `launch.jnlp`, то можно увидеть, что приложение написано в расчёта на Java версии 6:

    <j2se version="1.6.0+" initial-heap-size="128M" max-heap-size="128M" java-vm-args="-XX:PermSize=32M -XX:MaxPermSize=32M"/>

Если попробовать скачать и установить Java 6 версии из архива официальных репозиториев Debian 5 Lenny, то окажется, что в официальных репозиториях Debian 12 Bookworm не хватает некоторых пакетов-зависимостей. При попытке установить их пакеты с Java 6 удаляются:

    $ wget http://archive.debian.org/debian/pool/main/o/openjdk-6/openjdk-6-jdk_6b18-1.8.10-0~lenny2_amd64.deb
    $ wget http://archive.debian.org/debian/pool/main/o/openjdk-6/openjdk-6-jdk_6b18-1.8.10-0~lenny2_amd64.deb
    $ wget http://archive.debian.org/debian/pool/main/o/openjdk-6/openjdk-6-jre-headless_6b18-1.8.10-0~lenny2_amd64.deb
    $ wget http://archive.debian.org/debian/pool/main/o/openjdk-6/openjdk-6-jre_6b18-1.8.10-0~lenny2_amd64.deb
    # dpkg -i openjdk-6-jdk_6b18-1.8.10-0~lenny2_amd64.deb openjdk-6-jre_6b18-1.8.10-0~lenny2_amd64.deb openjdk-6-jre-headless_6b18-1.8.10-0~lenny2_amd64.deb openjdk-6-jre-lib_6b18-1.8.10-0~lenny2_all.deb 
    (Чтение базы данных … на данный момент установлено 107430 файлов и каталогов.)
    Подготовка к распаковке openjdk-6-jdk_6b18-1.8.10-0~lenny2_amd64.deb …
    Распаковывается openjdk-6-jdk (6b18-1.8.10-0~lenny2) на замену (6b18-1.8.10-0~lenny2) …
    Подготовка к распаковке openjdk-6-jre_6b18-1.8.10-0~lenny2_amd64.deb …
    Распаковывается openjdk-6-jre (6b18-1.8.10-0~lenny2) на замену (6b18-1.8.10-0~lenny2) …
    Подготовка к распаковке openjdk-6-jre-headless_6b18-1.8.10-0~lenny2_amd64.deb …
    Распаковывается openjdk-6-jre-headless (6b18-1.8.10-0~lenny2) на замену (6b18-1.8.10-0~lenny2) …
    Подготовка к распаковке openjdk-6-jre-lib_6b18-1.8.10-0~lenny2_all.deb …
    Распаковывается openjdk-6-jre-lib (6b18-1.8.10-0~lenny2) на замену (6b18-1.8.10-0~lenny2) …
    dpkg: зависимости пакетов не позволяют настроить пакет openjdk-6-jre:
     openjdk-6-jre зависит от libgif4 (>= 4.1.6), однако:
      Пакет libgif4 не установлен.
     openjdk-6-jre зависит от libpng12-0 (>= 1.2.13-4), однако:
      Пакет libpng12-0 не установлен.
    
    dpkg: ошибка при обработке пакета openjdk-6-jre (--install):
     проблемы зависимостей — оставляем не настроенным
    dpkg: зависимости пакетов не позволяют настроить пакет openjdk-6-jre-headless:
     openjdk-6-jre-headless зависит от tzdata-java, однако:
      Пакет tzdata-java не установлен.
     openjdk-6-jre-headless зависит от liblcms1, однако:
      Пакет liblcms1 не установлен.
     openjdk-6-jre-headless зависит от libnss3-1d (>= 3.12.3), однако:
      Пакет libnss3-1d не установлен.
    
    dpkg: ошибка при обработке пакета openjdk-6-jre-headless (--install):
     проблемы зависимостей — оставляем не настроенным
    dpkg: зависимости пакетов не позволяют настроить пакет openjdk-6-jre-lib:
     openjdk-6-jre-lib зависит от openjdk-6-jre-headless (>= 6b17), однако:
      Пакет openjdk-6-jre-headless пока не настроен.
    
    dpkg: ошибка при обработке пакета openjdk-6-jre-lib (--install):
     проблемы зависимостей — оставляем не настроенным
    dpkg: зависимости пакетов не позволяют настроить пакет openjdk-6-jdk:
     openjdk-6-jdk зависит от openjdk-6-jre (>= 6b18-1.8.10-0~lenny2), однако:
      Пакет openjdk-6-jre пока не настроен.
    
    dpkg: ошибка при обработке пакета openjdk-6-jdk (--install):
     проблемы зависимостей — оставляем не настроенным
    Обрабатываются триггеры для ca-certificates-java (20230620~deb12u1) …
    done.
    Обрабатываются триггеры для hicolor-icon-theme (0.17-2) …
    Обрабатываются триггеры для mailcap (3.70+nmu1) …
    Обрабатываются триггеры для desktop-file-utils (0.26-1) …
    При обработке следующих пакетов произошли ошибки:
     openjdk-6-jre
     openjdk-6-jre-headless
     openjdk-6-jre-lib
     openjdk-6-jdk
    # apt-get install -f
    Чтение списков пакетов… Готово
    Построение дерева зависимостей… Готово
    Чтение информации о состоянии… Готово         
    Исправление зависимостей… Готово
    Следующие пакеты будут УДАЛЕНЫ:
      openjdk-6-jdk openjdk-6-jre openjdk-6-jre-headless openjdk-6-jre-lib
    Обновлено 0 пакетов, установлено 0 новых пакетов, для удаления отмечено 4 пакетов, и 85 пакетов не обновлено.
    Установлено или удалено не до конца 4 пакетов.
    После данной операции объём занятого дискового пространства уменьшится на 120 MB.
    Хотите продолжить? [Д/н] y
    (Чтение базы данных … на данный момент установлено 107430 файлов и каталогов.)
    Удаляется openjdk-6-jdk (6b18-1.8.10-0~lenny2) …
    Удаляется openjdk-6-jre (6b18-1.8.10-0~lenny2) …
    Удаляется openjdk-6-jre-lib (6b18-1.8.10-0~lenny2) …
    Удаляется openjdk-6-jre-headless (6b18-1.8.10-0~lenny2) …
    Обрабатываются триггеры для hicolor-icon-theme (0.17-2) …
    Обрабатываются триггеры для ca-certificates-java (20230620~deb12u1) …
    done.
    Обрабатываются триггеры для mailcap (3.70+nmu1) …
    Обрабатываются триггеры для desktop-file-utils (0.26-1) …
    needrestart is being skipped since dpkg has failed

Вместо этого можно попробовать скачать и установить Java 8 версии из архива официальных репозиториев Debian 9 Stretch:

    $ wget http://mirror.ufanet.ru/debian/pool/main/o/openjdk-8/openjdk-8-jre-headless_8u402-ga-2_amd64.deb
    $ wget http://mirror.ufanet.ru/debian/pool/main/o/openjdk-8/openjdk-8-jre_8u402-ga-2_amd64.deb
    $ wget http://mirror.ufanet.ru/debian/pool/main/o/openjdk-8/openjdk-8-jdk-headless_8u402-ga-2_amd64.deb
    $ wget http://mirror.ufanet.ru/debian/pool/main/o/openjdk-8/openjdk-8-jdk_8u402-ga-2_amd64.deb
    # dpkg -i openjdk-8-jre-headless_8u402-ga-2_amd64.deb openjdk-8-jre_8u402-ga-2_amd64.deb openjdk-8-jdk-headless_8u402-ga-2_amd64.deb openjdk-8-jdk_8u402-ga-2_amd64.deb
    # apt-get install -f

Если теперь запустить JNLP-приложение под управлением Java 8 версии, то получим ошибку запуска `/usr/bin/xprop`:

    $ JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/ javaws launch.jnlp
    Warning! JAVA_HOME of /usr/lib/jvm/java-8-openjdk-amd64/ in play!
    java.security.AccessControlException: access denied ("java.io.FilePermission" "/usr/bin/xprop" "execute")
            at java.security.AccessControlContext.checkPermission(AccessControlContext.java:472)
            at java.security.AccessController.checkPermission(AccessController.java:886)
            at java.lang.SecurityManager.checkPermission(SecurityManager.java:549)
            at java.lang.SecurityManager.checkExec(SecurityManager.java:796)
            at java.lang.ProcessBuilder.start(ProcessBuilder.java:1018)
            at java.lang.Runtime.exec(Runtime.java:593)
            at java.lang.Runtime.exec(Runtime.java:423)
            at java.lang.Runtime.exec(Runtime.java:320)
            at org.GNOME.Accessibility.AtkWrapper.<clinit>(AtkWrapper.java:42)
            at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
            at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62)
            at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
            at java.lang.reflect.Constructor.newInstance(Constructor.java:423)
            at java.lang.Class.newInstance(Class.java:442)
            at java.awt.Toolkit.loadAssistiveTechnologies(Toolkit.java:805)
            at java.awt.Toolkit.getDefaultToolkit(Toolkit.java:886)
            at java.awt.Toolkit.getEventQueue(Toolkit.java:1736)
            at java.awt.EventQueue.invokeLater(EventQueue.java:1294)
            at net.sourceforge.swing.SwingUtils.invokeLater(SwingUtils.java:137)
            at net.sourceforge.jnlp.util.logging.JavaConsole.updateModel(JavaConsole.java:544)
            at net.sourceforge.jnlp.util.logging.JavaConsole.updateModel(JavaConsole.java:538)
            at net.sourceforge.jnlp.util.logging.JavaConsole.addMessage(JavaConsole.java:534)
            at net.sourceforge.jnlp.util.logging.OutputController.consume(OutputController.java:154)
            at net.sourceforge.jnlp.util.logging.OutputController.flush(OutputController.java:138)
            at net.sourceforge.jnlp.util.logging.OutputController$MessageQueConsumer.run(OutputController.java:124)
            at java.lang.Thread.run(Thread.java:750)
    Не удалось использовать параметры прокси Firefox. В качестве типа прокси используется "DIRECT".
    Warning! JAVA_HOME of /usr/lib/jvm/java-8-openjdk-amd64/ in play!
    java.security.AccessControlException: access denied ("java.io.FilePermission" "/usr/bin/xprop" "execute")

Если добавить в файл `/etc/java-8-openjdk/security/java.policy` разрешение запускать `/usr/bin/xprop` следующим образом:

    grant {
            permission java.io.FilePermission "/usr/bin/xprop", "execute";
    };

То получим ошибку доступа для запуска уже "всех файлов":

    $ JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/ javaws launch.jnlp
    Warning! JAVA_HOME of /usr/lib/jvm/java-8-openjdk-amd64/ in play!
    java.security.AccessControlException: access denied ("java.io.FilePermission" "<<ALL FILES>>" "execute")
            at java.security.AccessControlContext.checkPermission(AccessControlContext.java:472)
            at java.security.AccessController.checkPermission(AccessController.java:886)
            at java.lang.SecurityManager.checkPermission(SecurityManager.java:549)
            at java.lang.SecurityManager.checkExec(SecurityManager.java:799)
            at java.lang.ProcessBuilder.start(ProcessBuilder.java:1018)
            at java.lang.Runtime.exec(Runtime.java:593)
            at java.lang.Runtime.exec(Runtime.java:423)
            at java.lang.Runtime.exec(Runtime.java:320)
            at org.GNOME.Accessibility.AtkWrapper.<clinit>(AtkWrapper.java:53)
            at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
            at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62)
            at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
            at java.lang.reflect.Constructor.newInstance(Constructor.java:423)
            at java.lang.Class.newInstance(Class.java:442)
            at java.awt.Toolkit.loadAssistiveTechnologies(Toolkit.java:805)
            at java.awt.Toolkit.getDefaultToolkit(Toolkit.java:886)
            at java.awt.Toolkit.getEventQueue(Toolkit.java:1736)
            at java.awt.EventQueue.invokeLater(EventQueue.java:1294)
            at net.sourceforge.swing.SwingUtils.invokeLater(SwingUtils.java:137)
            at net.sourceforge.jnlp.util.logging.JavaConsole.updateModel(JavaConsole.java:544)
            at net.sourceforge.jnlp.util.logging.JavaConsole.updateModel(JavaConsole.java:538)
            at net.sourceforge.jnlp.util.logging.JavaConsole.addMessage(JavaConsole.java:534)
            at net.sourceforge.jnlp.util.logging.OutputController.consume(OutputController.java:154)
            at net.sourceforge.jnlp.util.logging.OutputController.flush(OutputController.java:138)
            at net.sourceforge.jnlp.util.logging.OutputController$MessageQueConsumer.run(OutputController.java:124)
            at java.lang.Thread.run(Thread.java:750)
    Не удалось использовать параметры прокси Firefox. В качестве типа прокси используется "DIRECT".
    Warning! JAVA_HOME of /usr/lib/jvm/java-8-openjdk-amd64/ in play!
    java.security.AccessControlException: access denied ("java.io.FilePermission" "<<ALL FILES>>" "execute")
            at java.security.AccessControlContext.checkPermission(AccessControlContext.java:472)
            at java.security.AccessController.checkPermission(AccessController.java:886)
            at java.lang.SecurityManager.checkPermission(SecurityManager.java:549)
            at java.lang.SecurityManager.checkExec(SecurityManager.java:799)
            at java.lang.ProcessBuilder.start(ProcessBuilder.java:1018)
            at java.lang.Runtime.exec(Runtime.java:593)
            at java.lang.Runtime.exec(Runtime.java:423)
            at java.lang.Runtime.exec(Runtime.java:320)
            at org.GNOME.Accessibility.AtkWrapper.<clinit>(AtkWrapper.java:53)
            at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
            at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62)
            at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
            at java.lang.reflect.Constructor.newInstance(Constructor.java:423)
            at java.lang.Class.newInstance(Class.java:442)
            at java.awt.Toolkit.loadAssistiveTechnologies(Toolkit.java:805)
            at java.awt.Toolkit.getDefaultToolkit(Toolkit.java:886)
            at java.awt.Toolkit.getEventQueue(Toolkit.java:1736)
            at java.awt.EventQueue.invokeLater(EventQueue.java:1294)
            at net.sourceforge.swing.SwingUtils.invokeLater(SwingUtils.java:137)
            at net.sourceforge.jnlp.util.logging.JavaConsole.updateModel(JavaConsole.java:544)
            at net.sourceforge.jnlp.util.logging.JavaConsole.updateModel(JavaConsole.java:538)
            at net.sourceforge.jnlp.util.logging.JavaConsole.addMessage(JavaConsole.java:534)
            at net.sourceforge.jnlp.util.logging.OutputController.consume(OutputController.java:154)
            at net.sourceforge.jnlp.util.logging.OutputController.flush(OutputController.java:138)
            at net.sourceforge.jnlp.util.logging.OutputController$MessageQueConsumer.run(OutputController.java:124)
            at java.lang.Thread.run(Thread.java:750)
    Не удалось использовать параметры прокси Firefox. В качестве типа прокси используется "DIRECT".
    JAR https://kvm.server.tld:443/iKVM__V1.69.53.0x0.jar not found. Continuing.
    JAR https://kvm.server.tld:443/liblinux_x86_64__V1.0.22.jar not found. Continuing.
    JAR https://kvm.server.tld:443/iKVM__V1.69.53.0x0.jar not found. Continuing.
    JAR https://kvm.server.tld:443/liblinux_x86_64__V1.0.22.jar not found. Continuing.
    netx: Ошибка инициализации: Не удалось инициализировать приложение. (Критическая: Ошибка инициализации: Неизвестный атрибут Main-Class. Не удалось определить основной класс для этого приложения.)
    net.sourceforge.jnlp.LaunchException: Критическая: Ошибка инициализации: Не удалось инициализировать приложение. Приложение не было инициализировано. Для получения дополнительных сведений выполните в командной строке команду javaws.
            at net.sourceforge.jnlp.Launcher.createApplication(Launcher.java:823)
            at net.sourceforge.jnlp.Launcher.launchApplication(Launcher.java:531)
            at net.sourceforge.jnlp.Launcher$TgThread.run(Launcher.java:946)
    Caused by: net.sourceforge.jnlp.LaunchException: Критическая: Ошибка инициализации: Неизвестный атрибут Main-Class. Не удалось определить основной класс для этого приложения.
            at net.sourceforge.jnlp.runtime.JNLPClassLoader.initializeResources(JNLPClassLoader.java:775)
            at net.sourceforge.jnlp.runtime.JNLPClassLoader.<init>(JNLPClassLoader.java:337)
            at net.sourceforge.jnlp.runtime.JNLPClassLoader.createInstance(JNLPClassLoader.java:420)
            at net.sourceforge.jnlp.runtime.JNLPClassLoader.getInstance(JNLPClassLoader.java:494)
            at net.sourceforge.jnlp.runtime.JNLPClassLoader.getInstance(JNLPClassLoader.java:467)
            at net.sourceforge.jnlp.Launcher.createApplication(Launcher.java:815)
            ... 2 more

Если теперь аналогичным образом добавить в файл `/etc/java-8-openjdk/security/java.policy` разрешение запускать "все файлы" следующим образом:

    grant {
            permission java.io.FilePermission "/usr/bin/xprop", "execute";
    };

То JNLP-приложение завершается ошибкой скачивания JAR-файлов:

    $ JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/ javaws launch.jnlp
    Warning! JAVA_HOME of /usr/lib/jvm/java-8-openjdk-amd64/ in play!
    Не удалось использовать параметры прокси Firefox. В качестве типа прокси используется "DIRECT".
    Warning! JAVA_HOME of /usr/lib/jvm/java-8-openjdk-amd64/ in play!
    Не удалось использовать параметры прокси Firefox. В качестве типа прокси используется "DIRECT".
    JAR https://kvm.server.tld:443/iKVM__V1.69.53.0x0.jar not found. Continuing.
    JAR https://kvm.server.tld:443/liblinux_x86_64__V1.0.22.jar not found. Continuing.
    JAR https://kvm.server.tld:443/iKVM__V1.69.53.0x0.jar not found. Continuing.
    JAR https://kvm.server.tld:443/liblinux_x86_64__V1.0.22.jar not found. Continuing.
    netx: Ошибка инициализации: Не удалось инициализировать приложение. (Критическая: Ошибка инициализации: Неизвестный атрибут Main-Class. Не удалось определить основной класс для этого приложения.)
    net.sourceforge.jnlp.LaunchException: Критическая: Ошибка инициализации: Не удалось инициализировать приложение. Приложение не было инициализировано. Для получения дополнительных сведений выполните в командной строке команду javaws.
            at net.sourceforge.jnlp.Launcher.createApplication(Launcher.java:823)
            at net.sourceforge.jnlp.Launcher.launchApplication(Launcher.java:531)
            at net.sourceforge.jnlp.Launcher$TgThread.run(Launcher.java:946)
    Caused by: net.sourceforge.jnlp.LaunchException: Критическая: Ошибка инициализации: Неизвестный атрибут Main-Class. Не удалось определить основной класс для этого приложения.
            at net.sourceforge.jnlp.runtime.JNLPClassLoader.initializeResources(JNLPClassLoader.java:775)
            at net.sourceforge.jnlp.runtime.JNLPClassLoader.<init>(JNLPClassLoader.java:337)
            at net.sourceforge.jnlp.runtime.JNLPClassLoader.createInstance(JNLPClassLoader.java:420)
            at net.sourceforge.jnlp.runtime.JNLPClassLoader.getInstance(JNLPClassLoader.java:494)
            at net.sourceforge.jnlp.runtime.JNLPClassLoader.getInstance(JNLPClassLoader.java:467)
            at net.sourceforge.jnlp.Launcher.createApplication(Launcher.java:815)

Если попробовать скачать эти файлы, то можно увидеть, что их действительно нет на веб-сервере:

    $ wget https://kvm.server.tld:443/liblinux_x86_64__V1.0.22.jar
    --2024-02-16 15:37:11--  https://kvm.server.tld/liblinux_x86_64__V1.0.22.jar
    Распознаётся kvm.server.tld (kvm.server.tld)… 192.168.1.1
    Подключение к kvm.server.tld (kvm.server.tld)|192.168.1.1|:443... соединение установлено.
    ОШИБКА: Нет доверия сертификату для «kvm.server.tld».
    ОШИБКА: Неизвестный издатель сертификата «kvm.server.tld».
    Владелец сертификата не совпадает с именем узла «kvm.server.tld»
    $ wget --no-check-certificate https://kvm.server.tld:443/liblinux_x86_64__V1.0.22.jar
    --2024-02-16 15:37:29--  https://kvm.server.tld/liblinux_x86_64__V1.0.22.jar
    Распознаётся kvm.server.tld (kvm.server.tld)… 192.168.1.1
    Подключение к kvm.server.tld (kvm.server.tld)|192.168.1.1|:443... соединение установлено.
    ПРЕДУПРЕЖДЕНИЕ: Нет доверия сертификату для «kvm.server.tld».
    ПРЕДУПРЕЖДЕНИЕ: Неизвестный издатель сертификата «kvm.server.tld».
    Владелец сертификата не совпадает с именем узла «kvm.server.tld»
    HTTP-запрос отправлен. Ожидание ответа… 404 Not Found
    2024-02-16 15:37:29 ОШИБКА 404: Not Found.

Поиск решения с Oracle Java
---------------------------

Попробуем воспользоваться той же версией Java, взятой на сайте Oracle.

Перейдём на официальный сайт компании Oracle [www.oracle.com](https://www.oracle.com/).

В меню Products, в разделе Hardware and Software переходим по ссылке [Java](https://www.oracle.com/java/).

На окткрывшейся странице справа находим кнопку Download Java, нажимаем и попадаем на страницу [Java Downloads](https://www.oracle.com/java/technologies/downloads/).

Нас интересует устаревшая версия Java, поэтому переходим по ссылке [Java archive](https://www.oracle.com/java/technologies/downloads/archive/).

Находим на странице раздел "Java SE downloads", а под ним ссылку [Java SE 8 (8u211 and later)](https://www.oracle.com/java/technologies/javase/javase8u211-later-archive-downloads.html).

В таблице файлов для скачивания находим строчку "Linux x64 Compressed Archive" и переходим на страницу скачивания архива `jdk-8u391-linux-x64.tar.gz`. Для скачивания архива необходимо принять лицензионное соглашение и зарегистрироваться на сайте.

Поиски альтернативных источников для скачивания этого файла, не требующих регистрации, привели меня страницу [Java SE JDK and JRE 8.391](https://www.techspot.com/downloads/5198-java-jre.html) сайта [www.techspot.com](https://www.techspot.com/). К сожалению, файла в формате TGZ тут нет, однако можно скачать пакет в формате [JDK Linux 64-bit RPM](https://www.techspot.com/downloads/downloadnow/5198/?evp=cc95b0e22a5ea8c81b34b55f1d9c7c54&file=5646).

При нажатии по ссылке скачивание начнётся автоматически. Если посмотреть ссылку, по которой происходит реальное скачивание, то она будет такой:

    https://cfdownload.adobe.com/pub/adobe/coldfusion/java/java8/java8u391/jdk/jdk-8u391-linux-x64.rpm

Решение
-------

Если попробовать заменить расширение файла `rpm` на `tar.gz`, то можно скачать файл в нужном нам формате:

    $ wget https://cfdownload.adobe.com/pub/adobe/coldfusion/java/java8/java8u391/jdk/jdk-8u391-linux-x64.tar.gz

Распакуем скачанный архив:

    $ tar xzvf jdk-8u391-linux-x64.tar.gz

В результате распаковки в текущем каталоге появится подкаталог `jdk1.8.0_391`. Запустим `javaws` из этого каталога с указанием JNLP-приложения:

    $ jdk-1.8-oracle-x64/bin/javaws launch.jnlp 
    Java HotSpot(TM) 64-Bit Server VM warning: ignoring option PermSize=32M; support was removed in 8.0
    Java HotSpot(TM) 64-Bit Server VM warning: ignoring option MaxPermSize=32M; support was removed in 8.0
    
    (java:3945787): dbind-WARNING **: 17:09:38.226: AT-SPI: Error retrieving accessibility bus address: org.freedesktop.DBus.Error.ServiceUnknown: The name org.a11y.Bus was not provided by any .service files
    connect failed sd:39
    a singal 17 is raised
    GetFileDevStr:4051 media_type = 40
    GetFileDevStr:4051 media_type = 45
    GetFileDevStr:4051 media_type = 40
    GetFileDevStr:4051 media_type = 45
    GetFileDevStr:4051 media_type = 40
    GetFileDevStr:4051 media_type = 45

Итак, на этот раз приложение запустилось. На всякий случай я сохранил архив с Oracle JDK 8 и приложил его к этой статье: [[jdk-8u391-linux-x64.tar.gz]].

Устранение предупреждений
-------------------------

В процессе запуска JNLP-приложения выводятся предупреждение об игнорировании опций `PermSize` и `MaxPermSize`, которые поддерживались в Java 6 версии, в 8 версии игнорируются с выводом предупреждения, а в последующих версиях приводят к завершению работы Java-машины с сообщением об ошибке.

Для того, чтобы устранить эти предупреждения, достаточно удалить эти опции из файла `launch.jnlp`:

    <j2se version="1.6.0+" initial-heap-size="128M" max-heap-size="128M" java-vm-args="-XX:PermSize=32M -XX:MaxPermSize=32M"/>
    <j2se version="1.6.0+" initial-heap-size="128M" max-heap-size="128M" java-vm-args=""/>

Также в процессе запуска JNLP-приложения выводится следующее предупреждение:

    (java:3946399): dbind-WARNING **: 17:29:43.836: AT-SPI: Error retrieving accessibility bus address: org.freedesktop.DBus.Error.ServiceUnknown: The name org.a11y.Bus was not provided by any .service files

Для его устранения достаточно установить в систему пакет `at-spi2-core`, например, следующим образом:

    # apt-get install at-spi2-core
