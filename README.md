puppet-ha-poc
=============

Simply `vagrant up` and wait.  Puppet clients `agent*` will be provisioned last.  If all
goes well, then they will run `puppet agent -t` once against any master via DNS round-robin
and then once against each available master, individually.  All Puppet runs should succeed.

Requirements
------------

* Vagrant (tested with 1.3.1)
* VirtualBox (tested with 4.2)
