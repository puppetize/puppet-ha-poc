#!/usr/bin/env ruby
# Reads "environment.yaml" and provisions the current machine based
# on its hostname.

require 'yaml'

# Add an entry to /etc/hosts, if it doesn't exist.
def ensure_host(ip, name, *aliases)
  content =  File.read '/etc/hosts'

  return if content.lines.any? { |line|
    _ip, *_names = line.split
    _ip == ip and _names.include? name
  }

  puts "Adding #{name} (#{ip}) to /etc/hosts"
  content += "#{ip} #{name} #{aliases.join ' '}\n"
  File.write '/etc/hosts', content
end

# Add an entry to /etc/fstab, if it doesn't exist.
def ensure_fstab(spec, file, vfstype, mntopts)
  content = File.read '/etc/fstab'

  return if content.lines.any? { |line|
    line.split[1] == file
  }

  puts "Adding #{spec} => #{file} to /etc/fstab"
  content += "#{spec} #{file} #{vfstype} #{mntopts} 0 0\n"
  File.write '/etc/fstab', content
end

# Check if a Debian package is already installed.
def package_installed?(name)
  system "dpkg -l #{name} 2>/dev/null >&2"
  $?.exitstatus == 0
end

# Ensure that the given packages are installed.
def ensure_package(*names)
  uninstalled = names.reject { |name| package_installed? name }
  unless uninstalled.empty?
    sh "DEBIAN_FRONTEND=noninteractive apt-get install -qq #{uninstalled.join ' '} >/dev/null"
  end
end

# Ensure that the PuppetLabs API repository is available.
def ensure_puppetlabs_repository
  codename = `lsb_release -cs`.chomp
  debfile = "puppetlabs-release-#{codename}.deb"
  deburl = "http://apt.puppetlabs.com/#{debfile}"

  unless package_installed? 'puppetlabs-release'
    sh "wget -q -O #{debfile} #{deburl}"
    sh "dpkg -i #{debfile} >/dev/null"
    sh "apt-get update -qq"
  end
end

# Execute a shell command and exit from Ruby if it fails.
def sh(command)
  puts "+ #{command}"
  system 'sh', '-c', command
  if $?.exitstatus != 0
    exit $?.exitstatus
  end
end

class Configuration
  def self.load_file(filename)
    new YAML.load_file(filename)
  end

  def initialize(data)
    @data = data
  end

  def roles
    @data.keys.map do |name|
      role name
    end
  end

  def role(name)
    Role.new name, @data[name]
  end

  def hosts
    roles.map { |sc| sc.hosts }.flatten
  end

  def host(hostname)
    hosts.find { |i| i.hostname == hostname }
  end
end

class Role
  attr_reader :name

  def initialize(name, details)
    @name = name
    @details = details
  end

  def hosts
    (1..@details[:instances]).map do |instance|
      Host.new self, instance
    end
  end

  def hostname(instance)
    "#{@name}#{instance}"
  end

  def fqdn(instance)
    "#{hostname instance}.#{`dnsdomainname`.chomp}"
  end

  def ipaddress(instance)
    octets = @details[:ipaddress].split('.')
    (octets[0..2] + [octets[3].to_i + instance - 1]).join('.')
  end
end

class Host
  attr_reader :role, :instance

  def initialize(role, instance)
    @role = role
    @instance = instance
  end

  def ipaddress
    @role.ipaddress @instance
  end

  def fqdn
    @role.fqdn @instance
  end

  def hostname
    @role.hostname @instance
  end

  def up?
    system "ping -c 1 #{hostname} 2>/dev/null >&2"
    $?.exitstatus == 0
  end
end

# Load the virtual machine configuration.
config = Configuration.load_file "#{File.dirname __FILE__}/environment.yaml"

# Add entries for all virtual machines to /etc/hosts.
config.hosts.each do |i|
  ensure_host i.ipaddress, i.fqdn, i.hostname
end

# Find out which machine we are supposed to provision now.
host = config.host `hostname`.chomp

# Provision this machine according to its role.
case host.role.name
when 'gluster'
  ensure_package 'glusterfs-server'

  # Describe the glusterfs volumes to create.
  volumes = {
    'puppet-confdir' => {
      :storage => '/srv/puppet/confdir',
    },
    'puppet-ssldir' => {
      :storage => '/srv/puppet/ssldir',
    }
  }

  # Create the local glusterfs bricks.
  volumes.each do |name, details|
    unless File.directory? details[:storage]
      sh "mkdir -p #{details[:storage]}"
    end
  end

  # Probe all running gluster instances.
  peers = []
  host.role.hosts.each do |i|
    if i.up?
      sh "gluster peer probe #{i.hostname}"
      peers << i.hostname
    end
  end

  # Create and start the glusterfs volumes.
  if peers.size >= 2
    volumes.each do |name, details|
      system "gluster volume info #{name} 2>/dev/null >&2"
      if $?.exitstatus != 0
        bricks = peers[0..1].map { |peer| "#{peer}:#{details[:storage]}" }

        sh "gluster volume create #{name} replica 2 #{bricks.join ' '}"
        sh "gluster volume start #{name}"
      end
    end
  end

when 'puppet'
  # Install Puppet from the PuppetLabs repository.
  ensure_puppetlabs_repository

  # Install the glusterfs client package (uses FUSE).
  ensure_package 'glusterfs-client'

  # glusterfs volume mount points
  volumes = {
    '/etc/puppet' => {
      :volume => 'puppet-confdir',
      :owner  => 'root:root',
      :mode   => '755'
    },
    '/var/lib/puppet/ssl' => {
      :volume => 'puppet-ssldir',
      :owner  => 'puppet:root',
      :mode   => '771'
    }
  }

  # Select one of two gluster instance to mount from, assuming blindly
  # that both instances are currently up and configured.
  gluster = config.role('gluster').hosts.
    at((host.instance - 1) % 2).hostname

  # Ensure that the base directory for /var/lib/puppet/ssl exists and
  # has correct permissions.  The "puppet" user already exists on the
  # Vagrant box.
  unless File.directory? '/var/lib/puppet'
    sh 'mkdir /var/lib/puppet'
    sh 'chmod 750 /var/lib/puppet'
    sh 'chown puppet:puppet /var/lib/puppet'
  end

  # Mount the glusterfs volumes.
  volumes.each do |mountpoint, details|
    device = "#{gluster}:/#{details[:volume]}"

    unless File.directory? mountpoint
      sh "mkdir -p #{mountpoint}"
    end

    ensure_fstab device, mountpoint, 'glusterfs', 'defaults,_netdev'

    unless `mount`.include? device
      sh "mount #{mountpoint}"
      sh "chmod #{details[:mode]} #{mountpoint}"
      sh "chown #{details[:owner]} #{mountpoint}"
    end
  end

  unless File.exists? '/etc/puppet/autosign.conf'
    puts "Creating /etc/puppet/autosign.conf"
    content = "*.#{`dnsdomainname`.chomp}\n"
    File.write '/etc/puppet/autosign.conf', content
  end

  # Install the Puppet packages.
  ensure_package 'puppet', 'puppetmaster-passenger'

  # Direct local Puppet runs to use the local master.
  ensure_host host.ipaddress, 'puppet'

when 'agent'
  # Install Puppet from the PuppetLabs repository.
  ensure_puppetlabs_repository

  # Add host entries for dnsmasq to return in a round-robin fashion.
  config.role('puppet').hosts.each do |h|
    ensure_host h.ipaddress, 'puppet'
  end

  # Install packages and configure dnsmasq as the local resolver.
  ensure_package 'dnsmasq', 'resolvconf', 'puppet'

  # This should succeed now, no matter which Puppet master is up.
  sh "puppet agent -t"

  # Run the agent individually against all available masters.
  config.role('puppet').hosts.each do |h|
    sh "puppet agent -t #{h.fqdn}" if h.up?
  end
end
