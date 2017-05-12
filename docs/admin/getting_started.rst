Getting Started
===============

Preparation
-----------

Dependencies
````````````

The ffnord-puppet-gateway module has some depencies to the host:

* OS: Debian 7.7 (Wheezy) or 8.1 (Jessie)
* Packages: puppet git apt-transport-https
* Preinstalled puppet modules

 * puppetlabs-stdlib --version 4.15.0
 * puppetlabs-apt --version 1.5.1
 * puppetlabs-vcsrepo --version 1.3.2
 * saz-sudo --version 4.1.0
 * torrancew-account --version 0.1.0


Recieving the module
````````````````````

Releases of ffnord-puppet-gateway are managed using Git tags. We recommend to 
use the latest stable release, especially if you are just starting using this
puppet module, or puppet at all. 

Checkout the module into the ``/etc/puppet/modules`` directory.


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
      mesh_name    => "Freifunk Gotham City",
      mesh_code    => "ffgc",
      mesh_as      => 65035,
      mesh_mac     => "de:ad:be:ef:de:ad",
      vpn_mac      => "de:ad:be:ff:de:ad",
      mesh_ipv6    => "fd35:f308:a922::ff00/64",
      mesh_ipv4    => "10.35.0.1/19",
      mesh_mtu     => "1280",
      range_ipv4   => "10.35.0.0/16",
      mesh_peerings => "/root/mesh_peerings.yaml",
      
      fastd_secret => "/root/fastd_secret.key",
      fastd_port   => 11280,
      fastd_peers_git => 'git://somehost/peers.git',
      fastd_verify=> 'true',                      # set this to 'true' to accept all fastd keys without verification

      dhcp_ranges => [ '10.35.0.2 10.35.0.254'    # the whole net is 10.71.0.0 - 10.71.63.255 
                                                  # so take one 32dr of this range but don't give out the ip of the gw itself
                     , '10.35.1.1 10.35.1.254'    # more ranges can be added here
                     , '10.35.2.2 10.35.2.254'
                     , '10.35.3.2 10.35.3.254'
                     , '10.35.4.2 10.35.4.254'
                     ],
      dns_servers => [ '10.35.5.1'
                     , '10.35.10.1'
                     , '10.35.15.1'
                     , '10.35.20.1'
                     ],
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

  secret "<*****>";
