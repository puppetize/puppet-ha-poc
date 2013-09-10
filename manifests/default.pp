node puppetmaster
{
  package { 'puppetmaster-passenger':
    ensure => installed,
  }
}

node 'puppet1' inherits puppetmaster
{
}

node 'puppet2' inherits puppetmaster
{
}
