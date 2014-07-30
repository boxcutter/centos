#!/bin/bash -eux
if [[ $UPDATE  =~ true || $UPDATE =~ 1 || $UPDATE =~ yes ]]; then
    echo "==> Applying updates"
    yum -y update

    # reboot
    echo "Rebooting the machine..."
    reboot
    sleep 60
fi
