# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    config.vm.define "vagrant-centos70"
    config.vm.box = "centos70"
    config.vm.synced_folder ".", "/vagrant", disabled: true
end
