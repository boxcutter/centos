require_relative 'spec_helper'

describe 'box' do
  it 'should have a root user' do
    expect(user 'root').to exist
  end

  it 'should have a vagrant user' do
    expect(user 'vagrant').to exist
  end

  it 'should not have a .vbox_version file' do
    expect(file '/home/vagrant/.vbox_version').to_not be_file
  end

  it 'should disable SELinux' do
    expect(selinux).to be_permissive
  end

  # https://www.chef.io/blog/2015/02/26/bento-box-update-for-centos-and-fedora/
  describe 'test-cacert' do
    it 'uses the vendor-supplied openssl certificates' do
      expect(command('openssl s_client -CAfile /etc/pki/tls/certs/ca-bundle.crt -connect packagecloud-repositories.s3.amazonaws.com:443 </dev/null 2>&1 | grep -i "verify return code"').stdout).to match /\s+Verify return code: 0 \(ok\)/
    end
  end

  has_docker = command('command -v docker').exit_status == 0
  it 'should make vagrant a member of the docker group', :if => has_docker do
    expect(user 'vagrant').to belong_to_group 'docker'
  end
end
