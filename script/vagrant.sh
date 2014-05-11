#!/bin/bash -eux

echo '==> Configuring settings for vagrant'

VAGRANT_USER=${VAGRANT_USER:-vagrant}
VAGRANT_HOME=${VAGRANT_HOME:-/home/${VAGRANT_USER}}
VAGRANT_SSH_KEY_URL=${VAGRANT_SSH_KEY_URL:-https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub}

# Add vagrant user (if it doesn't already exist)
if ! id -u $VAGRANT_USER >/dev/null 2>&1; then
    echo '==> Creating Vagrant user'
    /usr/sbin/groupadd $VAGRANT_USER
    /usr/sbin/useradd $VAGRANT_USER -g $VAGRANT_USER -G wheel
    echo "${VAGRANT_USER}"|passwd --stdin $VAGRANT_USER
    echo "${VAGRANT_USER}        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
fi

# Installing vagrant keys
echo '==> Installing Vagrant SSH key'
mkdir -pm 700 $VAGRANT_HOME/.ssh
echo "==> Downloading SSH key from ${VAGRANT_SSH_KEY_URL}"
echo "==> Saving to ${VAGRANT_HOME}/.ssh/autorized_keys"
wget --no-check-certificate "${VAGRANT_SSH_KEY_URL}" -O $VAGRANT_HOME/.ssh/authorized_keys
chmod 0600 $VAGRANT_HOME/.ssh/authorized_keys
chown -R $VAGRANT_USER:$VAGRANT_USER $VAGRANT_HOME/.ssh

echo '==> Recording box config date'
date > /etc/vagrant_box_build_time

echo '==> Customizing message of the day'
echo 'Welcome to your Packer-built virtual machine.' > /etc/motd
