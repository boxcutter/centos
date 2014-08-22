#!/bin/bash

echo "==> Adding EPEL repo"
cat /etc/redhat-release
if grep -q -i "release 7" /etc/redhat-release ; then
    rpm -Uvh http://mirrors.mit.edu/epel/beta/7/x86_64/epel-release-7-0.2.noarch.rpm
    echo "==> Installing docker"
    yum install -y docker
elif grep -q -i "release 6" /etc/redhat-release ; then
    rpm -Uvh http://fedora-epel.mirror.lstn.net/6/i386/epel-release-6-8.noarch.rpm
    echo "==> Installing docker"
    yum install -y docker-io
fi

echo "==> Starting docker"
service docker start
echo "==> Enabling docker to start on reboot"
chkconfig docker on
