MySQL-replica
=============

- Настройка репликации master-slave
- Восстановление мастера из реплики

Работает с двумя хостами. Имена захардкожены: mysql-source и mysql-replica

Requirements
------------

Role Variables
--------------

- mysql_root_password - пароль суперпользователя БД
- mysql_repl_password - пароль пользователя созданного для репликации (repl)

**Используются для выбора направления: master-slave или slave-master (тэг restore from replica)**
- var_src: "{{ 'mysql-replica' if 'restore from replica' in ansible_run_tags else 'mysql-source' }}"
- var_dest: "{{ 'mysql-source' if 'restore from replica' in ansible_run_tags else 'mysql-replica' }}"

Dependencies
------------


Example Playbook
----------------
```
- hosts: mariadb-source,mariadb-replica
  roles:
    - mysql-replica
  tags:
    - Set up replica
```
License
-------

GPL v.2 or later

Author Information
------------------

Ivan Ivanov <kasper_wps@mail.ru>
https://github.com/KasperWPS
