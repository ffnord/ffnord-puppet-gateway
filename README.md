# Freifunk Gateway Module

Martin Schütte <info@mschuette.name>
Daniel Ehlers <danielehlers@mindeye.net>

This module tries to automate the configuration of a FFNord Freifunk Gateway.
The idea is to implement the step-by-step guide on http://wiki.freifunk.net/Freifunk_Hamburg/Gateway with multi community support and almost all other FFNord tools.

Basically this is a complete rewrite of the puppet scripts provided by the
Freifunk Hamburg Community.

## Open Problems

* The apt repository at http://bird.network.cz/debian/ does not use PGP
  signatures, so `bird` and `bird6` will not be installed automatically.
* As usual, you should have configure the fully qualified domain name (fqdn) before running
  this module.
* Currently this module do not install a dns server, but reports one via 
  dhcp on every mesh bridge.
* Since puppet renders all templates during initial processing, you have
  to clone the icvpn repo by hand before starting the puppet manifest.

## TODO

* Bird IPv4 Route exchange
* named/bind9 Freifunk/Hackint/DN42 TLDs

## Usage

Install as a puppet module, then include with node-specific parameters.

### Dependencies

Install Puppet and some required modules with:

```
apt-get install puppet git
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
cd /etc/
mkdir tinc
git clone https://github.com/sargon/icvpn 
```

### Parameters

Now include the module in your manifest and provide all parameters.
Basically there is one type for mesh network, which pulls
in all the magic and classes for the icvpn connection, monitoring and
anonymous vpn uplink.

Example puppet code (save e.g. as `/root/gateway.pp`):

```
# You can repeat this mesh block for every community you support
ffnord::mesh { 'mesh_ffeh':
      , mesh_name => "Freifunk Entenhausen"
      , mesh_code => "ffeh"
      , mesh_mac  => "de:ad:be:ef:de:ad"
      , mesh_prefix_ipv6 => "fda1:384a:74de:1::/64"
      , mesh_prefix_ipv4 => "255.255.255.128"
      , mesh_ipv6  => "fda1:384a:74de:1::1"
      , mesh_ipv4  => "10.13.37.1"

      , fastd_secret => "50292dd647f0e41eb0c72f18c652bfd1bea8c8bd00ae9da3f772068b78111644"
      , fastd_port   => 10000

      , dhcp_ranges => ['10.13.37.2 10.13.37.254','10.13.38.1 10.13.38.254']
      , dns_servers => ['10.13.39.1','10.13.41.1']
      }

class {'ffnord::vpn::provider::hideio':
  openvpn_server => "nl-7.hide.io",
  openvpn_port   => 3478,
  openvpn_user   => "gordan"
  openvpn_password => "secretpw",
}


class { 'ffnord::monitor::munin':
      , host => '192.168.0.1'
}

class { 'ffnord::monitor::nrpe':
      , allowed_hosts => '217.70.197.95'
      }
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

### Run Puppet

To apply the puppet manifest (e.g. saved as `gw.pp`) run:

```
puppet apply --verbose /root/gateway.pp
```

The verbose flag is optional and shows all changes.
To be even more catious you can also add the `--noop` flag to only show changes
but not apply them.

