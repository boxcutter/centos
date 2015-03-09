#!/bin/bash

echo "==> Adding EPEL repo"
yum install -y epel-release
cat /etc/resolv.conf
cat /etc/redhat-release
if grep -q -i "release 7" /etc/redhat-release ; then
    echo "==> Installing docker"
    yum install -y docker
elif grep -q -i "release 6" /etc/redhat-release ; then
    echo "==> Installing docker"
    yum install -y docker-io
fi

# Add the docker group if it doesn't already exist
groupadd docker

# Add the connected "${USER}" to the docker group.
gpasswd -a ${USER} docker
gpasswd -a ${SSH_USERNAME} docker

echo "==> Starting docker"
service docker start
echo "==> Enabling docker to start on reboot"
chkconfig docker on
