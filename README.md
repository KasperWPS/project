# Проектная работа "Разработка стенда для демонстрации аварийного восстановления ключевых узлов инфраструктуры предприятия"

**Задание**
- [x] Подготовить стенд отвечающий следующим требованиям:
  - [x] Включен https
  - [x] Основная инфраструктура в DMZ
  - [x] Файрвалл на входе
  - [x] Сбор метрик и настроенный алертинг
  - [x] Организован централизованный сбор логов
  - [x] *Организован backup*
    - [x] Backup www
    - [x] Backup sql
    - [x] Backup snapshots Elasticsearch
    - [ ] Backup Prometheus
  - [x] Backup server
- [x] Дополнительно реализовано:
  - [x] Репликация СУБД
  - [x] Распределенная файловая система для web-каталога
  - [x] NTPD
  - [x] Локальный репозиторий


![Network topology](https://github.com/KasperWPS/project/blob/main/images/projectTopology.svg)

**Содержание**
- [reverseProxy](#reverseproxy)
- [inetRouter](#inetrouter)
- [repo](#repo)
- [Websrv](#websrv)
- [GlusterFS](#glusterfs)
- [MariaDB](#mariadb)
- [Prometheus](#monitor)
- [ELK](#elk)
- [Восстановление из бэкапа www](#backup_www)
- [Восстановление mysql-source из реплики](#sourceFromReplica)

Стенд
- Vagrant 2.4.1
- Ansible 2.16.6
- Python: 3.11.9
- Packer: 1.9.5

Ресурсы на ВМ:
- Prometheus (http://mon.kdev.su:2802/)
- Kibana (http://kibana.kdev.su:2801/)
- Repositories (http://repo.kdev.su:2800/repo/)
- Websrv - nextcloud (https://websrv.kdev.su:8443/)

## Образ (box) хостов
Для стэнда подготовлен образ виртуальной машины на основе Fedora Server 40. В образе отключен SELinux, firewalld, диск разбит автоматически (XFS, LVM), загрузка EFI, SWAP-раздел отсутствует, добавлен флаг ядра clk_ignore_unused, удалены флаги rhgb & quiet. Предустановлено следующее ПО:

- NetworkManager-initscripts-ifcfg-rh (для функционирования штатного механизма конфигурирования сетевых интерфейсов Vagrant)
- mc
- tcpdump

А также прописан vagrant insecure public key, создан **пользователь vagrant** с **паролем vagrant**

## Описание хостов

### <a id="reverseProxy">reverseProxy</a>

- Network:
  - enp0s3; 10.0.2.15/24. Смотрит наружу. Проброшены порты с хоста:
    - 2501 -> 22
    - 8080 -> 80 (редирект на 443)
    - 8443 -> 443
  - enp0s9; 192.168.0.6/30. Смотрит внутрь, на роутер (+ firewall)

- nftables
  - 80, 443
  - 22 для управления vagrant+ansible; в реальных условиях разрешен только из внутренней сети
  - 9100 - с ip 192.168.0.72 (мониторинг)
  - ICMP

- Nginx:
  - redirect (301 permanently) 80 -> 443
  - openssl генерирует ключевую пару для доменов *.kdev.su
  - mon.kdev.su:8443 проксируется на 192.168.0.72:3000 (Grafana) - только для стэнда, в проде нет, доступ исключительно из внутренней сети
  - websrv.kdev.su:8443 проксируется на 192.168.0.71:80(VM websrv). Для теста на websrv установлен nextcloud

- Destroy and deploy:

```bash
vagrant destroy reverseProxy -f
```

```bash
vagrant up reverseProxy
```

```bash
ansible-playbook provisioning/playbook.yml --tags="deploy reverseProxy"
```

## <a id="inetRouter">inetRouter</a>

- Network:
  - enp0s3; 10.0.2.15/24. Смотрит наружу. Проброшен порт с хоста 2502 -> 22
  - enp0s8; 192.168.0.5/30 - отдельный интерфейс для reverseProxy
  - enp0s9; 192.168.0.126/26 - смотрит во внутреннюю сеть
  - Включен forwarding
    - Из внутренней сети наружу без ограничений
    - От reverseProxy (192.168.0.6) до
      - 192.168.0.71:80 (websrv)
      - 192.168.0.73:5044 (filebeat - logstash)
      - 192.168.0.65:80 (local repository)

- nftables
  - 22 для управления vagrant+ansible; в реальных условиях разрешен только из внутренней сети
  - UDP 33434-33524 для traceroute
  - ICMP accept
  - Маскарадинг трафика из внутренней сети во внешнюю
  - Forwarding по-умолчанию запрещён

- Destroy and deploy:

```bash
vagrant destroy inetRouter -f
```

```bash
vagrant up inetRouter
```

```bash
ansible-playbook provisioning/playbook.yml --tags="deploy inetRouter"
```


## <a id="repo">repo - Локальные репозитории</a>

Т.к. объем репозиториев 160 Гб они были расположены на NFS-шаре, где 2 жестких диска в RAID 1 добавлены в phisical volume из которого выделен logical volume для репозитория.

Для данного проекта написаны скрипты для сборки и размещены в локальном репозитории следующие пакеты:
  - gluster-exporter (https://github.com/KasperWPS/gluster-exporter)
  - mysqld_exporter (https://github.com/KasperWPS/mysqld_exporter)
  - prometheus-alertmanager (https://github.com/KasperWPS/alertmanager_rpm)

Добавлен локальный репозиторий для разворачивания ELK-стэка (elasticsearch-8.x)

На этом же хосте **поднят NTPD**

- Проверка ntpd

```bash
chronyc sources
```

```bash
chronyc tracking
```

- Network:
  - enp0s3; 10.0.2.15/24. Проброшен порт с хоста 2503 -> 22. Отключено применение маршрута по-умолчанию от dhcp.
  - enp0s8; 192.168.0.65/26 - internal

- nftables
  - 22 для управления vagrant+ansible;
  - 9100 - с ip 192.168.0.72 (мониторинг)
  - 80 с ip-адресов 192.168.0.64/26; 192.168.0.6/32 для доступа к локальному репозиторию
  - 123 UDP 192.168.0.64/26; 192.168.0.6/32 NTPD

- Nginx:
  - root /var/www - точка монтирования NFS-шары с репозиториями
  - autoindex

- Destroy and deploy:

```bash
vagrant destroy repo -f
```

```bash
vagrant up repo
```

```bash
ansible-playbook provisioning/playbook.yml --tags="deploy repo"
```

## <a id="Websrv">Websrv</a>

- Network:
  - enp0s3; 10.0.2.15/24. Смотрит наружу. Проброшен порт с хоста 2509 -> 22. Отключено применение маршрута по-умолчанию от dhcp.
  - enp0s8; 192.168.0.71/26 - internal

- nftables
  - 22 для управления vagrant+ansible;
  - 9100 - с ip 192.168.0.72 (мониторинг)
  - 80 с ip-адреса 192.168.0.6/32
  - ICMP

- Nginx:
  - root /var/gfs-point/www - точка монтирования GlusterFS
  - fastcgi_pass unix:/run/php-fpm/www.sock;

- PHP-FPM
  - user, group - nginx
  - listen = /run/php-fpm/www.sock
  - php.ini - display_errors on - для тестирования, максимальное время исполнения было увеличено.

- Установлены:
  - php-fpm
  - php-gd
  - php-mbstring
  - php-xml
  - php-pdo
  - php-pecl-zip
  - php-opcache
  - php-mysqlnd
  - php-process
  - php-cli (ocs; работа с индексами и прочее для обслуживания)

- Destroy and deploy:

```bash
vagrant destroy websrv -f
```

```bash
vagrant up websrv
```

```bash
ansible-playbook provisioning/playbook.yml --tags="deploy websrv"
```


## <a id="glusterfs">GlusterFS (Hosts: brick1, brick2, brick3)</a>

- Network (на каждом хосте):
  - enp0s3; 10.0.2.15/24. Смотрит наружу. Отключено применение маршрута по-умолчанию от dhcp. Проброшен порт с хоста
    - 2506 -> 22; brick1
    - 2507 -> 22; brick2
    - 2508 -> 22; brick3
  - enp0s8;
    - 192.168.0.68/26 - brick1. Internal network
    - 192.168.0.69/26 - brick2. Internal network
    - 192.168.0.70/26 - brick3. Internal network

- nftables
  - 22 для управления vagrant+ansible;
  - 9100 - с ip 192.168.0.72 (мониторинг)
  - 9713 - с ip 192.168.0.72 (мониторинг Gluster-exporter)
  - 24007-24008; 49152-60999 TCP - GlusterFS с адресов 192.168.0.73, 192.168.0.74, 192.168.0.71, 192.168.0.66, 192.168.0.67 (elk, backup, websrv, mysql-source, mysql-replica)
  - 192.168.0.68-192.168.0.70 - brick1, brick2, brick3
  - ICMP

На всех хостах GlusterFS подключены виртуальные диски объемом 4096 Мб, создан раздел с файловой системой XFS и смонтированы в /mnt/gfs

Структура volume (/var/gfs-point/):
 - sql (0:0)
 - elk (984:984)
 - www (985:985)

**При отвале ноды (вручную):**

- Смотрим какие брики имеются на volume

```bash
gluster volume info gfs
```

- Смотрим какие брики в наличии на volume

```bash
gluster volume status gfs
```

- Удаляем брики с отвалившегося пира (в пример пир brick2 с бриком /mnt/gfs)

```bash
gluster volume remove-brick gfs replica 2 brick2:/mnt/gfs force
```

- Детачим отвалившийся пир

```bash
gluster peer detach brick2
```

- Присоединить вновь поднятый пир

```bash
gluster peer probe brick2
```

- Добавляем брик

```bash
gluster volume add-brick gfs replica 3 brick2:/mnt/gfs force
```

**Полный дестрой и поднятие**

```bash
vagrant destroy brick1 brick2 brick3 -f
```

- Собрать новый volume

```bash
ansible-playbook --vault-id @prod provisioning/playbook.yml --tags="deploy glusterfs"
```

- Перезагрузить серверы на которых был примонтирован volume или на каждом выполнить umount /var/gfs-point && mount /var/gfs-point

```bash
vagrant reload mysql-replica backup websrv elk
```

- <a id="backup_www">Восстановить последние бэкапы.</a>

```bash
ansible-playbook --vault-id @prod provisioning/playbook.yml --tags="deploy backup server, restore backup elk, restore backup www, restore backup sql"
```

- Во время написания проекта столкнулся с тем, что бэкап выполнялся в момент уничтожения glusterfs и в репозиторий попадала пустая директория (в другой раз битые файлы после уничтожения двух пиров glusterfs) - в подобных случаях необходимо восстановится вручную. Инструкция ниже:

```bash
vagrant ssh backup
```

- Список бэкапов в репозитории **www** (/var/gfs-point/www), есть также **sql** и **elk**

```bash
borg list borg@10.111.177.108:www
```

```
2024-06-09_20:24:59                  Sun, 2024-06-09 20:25:00 [a193d825a690a0cfcbe1b237b0633d1464f94e47ba0a7ab75ef6aee1b370e2bd]
2024-06-10_19:48:21                  Mon, 2024-06-10 19:48:21 [2caa71e926b89baaeef2e20dff73845b7ee09b743d4cdcd234ef3a67f016a82b]
2024-06-11_19:20:41                  Tue, 2024-06-11 19:20:42 [0ea3ee6e7f6844017a9c6d9dea26b45253ba4df7f757bc360c5c81b4bf56650d]
2024-06-12_15:13:32                  Wed, 2024-06-12 15:13:32 [03b058ca84ca0b36b9f7b1a936c6953e13e3bf7fee6812bb48fd55987eb7d4d5]
2024-06-12_16:21:21                  Wed, 2024-06-12 16:21:22 [0b03121e3b55bd41bc196aa0154ab9a09c2915b1ad1a99ee661eb69aa03fd7b9]
```

- Восстановить бэкап 2024-06-12_16:21:21

```bash
cd /
borg extract borg@10.111.177.108:www::2024-06-12_16:21:21
```

## <a id="mariadb">MariaDB</a>

СУБД

- Network:
  - enp0s3; 10.0.2.15/24. Проброшен порт с хоста 2504 -> 22. Отключено применение маршрута по-умолчанию от dhcp.
  - enp0s8; 192.168.0.66/26 - internal

- nftables (host mysql-source)
  - 22 для управления vagrant+ansible;
  - 9100 - с ip 192.168.0.72 (мониторинг)
  - 9104 - с ip 192.168.0.72 (мониторинг mysql_exporter)
  - 3306 с ip-адресов 192.168.0.67 (replica), 192.168.0.71 (websrv)

- Уничтожить и восстановить реплику

```bash
vagrant destroy mysql-replica -f
```

```bash
vagrant up mysql-replica
```

```bash
ansible-playbook provisioning/playbook.yml --vault-id @prod --tags="deploy mysql-replica, Set up replica"
```

- <a id="sourceFromReplica">Уничтожение и восстановление мастера из реплики</a>

```bash
vagrant destroy mysql-source -f
```

```bash
vagrant up mysql-source
```

```bash
ansible-playbook --vault-id @prod provisioning/playbook.yml --tags="deploy mysql-source, Set up replica, restore from replica"
```

- Уничтожение мастера и реплики с восстановлением из sql-dump'а

```bash
vagrant destroy mysql-source mysql-replica -f
```

```bash
vagrant up mysql-source mysql-replica
```

```bash
ansible-playbook --vault-id @prod provisioning/playbook.yml --tags="deploy mysql-source, restore from sql on mysql-source, deploy mysql-replica, Set up replica"
```

## <a id="monitor">Prometheus</a>

Alertmanager собран из исходников (в репозитории Fedora старая версия без поддержки Telegram, можно с использованием curl, но практикуюсь в сборке пакетов)

- alertmanager (https://github.com/KasperWPS/alertmanager_rpm)

На Grafana настроен также алертинг, т.к. версия из дистрибутива использует устаревший API (v1) alertmanager не удалось настроить их совместную работу, использован сервис графаны, alertmanager используется только в алертинге prometheus.

## <a id="elk">ELK</a>

Snapshots

