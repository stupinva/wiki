Использование partclone.ntfs
============================

    # partclone.ntfs -c -s /dev/stupin/winxp-d-disk -o /home/stupin/d.ntfs

    # lvcreate -n winxp-d -L 25G stupin
    # mkfs.ntfs /dev/stupin/winxp-d
  
    # ntfsresize -s 25G /dev/stupin/winxp-d-disk
