# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  %w{puppet1 puppet2}.each do |name|
    config.vm.define name do |puppet|
      puppet.vm.box = "wheezy"
      puppet.vm.box_url = "http://puppet-vagrant-boxes.puppetlabs.com/debian-70rc1-x64-vbox4210-nocm.box"
      puppet.vm.provision "shell", inline: "wget http://apt.puppetlabs.com/puppetlabs-release-wheezy.deb && dpkg -i puppetlabs-release-wheezy.deb && apt-get update && apt-get install puppet"
      puppet.vm.provision "puppet"
    end
  end

end
