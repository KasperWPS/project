#!/bin/bash

path_sql=/var/gfs-point/sql/

if [ ! -d ${path_sql} ]; then
  exit 0
fi

latestBackup=$(borg list --last 1 --format '{archive}' borg@10.111.177.108:sql)

if [ $? -ne 0 ]; then
  borg init -e none borg@10.111.177.108:sql
  if [ $? -ne 0 ]; then
    exit 2;
  fi
fi

borg create borg@10.111.177.108:sql::"{now:%Y-%m-%d_%H:%M:%S}" ${path_sql}
