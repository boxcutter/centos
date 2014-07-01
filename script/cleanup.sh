#!/bin/bash -eux

#CLEANUP_PAUSE=${CLEANUP_PAUSE:-0}
#echo "==> Pausing for ${CLEANUP_PAUSE} seconds..."
#sleep ${CLEANUP_PAUSE}

echo "==> Cleaning up temporary network addresses"
# Make sure udev doesn't block our network
if grep -q -i "release 6" /etc/redhat-release ; then
    rm -f /etc/udev/rules.d/70-persistent-net.rules
    mkdir /etc/udev/rules.d/70-persistent-net.rules
    rm /lib/udev/rules.d/75-persistent-net-generator.rules
fi
rm -rf /dev/.udev/
if [ -f /etc/sysconfig/network-scripts/ifcfg-eth0 ] ; then
    sed -i "/^HWADDR/d" /etc/sysconfig/network-scripts/ifcfg-eth0
    sed -i "/^UUID/d" /etc/sysconfig/network-scripts/ifcfg-eth0
fi

echo "==> Cleaning up yum cache of metadata and packages to save space"
yum -y clean all

echo "==> Removing temporary files used to build box"
rm -rf /tmp/*

echo '==> Zeroing out empty area to save space in the final image'
# Zero out the free space to save space in the final image.  Contiguous
# zeroed space compresses down to nothing.
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Block until the empty file has been removed, otherwise, Packer
# will try to kill the box while the disk is still full and that's bad
sync
