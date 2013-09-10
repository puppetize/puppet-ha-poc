host { 'puppet1.vagrantup.com':
  host_aliases => ['puppet1'],
  ip           => '172.16.0.10',
}

host { 'puppet2.vagrantup.com':
  host_aliases => ['puppet2'],
  ip           => '172.16.0.11',
}

package { 'puppetmaster-passenger':
  ensure => installed,
}

package { 'glusterfs-server':
  ensure => installed,
} ->

file { '/srv/puppet':
  ensure => directory,
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}
