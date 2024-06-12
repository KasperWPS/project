#!/bin/bash

path_elk=/var/gfs-point/elk/

if [ ! -d ${path_elk} ]; then
  exit 0
fi

latestBackup=$(borg list --last 1 --format '{archive}' borg@10.111.177.108:elk)

if [ $? -ne 0 ]; then
  borg init -e none borg@10.111.177.108:elk
  if [ $? -ne 0 ]; then
    exit 2;
  fi
fi

borg create borg@10.111.177.108:elk::"{now:%Y-%m-%d_%H:%M:%S}" ${path_elk}
