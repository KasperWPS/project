#!/bin/bash

if [ -f fedora-40.box ]; then
  rm -f fedora-40.box
fi

packer build ./fedora.json

if [ $? -eq 0 ]; then
  vagrant box remove fedora/40
  vagrant box add fedora-40.box --name fedora/40
fi