#!/bin/bash -eux

SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}

install_vmware_tools_centos_70()
{
    cd /tmp
    mkdir -p /mnt/cdrom
    mount -o loop $SSH_USER_HOME/linux.iso /mnt/cdrom
    tar zxf /mnt/cdrom/VMwareTools-*.tar.gz -C /tmp/

    mkdir -p /mnt/floppy
    modprobe floppy
    mount -t vfat /dev/fd0 /mnt/floppy

    cd /tmp/vmware-tools-distrib

    if [[ -f /mnt/cdrom/VMwareTools-9.6.2-1688356.tar.gz ]]
    then
        pushd lib/modules/source
        if [ ! -f vmhgfs.tar.orig ]
        then
            cp vmhgfs.tar vmhgfs.tar.orig
        fi
        rm -rf vmhgfs-only
        tar xf vmhgfs.tar
        pushd vmhgfs-only/shared
        patch -p1 < /mnt/floppy/vmware9.compat_dcache.h.patch
        popd
        tar cf vmhgfs.tar vmhgfs-only
        rm -rf vmhgfs-only
        popd        
    fi

    /tmp/vmware-tools-distrib/vmware-install.pl --default --force
    rm $SSH_USER_HOME/linux.iso
    umount /mnt/cdrom
    rmdir /mnt/cdrom
    rm -rf /tmp/VMwareTools-*

    echo "==> Removing packages needed for building guest tools"
    yum -y remove gcc cpp kernel-devel kernel-headers perl
    
    exit
}

if [[ $PACKER_BUILDER_TYPE =~ vmware ]]; then
    echo "==> Installing VMware Tools"
    cat /etc/redhat-release
    if grep -q -i "release 7" /etc/redhat-release ; then
        install_vmware_tools_centos_70
    fi
    if grep -q -i "release 6" /etc/redhat-release ; then
        # Uninstall fuse to fake out the vmware install so it won't try to
        # enable the VMware blocking filesystem
        yum erase -y fuse
    fi
    # Assume that we've installed all the prerequisites:
    # kernel-headers-$(uname -r) kernel-devel-$(uname -r) gcc make perl
    # from the install media via ks.cfg

    # On RHEL 5, add /sbin to PATH because vagrant does a probe for
    # vmhgfs with lsmod sans PATH
    if grep -q -i "release 5" /etc/redhat-release ; then
        echo "export PATH=$PATH:/usr/sbin:/sbin" >> $SSH_USER_HOME/.bashrc
    fi

    cd /tmp
    mkdir -p /mnt/cdrom
    mount -o loop $SSH_USER_HOME/linux.iso /mnt/cdrom
    tar zxf /mnt/cdrom/VMwareTools-*.tar.gz -C /tmp/
    /tmp/vmware-tools-distrib/vmware-install.pl --default
    rm $SSH_USER_HOME/linux.iso
    umount /mnt/cdrom
    rmdir /mnt/cdrom
    rm -rf /tmp/VMwareTools-*
fi

if [[ $PACKER_BUILDER_TYPE =~ virtualbox ]]; then
    echo "==> Installing VirtualBox guest additions"
    # Assume that we've installed all the prerequisites:
    # kernel-headers-$(uname -r) kernel-devel-$(uname -r) gcc make perl
    # from the install media via ks.cfg

    VBOX_VERSION=$(cat $SSH_USER_HOME/.vbox_version)
    mount -o loop $SSH_USER_HOME/VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
    sh /mnt/VBoxLinuxAdditions.run --nox11
    umount /mnt
    rm -rf $SSH_USER_HOME/VBoxGuestAdditions_$VBOX_VERSION.iso
    rm -f $SSH_USER_HOME/.vbox_version

    if [[ $VBOX_VERSION = "4.3.10" ]]; then
        ln -s /opt/VBoxGuestAdditions-4.3.10/lib/VBoxGuestAdditions /usr/lib/VBoxGuestAdditions
    fi
fi

echo "==> Removing packages needed for building guest tools"
yum -y remove gcc cpp libmpc mpfr kernel-devel kernel-headers perl
