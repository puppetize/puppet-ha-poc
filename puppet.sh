#!/bin/sh -ex

codename='wheezy'
hostlist='puppet1 puppet2'
#bricklist='puppet1:/etc/puppet puppet2:/etc/puppet'

if [ ! -f puppetlabs-release-${codename}.deb ]; then
        wget http://apt.puppetlabs.com/puppetlabs-release-${codename}.deb
fi

if ! dpkg -l puppetlabs-release >/dev/null 2>&1; then
        dpkg -i puppetlabs-release-${codename}.deb
        apt-get update
fi

package()
{
        for pkg in $*; do
                if ! dpkg -l ${pkg} >/dev/null 2>&1; then
                        DEBIAN_FRONTEND=noninteractive apt-get install -qq ${pkg}
                fi
        done
}

package puppet puppetmaster-passenger glusterfs-server

if ! grep -q '172\.16\.0\.10' /etc/hosts; then
        cat >> /etc/hosts << EOF
172.16.0.10 puppet1.vagrantup.com puppet1
172.16.0.11 puppet2.vagrantup.com puppet2
EOF
fi

for host in ${hostlist}; do
        gluster peer probe ${host} || true
done

#gluster volume create replica 2 transport tcp ${bricklist}
