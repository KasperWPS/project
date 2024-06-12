GlusterFS
=========

- Развернёт GlusterFS состоящую из трёх хостов (brick1, brick2, brick3).
- Добавит точку монтирования в /var/gfs-point каждому хосту, к которому применена эта роль

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - glusterfs

License
-------

GPL 2.0 or later

Author Information
------------------

Ivan Ivanov <kasper_wps@mail.ru>
https://github.com/KasperWPS
