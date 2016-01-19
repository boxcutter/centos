#!/bin/bash -eux

echo "==> Recording box generation date"
date > /etc/vagrant_box_build_date

echo "==> Customizing message of the day"
MOTD_FILE=/etc/motd
BANNER_WIDTH=64
PLATFORM_RELEASE=$(sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release)
PLATFORM_MSG=$(printf 'CentOS %s' "$PLATFORM_RELEASE")
BUILT_MSG=$(printf 'built %s' $(date +%Y-%m-%d))
printf '%0.1s' "-"{1..64} > ${MOTD_FILE}
printf '\n' >> ${MOTD_FILE}
printf '%2s%-30s%30s\n' " " "${PLATFORM_MSG}" "${BUILT_MSG}" >> ${MOTD_FILE}
printf '%0.1s' "-"{1..64} >> ${MOTD_FILE}
printf '\n' >> ${MOTD_FILE}
