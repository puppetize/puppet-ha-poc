# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  %w{puppet1 puppet2}.each_with_index do |name, index|
    config.vm.define name do |multi|
      multi.vm.box = "wheezy"
      multi.vm.box_url = "http://puppet-vagrant-boxes.puppetlabs.com/debian-70rc1-x64-vbox4210-nocm.box"
      multi.vm.hostname = "#{name}.vagrantup.com"
      multi.vm.network "private_network", ip: "172.16.0.#{10 + index}"
      multi.vm.provision "shell", :inline => "wget http://apt.puppetlabs.com/puppetlabs-release-wheezy.deb && dpkg -i puppetlabs-release-wheezy.deb && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -qq puppet puppetmaster-passenger"
      multi.vm.provision "puppet" do |puppet|
        puppet.manifest_file = "puppet.pp"
      end
    end
  end

end
