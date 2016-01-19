#!/bin/bash

# Configure the elrepo repository so we can upgrade the kernel to 3.13
# Any kernel above 3.8 is more docker-friendly
echo "==> Configuring elrepo repository"
yum install -y http://www.elrepo.org/elrepo-release-6-6.el6.elrepo.noarch.rpm

echo "==> Installing kernel-ml from elrepo"
yum --enablerepo=elrepo-kernel install -y kernel-ml

# Grub tweaks - default to latest kernel
echo "==> Changing grub to boot to latest kernel"
sed -i 's/^default=1/default=0/' /boot/grub/grub.conf
echo "==> Enabling memory limit & control of swap"
sed -i '/kernel \/vmlinuz-3.14/ s/$/ cgroup_enabled=memory swapaccount=1/' /boot/grub/grub.conf

echo "==> Disabling selinux"
sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config


# reboot
echo "Rebooting the machine..."
reboot
sleep 60
