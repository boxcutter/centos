#!/bin/bash

echo "==> Installing docker"
yum install -y docker-io

echo "==> Starting docker"
service docker start
echo "==> Enabling docker to start on reboot"
chkconfig docker on
