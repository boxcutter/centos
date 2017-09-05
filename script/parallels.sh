#!/bin/bash -eux

SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}

if [[ $PACKER_BUILDER_TYPE =~ parallels ]]; then
    echo "==> Installing Parallels tools"
    mount -o loop $SSH_USER_HOME/prl-tools-lin.iso /mnt
    bash /mnt/install --install-unattended-with-deps
    umount /mnt
    rm -rf $SSH_USER_HOME/prl-tools-lin.iso
    rm -f $SSH_USER_HOME/.prlctl_version
fi
