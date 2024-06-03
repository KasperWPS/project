#!/bin/bash

echo "Stage 2. Clean."

if rpm -q --whatprovides kernel | grep -Fqv "$(uname -r)"; then
   rpm -q --whatprovides kernel | grep -Fv  "$(uname -r)" | xargs sudo dnf -y erase
fi

dnf clean all

rm -rf /tmp/*

rm -f /home/vagrant/*.iso
rm -f ~/.bash_history

history -c

hostnamectl set-hostname fedora-srv

# Disable waiting
sed -i 's/GRUB_TIMEOUT=[0-9]\{,2\}/GRUB_TIMEOUT=0/' /etc/default/grub
# Disable splash (two parameters: rhgb & quiet)
sed -i 's/rhgb\s\|quiet\s//g' /etc/default/grub
# Add param clk_ignore_unused. On virtualbox sometime freeze on clk: Disabling unused clocks
sed -i 's/GRUB_CMDLINE_LINUX="[^"]*/& clk_ignore_unused/' /etc/default/grub

grub2-mkconfig -o /etc/grub2-efi.cfg

nmcli connection migrate --plugin ifcfg-rh

# Disable web panel Cockpit
systemctl disable cockpit.socket

# Set skin mc (black color schema)
mkdir -p /root/.config/mc
echo -e "[Midnight-Commander]\nskin=yadt256\n" > /root/.config/mc/ini
sudo -u vagrant mkdir -p /home/vagrant/.config/mc
sudo -u vagrant echo -e "[Midnight-Commander]\nskin=yadt256\n" > /home/vagrant/.config/mc/ini

sync