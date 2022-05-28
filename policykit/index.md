Настройка PolicyKit
===================

Для того, чтобы пользователи графической оболочки, вроде GNOME или XFCE, могли монитровать, размонтировать диски и флешки, перезагружать или выключать компьютер, нужно настроить права на совершение соответствующих операций с помощью демона PolicyKit.

Посмотрим список всех доступных прав:

    # pkaction 
    org.freedesktop.consolekit.system.restart
    org.freedesktop.consolekit.system.restart-multiple-users
    org.freedesktop.consolekit.system.stop
    org.freedesktop.consolekit.system.stop-multiple-users
    org.freedesktop.hostname1.set-hostname
    org.freedesktop.hostname1.set-machine-info
    org.freedesktop.hostname1.set-static-hostname
    org.freedesktop.locale1.set-keyboard
    org.freedesktop.locale1.set-locale
    org.freedesktop.login1.attach-device
    org.freedesktop.login1.flush-devices
    org.freedesktop.login1.power-off
    org.freedesktop.login1.power-off-multiple-sessions
    org.freedesktop.login1.reboot
    org.freedesktop.login1.reboot-multiple-sessions
    org.freedesktop.login1.set-user-linger
    org.freedesktop.policykit.exec
    org.freedesktop.policykit.lockdown
    org.freedesktop.systemd1.bus-access
    org.freedesktop.systemd1.reply-password
    org.freedesktop.timedate1.set-local-rtc
    org.freedesktop.timedate1.set-ntp
    org.freedesktop.timedate1.set-time
    org.freedesktop.timedate1.set-timezone
    org.freedesktop.udisks.cancel-job-others
    org.freedesktop.udisks.change
    org.freedesktop.udisks.change-system-internal
    org.freedesktop.udisks.drive-ata-smart-refresh
    org.freedesktop.udisks.drive-ata-smart-retrieve-historical-data
    org.freedesktop.udisks.drive-ata-smart-selftest
    org.freedesktop.udisks.drive-detach
    org.freedesktop.udisks.drive-eject
    org.freedesktop.udisks.drive-set-spindown
    org.freedesktop.udisks.filesystem-check
    org.freedesktop.udisks.filesystem-check-system-internal
    org.freedesktop.udisks.filesystem-lsof
    org.freedesktop.udisks.filesystem-lsof-system-internal
    org.freedesktop.udisks.filesystem-mount
    org.freedesktop.udisks.filesystem-mount-system-internal
    org.freedesktop.udisks.filesystem-unmount-others
    org.freedesktop.udisks.inhibit-polling
    org.freedesktop.udisks.linux-lvm2
    org.freedesktop.udisks.linux-md
    org.freedesktop.udisks.luks-lock-others
    org.freedesktop.udisks.luks-unlock
    org.freedesktop.udisks2.ata-check-power
    org.freedesktop.udisks2.ata-secure-erase
    org.freedesktop.udisks2.ata-smart-enable-disable
    org.freedesktop.udisks2.ata-smart-selftest
    org.freedesktop.udisks2.ata-smart-simulate
    org.freedesktop.udisks2.ata-smart-update
    org.freedesktop.udisks2.ata-standby
    org.freedesktop.udisks2.ata-standby-other-seat
    org.freedesktop.udisks2.ata-standby-system
    org.freedesktop.udisks2.cancel-job
    org.freedesktop.udisks2.cancel-job-other-user
    org.freedesktop.udisks2.eject-media
    org.freedesktop.udisks2.eject-media-other-seat
    org.freedesktop.udisks2.eject-media-system
    org.freedesktop.udisks2.encrypted-change-passphrase
    org.freedesktop.udisks2.encrypted-change-passphrase-system
    org.freedesktop.udisks2.encrypted-lock-others
    org.freedesktop.udisks2.encrypted-unlock
    org.freedesktop.udisks2.encrypted-unlock-crypttab
    org.freedesktop.udisks2.encrypted-unlock-other-seat
    org.freedesktop.udisks2.encrypted-unlock-system
    org.freedesktop.udisks2.filesystem-fstab
    org.freedesktop.udisks2.filesystem-mount
    org.freedesktop.udisks2.filesystem-mount-other-seat
    org.freedesktop.udisks2.filesystem-mount-system
    org.freedesktop.udisks2.filesystem-unmount-others
    org.freedesktop.udisks2.loop-delete-others
    org.freedesktop.udisks2.loop-modify-others
    org.freedesktop.udisks2.loop-setup
    org.freedesktop.udisks2.manage-md-raid
    org.freedesktop.udisks2.manage-swapspace
    org.freedesktop.udisks2.modify-device
    org.freedesktop.udisks2.modify-device-other-seat
    org.freedesktop.udisks2.modify-device-system
    org.freedesktop.udisks2.modify-drive-settings
    org.freedesktop.udisks2.modify-system-configuration
    org.freedesktop.udisks2.open-device
    org.freedesktop.udisks2.open-device-system
    org.freedesktop.udisks2.power-off-drive
    org.freedesktop.udisks2.power-off-drive-other-seat
    org.freedesktop.udisks2.power-off-drive-system
    org.freedesktop.udisks2.read-system-configuration-secrets
    org.freedesktop.udisks2.rescan
    org.freedesktop.upower.hibernate
    org.freedesktop.upower.qos.cancel-request
    org.freedesktop.upower.qos.request-latency
    org.freedesktop.upower.qos.request-latency-persistent
    org.freedesktop.upower.qos.set-minimum-latency
    org.freedesktop.upower.suspend
    org.xfce.power.backlight-helper

Более подробное описание всех прав можно посмореть при помощи такой команды (вывод команды опущен):

    # pkaction --verbose

Или можно посмотреть подробное описание одного из прав:

    # pkaction --action-id org.freedesktop.consolekit.system.stop --verbose
    org.freedesktop.consolekit.system.stop:
    description:       Stop the system
    message:           System policy prevents stopping the system
    vendor:            
    vendor_url:        
    icon:              
    implicit any:      no
    implicit inactive: no
    implicit active:   yes

На моём компьютере прописаны следующие права доступа:

    # vim /etc/polkit-1/localauthority/50-local.d/10-stupin.pkla
  
    [Configuration]
    AdminIdentities=unix-group:root
  
    [Restart System]
    Identity=unix-user:stupin;unix-user:gala
    Action=org.freedesktop.consolekit.system.restart
    ResultActive=yes
    ResultInactive=yes
    ResultAny=no
  
    [Restart System when loggen multiple users]
    Identity=unix-user:stupin;unix-user:gala
    Action=org.freedesktop.consolekit.system.restart-multiple-users
    ResultActive=yes
    ResultInactive=yes
    ResultAny=no
  
    [Stop System]
    Identity=unix-user:stupin;unix-user:gala
    Action=org.freedesktop.consolekit.system.stop
    ResultActive=yes
    ResultInactive=yes
    ResultAny=no
  
    [Stop System when loggen multiple users]
    Identity=unix-user:stupin;unix-user:gala
    Action=org.freedesktop.consolekit.system.stop-multiple-users
    ResultActive=yes
    ResultInactive=yes
    ResultAny=no
  
    [Detach drive]
    Identity=unix-user:stupin;unix-user:gala
    Action=org.freedesktop.udisks.drive-detach
    ResultActive=yes
    ResultInactive=yes
    ResultAny=no
  
    [Check filesystem for errors]
    Identity=unix-user:stupin;unix-user:gala
    Action=org.freedesktop.udisks.filesystem-check
    ResultActive=yes
    ResultInactive=yes
    ResultAny=no
  
    [Check internal filesystem for errors]
    Identity=unix-user:stupin
    Action=org.freedesktop.udisks.filesystem-check-system-internal
    ResultActive=yes
    ResultInactive=no
    ResultAny=no
  
    [List of opened files on filesystem]
    Identity=unix-user:stupin;unix-user:gala
    Action=org.freedesktop.udisks.filesystem-lsof
    ResultActive=yes
    ResultInactive=no
    ResultAny=no
  
    [List of opened files on internal filesystem]
    Identity=unix-user:stupin
    Action=org.freedesktop.udisks.filesystem-lsof-system-internal
    ResultActive=yes
    ResultInactive=no
    ResultAny=no
  
    [Eject drive]
    Identity=unix-user:stupin;unix-user:gala
    Action=org.freedesktop.udisks.drive-eject
    ResultActive=yes
    ResultInactive=yes
    ResultAny=no
  
    [Mount drive]
    Identity=unix-user:stupin;unix-user:gala
    Action=org.freedesktop.udisks.filesystem-mount
    ResultActive=yes
    ResultInactive=yes
    ResultAny=no
  
    [Mount internal drive]
    Identity=unix-user:stupin
    Action=org.freedesktop.udisks.filesystem-mount-system-internal
    ResultActive=yes
    ResultInactive=no
    ResultAny=no
  
    [Unmount drive mounted other user]
    Identity=unix-user:stupin;unix-user:gala
    Action=org.freedesktop.udisks.filesystem-unmount-others
    ResultActive=yes
    ResultInactive=yes
    ResultAny=no
  
    [Detection of media]
    Identity=unix-user:stupin:unix-user:gala
    Action=org.freedesktop.udisks.inhibit-polling
    ResultActive=yes
    ResultInactive=yes
    ResultAny=no
  
    [Eject media 2]
    Identity=unix-user:stupin;unix-user:gala
    Action=org.freedesktop.udisks2.eject-media
    ResultActive=yes
    ResultInactive=yes
    ResultAny=no
  
    [Mount drive 2]
    Identity=unix-user:stupin;unix-user:gala
    Action=org.freedesktop.udisks2.filesystem-mount
    ResultActive=yes
    ResultInactive=yes
    ResultAny=no
  
    [Attach drive]
    Identity=unix-user:stupin;unix-user:gala
    Action=org.freedesktop.login1.attach-device
    ResultActive=yes
    ResultInactive=yes
    ResultAny=no

Формат файла такой:

* [Eject drive] - название раздела
* Identity=unix-user:stupin;unix-user:gala - список пользователей (unix-user) или групп (unix-group), к которым относится этот раздел
* Action=org.freedesktop.udisks.drive-eject - название действия, права к которому описывает раздел
* ResultActive=yes - операция разрешеня для пользователя, который в данный момент активен (его сеанс отображается на мониторе)
* ResultInactive=yes - операция досупна для пользователя, который в данный момент не активен (его сеанс открыт, но не активен и в данный момент не отображается)
* ResultAny=no - операция запрещена всем остальным пользователям
