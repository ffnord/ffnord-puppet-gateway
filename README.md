# Freifunk Gateway Module

* Martin Schütte <info@mschuette.name>
* Daniel Ehlers <danielehlers@mindeye.net>

This module tries to automate the configuration of a FFNord Freifunk Gateway.
The idea is to implement the step-by-step guide on http://wiki.freifunk.net/Freifunk_Hamburg/Gateway with multi community support and almost all other FFNord tools.

Basically this is a complete rewrite of the puppet scripts provided by the
Freifunk Hamburg Community.

The 'ffnord::mesh' block will setup a bridge, fastd, batman, ntp, dhcpd, dns (bind9),
radvd, bird6 and firewall rules vor IPv4 and IPv6.
There are types for setting up monitoring, icvpn, anonymous vpn and alfred announcements.

## Open Problems

* As usual, you should have configure the fully qualified domain name (fqdn) before running
  this module, you can check this with 'hostname -f'.
* The configured dns server only provide support for the root zone.
  Custom tlds are currently not supported.  
* Bird6 must be reconfigured after a puppet run, otherwise the icvpn protocols are not available
* When touching the network devices on a rerun named should be restarted.

## TODO

* Bird IPv4 Route exchange
* Apply firewall rules automatially, when all rules are defined.
* Deactivate radvd in maintenance mode

## Usage

Install as a puppet module, then include with node-specific parameters.

### Dependencies

Install Puppet and some required modules with:

```
apt-get install --no-install-recommends puppet git
puppet module install puppetlabs-stdlib
puppet module install puppetlabs-apt
puppet module install puppetlabs-vcsrepo
puppet module install saz-sudo
puppet module install torrancew-account
```

Then add this module (which is not in the puppet forge, so it has to be
downloaded manually):

```
cd /etc/puppet/modules
git clone https://github.com/ffnord/ffnord-puppet-gateway ffnord
```

### Parameters

Now include the module in your manifest and provide all parameters.
Basically there is one type for mesh network, which pulls
in all the magic and classes for the icvpn connection, monitoring and
anonymous vpn uplink.

Example puppet code (save e.g. as `/root/gateway.pp`):

```
# Global parameters for this host
class { 'ffnord::params':
  router_id => "10.35.0.1", # The id of this router, probably the ipv4 address
                            # of the mesh device of the providing community
  icvpn_as => "65035",      # The as of the providing community
  wan_devices => ['eth0']   # A array of devices which should be in the wan zone
}

# You can repeat this mesh block for every community you support
ffnord::mesh { 'mesh_ffgc':
      mesh_name    => "Freifunk Gotham City",
      mesh_code    => "ffgc",
      mesh_as      => 65035,
      mesh_mac     => "de:ad:be:ef:de:ad",
      mesh_ipv6    => "fd35:f308:a922::ff00/64
      mesh_ipv4    => "10.35.0.1/19"

      fastd_secret => "50292dd647f0e41eb0c72f18c652bfd1bea8c8bd00ae9da3f772068b78111644",
      fastd_port   => 10035,
      fastd_peers_git => 'git://somehost/peers.git',

      dhcp_ranges => [ '10.35.0.2 10.35.0.254'
                     , '10.35.1.1 10.35.1.254'
                     , '10.35.2.2 10.35.2.254'
                     , '10.35.3.2 10.35.3.254'
                     , '10.35.4.2 10.35.4.254'
                     ],
      dns_servers => [ '10.35.5.1'
                     , '10.35.10.1'
                     , '10.35.15.1'
                     , '10.35.20.1'
                     ]
      }

class {'ffnord::vpn::provider::hideio':
  openvpn_server => "nl-7.hide.io",
  openvpn_port   => 3478,
  openvpn_user   => "wayne"
  openvpn_password => "brucessecretpw",
}

ffnord::bird6::icvpn { 'gotham_city0':
  icvpn_as => 65035,
  icvpn_ipv4_address => "10.112.0.1",
  icvpn_ipv6_address => "fec0::a:cf:0:35",
  icvpn_exclude_peerings     => [gotham],
  tinc_keyfile       => "/root/tinc_rsa_key.priv"
}

class { 'ffnord::monitor::munin':
      , host => '10.35.31.1'
}

class { 'ffnord::monitor::nrpe':
      , allowed_hosts => '10.35.31.1'
      }

class { 'ffnord::alfred':}
```

#### Mesh Type
```
ffnord :: mesh { '<mesh_code>':
  mesh_name,        # Name of your community, e.g.: Freifunk Gotham City
  mesh_code,        # Code of your community, e.g.: ffgc
  mesh_as,          # AS of your community
  mesh_mac,         # mac address mesh device: 52:54:00:bd:e6:d4
  mesh_ipv6,        # ipv6 address of mesh device in cidr notation, e.g. 10.35.0.1/19
  mesh_ipv4,        # ipv4 address of mesh device in cidr notation, e.g. fd35:f308:a922::ff00/64
  mesh_peerings,    # path to the local peerings description yaml file

  fastd_secret,     # fastd secret
  fastd_port,       # fastd port
  fastd_peers_git,  # fastd peers repository

  dhcp_ranges = [], # dhcp pool
  dns_servers = [], # other dns servers in your network
}
```

#### ICVPN Type
```
ffnord :: bird6::icvpn {
  icvpn_as,            # AS of the community peering
  icvpn_ipv4_address,  # transfer network IPv4 address
  icvpn_ipv6_address,  # transfer network IPv6 address
  icvpn_peerings = [], # Lists of icvpn names

  tinc_keyfile,        # Private Key for tinc
}
```

#### Peering description
Be aware that currently the own system mesh address will not be filtered.

```
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
```

### Firewall

The firewall rules created are collected in `/etc/iptables.d`, they are not applied
automatically! You have to call `build-firewall` to apply them.

### Run Puppet

To apply the puppet manifest (e.g. saved as `gateway.pp`) run:

```
puppet apply --verbose /root/gateway.pp
build-firewall
```

The verbose flag is optional and shows all changes.
To be even more catious you can also add the `--noop` flag to only show changes
but not apply them.

## Maintenance Mode

To allow administrative operations on a gateway without harming user connections
you should bring the gateway into maintenance mode:

```
maintenance on
```

This will deactivate the gateway feature of batman in the next run of check-gateway.
And after DHCP-Lease-Time there should be no user device with a default route to
the gateway. 

To deactivate maintenance mode and reactivate the batman-adv gateway feature:

```
maintenance off
```
