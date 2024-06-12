#!/bin/bash

set -e

if [ -b /dev/sdb1 ]; then
  echo "Partition sdb1 is found. Skip"
  exit 0
fi

if [ -b /dev/sdb ]; then
  # Create partition table
  parted -s /dev/sdb mklabel gpt
  # Create primary partition
  parted /dev/sdb mkpart primary xfs 0% 100%
  mkfs.xfs -f /dev/sdb1

  mkdir -p /mnt/gfs

  uuid=`blkid -o export /dev/sdb1 | grep ^UUID`
  echo "${uuid} /mnt/gfs xfs noatime 0 0" >> /etc/fstab

  systemctl daemon-reload
  mount -a
fi
