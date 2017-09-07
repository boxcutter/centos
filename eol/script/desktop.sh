#!/bin/bash

if [[ ! "$DESKTOP" =~ ^(true|yes|on|1|TRUE|YES|ON])$ ]]; then
  exit
fi

USERNAME=vagrant

cat /etc/redhat-release
if grep -q -i "release 7" /etc/redhat-release ; then
    # set the graphical.target for systemd so it will run startx on boot
    ln -sf /lib/systemd/system/graphical.target /etc/systemd/system/default.target
fi

GDM_CONFIG=/etc/gdm/custom.conf

# Configure gdm autologin.

if [ -f $GDM_CONFIG ]; then
    sed -i s/"daemon]$"/"daemon]\nAutomaticLoginEnable=true\nAutomaticLogin=vagrant"/ /etc/gdm/custom.conf
fi
