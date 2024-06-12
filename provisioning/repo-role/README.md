Repo role
=========

Позволяет развернуть локальный репозиторий и настроить хосты на его использование

Dependencies
------------

На сервере с NFS-шарой необходимо контролировать появление файла .runtask в репозиториях, например так:

```bash
#!/bin/bash

for item in $(ls -d /export/backup/fedora/*)
do
  if [ -f ${item}/.runtask ]; then
    cd ${item}
    createrepo_c --update --database --workers $(nproc) ./
    if [ $? -eq 0 ]; then
      rm -f ${item}/.runtask
    fi
  fi
done
```

Example Playbook
----------------

    - hosts: all
      roles:
         - repo-role


License
-------

GPL v.2.0 or later

Author Information
------------------

Ivan Ivanov <kasper_wps@mail.ru>
https://github.com/KasperWPS
