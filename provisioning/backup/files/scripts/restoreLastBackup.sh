#!/bin/bash

if [[ $# > 0 ]]; then
  for d in "${@}"; do
    if [[ ${d} == 'elk' || ${d} == 'sql' || ${d} == 'www' ]]; then
      if [ $? -ne 0 ]; then
        borg init -e none borg@10.111.177.108:${d}
        if [ $? -ne 0 ]; then
          exit 2;
        fi
      fi

      latestBackup=$(borg list --last 1 --format '{archive}' borg@10.111.177.108:${d})

      echo "Restore from backup ${d}::${latestBackup}"

      cd /

      borg extract borg@10.111.177.108:${d}::${latestBackup}
    fi
  done
fi
