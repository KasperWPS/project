ELK
===

- Установит на одном хосте (elk - hostname) весь ELK-стэк, настроит снэпшоты в glusterfs mount-point
- Сгенерирует пароли пользователям elastic, kibana_system и оставит в /home/vagrant/elk с правами root:root 0644 - **только для демонстрации**
- Установит filebeat на хостах и сконфигурирует

Role Variables
--------------

elk='["nginx", "system"]' - список определяется в инвентаре, описание значений:
- nginx включит модуль nginx filebeat
- system включит модуль system filebeat

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - elk

License
-------

GPL 2.0 or later

Author Information
------------------

Ivan Ivanov <kasper_wps@mail.ru>
https://github.com/KasperWPS
