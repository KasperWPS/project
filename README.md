# Проектная работа "Разработка стенда для демонстрации аварийного восстановления ключевых узлов инфраструктуры предприятия"

Задание
- [ ] Подготовить стенд отвечающий следующим требованиям:
  - [x] Включен https
  - [x] Основная инфраструктура в DMZ
  - [x] Файрвалл на входе
  - [x] Сбор метрик и настроенный алертинг
  - [x] Организован централизованный сбор логов
  - [ ] Организован backup
  - [ ] Backup server
- [ ] Дополнительно реализовано:
  - [x] Репликация СУБД
  - [x] Распределенная файловая система для web-каталога
  - [x] NTPD
  - [x] Локальный репозиторий


![Network topology](https://github.com/KasperWPS/project/blob/main/images/projectTopology.svg)

Содержание:
- [reverseProxy](#reverseproxy)
- [inetRouter](#inetrouter)
- [repo](#repo)
- [Websrv](#websrv)
- [GlusterFS](#glusterfs)

Стенд
- Vagrant 2.4.1
- Ansible 2.16.6
- Python: 3.11.9
- Packer: 1.9.5

## Образ (box) хостов
Для стэнда подготовлен образ виртуальной машины на основе Fedora Server 40. В образе отключен SELinux, firewalld, диск разбит автоматически (XFS, LVM), загрузка EFI, SWAP-раздел отсутствует, добавлен флаг ядра clk_ignore_unused, удалены флаги rhgb & quiet. Предустановлено следующее ПО:
- NetworkManager-initscripts-ifcfg-rh (для функционирования штатного механизма конфигурирования сетевых интерфейсов Vagrant)
- mc
- tcpdump
А также прописан vagrant insecure public key, создан **пользователь vagrant** с **паролем vagrant**

## Описание хостов

### reverseProxy

- Network:
  - enp0s3; 10.0.2.15/24. Смотрит наружу. Проброшены порты с хоста 8080 -> 80; 8443 -> 443; 2501 -> 22
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
ansible-playbook -i provisioning/hosts provisioning/playbook.yml --tags="deploy reverseProxy"
```

## inetRouter

- Network:
  - enp0s3; 10.0.2.15/24. Смотрит наружу. Проброшен порт с хоста 2502 -> 22
  - enp0s8; 192.168.0.5/30 - отдельный интерфейс для reverseProxy
  - enp0s9; 192.168.0.126/26 - смотрит во внутреннюю сеть
  - Включен forwarding
    - Из внутренней сети наружу без ограничений
    - От reverseProxy (192.168.0.6) до
      - 192.168.0.71:80 (websrv)
      - 192.168.0.76:5044 (filebeat - logstash)
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
ansible-playbook -i provisioning/hosts provisioning/playbook.yml --tags="deploy inetRouter"
```


## <a id="repo">repo - Локальные репозитории</a>

Т.к. объем репозиториев 160 Гб они были расположены на NFS-шаре, где 2 жестких диска в RAID 1 добавлены в phisical volume из которого выделен logical volume для репозитория.

Для данного проекта написаны скрипты для сборки и размещены в локальном репозитории следующие пакеты:
  - gluster-exporter (https://github.com/KasperWPS/gluster-exporter)
  - mysqld_exporter (https://github.com/KasperWPS/mysqld_exporter)

На этом же хосте **поднят NTPD**

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
ansible-playbook -i provisioning/hosts provisioning/playbook.yml --tags="deploy repo"
```

## Websrv

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


## <a id="glusterfs">GlusterFS (Hosts: brick1, brick2, brick3)</a>

- Network (на каждом хосте):
  - enp0s3; 10.0.2.15/24. Смотрит наружу. Отключено применение маршрута по-умолчанию от dhcp. Проброшен порт с хоста
    - 2506 -> 22. brick1.
    - 2507 -> 22. brick2.
    - 2508 -> 22. brick3.
  - enp0s8;
    - 192.168.0.68/26 - brick1. Internal network
    - 192.168.0.69/26 - brick2. Internal network
    - 192.168.0.70/26 - brick3. Internal network

- nftables
  - 22 для управления vagrant+ansible;
  - 9100 - с ip 192.168.0.72 (мониторинг)
  - 9713 - с ip 192.168.0.72 (мониторинг Gluster-exporter)
  - 24007-24008; 49152-49156 TCP - GlusterFS с адресов 192.168.0.68-192.168.0.71, 192.168.0.73-192.168.0.74 (brick1, brick2, brick3, elk, backup)
  - ICMP

На всех хостах GlusterFS подключены виртуальные диски объемом 4096 Мб, создан раздел с файловой системой XFS и смонтированы в /mnt/gfs


