Getting Started
===============

Preparation
-----------

Dependencies
````````````

The ffnord-puppet-gateway module has some Dependencies to the host:

* OS: Debian 7.7 (Wheezy) or 8.1 (Jessie)
* Packages: puppet git apt-transport-https
* Preinstalled needed puppet modules

 * puppetlabs-stdlib
 * puppetlabs-apt
 * puppetlabs-vcsrepo
 * saz-sudo
 * torrancew-account

Recieving the module
````````````````````

Releases of ffnord-puppet-gateway are managed using Git.

Checkout the module into the ``/etc/puppet/modules`` directory:

::
  
  cd /etc/puppet/modules
  git clone https://github.com/ffnord/ffnord-puppet-gateway ffnord

::


Summary
```````

The following lists possible commands for preparing a fresh ``Debian`` host.

::

  apt-get install --no-install-recommends puppet git
  puppet module install puppetlabs-stdlib --version 4.15.0
  puppet module install puppetlabs-apt --version 1.5.1
  puppet module install puppetlabs-vcsrepo --version 1.3.2
  puppet module install saz-sudo --version 4.1.0
  puppet module install torrancew-account --version 0.1.0

  cd /etc/puppet/modules
  git clone https://github.com/ffnord/ffnord-puppet-gateway ffnord

Parameters
----------

Now include the module in your manifest and provide all parameters.
Basically there is one type for mesh network, which pulls
in all the magic and classes for the icvpn connection, monitoring and
anonymous vpn uplink.

Please make sure that the content of your fastd key-file looks like this:

::

  secret "**************************";

::

The stars are replaced by your private fastd key

A First Manifest
----------------

After we have prepared the dependencies and received the module source we can
start describing what we want to setup. In the following will discuss an
example manifest and its dependencies.

::

  # Global parameters for this host
  class { 
    'ffnord::params':
      router_id => "10.35.0.1",  # The id of this router, probably the ipv4 address
                                 # of the mesh device of the providing community
      icvpn_as => "65035",       # The AS of the providing community
      wan_devices => ['eth0'],   # An array of devices which should be in the wan zone
      
      wmem_default => 87380,     # Define the default socket send buffer
      wmem_max     => 12582912,  # Define the maximum socket send buffer
      rmem_default => 87380,     # Define the default socket recv buffer
      rmem_max     => 12582912,  # Define the maximum socket recv buffer
      
      gw_control_ips => "192.0.2.1 192.0.2.2 192.0.2.3", # Define target to ping against for function check

      max_backlog  => 5000,      # Define the maximum packages in buffer

      batman_version => 15,     # B.A.T.M.A.N. adv version
  }

  # You can repeat this mesh block for every community you support
  ffnord::mesh { 
    'mesh_ffgc':
      mesh_name    => "Freifunk Gotham City",        # Name of your community, e.g. 'Freifunk Gotham City'
      mesh_code    => "ffgc",                        # Code of your community, e.g. 'ffgc'
      mesh_as      => 65035,                         # AS of your community
      mesh_mac     => "de:ad:be:ef:de:ad",           # mac address mesh device: e.g. '52:54:00:bd:e6:d4'
      vpn_mac      => "de:ad:be:ff:de:ad",           # mac address vpn device, ideally != mesh_mac and unique
      range_ipv4   => "10.35.0.0/16",                # ipv4 range allocated to community in cidr notation, e.g. '10.35.0.1/16'
      mesh_ipv4    => "10.35.0.1/19",                # ipv4 address in cidr notation, e.g. '10.35.0.1/19'
      mesh_ipv6    => "fd35:f308:a922::ff00/64",     # ipv6 address in cidr notation, e.g.
      mesh_peerings => "/root/mesh_peerings.yaml",   # path to the local peerings description yaml file
      mesh_mtu     => "1280",                        # mtu used, default only suitable for fastd via ipv4
       
      fastd_peers_git => 'git://somehost/peers.git', # fastd peers
      fastd_secret => "/root/fastd_secret.key",      # fastd secret
      fastd_port   => 11280,                         # fastd port
      fastd_verify=> 'true',                         # fastd verification override string for connection attempts, e.g. 'true' = accept all, '' = default (no override)

      dhcp_ranges => [ '10.35.0.2 10.35.0.254'       # dhcp pool, the whole net is 10.71.0.0 - 10.71.63.255 
                                                     # so take one 32dr of this range but don't give out the ip of the gw itself
                     , '10.35.1.1 10.35.1.254'       # more ranges can be added here
                     , '10.35.2.2 10.35.2.254'
                     , '10.35.3.2 10.35.3.254'
                     , '10.35.4.2 10.35.4.254'
                     ],
      dns_servers => [ '10.35.5.1'                   # other dns servers in your network
                     , '10.35.10.1'
                     , '10.35.15.1'
                     , '10.35.20.1'
                     ],
      mesh_hop_penalty => 60,                        # hop_penalty for gateway hops
  }

  ffnord::named::zone {
    'ffgc': zone_git => 'git://somehost/ffgc-zone.git';
  }

  ffnord::dhcpd::static {
    'ffgc': static_git => 'git://somehost/ffgc-static.git';
  }

  class {
    'ffnord::vpn::provider::hideio':
      openvpn_server => "nl-7.hide.io",
      openvpn_port   => 3478,
      openvpn_user   => "wayne",
      openvpn_password => "brucessecretpw",
  }

  ffnord::fastd { 
    'ffgc_old':
      mesh_code       => "ffgc",
      mesh_interface  => "ffgc-old",
      mesh_mac        => "de:ad:be:ee:de:ad",
      vpn_mac         => "de:ad:be:fe:de:ad",
      mesh_mtu        => 1426,
      fastd_secret    => "/root/fastd_secret.conf",
      fastd_port      => 10000,
      fastd_peers_git => '/vagrant/fastd/gc/',
      fastd_verify=> 'true',                    # set this to 'true' to accept all fastd keys without verification
  }

  ffnord::icvpn::setup {
    'gotham_city0':
      icvpn_as => 65035,
      icvpn_ipv4_address => "10.207.0.1",
      icvpn_ipv6_address => "fec0::a:cf:0:35",
      icvpn_exclude_peerings     => [gotham], # the own zone to prevent double configuration in icvpn-meta and own zone file
      tinc_keyfile       => "/root/tinc_rsa_key.priv"
  }

  class {
    'ffnord::monitor::munin':
      host => '10.35.31.1'
  }

  class {
    'ffnord::monitor::nrpe':
      allowed_hosts => '10.35.31.1'
  }

  class {
    'ffnord::monitor::zabbix':
      zabbixserver => "10.35.31.1";
  }

  class { 'ffnord::alfred': master => true }

  class { 'ffnord::etckeeper': }
  
  class { 'ffnord::mosh': }

  class { 'ffnord::nullmailer':
    adminaddr => 'noc@example.com',
    remotes => 'mx.gotham.com',
    defaultdomain => 'ffgo.de'.
    
  }

  # Useful packages
  package {
    ['vim','tcpdump','dnsutils','realpath','screen','htop','tcpdump','mlocate','tig','sshguard']:
      ensure => installed;
  }
  
:: 

Firewall
--------

The firewall rules created are collected in ``/etc/iptables.d``, they are not applied
automatically! You have to call ``build-firewall`` to apply them.

On Debian jessie
`````````````
you have to load the ip_tables and ip_conntrack module manally before applying the puppet manifest:

::

    modprobe ip_tables
    modprobe ip_conntrack

::

On Debian jessie add it to autoĺoad on reboot:

::

    echo ip_conntrack >> /etc/modules

::

Run Puppet
``````````

To apply the puppet manifest (e.g. saved as ``/root/gateway.pp``) run:

::

  puppet apply --verbose /root/gateway.pp
  build-firewall

::

The verbose flag is optional and shows all changes. To be even more catious you can
also add the ``--noop`` flag to only show changes but not apply them.  
**This should be run best inside a** ``screen`` **session!**

Re-run Puppet
`````````````

To run puppet again, you have to ensure that old fastd-configurations are deleted before you start:

::

  rm -Rf /etc/fastd/
  puppet apply --verbose /root/gateway.pp
  build-firewall

::

First time: start services
`````````````

::

  /etc/init.d/fastd restart

::

Maintenance Mode
----------------

To allow administrative operations on a gateway without harming user connections
you should bring the gateway into maintenance mode:

::

  maintenance on

::

This will deactivate the gateway feature of batman in the next run of check-gateway (cronjob every minute).
And after DHCP-Lease-Time (usually one hour) there should be no user device left with a default route to
the gateway. 

To deactivate maintenance mode and reactivate the batman-adv gateway feature:

::

  maintenance off

::

check with 

::

  maintenance status

::

FASTD Query
-----------

For debugging purposes we utilize the status socket of fastd using a little
helper script called ``fastd-query``, which itself is a wrapper around ``socat``
and ``jq``. An alias ``fastd-query-${mesh_code}`` is created for every
mesh network. For example you can retrieve the status for some node, where
the node name is equivalent to the peers filename:

::

  # fastd-query-ffgc peers name gc-gw0 

::


Further details
===============



Named Zone Type
---------------

This type enables you to receive a zone file from a git repository, include
it into the named configuration and setup a cronjob for pulling changes in.
By default the cronjob will pull every 30min. 

The provided configuration should not rely on a relative path but use
the absolute path prefixed with ``/etc/bind/zones/${name}/``.

::

  ffnord::named::zone {
    '<name>':
      zone_git; # zone file repo
  }

::

DHCPd static type
-----------------

This type enables you to receive a file with static dhcp assignments from a git repository, include
it into the dhcp configuration and setup a cron job for pulling changes in.
By default the cronjob will pull every 30min.

The provided configuration should not rely on relative path but use
the absolute path prefixed with '/etc/dhcp/statics/${name}/'.
The name should be the same as the community the static assignments belong to.
There has to be a file named static.conf in the repo.

::

  ffnord::dhcpd::static {
    '<name>':
      static_git; # dhcp static file repo
  }

::

ICVPN Type
----------

::

  ffnord :: icvpn::setup {
    icvpn_as,            # AS of the community peering
    icvpn_ipv4_address,  # transfer network IPv4 address
    icvpn_ipv6_address,  # transfer network IPv6 address
    icvpn_peerings = [], # Lists of icvpn names

    tinc_keyfile,        # Private Key for tinc
  }

::

IPv4 Uplink via GRE Tunnel
--------------------------

This is a module for an IPv4 Uplink via GRE tunnel and BGP.
This module and the VPN module are mutually exclusive.
Define the ffnord::uplink::ip class once and ffnord::uplink::tunnel
for each tunnel you want to use. See http://wiki.freifunk.net/Freifunk_Hamburg/IPv4Uplink
for a more detailed description.

::

  class {
    'ffnord::uplink::ip':
      nat_network,        # network of IPv4 addresses usable for NAT
      tunnel_network,     # network of tunnel IPs to exclude from NAT
  }
  ffnord::uplink::tunnel {
     '<name>':
       local_public_ip,  # local public IPv4 of this gateway
       remote_public_ip, # remote public IPv4 of the tunnel endpoint
       local_ipv4,       # tunnel IPv4 on our side
       remote_ip,        # tunnel IPv4 on the remote side
       remote_as,        # ASN of the BGP server announcing a default route for you
  }

::

Peering description
-------------------

Be aware that currently the own system mesh address will not be filtered.

::

  gc-gw1:
    ipv4: "10.35.5.1"
    ipv6: "fd35:f308:a922::ff01"
  gc-gw2:
    ipv4: "10.35.10.1"
    ipv6: "fd35:f308:a922::ff02"
  gc-gw3:
    ipv4: "10.35.15.1"
    ipv6: "fd35:f308:a922::ff03"
  gc-gw4:
    ipv4: "10.35.20.1"
    ipv6: "fd35:f308:a922::ff04"

::
