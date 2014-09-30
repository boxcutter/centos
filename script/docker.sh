#!/bin/bash

echo "==> Adding EPEL repo"
cat /etc/redhat-release
if grep -q -i "release 7" /etc/redhat-release ; then
    wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-2.noarch.rpm
    rpm -Uvh epel-release-7*.rpm
    echo "==> Installing docker"
    yum install -y docker
elif grep -q -i "release 6" /etc/redhat-release ; then
    wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
    rpm -Uvh epel-release-6*.rpm
    echo "==> Installing docker"
    yum install -y docker-io
fi

echo "==> Starting docker"
service docker start
echo "==> Enabling docker to start on reboot"
chkconfig docker on
