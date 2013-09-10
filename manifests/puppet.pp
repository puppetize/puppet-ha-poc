package { 'puppetmaster-passenger':
  ensure => installed,
} ->

file { '/var/lib/puppet/reports':
  ensure => directory,
  owner  => 'puppet',
  group  => 'puppet',
  mode   => '0750',
} ~>

service { 'apache2':
  ensure    => running,
  hasstatus => true,
}
