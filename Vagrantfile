# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  #config.vm.provider("virtualbox") { |v| v.gui = true }

  order = %w{gluster puppet agent}

  environment = YAML.load_file('environment.yaml').sort { |a, b|
    order.index(a.first) <=> order.index(b.first)
  }

  environment.each do |role, details|
    (1..details[:instances]).each do |instance|
      hostname = "#{role}#{instance}"

      octets = details[:ipaddress].split('.')
      ipaddress = (octets[0..2] + [octets[3].to_i + instance - 1]).join('.')

      config.vm.define hostname do |multi|
        multi.vm.box = 'wheezy'
        multi.vm.box_url = 'http://puppet-vagrant-boxes.puppetlabs.com/debian-70rc1-x64-vbox4210-nocm.box'
        multi.vm.hostname = "#{hostname}.vagrantup.com"
        multi.vm.network "private_network", ip: ipaddress
        multi.vm.provision "shell", inline: "DEBIAN_FRONTEND=noninteractive apt-get install -qq ruby >/dev/null && ruby /vagrant/provision.rb"
      end
    end
  end
end
