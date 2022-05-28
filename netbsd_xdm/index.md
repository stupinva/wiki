Настройка внешнего вида xdm в NetBSD
====================================

Изменение цветов элементов
--------------------------

Отредактируем файл /etc/X11/xdm/Xresources следующим образом:

    #xlogin*shdColor: grey30
    xlogin*shdColor: black
    #xlogin*hiColor: grey90
    xlogin*hiColor: black
    #xlogin*background: grey
    xlogin*background: white
    xlogin*inpColor: grey
    xlogin*inpColor: white
    #xlogin*greetColor: Blue3
    xlogin*greetColor: darkred

Изменение фона логотипа
-----------------------

В поставке X11 по умолчанию в формате xpm, используемом xdm, имеются только логотипы NetBSD с серым и чёрным фоном. Чтобы сгенерировать логотип с белым фоном из файла png, нам понадобится установить pkgsrc graphics/netpbm.

Далее выполним следующие команды:

    # cd /usr/X11R7/include/X11/pixmaps/
    # pngtopnm -mix -background white NetBSD-flag.png | ppmtoxpm > NetBSD-flag.xpm

И отредактируем файл /etc/X11/xdm/Xresources следующим образом:

    #xlogin*logoFileName: /usr/X11R7/include/X11/pixmaps/NetBSD-flag1.xpm
    xlogin*logoFileName: /usr/X11R7/include/X11/pixmaps/NetBSD-flag.xpm

Другие изменения
----------------

Кроме этого я также поменял приглашение на ввод логина в файле /etc/X11/xdm/Xresources следующим образом:

    #xlogin*namePrompt: \040\040\040\040\040\040\040Login:
    xlogin*namePrompt: Login:

В файле /etc/X11/xdm/Xsetup_0 отключил запуск терминала с консолью и установил серый фон, поменяв следующие строчки:

    #xcolsole -geometry 480x130-0-0 -daemon -notify -verbose -fn fixed -exitOnFail
    xsetroot -solid grey

Если не нравится скучный серый цвет, то можно установить фоновую картинку. Лучше подыскать картинку, размер которой будет совпадать с разрешением экрана. Для установки фоновой картинки нужно отредактировать файл /etc/X11/xdm/Xsetup_0 следующим образом:

    #xcolsole -geometry 480x130-0-0 -daemon -notify -verbose -fn fixed -exitOnFail
    xsetwallpaper /root/city_grass.jpg

Результат
---------

Экран входа xdm с фоновой картинкой выглядит следующим образом:

[[xdm.jpg]]

Теперь можно установить из pkgsrc оконный менджер, например, IceWM из wm/icewm, и прописать его запуск в файл `~/.xsession` следующим образом:

    exec icewm

После входа в систему через xdm запустится менеджер окон IceWM, но фоновая картинка останется прежней:

[[icewm.jpg]]

Настройка внешнего вида xterm
-----------------------------

Создадим файл `~/.Xresources` и добавим в него настройки цвета для вывода белого текста на чёрном фоне:

    XTerm*background: black
    XTerm*foreground: white

Для настройки толщины и цвета бордюра можно добавить такие настройки:

    XTerm*borderWidth: 5
    XTerm*borderColor: lightgrey

Для того, чтобы `xterm` автоматически запускался в полноэкранном режиме, можно добавить такую опцию:

    XTerm*maximized: true

Вместо предыдущей опции можно прописать опцию для запуска `xterm` в полноэкранном режиме (при этом не будет видно рабочего стола, декорации окна и панелей менеджера окон):

    XTerm*fullscreen: true

Чтобы эти настройки применялись автоматически при входе в систему, нужно прописать в файл `~/.xsession` команду для загрузки файла ресурсов до запуска менеджера окон:

    xrdb -load ~/.Xresources

Если в систему не установлен архив xcomp, то запускать `xrdb` нужно без использования препроцессора:

    xrdb -nocpp -load ~/.Xresources

Для настройки вида приглашения оболочки `bash` создал файл `~/.bashrc` со следующим содержимым:

    . $HOME/.shrc

Содержимое файла `~/.shrc` привёл к следующему виду:

    #       $NetBSD: dot.shrc,v 1.3 2007/11/24 11:14:42 pavel Exp $
    
    if [ -f /etc/shrc ]; then
            . /etc/shrc
    fi
    
    case "$-" in *i*)
            # interactive mode settings go here
            PS1="\u@\H:\w\$ "
            export PS1
            ;;
    esac

Использованные материалы
------------------------

* [[Запуск xdm в NetBSD с помощью daemonotools|netbsd_daemontools_xdm/]]
* [Настройка xdm](http://stupin.su/blog/xdm/)
