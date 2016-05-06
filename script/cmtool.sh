#!/bin/bash -eux

# CM and CM_VERSION variables should be set inside of Packer's template:
#
# Values for CM can be:
#   'nocm'            -- build a box without a configuration management tool
#   'chef'            -- build a box with the Chef
#   'chefdk'          -- build a box with the Chef Development Kit
#   'puppet'          -- build a box with the Puppet
#
# Values for CM_VERSION can be (when CM is chef|salt|puppet):
#   'x.y.z'           -- build a box with version x.y.z of Chef or Puppet
#   'x.y'             -- build a box with version x.y of Salt
#   'x' (x >=4)       -- build a box with the latest version x.y.z of Puppet
#   'latest'          -- build a box with the latest version
#
# Set CM_VERSION to 'latest' if unset because it can be problematic
# to set variables in pairs with Packer (and Packer does not support
# multi-value variables).
#
# Note that for versions of puppet >=4.0.0, not only does the name of 
# package used to install Puppet change, but the version of that package
# no longer reflects the actual version of Puppet.
# See https://docs.puppet.com/puppet/latest/reference/about_agent.html
# Specifying cm_version=4.x.y should work, where this script has been 
# updated with the details of that release.
# Specifying cm_version=4 will install the latest version of Puppet >= 4.0.0.
CM_VERSION=${CM_VERSION:-latest}

#
# CM installs.
#

install_chef()
{
    echo "==> Installing Chef"
    if [[ ${CM_VERSION:-} == 'latest' ]]; then
        echo "==> Installing latest Chef version"
        curl -Lk https://www.opscode.com/chef/install.sh | sh
    else
        echo "==> Installing Chef version ${CM_VERSION}"
        curl -Lk https://www.opscode.com/chef/install.sh | sh -s -- -v ${CM_VERSION}
    fi
}

install_chefdk()
{
    echo "==> Installing Chef Development Kit"
    if [[ ${CM_VERSION:-} == 'latest' ]]; then
        echo "==> Installing latest Chef version"
        curl -Lk https://www.opscode.com/chef/install.sh | sh -s -- -P chefdk
    else
        echo "==> Installing Chef version ${CM_VERSION}"
        curl -Lk https://www.opscode.com/chef/install.sh | sh -s -- -P chefdk -v ${CM_VERSION}
    fi
    echo "==> Adding Chef Development Kit and Ruby to PATH"
    echo 'eval "$(chef shell-init bash)"' >> /home/vagrant/.bash_profile
    chown vagrant /home/vagrant/.bash_profile
}

install_salt()
{
    echo "==> Installing Salt"
    if [[ ${CM_VERSION:-} == 'latest' ]]; then
        echo "==> Installing latest Salt version"
        curl -L http://bootstrap.saltstack.org | sudo sh
    else
        echo "==> Installing Salt version ${CM_VERSION}"
        curl -L http://bootstrap.saltstack.org | sudo sh -s -- git ${CM_VERSION}
    fi
}

install_puppet()
{
    REDHAT_MAJOR_VERSION=$(egrep -Eo 'release ([0-9][0-9.]*)' /etc/redhat-release | cut -f2 -d' ' | cut -f1 -d.)

    case ${CM_VERSION:-} in
        4* ) CM_PC_VERSION="pc1"
              RPM_URL="https://yum.puppetlabs.com/puppetlabs-release-${CM_PC_VERSION}-el-${REDHAT_MAJOR_VERSION}.noarch.rpm"
              PUPPET_PACKAGE="puppet-agent"
              case ${CM_VERSION} in
                      4) CM_VERSION="latest" ;;
                  4.4.2) CM_VERSION="1.4.2" ;;
                  4.4.1) CM_VERSION="1.4.1" ;;
                  4.4.0) CM_VERSION="1.4.0" ;;
                  4.3.2) CM_VERSION="1.3.6" ;;
                  4.3.1) CM_VERSION="1.3.2" ;;
                  4.3.0) CM_VERSION="1.3.0" ;;
                  4.2.3) CM_VERSION="1.2.7" ;;
                  4.2.2) CM_VERSION="1.2.6" ;;
                  4.2.1) CM_VERSION="1.2.2" ;;
                  4.2.0) CM_VERSION="1.2.1" ;;
                  4.1.0) CM_VERSION="1.1.1" ;;
                  4.0.0) CM_VERSION="1.0.1" ;;
              esac
              ;;
        * )   RPM_URL="https://yum.puppetlabs.com/puppetlabs-release-el-${REDHAT_MAJOR_VERSION}.noarch.rpm" 
              PUPPET_PACKAGE="puppet"
              ;;
    esac
    
    echo "==> Installing Puppet"
    echo "==> Installing Puppet Labs repositories"
    rpm -ipv $RPM_URL

    if [[ ${CM_VERSION:-} == 'latest' ]]; then
        echo "==> Installing latest Puppet version"
        yum -y install "${PUPPET_PACKAGE}"
    else
        echo "==> Installing Puppet version ${CM_VERSION}"
        yum -y install "${PUPPET_PACKAGE}-${CM_VERSION}"
    fi
}

#
# Main script
#

case "${CM}" in
  'chef')
    install_chef
    ;;

  'chefdk')
    install_chefdk
    ;;

  'salt')
    install_salt
    ;;

  'puppet')
    install_puppet
    ;;

  *)
    echo "==> Building box without baking in a config management tool"
    ;;
esac
