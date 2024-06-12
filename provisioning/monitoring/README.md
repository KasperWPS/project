Monitoring
==========

Установит и настроит prometheus + alerting на сервере мониторинга, а также установит экспортеры на все хосты.

Из локального репозитория будут установлены:
- gluster-exporter
- mysqld_exporter
- prometheus-alertmanager

Role Variables
--------------

- mysql_root_password - пароль пользователя СУБД созданного для мониторинга, для упрощения используется пароль тот же, что и для суперпользователя.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - monitoring

License
-------

GPL 2.0 or later

Author Information
------------------

Ivan Ivanov <kasper_wps@mail.ru>
https://github.com/KasperWPS
