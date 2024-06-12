Backup
======

Развернёт backup-server настроит backup sql на mysql-replica (логический бэкап)

Role Variables
--------------

mysql_root_password - пароль супер-пользователя СУБД. Можно создать пользователя backup с нужными правами, а восстанавливать уже с правами root. Для данной работы можно считать допустимым использование root'а.

Example Playbook
----------------

    - hosts: servers
      roles:
         - backup

License
-------

GPL 2.0 or later

Author Information
------------------

Ivan Ivanov <kasper_wps@mail.ru>
https://github.com/KasperWPS
