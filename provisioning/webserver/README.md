Webserver
=========

Развернёт nginx, php-fpm, nextcloud и настроит

Role variables
--------------

- nextcloud_password - пароль пользователя nextcloud в СУБД
- mysql_root_password - пароль супер-пользователя СУБД


Example Playbook
----------------

    - hosts: servers
      roles:
         - webserver

License
-------

GPL 2.0 or later

Author Information
------------------

Ivan Ivanov <kasper_wps@mail.ru>
https://github.com/KasperWPS
