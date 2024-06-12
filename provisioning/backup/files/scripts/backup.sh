#!/bin/bash

latestBackup=$(borg list --last 1 --format '{archive}' borg@10.111.177.108:www)

if [ $? -ne 0 ]; then
  borg init -e none borg@10.111.177.108:www
  if [ $? -ne 0 ]; then
    exit 2;
  fi
fi

borg create borg@10.111.177.108:www::"{now:%Y-%m-%d_%H:%M:%S}" /var/gfs-point/www
