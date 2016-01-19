require 'serverspec'
require 'net/ssh'

set :backend, :ssh

# Set PATH
set :path, '/usr/local/sbin:/usr/sbin:/sbin:$PATH'
