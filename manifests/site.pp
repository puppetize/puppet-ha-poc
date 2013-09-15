# Regex node declaration is broken:
# http://projects.puppetlabs.com/issues/21405
node default
{
  case $::hostname {
    /^postgres\d$/: {
      class { 'puppetdb::database::postgresql':
        listen_addresses => '*',
      }
    }

    /^puppetdb\d$/: {
      class { 'puppetdb::server':
        listen_address     => '0.0.0.0',
	ssl_listen_address => '0.0.0.0',
	# FIXME: "postgres" should be the active master
        database_host      => "postgres1.${::domain}",
      }
    }

    /^puppet\d$/: {
      class { 'puppetdb::master::config':
        puppetdb_server     => 'puppetdb',
	puppet_service_name => 'apache2',
      }
    }

    /^agent\d$/: {
      if $::sshdsakey {
        @@sshkey { $::fqdn:
          ensure       => present,
          host_aliases => [$::hostname],
          key          => $::sshdsakey,
          type         => 'ssh-dss',
        }
      } elsif $::sshecdsakey {
        @@sshkey { $::fqdn:
          ensure       => present,
          host_aliases => [$::hostname],
          key          => $::sshecdsakey,
          type         => 'ssh-ecdsa',
        }
      } elsif $::sshrsakey {
        @@sshkey { $::fqdn:
          ensure       => present,
          host_aliases => [$::hostname],
          key          => $::sshrsakey,
          type         => 'ssh-rsa',
        }
      }

      Sshkey <<| |>>

      resources { 'sshkey':
        purge => true,
      }
    }
  }
}
