#!/bin/bash

path_backup=/backup/full_backup
path_olddata=/old_MySQLdata/$(date +%F-%s)
path_mysqlData=/var/lib/mysql

if [ -d ${path_backup} ]; then
  echo "Stage 1. Decompress backup"
  mariabackup --decompress --parallel=$(nproc) --remove-original --target-dir=${path_backup}
  if [ $? -ne 0 ]; then
    echo "Decompress backup fault!"
    exit 1;
  fi
  echo "Stage 2. Prepare backup"
  mariabackup --prepare --target-dir=${path_backup}
  if [ $? -ne 0 ]; then
    echo "Prepare backup fault!"
    exit 1;
  fi
  echo "Stage 3. Stop MariaDB service"
  systemctl stop mariadb

  echo "Stage 4. Move data"
  mkdir -p ${path_olddata}
  mv ${path_mysqlData}/* ${path_olddata}
  mv ${path_backup}/* ${path_mysqlData}
  chown -R mysql:mysql ${path_mysqlData}

  echo "Stage 5. Start MariaDB service"
  systemctl start mariadb
  if [ $? -ne 0 ]; then
    echo "MariaDB is not started!"
    exit 1
  fi

  echo "Stage 6. Remove ${path_backup}"
  rm -rf ${path_backup}
else
  echo "Not found directory /backup/full_backup"
  exit 1
fi

gtid=$(cat /var/lib/mysql/xtrabackup_info | grep -i GTID | sed -E "s/.+GTID.+'([0-9-]+)'/\1/")

