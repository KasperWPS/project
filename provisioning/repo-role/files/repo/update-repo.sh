#!/bin/bash

echo "Repo sync start $(date)"

#Path to repo-base
path_repoBase=/var/www/repo/

if [ ! -d ${path_repoBase} ]; then
  echo "Path ${path_repoBase} not found!"
  exit 1;
fi

#Array of repositories
repos=(fedora updates fedora-cisco-openh264)

for name in ${repos[@]:0:${#repos[@]}};
do
  cd ${path_repoBase}
  echo "Sync repo ${name}"

  dnf reposync --repoid ${name} > /dev/null

  while [ $? -eq 1 ] # Бесконечно долбим
  do
    dnf reposync --repoid ${name} > /dev/null
  done

  cd ${name}
  #createrepo --update --database --workers $(nproc) ./
  # Запуск createrepo на удаленном сервере, т.к. иначе все пакеты при инвентаризации
  # будут передаваться по сети, что, в свою очередь, положит сеть
  echo "1" > ${path_repoBase}/${name}/.runtask
done

echo "Repo sync stop $(date)"
