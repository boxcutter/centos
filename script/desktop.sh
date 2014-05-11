#!/bin/bash

USERNAME=vagrant
GDM_CONFIG=/etc/gdm/custom.conf

# Configure gdm autologin.

if [ -f $GDM_CONFIG ]; then
    sed -i s/"daemon]$"/"daemon]\nAutomaticLoginEnable=true\nAutomaticLogin=vagrant"/ /etc/gdm/custom.conf
fi
