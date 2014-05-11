#!/bin/bash -eux

# PROVISIONER and PROVISIONER_VERSION variables should be set inside of
# Packer's template:
#
# Values for PROVISIONER are:
#   'provisionerless' -- build a box without a provisioner
#   'chef'            -- build a box with the Chef provisioner
#   'salt'            -- build a box with the Salt provisioner
#   'puppet'          -- build a box with the Puppet provisioner
#
# When PROVISIONER != 'provisionerless' values for PROVISIONER_VERSION are:
#   'x.y.z'           -- build a box with version x.y.z of the Chef provisioner
#   'x.y'             -- build a box with version x.y of the Salt provisioner
#   'latest'          -- build a box with the latest version of the provisioner
#
# Assume that PROVISIONER environment variable is set inside of Packer's
# template.
#
# Set PROVISIONER_VERSION to 'latest' if unset because it can be problematic
# to set variables in pairs with Packer (and Packer does not support
# multi-value variables).
PROVISIONER_VERSION=${PROVISIONER_VERSION:-latest}

#
# Provisioner installs.
#

install_chef()
{
    echo "==> Installing Chef provisioner"
    if [[ ${PROVISIONER_VERSION:-} == 'latest' ]]; then
        echo "==> Installing latest Chef version"
        curl -L https://www.opscode.com/chef/install.sh | sh
    else
        echo "==> Installing Chef version ${PROVISIONER_VERSION}"
        curl -L https://www.opscode.com/chef/install.sh | sh -s -- -v ${PROVISIONER_VERSION}
    fi
    if [[ ${PROVISIONER_SET_PATH:-} == 'true' ]]; then
      echo "Automatically setting vagrant PATH to Chef Client"
      echo 'export PATH="/opt/chef/embedded/bin:$PATH"' >> /home/vagrant/.bash_profile
    fi
}

install_salt()
{
    echo "==> Installing Salt provisioner"
    if [[ ${PROVISIONER_VERSION:-} == 'latest' ]]; then
        echo "==> Installing latest Salt version"
        curl -L http://bootstrap.saltstack.org | sudo sh
    else
        echo "==> Installing Salt version ${PROVISIONER_VERSION}"
        curl -L http://bootstrap.saltstack.org | sudo sh -s -- git ${PROVISIONER_VERSION}
    fi
}

install_puppet()
{
    echo "==> Installing Puppet provisioner"
    REDHAT_MAJOR_VERSION=$(egrep -Eo 'release ([0-9][0-9.]*)' /etc/redhat-release | cut -f2 -d' ' | cut -f1 -d.)

    echo "==> Installing Puppet Labs repositories"
    rpm -ipv "http://yum.puppetlabs.com/puppetlabs-release-el-${REDHAT_MAJOR_VERSION}.noarch.rpm"

    if [[ ${PROVISIONER_VERSION:-} == 'latest' ]]; then
        echo "==> Installing latest Puppet version"
        yum -y install puppet
    else
        echo "==> Installing Puppet version ${PROVISIONER_VERSION}"
        yum -y install "puppet-${PROVISIONER_VERSION}"
    fi
}

#
# Main script
#

case "${PROVISIONER}" in
  'chef')
    install_chef
    ;;

  'salt')
    install_salt
    ;;

  'puppet')
    install_puppet
    ;;

  *)
    echo "==> Building box without a provisioner"
    ;;
esac
