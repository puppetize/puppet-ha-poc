Puppet HA: Proof-of-Concept
===========================

Simply `vagrant up` and wait.  Puppet clients `agent*` will be provisioned
last.  If all goes well, then they will run `puppet agent -t` once against
any master via DNS round-robin and then once against each available master,
individually.  All Puppet runs should succeed.

If you don't have the time or a powerful enough development machine, have
a look at the file [output.txt](output.txt).  It contains the output of the
shell provisioner for a successful run of `vagrant up | egrep 'Machine booted
and ready|Running provisioner|^[+]'`.

Requirements
------------

* Vagrant (tested with 1.3.1)
* VirtualBox (tested with 4.2)
