#!/bin/bash

if [[ ! "$DOCKER" =~ ^(true|yes|on|1|TRUE|YES|ON])$ ]]; then
  exit
fi

echo "==> Run the Docker installation script"
curl -sSL https://get.docker.com | sh

echo "==> Create the docker group"
# Add the docker group if it doesn't already exist
groupadd docker

echo "==> Add the connected "${USER}" to the docker group."
gpasswd -a ${USER} docker
gpasswd -a ${SSH_USERNAME} docker

echo "==> Starting docker"
service docker start
echo "==> Enabling docker to start on reboot"
chkconfig docker on
