#!/bin/bash -eux

echo '==> Removing temporary files used to build box'
# Make sure udev doesn't block our network
if grep -q -i "release 6" /etc/redhat-release ; then
    rm -f /etc/udev/rules.d/70-persistent-net.rules
    mkdir /etc/udev/rules.d/70-persistent-net.rules
    rm /lib/udev/rules.d/75-persistent-net-generator.rules
fi
rm -rf /dev/.udev/
sed -i "/^HWADDR/d" /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i "/^UUID/d" /etc/sysconfig/network-scripts/ifcfg-eth0

echo '==> Cleaning up yum cache of metadata and packages to save space'
yum -y clean all

rm -rf /tmp/*
