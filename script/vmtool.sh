#!/bin/bash -eux

install_vmware_tools_centos_70()
{
    cd /tmp
    mkdir -p /mnt/cdrom
    mount -o loop /home/vagrant/linux.iso /mnt/cdrom
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

    /tmp/vmware-tools-distrib/vmware-install.pl --default
    rm /home/vagrant/linux.iso
    umount /mnt/cdrom
    rmdir /mnt/cdrom
    rm -rf /tmp/VMwareTools-*

    exit
}

install_virtualbox_guest_additions_70()
{
    vb_version=$(cat /home/vagrant/.vbox_version)
    mount -o loop /home/vagrant/VBoxGuestAdditions_${vb_version}.iso /mnt
    sh /mnt/VBoxLinuxAdditions.run --noexec --keep
    umount /mnt

    # Apply patch
    cur_dir=$(pwd)
    tmp_dir=$(mktemp -d)
    patch=VBox-numa_no_reset.diff
cat > ${patch} << _EOF_
Index: src/vboxguest-${vb_version}/vboxguest/r0drv/linux/memobj-r0drv-linux.c
===================================================================
--- src/vboxguest-${vb_version}/vboxguest/r0drv/linux/memobj-r0drv-linux.c (Revision 50574)
+++ src/vboxguest-${vb_version}/vboxguest/r0drv/linux/memobj-r0drv-linux.c (Arbeitskopie)
@@ -66,6 +66,18 @@
 #endif
 
 
+/*
+ * Distribution kernels like to backport things so that we can't always rely
+ * on Linux kernel version numbers to detect kernel features.
+ */
+#ifdef CONFIG_SUSE_KERNEL
+# if LINUX_VERSION_CODE >= KERNEL_VERSION(3, 12, 0)
+# define NUMA_NO_RESET
+# endif
+#elif LINUX_VERSION_CODE < KERNEL_VERSION(3, 13, 0)
+# define NUMA_NO_RESET
+#endif
+
 /*******************************************************************************
 *   Structures and Typedefs                                                    *
 *******************************************************************************/
@@ -1533,12 +1545,12 @@
                 /** @todo Ugly hack! But right now we have no other means to disable
                  *        automatic NUMA page balancing. */
 # ifdef RT_OS_X86
-#  if LINUX_VERSION_CODE < KERNEL_VERSION(3, 13, 0)
+#  ifndef NUMA_NO_RESET
                 pTask->mm->numa_next_reset = jiffies + 0x7fffffffUL;
 #  endif
                 pTask->mm->numa_next_scan  = jiffies + 0x7fffffffUL;
 # else
-#  if LINUX_VERSION_CODE < KERNEL_VERSION(3, 13, 0)
+#  ifndef NUMA_NO_RESET
                 pTask->mm->numa_next_reset = jiffies + 0x7fffffffffffffffUL;
 #  endif
                 pTask->mm->numa_next_scan  = jiffies + 0x7fffffffffffffffUL;
_EOF_

    tarball=${cur_dir}/install/VBoxGuestAdditions-amd64.tar.bz2

    cd ${tmp_dir}
    tar xjf ${tarball}
    patch -p0 < ${cur_dir}/${patch}
    tar cjf ${tarball} *

    # Run installer
    cd ${cur_dir}/install
    ./install.sh

    # Clean up
    cd ..
    rm -rf ${tmp_dir}
    rm -rf ${cur_dir}/install
    rm -f ${cur_dir}/${patch}

    rm -f /home/vagrant/VBoxGuestAdditions_$VBOX_VERSION.iso
    rm -f /home/vagrant/.vbox_version
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
        echo "export PATH=$PATH:/usr/sbin:/sbin" >> /home/vagrant/.bashrc
    fi

    cd /tmp
    mkdir -p /mnt/cdrom
    mount -o loop /home/vagrant/linux.iso /mnt/cdrom
    tar zxf /mnt/cdrom/VMwareTools-*.tar.gz -C /tmp/
    /tmp/vmware-tools-distrib/vmware-install.pl --default
    rm /home/vagrant/linux.iso
    umount /mnt/cdrom
    rmdir /mnt/cdrom
    rm -rf /tmp/VMwareTools-*
fi

if [[ $PACKER_BUILDER_TYPE =~ virtualbox ]]; then
    echo "==> Installing VirtualBox guest additions"

    if grep -q -i "release 7" /etc/redhat-release ; then
        install_virtualbox_guest_additions_70
    fi

    # Assume that we've installed all the prerequisites:
    # kernel-headers-$(uname -r) kernel-devel-$(uname -r) gcc make perl
    # from the install media via ks.cfg

    VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
    mount -o loop /home/vagrant/VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
    sh /mnt/VBoxLinuxAdditions.run --nox11
    umount /mnt
    rm -rf /home/vagrant/VBoxGuestAdditions_$VBOX_VERSION.iso
    rm -f /home/vagrant/.vbox_version

    if [[ $VBOX_VERSION = "4.3.10" ]]; then
        ln -s /opt/VBoxGuestAdditions-4.3.10/lib/VBoxGuestAdditions /usr/lib/VBoxGuestAdditions
    fi
fi

echo "==> Removing packages needed for building guest tools"
yum -y remove gcc cpp kernel-devel kernel-headers perl
