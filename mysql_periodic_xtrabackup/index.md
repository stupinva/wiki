Периодическое резервное копирование MySQL с помощью xtrabackup
==============================================================

Для ускорения периодического резервного копированя можно воспользоваться битовыми картами для отслеживания изменённых страниц [XtraDB changed page tracking](https://www.percona.com/doc/percona-server/5.6/management/changed_page_tracking.html).

Готовые скрипты для периодического инкрементального резервного копирования: [How To Configure MySQL Backups with Percona XtraBackup on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-configure-mysql-backups-with-percona-xtrabackup-on-ubuntu-16-04).

Репозиторий со скриптами: [https://github.com/do-community/ubuntu-1604-mysql-backup](https://github.com/do-community/ubuntu-1604-mysql-backup)
