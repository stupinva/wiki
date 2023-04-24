Настройка D-Link DWA-566
========================

[Hostapd - Gentoo Wiki](https://wiki.gentoo.org/wiki/Hostapd)

[hostap can't set 5ghz channel](https://ubuntuforums.org/showthread.php?t=2032357)

[402-ath_regd_optional.patch](https://github.com/openwrt/openwrt/blob/master/package/kernel/mac80211/patches/ath/402-ath_regd_optional.patch)

[WiFi hostapd configuration for 802.11ac networks](https://blog.fraggod.net/2017/04/27/wifi-hostapd-configuration-for-80211ac-networks.html)

[List of WLAN channels / 5 GHz (802.11a/h/j/n/ac/ax)](https://en.wikipedia.org/wiki/List_of_WLAN_channels#5_GHz_(802.11a/h/j/n/ac/ax))

[hostapd configuration file](https://w1.fi/cgit/hostap/plain/hostapd/hostapd.conf)

Устанавливаем пакеты:

    # apt-get install crda wireless-regdb

Применяем настройки `udev` после установки `crda`:

    # udevadm control -R

Создаём файл `/etc/modprobe.d/cfg80211.conf` и вписываем в него опции модуля:

    options cfg80211 ieee80211_regdom=RU

Создаём файл `/etc/modprobe.d/ath9k.conf` и вписываем в него опции модуля:

    options ath9k ps_enable=0

Выгружаем и снова загружаем модули:

    # rmmod ath9k ath9k_hw ath9k_common ath mac80211 cfg80211
    # modprobe ath9k

Убедиться в том, что настройки модулей ядра были применены, можно следующим образом:

    # cat /sys/module/cfg80211/parameters/ieee80211_regdom 
    RU
    # cat /sys/module/ath9k/parameters/ps_enable 
    0
